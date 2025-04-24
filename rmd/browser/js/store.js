/* ────────────────────────────────────────────────────────────
 * store.js  –  single source of truth for the Vocabulary Browser
 * -------------------------------------------------------------
 * ▸ Holds every piece of mutable state (concepts, filters, UI params …)
 * ▸ All modules must read & write through these getters / setters
 * ▸ Emits change events so UI layers can re‑render automatically
 * ▸ Includes one shared helper:  store.applyFilters()
 * ------------------------------------------------------------- */

const _state = {
  /* core data */
  concepts:        [],          // entire concept list from concept_delta.csv
  filtered:        [],          // current view after search / filters
  relationships:   null,        // lazy‑loaded CSV
  synonyms:        null,        // lazy‑loaded CSV

  /* UI params */
  rowsPerPage:     25,
  page:            1,

  /* filter params */
  search:          "",
  vocabFilter:     "",
  domainFilter:    "",
  classFilter:     "",
  standardConceptFilter: ""
};

/* -------------------------------------------------------------
   Simple pub/sub: UI modules can subscribe to state changes
------------------------------------------------------------- */
const _listeners = new Set();

/** internal: notify every subscriber */
function _emit() {
  _listeners.forEach(fn => fn(_state));
}

/** Public API: store.subscribe(cb) → unsubscribe() */
export function subscribe(listener) {
  _listeners.add(listener);
  return () => _listeners.delete(listener);
}

/* -------------------------------------------------------------
   Getters / Setters
   – Change detection & validation can live here if needed
------------------------------------------------------------- */
export const store = {
  /* ------------ data collections ------------ */
  get concepts()               { return _state.concepts; },
  set concepts(val)            { _state.concepts = val; _emit(); },

  get filtered()               { return _state.filtered; },
  set filtered(val)            { _state.filtered = val; _emit(); },

  get relationships()          { return _state.relationships; },
  set relationships(val)       { _state.relationships = val; _emit(); },

  get synonyms()               { return _state.synonyms; },
  set synonyms(val)            { _state.synonyms = val; _emit(); },

  /* ------------ ui parameters --------------- */
  get rowsPerPage()            { return _state.rowsPerPage; },
  set rowsPerPage(val) {
    const n = Number(val);
    _state.rowsPerPage = (n >= 1 && n <= 500) ? n : 25;
    _emit(); // triggers UI update
},

  get page()                   { return _state.page; },
  set page(val)                {
    _state.page = Math.max(1, Number(val) || 1);
    _emit();
  },

  /* ------------ filter parameters ----------- */
  get search()                 { return _state.search; },
  set search(val)              { _state.search = String(val); _emit(); },

  get vocabFilter()            { return _state.vocabFilter; },
  set vocabFilter(val)         { _state.vocabFilter = val; _emit(); },

  get domainFilter()           { return _state.domainFilter; },
  set domainFilter(val)        { _state.domainFilter = val; _emit(); },

  get classFilter()            { return _state.classFilter; },
  set classFilter(val)         { _state.classFilter = val; _emit(); },
  
  get standardConceptFilter() { return _state.standardConceptFilter; },
  set standardConceptFilter(v) { _state.standardConceptFilter = v; _emit(); },


  /* ---------------------------------------------------------
     Helper: recompute filtered list based on current filters
  --------------------------------------------------------- */
applyFilters() {
  const term = _state.search.toLowerCase();

  _state.filtered = _state.concepts.filter(c => {
    const matchesSearch = !term || Object.values(c).some(v =>
      String(v).toLowerCase().includes(term)
    );
    const matchesVocab  = !_state.vocabFilter  || c.vocabulary_id     === _state.vocabFilter;
    const matchesDomain = !_state.domainFilter || c.domain_id         === _state.domainFilter;
    const matchesClass  = !_state.classFilter  || c.concept_class_id  === _state.classFilter;
    const stdMatch      = !_state.standardConceptFilter || c.standard_concept === _state.standardConceptFilter;

    return matchesSearch && matchesVocab && matchesDomain && matchesClass && stdMatch;
  });

  _state.page = 1;
  _emit();
}
};

export default store;
