/* ui/filters.js
 * -------------------------------------------------------------
 * Builds the three <select> filters and the search box,
 * hooks their events, and triggers store.applyFilters().
 *
 * ▸ Populates options dynamically from store.concepts
 * ▸ When a higher‑level filter changes (vocabulary → domain → class),
 *   lower‑level dropdowns are rebuilt to reflect available choices.
 * ------------------------------------------------------------- */

import { store }               from "../store.js";

const searchInput       = document.getElementById("searchInput");
const vocabularyFilter  = document.getElementById("vocabularyFilter");
const domainFilter      = document.getElementById("domainFilter");
const classFilter       = document.getElementById("conceptClassFilter");
const standardConceptFilter = document.getElementById("standardConceptFilter");
const rowsSelect       = document.getElementById("rowsPerPage"); 

/* -------------------------------------------------------------
   buildFilters()  – run after concepts are loaded or filters reset
------------------------------------------------------------- */
export function buildFilters() {
  buildVocabularyOptions();
  buildDomainOptions();
  buildClassOptions();
}

/* -------------------------------------------------------------
   initFilterEvents() – attach listeners exactly once
------------------------------------------------------------- */
export function initFilterEvents() {
  /* search box (debounced) */
  let timer;
  searchInput.addEventListener("input", e => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      store.search = e.target.value;
      store.applyFilters();
    }, 300);
  });

  /* vocabulary <select> */
  vocabularyFilter.addEventListener("change", e => {
    store.vocabFilter  = e.target.value;   // "" means “All”
    /* reset downstream filters */
    store.domainFilter = "";
    store.classFilter  = "";
    buildDomainOptions();
    buildClassOptions();
    store.applyFilters();
  });

  /* domain <select> */
  domainFilter.addEventListener("change", e => {
    store.domainFilter = e.target.value;
    store.classFilter  = "";
    buildClassOptions();
    store.applyFilters();
  });

  /* class <select> */
  classFilter.addEventListener("change", e => {
    store.classFilter = e.target.value;
    store.applyFilters();
  });
  /* StandardConcept <select> */  
  standardConceptFilter.addEventListener("change", (event) => {
    store.standardConceptFilter = event.target.value;
    store.applyFilters();
  });
  /* rows per page <select> */
rowsSelect.addEventListener("change", e => {
  store.rowsPerPage = e.target.value;  // update store
  store.page = 1;                      // returns to the first page
});
}

/* =============================================================
   Helper functions to populate <select> elements
================================================================ */

function buildVocabularyOptions() {
  const uniques = new Set(store.concepts.map(c => c.vocabulary_id).filter(Boolean));
  fillSelect(vocabularyFilter, uniques, store.vocabFilter);
}

function buildDomainOptions() {
  const base = store.concepts.filter(c =>
    !store.vocabFilter || c.vocabulary_id === store.vocabFilter
  );
  const uniques = new Set(base.map(c => c.domain_id).filter(Boolean));
  fillSelect(domainFilter, uniques, store.domainFilter);
}

function buildClassOptions() {
  let base = store.concepts;
  if (store.vocabFilter)
    base = base.filter(c => c.vocabulary_id === store.vocabFilter);
  if (store.domainFilter)
    base = base.filter(c => c.domain_id === store.domainFilter);

  const uniques = new Set(base.map(c => c.concept_class_id).filter(Boolean));
  fillSelect(classFilter, uniques, store.classFilter);
}

/**
 * Small util: reset <select> then append options from Set(values).
 * Keeps the previously selected value if it still exists.
 */
function fillSelect(selectEl, valuesSet, currentValue) {
  const prev = currentValue || "";
  selectEl.innerHTML = "";                     // wipe

  // default option
  selectEl.insertAdjacentHTML("beforeend",
    `<option value="">All</option>`);

  [...valuesSet]
    .sort()
    .forEach(v =>
      selectEl.insertAdjacentHTML(
        "beforeend",
        `<option value="${v}" ${v === prev ? "selected" : ""}>${v}</option>`
      )
    );

  // ensure the <select> reflects the model if prev value vanished
  if (!valuesSet.has(prev)) selectEl.value = "";
}
