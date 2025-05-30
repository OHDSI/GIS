/* ────────────────────────────────────────────────────────────
 * dataService.js   –  download + parse CSV files, fill store
 * ------------------------------------------------------------
 *  One fetch helper with error handling + caching.
 *  Uses PapaParse for robust CSV parsing (header mode).
 *  Public API:
 *        ─ initData()              – initial concepts load
 *        ─ ensureRelationships()   – lazy load relationships
 *        ─ ensureSynonyms()        – lazy load synonyms
 * ------------------------------------------------------------ */

import { store } from "./store.js";

/** Base URL for raw CSV files (change once – everywhere else just filenames) */
const CSV_BASE =
  "https://raw.githubusercontent.com/TuftsCTSI/CVB/main/GIS/Ontology/";

/** Internal cache so the same file is never fetched twice */
const _cache = new Map();

/**
 * Fetches a CSV file (text). Caches successful responses in _cache.
 * @param {string} name  filename, e.g. "concept_delta.csv"
 * @returns {Promise<string>} raw CSV text
 */
export async function fetchCSV(name) {
  if (_cache.has(name)) return _cache.get(name);            // cached

  const res = await fetch(CSV_BASE + name);
  if (!res.ok)
    throw new Error(`${name}: ${res.status} ${res.statusText}`);

  const text = await res.text();
  _cache.set(name, text);
  return text;
}

/**
 * Parses CSV text to array of objects using PapaParse.
 * Assumes header row is present and skips empty lines.
 * @param {string} csv  raw csv string
 * @returns {Array<Object>} array of row objects
 */
export function csvToArray(csv) {
  const result = Papa.parse(csv, {
    header: true,
    skipEmptyLines: true,
    dynamicTyping: false, // keep false unless you want automatic type coercion
    transformHeader: h => h.trim(),
    transform: v => v.trim()
  });

  if (result.errors.length) {
    console.warn("PapaParse errors:", result.errors);
  }

  return result.data || [];
}

/* -------------------------------------------------------------
   Lazy loaders for secondary CSV files
------------------------------------------------------------- */

export async function ensureRelationships() {
  if (store.relationships) return;                         // already loaded
  const relCsv = await fetchCSV("concept_relationship_delta.csv");
  store.relationships = csvToArray(relCsv);
}

export async function ensureSynonyms() {
  if (store.synonyms) return;                              // already loaded
  const synCsv = await fetchCSV("concept_synonym_delta.csv");
  store.synonyms = csvToArray(synCsv);
}

/* -------------------------------------------------------------
   initial concepts load  – called once from main.js
------------------------------------------------------------- */

export async function initData() {
  const conceptCsv = await fetchCSV("concept_delta.csv");

  store.concepts = csvToArray(conceptCsv)
    .sort((a, b) => a.concept_name.localeCompare(b.concept_name, "en"));

  // filtered == full list until user applies filters
  store.filtered = [...store.concepts];
}

console.log("Loaded concepts:", store.concepts.length);
console.log("Sample concept:", store.concepts[0]);