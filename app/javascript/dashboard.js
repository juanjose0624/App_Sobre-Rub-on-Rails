import Swal from "sweetalert2"

document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".btn-tabla").forEach((boton) => {
    boton.onclick = () => {
      const tabla = boton.dataset.tabla;

      Swal.fire({
        title: "Abrir tabla",
        text: `¿Deseas ver la tabla ${tabla}?`,
        icon: "question",
        showCancelButton: true,
        confirmButtonText: "Sí, abrir",
        cancelButtonText: "Cancelar"
      }).then((result) => {
        if (result.isConfirmed) {
          window.location.href = `/tablas/${tabla}`;
        }
      });
    };
  });
});