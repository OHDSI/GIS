/* main.js  ───────────────  entry point / orchestrator */

import { initData, ensureSynonyms, ensureRelationships } from "./dataService.js";
import { buildFilters, initFilterEvents } from "./ui/filters.js";
import { renderTable } from "./ui/table.js";
import { renderPagination } from "./ui/pagination.js";

/**
 * Bootstraps the Vocabulary Browser once the DOM is ready.
 * Loads all required data and initializes the UI.
 */
async function init() {
  try {
    // Load the core concept data
    await initData();

    // Preload optional secondary data
    await ensureSynonyms();
    await ensureRelationships();

    // Build UI and render
    buildFilters();
    initFilterEvents();
    renderTable();
    renderPagination();
  } catch (err) {
    console.error("Failed to initialize Vocabulary Browser:", err);

    // Display error in table area if available
    const tbody = document.querySelector("#results-table tbody");
    if (tbody) {
      tbody.innerHTML =
        `<tr><td colspan="9" style="color:red;">${err.message}</td></tr>`;
    } else {
      document.body.innerHTML = `<p style="color:red;padding:2em">App failed to load. Check console for details.</p>`;
    }
  }
}

// Run after DOM is fully ready
document.addEventListener("DOMContentLoaded", init);