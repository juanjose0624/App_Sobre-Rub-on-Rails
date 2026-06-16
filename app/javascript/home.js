import Swal from "sweetalert2";

document.addEventListener("turbo:load", function () {
  const enterButton = document.getElementById("enterBtn");

  if (enterButton) {
    enterButton.addEventListener("click", function () {
      Swal.fire({
        title: "Bienvenido al sistema",
        text: "Estás a punto de entrar al panel principal",
        icon: "success",

        confirmButtonText: "Entrar",
        confirmButtonColor: "#2563eb",

        background: "#1f2937",
        color: "#ffffff",

        backdrop: `
          rgba(0,0,0,0.7)
        `,
        position: "center",
        showClass: {
          popup: "animate__animated animate__zoomIn"
        },
        hideClass: {
          popup: "animate__animated animate__zoomOut"
        }
      }).then(() => {
        window.location.href = "pages/info";
      });
    });
  }
});