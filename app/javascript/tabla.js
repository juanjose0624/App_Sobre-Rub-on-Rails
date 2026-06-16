import Swal from "sweetalert2";

document.addEventListener("DOMContentLoaded", () => {
  const btnNuevo = document.getElementById("btn-nuevo");
  const tabla = btnNuevo?.dataset.tabla;

  // ----------------- ELEMENTOS DEL DOM -----------------
  const formContainer = document.getElementById("form-container");
  const btnCancelar = document.getElementById("btn-cancelar");
  const form = document.getElementById("form-crear");

  // ----------------- MOSTRAR FORMULARIO -----------------
  if (btnNuevo) {
    btnNuevo.addEventListener("click", () => {
      formContainer.style.display = "block";
    });
  }

  if (btnCancelar) {
    btnCancelar.addEventListener("click", () => {
      formContainer.style.display = "none";
      if (form) form.reset();
    });
  }

  // ----------------- CREAR REGISTRO -----------------
  if (form) {
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      const formData = new FormData(form);

      fetch(`/tablas/${tabla}/create`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: formData
      })
      .then(res => {
        if (!res.ok) {
          return res.json().then(data => { throw new Error(data.error) });
        }
        Swal.fire({
          icon: "success",
          title: "Registro creado"
        }).then(() => location.reload());
      })
      .catch(err => {
        Swal.fire({
          icon: "error",
          title: "Error al guardar",
          text: err.message
        });
      });
    });
  }

  // ----------------- ELIMINAR -----------------
  document.querySelectorAll(".btn-eliminar").forEach(btn => {
    btn.addEventListener("click", () => {
      const id = btn.dataset.id;

      Swal.fire({
        title: "¿Eliminar registro?",
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: "Sí, eliminar"
      }).then((result) => {
        if (result.isConfirmed) {
          fetch(`/tablas/${tabla}/delete/${id}`, {
            method: "DELETE",
            headers: {
              "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
            }
          })
          .then(res => {
            if (!res.ok) {
              return res.json().then(data => { throw new Error(data.error) });
            }
            Swal.fire({
              icon: "success",
              title: "Registro eliminado"
            }).then(() => location.reload());
          })
          .catch(err => {
            Swal.fire({
              icon: "error",
              title: "Error al eliminar",
              text: err.message
            });
          });
        }
      });
    });
  });

  // ----------------- EDITAR -----------------
  document.querySelectorAll(".btn-editar").forEach(btn => {
    btn.addEventListener("click", () => {
      const id = btn.dataset.id;
      const fila = btn.closest("tr");
      const inputs = {};

      fila.querySelectorAll("td").forEach((td, index) => {
        const header = document.querySelectorAll("thead th")[index];
        if (!header || header.innerText.trim() === "Acciones") return;

        const colName = header.dataset.col || header.innerText.trim();
        inputs[colName] = td.innerText.trim();
      });

      let html = "";
      Object.entries(inputs).forEach(([col, val]) => {
        if (col === "state_id") return;
        html += `
          <div style="margin-bottom: 10px; text-align: left;">
            <label style="display: block; font-weight: bold;">${col}</label>
            <input id="swal-${col}" class="swal2-input" value="${val}" style="margin: 5px 0; width: 100%;">
          </div>
        `;
      });

      Swal.fire({
        title: "Editar registro",
        html: html,
        showCancelButton: true,
        confirmButtonText: "Guardar",
        preConfirm: () => {
          const datos = {};
          Object.keys(inputs).forEach(col => {
            if (col === "state_id") return;
            const inputElement = document.getElementById(`swal-${col}`);
            datos[col] = inputElement ? inputElement.value : "";
          });
          return datos;
        }
      }).then(result => {
        if (!result.isConfirmed) return;

        fetch(`/tablas/${tabla}/update/${id}`, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
          },
          body: JSON.stringify({ datos: result.value })
        })
        .then(res => {
          if (!res.ok) {
            return res.json().then(data => { throw new Error(data.error) });
          }
          Swal.fire({
            icon: "success",
            title: "Registro actualizado"
          }).then(() => location.reload());
        })
        .catch(err => {
          Swal.fire({
            icon: "error",
            title: "Error al actualizar",
            text: err.message
          });
        });
      });
    });
  });
});