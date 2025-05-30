document.addEventListener("DOMContentLoaded", function () {
  const toc = document.querySelector(".tocify");
  if (!toc) return;

  // Add a class to indicate this TOC will behave like an accordion
  toc.classList.add("accordion-toc");

  // Select all TOC header items
  const headers = toc.querySelectorAll("li.tocify-item");

  headers.forEach(header => {
    const sublist = header.nextElementSibling;

    if (sublist && sublist.classList.contains("tocify-subheader")) {
      // Hide subheaders by default
      sublist.style.display = "none";

      // Toggle visibility on click
      header.addEventListener("click", function () {
        const isOpen = sublist.style.display === "block";
        sublist.style.display = isOpen ? "none" : "block";
      });
    }
  });
});
