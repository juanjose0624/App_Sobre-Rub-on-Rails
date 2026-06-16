class TablasController < ApplicationController
  before_action :validar_tabla

  # GET /tablas/:tabla
  def tabla
    if params[:q].present?
      columnas = ActiveRecord::Base.connection.columns(@tabla).map(&:name)
      termino = ActiveRecord::Base.connection.quote("%#{params[:q]}%")

      condiciones = columnas.map do |c|
        "CAST(#{c} AS TEXT) ILIKE #{termino}"
      end.join(" OR ")

      sql = "SELECT * FROM #{@tabla} WHERE #{condiciones}"
      @registros = ActiveRecord::Base.connection.exec_query(sql)
    else
      @registros = ActiveRecord::Base.connection.exec_query("SELECT * FROM #{@tabla}")
    end

    @pk = pk_columna

    # =========================
    # ESTADÍSTICAS
    # =========================

    @total_registros = ActiveRecord::Base.connection.select_value(
      "SELECT COUNT(*) FROM #{@tabla}"
    )

    # maneja PK compuesta (array) y PK simple (string)
    @ultimo_id = if @pk.is_a?(Array)
                     @pk.map { |col|
                       ActiveRecord::Base.connection.select_value("SELECT MAX(#{col}) FROM #{@tabla}")
                     }.join(" / ")
    else
                     ActiveRecord::Base.connection.select_value("SELECT MAX(#{@pk}) FROM #{@tabla}")
    end

    @num_columnas = ActiveRecord::Base.connection.columns(@tabla).size

    # Tomar la primera columna que no sea PK para contar valores únicos
    pk_cols = Array(@pk)
    columna = ActiveRecord::Base.connection.columns(@tabla)
      .map(&:name)
      .reject { |c| pk_cols.include?(c) }
      .first

    if columna
      @valores_unicos = ActiveRecord::Base.connection.select_value(
        "SELECT COUNT(DISTINCT #{columna}) FROM #{@tabla}"
      )
    end

    render "home/tabla"
  end

  # POST /tablas/:tabla/create
  def create
    columnas_validas = columnas_tabla
    datos_filtrados = datos.slice(*columnas_validas)

    if datos_filtrados.empty?
      render json: { error: "No se enviaron datos para insertar" }, status: :unprocessable_entity
      return
    end

    pk = pk_columna

    #  si la PK es compuesta, no se puede auto-generar
    if pk.is_a?(Array)
      pk.each do |col|
        if datos_filtrados[col].blank?
          render json: { error: "Esta tabla tiene clave primaria compuesta. Debes proveer un valor para '#{col}'." }, status: :unprocessable_entity
          return
        end
      end
    else
      # PK simple: auto-generar si no viene
      if !datos_filtrados.key?(pk) || datos_filtrados[pk].blank?
        max_id = ActiveRecord::Base.connection.exec_query(
          "SELECT COALESCE(MAX(#{pk}), 0) + 1 AS next_id FROM #{@tabla}"
        ).first["next_id"]

        datos_filtrados[pk] = max_id
      end
    end

    columnas = datos_filtrados.keys
      .map { |c| ActiveRecord::Base.connection.quote_column_name(c) }
      .join(", ")

    valores = datos_filtrados.values
      .map { |v| ActiveRecord::Base.connection.quote(v) }
      .join(", ")

    begin
      ActiveRecord::Base.connection.execute(
        "INSERT INTO #{@tabla} (#{columnas}) VALUES (#{valores})"
      )
      head :ok

    rescue => e
      logger.error "Error INSERT en #{@tabla}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # PATCH /tablas/:tabla/update/:id
  def update
    pk = pk_columna
    id = params[:id]

    datos = params[:datos] ? params[:datos].to_unsafe_h : {}

    columnas_validas = columnas_tabla
    datos_filtrados = datos.slice(*columnas_validas)

    if datos_filtrados.empty?
      render json: { error: "No se enviaron datos para actualizar" }, status: :unprocessable_entity
      return
    end

    set_clause = datos_filtrados.map do |col, val|
      "#{ActiveRecord::Base.connection.quote_column_name(col)} = #{ActiveRecord::Base.connection.quote(val)}"
    end.join(", ")

    begin
      # ✅ CORREGIDO: usa where_pk para manejar PK compuesta
      ActiveRecord::Base.connection.execute(
        "UPDATE #{@tabla} SET #{set_clause} WHERE #{where_pk(pk, id)}"
      )

      render json: { ok: true }

    rescue => e
      Rails.logger.error "Error UPDATE en #{@tabla}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # DELETE /tablas/:tabla/delete/:id
  def delete
    pk = pk_columna

    begin
      # ✅ CORREGIDO: usa where_pk para manejar PK compuesta
      ActiveRecord::Base.connection.execute(
        "DELETE FROM #{@tabla} WHERE #{where_pk(pk, params[:id])}"
      )
      head :ok

    rescue ActiveRecord::InvalidForeignKey
      render json: { error: "No se puede eliminar: existen registros relacionados." }, status: :forbidden

    rescue => e
      logger.error "Error eliminando #{@tabla} id=#{params[:id]}: #{e.message}"
      render json: { error: "Error al eliminar el registro." }, status: :internal_server_error
    end
  end

  private

  def validar_tabla
    tablas_permitidas = %w[
      categories customer_customer_demo customer_demographics customers
      employee_territories employees order_details orders products region
      shippers suppliers territories us_states
    ]

    @tabla = params[:tabla]

    unless tablas_permitidas.include?(@tabla)
      render json: { error: "Tabla no permitida" }, status: :forbidden
    end
  end

  # Obtiene columnas reales de la tabla
  def columnas_tabla
    @columnas_tabla ||= ActiveRecord::Base.connection.columns(@tabla).map(&:name)
  end

  # Obtiene datos enviados por el formulario
  def datos
    params.to_unsafe_h.except(
      :controller,
      :action,
      :tabla,
      :id,
      :format
    )
  end

  # Detecta la PK automáticamente (puede ser String o Array si es compuesta)
  def pk_columna
    @pk_columna ||= ActiveRecord::Base.connection.primary_key(@tabla)
  end

  # ✅ NUEVO: construye el WHERE correcto para PK simple o compuesta
  # Para PK compuesta, params[:id] debe venir como "val1,val2"
  def where_pk(pk, id)
    if pk.is_a?(Array)
      valores = id.to_s.split(",")
      pk.zip(valores).map do |col, val|
        "#{ActiveRecord::Base.connection.quote_column_name(col)} = #{ActiveRecord::Base.connection.quote(val)}"
      end.join(" AND ")
    else
      "#{ActiveRecord::Base.connection.quote_column_name(pk)} = #{ActiveRecord::Base.connection.quote(id)}"
    end
  end
end
