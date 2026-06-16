class HomeController < ApplicationController

  TABLAS_PERMITIDAS = %w[
   categories
    customer_customer_demo
    customer_demographics
    customers
    employee_territories
    employees
    order_details
    orders
    products
    region
    shippers
    suppliers
    territories
    us_states
  ]

  def index
  end

  def tabla
    @tabla = params[:nombre]

    unless TABLAS_PERMITIDAS.include?(@tabla)
      redirect_to dashboard_path and return
    end

    @registros = ActiveRecord::Base.connection.execute(
      "SELECT * FROM #{@tabla}"
    )
  end

  def create
    tabla = params[:nombre]
    datos = params[:datos]

    unless TABLAS_PERMITIDAS.include?(tabla)
      head :forbidden and return
    end

    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{tabla} (name) VALUES ($1)",
      [datos]
    )

    head :ok
  end

  def delete
    tabla = params[:nombre]
    id = params[:id]

    unless TABLAS_PERMITIDAS.include?(tabla)
      head :forbidden and return
    end

    ActiveRecord::Base.connection.execute(
      "DELETE FROM #{tabla} WHERE id = $1",
      [id]
    )

    head :ok
  end

end