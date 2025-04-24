# Vocabulary Browser (GIS Edition)

This folder contains all frontend assets (JavaScript, CSS, and supporting files) for the **Vocabulary Browser**, an interactive client used to explore and QA OMOP CDM-compatible vocabulary extensions — specifically tailored here for **GIS Vocabulary Packages**.

---

## Structure

```text
browser/
|-- index.html                      # Static entry point for the Vocabulary Browser UI; defines layout, loads styles/scripts, and launches the client-side app
|-- css/
|   `-- vocabulary-browser.css      # Styling for layout, filters, tables, and mapping display
|-- js/
|   |-- main.js                     # App entry point; orchestrates loading, rendering, events
|   |-- dataService.js              # Fetches and parses CSVs; fills `store`
|   |-- store.js                    # Central state management (filters, data, events)
|   `-- ui/
|       |-- table.js                # Renders main concept table and click behavior
|       |-- filters.js              # Builds dynamic filters and binds events
|       |-- pagination.js           # Controls pagination state and UI
|       `-- mapping.js              # Displays relationship and synonym panels

```
## Features
- Dynamic filtering by Vocabulary, Domain, Concept Class, Standard Concept
- Free-text search across concept fields
- Interactive mapping viewer:
    - Inline expansion to reveal relationships and synonyms
    - One-click isolation of selected row
- Pagination controls with configurable row limits
- Semantic QA vew for reviewers and domain experts


## Input Data
The browser expects OMOP-compatible delta files hosted via HTTP(S):
- concept_delta.csv
- concept_relationship_delta.csv
- concept_synonym_delta.csv 
- concept_ancestor_delta.csv (TBD)
Set the base path in dataService.js under CSV_BASE to match your hosted location.
```js
const CSV_BASE = "https://your-hosted-path/";
```
>Note: Files must be in UTF-8 encoding and follow OMOP CDM v5+ structure.

## Running Locally
Use Python or any static file server:
```bash
cd path/to/docs/
python -m http.server 8000
```
Then open:
```bash
http://localhost:8000/browser/index.html
```
>Chrome blocks file:/// access to module JS. Always use a local server.

##  QA Use Case
Browser supports manual vocabulary QA workflows by enabling:
- Visual inspection of mappings
- Coverage validation
- Edge-case detection (e.g., duplicates, broken relationships)
- Synonym completeness checks


##  Customization Notes
- To extend filters (e.g., add source vocabulary set), update `filters.js` and `store.js`
- Additional columns or custom metadata can be added in `table.js`
- Mapping and synonym logic may be customized in `mapping.js` to reflect domain-specific predicates

## `index.html` Connection

The browser UI is bootstrapped through `index.html`, which loads and connects all necessary JavaScript and CSS resources to render the application.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Vocabulary Browser</title>
  <link rel="stylesheet" href="css/vocabulary-browser.css" />
</head>
<body>
  <!-- Main interface: search, filters, table -->
  <div id="app">
    <!-- Filters and table will be dynamically rendered here -->
  </div>

  <!-- Entry point: loads JS modules -->
  <script type="module" src="js/main.js"></script>
</body>
</html>
```

### Key Points
- The entry script `main.js` is loaded as an ES module via type="module".
- All DOM elements (table body, filters, etc.) are rendered dynamically using JavaScript.
- `vocabulary-browser.css` is used for styling the table, filter bar, mapping sections, and responsive layout.
- No server-side logic is required - all behavior is client-side using JavaScript and CSV data fetched remotely.

> To view the application in a browser, `index.html` must be served via HTTP (e.g., localhost:8000). Loading it via file:/// will result in CORS errors or blocked modules.

##  License & Credits
Developed by the SciForce Medical Team and Tufts CTSI for the GIS Vocabulary pipeline.
