/* ui/table.js
 * -------------------------------------------------------------
 * Renders the results table from store.filtered
 * Uses event delegation for row clicks => renders inline mapping
 * Automatically re-renders whenever the store changes
 * ------------------------------------------------------------- */

import { store, subscribe } from "../store.js";
import { ensureRelationships, ensureSynonyms } from "../dataService.js";
import { renderInlineMapping } from "./mapping.js"; // must return DOM element

const tbody = document.querySelector("#results-table tbody");

/**
 * Renders the table body based on current page and filters.
 */
export function renderTable() {
  const start = (store.page - 1) * store.rowsPerPage;
  const end   = start + store.rowsPerPage;
  const data  = store.filtered.slice(start, end);

  tbody.innerHTML = data.map(c => `
    <tr data-id="${c.concept_id}" data-name="${c.concept_name}">
      <td>${c.concept_id}</td>
      <td>${c.concept_name}</td>
      <td>${c.domain_id}</td>
      <td>${c.vocabulary_id}</td>
      <td>${c.concept_class_id}</td>
      <td>${c.standard_concept || ""}</td>
      <td>${c.concept_code}</td>
      <td>${c.valid_start_date}</td>
      <td>${c.valid_end_date}</td>
    </tr>
  `).join("");
}

// Automatically re-render on store changes
subscribe(renderTable);

/**
 * Handles click events on table rows to display inline mapping.
 * Hides all other rows and inserts a dynamic mapping section directly under the clicked row.
 */
tbody.addEventListener("click", async evt => {
  const tr = evt.target.closest("tr");
  if (!tr) return;

  const conceptId   = Number(tr.dataset.id);
  const conceptName = tr.dataset.name;

  // Load required data on demand
  await Promise.all([ensureRelationships(), ensureSynonyms()]);

  // Hide all rows
  [...tbody.rows].forEach(row => row.classList.add("hidden"));
  tr.classList.remove("hidden");

  // Remove existing inline mapping row if present
  const existing = tbody.querySelector(".inline-mapping-row");
  if (existing) existing.remove();

  // Create and insert new mapping row
  const mappingRow = renderInlineMapping(conceptId, conceptName, tr);
  tr.insertAdjacentElement("afterend", mappingRow);
});
