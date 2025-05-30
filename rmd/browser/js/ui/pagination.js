/* ui/pagination.js
 * -------------------------------------------------------------
 * Builds “bottom” and “top‑right” pagination bars.
 * • Reads store.page, store.rowsPerPage, store.filtered.length
 * • Writes store.page on button click, then calls renderTable()
 * • Auto‑updates on any state change via store.subscribe()
 * ------------------------------------------------------------- */

import { store, subscribe } from "../store.js";
import { renderTable }      from "./table.js";

const bottomBar   = document.getElementById("pagination-container");
const topRightBar = document.getElementById("top-right-pagination-container");

/* -------------------------------------------------------------
   Public API
------------------------------------------------------------- */
export function renderPagination() {
  buildBar(bottomBar,   5);   // detailed bar at the bottom
  buildBar(topRightBar, 3);   // compact bar in the header
}

/* initial render + reactive update */
renderPagination();
subscribe(renderPagination);

/* =============================================================
   Internals
================================================================ */

/**
 * Builds a single bar (<div>) with numbered buttons + First/Last.
 * @param {HTMLElement} container  where to inject buttons
 * @param {number} maxVisible      how many page numbers to show (3–5)
 */
function buildBar(container, maxVisible) {
  const totalPages = Math.ceil(store.filtered.length / store.rowsPerPage);
  container.innerHTML = "";

  if (totalPages <= 1) return;                         // nothing to paginate

  let start = Math.max(1, store.page - Math.floor(maxVisible / 2));
  let end   = Math.min(totalPages, start + maxVisible - 1);
  if (end - start + 1 < maxVisible) start = Math.max(1, end - maxVisible + 1);

  /* ---- First button / leading dots ---- */
  if (start > 1) {
    container.appendChild(makeNavBtn("First", 1));
    if (start > 2) container.appendChild(makeDots());
  }

  /* ---- numeric page buttons ---- */
  for (let p = start; p <= end; p++) {
    const btn = makeNavBtn(p, p);
    if (p === store.page) btn.disabled = true;
    container.appendChild(btn);
  }

  /* ---- trailing dots / Last button ---- */
  if (end < totalPages) {
    if (end < totalPages - 1) container.appendChild(makeDots());
    container.appendChild(makeNavBtn("Last", totalPages));
  }
}

/* -------------------------------------------------------------
   helpers
------------------------------------------------------------- */

function makeNavBtn(label, targetPage) {
  const btn = document.createElement("button");
  btn.textContent = label;
  btn.addEventListener("click", () => {
    store.page = targetPage;
    renderTable();           // redraw rows
    renderPagination();      // redraw both bars
  });
  return btn;
}

function makeDots() {
  const span = document.createElement("span");
  span.textContent = "...";
  span.style.padding = "0 4px";
  return span;
}
