document.addEventListener("turbo:load", () => {
  const accordions = document.querySelectorAll(".accordion");

  accordions.forEach((btn, index) => {
    btn.addEventListener("click", function () {

      // cerrar todos
      accordions.forEach((item, i) => {
        if (i !== index) {
          item.classList.remove("active");
          if (item.nextElementSibling) {
            item.nextElementSibling.style.maxHeight = null;
          }
        }
      });

      // abrir actual
      this.classList.toggle("active");
      const panel = this.nextElementSibling;

      if (panel.style.maxHeight) {
        panel.style.maxHeight = null;
      } else {
        panel.style.maxHeight = panel.scrollHeight + "px";
      }
    });
  });
});