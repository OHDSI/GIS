# Claude Code prompt: verification and URL-health checks (proof of concept)

Paste everything below the line into Claude Code, run from `D:\workspace\gaia`, with web access on.

---

You are building a **proof of concept for dataset verification and URL-health monitoring** for the OHDSI GIS place-based data inventory. Read these first:

- `docs/discovery/README.md`;
- `docs/discovery/next-pass-2026-10-20-report.md`;
- the About tab of `docs/discovery/place-data-inventory-2026-10-21.xlsx`.

The design idea: **verification is not one yes/no.** Each kind of check is its own column, with its own result and evidence. Summary columns roll them up.

## Rules

- **Write only under `docs/discovery/`.** Don't change `repos/`. Don't commit or push.
- **Back up before changing anything:** copy `inventory-working.csv` to `_to_delete/inventory-working-before-verify.csv` before modifying it.
- **Never download a dataset.** Use HEAD requests, or GET with `Range: bytes=0-1023`, for endpoints. Landing pages may be fetched in full.
- **Be polite to every site:**
  - send a User-Agent of `OHDSI-GIS-WG-inventory-check/0.1 (+https://ohdsi.github.io/GIS/)`;
  - make at most 1 request per second per domain;
  - time out after 20 s, with one retry;
  - respect robots.txt for landing pages: if it disallows the page, record `blocked_robots` rather than fetching.
- **Never guess.** A field is only confirmed if you read it on a page, and you store that page's URL as the evidence. Otherwise use `not_checked` or `unknown`.
- **Results use a fixed vocabulary:** `pass` / `warn` / `fail` / `n.a.` / `not_checked`. Each check also gets a short `_detail` column.
- **Save progress every 25 rows,** so an interruption loses little.

## Scope

- **Stage 1 (scripted, cheap):** all **1,018 rows** of the workbook's Inventory tab. That's the 594 rows of `inventory-working.csv`, plus the 424 inferred-unit leads, which are in the workbook only. Rebuild those leads with `scripts/build_share_workbook.py` logic, or read them from the workbook's Inventory sheet.
- **Stage 2 (agent page read):** the **211 shortlist rows** (167 "Verify first" + 44 "Investigate") whose landing page passed or warned in stage 1.
- **Stage 3 (browser queue):** shortlist rows that stage 1 marked `blocked_bot` or `blocked_robots`. Don't work around bot protection. List them for a person to check in a browser.

## The checks

### A. Reachability and URL health (stage 1, scripted: `scripts/verify_links.py`)

| Column | pass | warn | fail |
|---|---|---|---|
| `chk_link_live` | 2xx after redirects | 401, 403 or 429 (`blocked_bot` in detail), or a timeout after retry | 404, 410, 5xx, DNS failure |
| `chk_redirect` | no redirect, or same registered domain | moved to another domain (record `final_url`) | redirect loop |
| `chk_tls` | valid certificate | — | certificate error (record it; don't bypass) |
| `chk_soft404` | page title or body contains ≥ 50% of the dataset name’s significant tokens, or the publisher name | weak match | page is a generic home, search or "not found" page |
| `chk_withdrawn` | no withdrawal language | — | page says retired, decommissioned, discontinued, no longer available or archived (quote it in detail) |
| `chk_access_url` | access_url HEAD/Range returns 2xx | 401/403 (needs login or key) | 404/410/5xx; `n.a.` if there's no access_url |
| `chk_format_match` | content-type or file extension matches the stated `format` | ambiguous (html landing page) | contradicts it |
| `chk_machine_metadata` | page embeds schema.org `Dataset` JSON-LD or DCAT, or is a CKAN, STAC, CMR or Socrata record | other structured metadata (OpenGraph only) | none |
| `chk_persistent_id` | DOI or other persistent identifier found on the page | — | none (use warn, not fail, for this one) |
| `chk_archived` | Wayback Machine snapshot exists (`https://archive.org/wayback/available?url=`), with its date | snapshot older than 2 years | none |

Also store `http_status`, `final_url`, `response_ms`, `content_type` and `checked_at` (ISO timestamp).

### B. Content (stage 2, agent reads the landing page and its linked documentation)

| Column | What to confirm (evidence URL required) |
|---|---|
| `chk_license` | A license or terms are stated. Put the license in `license_confirmed`, and classify it in `license_class`: open / attribution / non-commercial / registration / restricted / unknown. pass = stated and open or attribution; warn = non-commercial or registration; fail = restricted or none found |
| `chk_temporal` | The years covered match or replace `temporal`. Record `latest_year` |
| `chk_recency` | pass if latest_year ≥ 2021; warn if 2015–2020; fail if older than 2015 or discontinued |
| `chk_cadence` | Update frequency is stated (`update_cadence_confirmed`) |
| `chk_version` | The current version or release is named (`version_confirmed`) |
| `chk_unit` | The finest spatial unit is confirmed and matches `finest_unit` (pass), is finer or coarser than recorded (warn: record the correct one), or is not stated (not_checked) |
| `chk_coverage` | Geographic coverage is confirmed |
| `chk_access` | Access is confirmed: open download / registration / API key / request / restricted |
| `chk_join_key` | The data dictionary shows a standard geographic key (FIPS/GEOID, ZIP/ZCTA, LSOA, ISO/admin codes), or a geometry column |
| `chk_format_gaia` | At least one distribution is a format the GDAL-based catalog scripts can load (shp, gpkg, geojson, gdb, csv with key or coordinates, parquet) |

Each check gets an `_evidence` column holding a URL, or several separated by `;`.

### C. Gaia readiness (from the workspace, no web)

| Column | Rule |
|---|---|
| `chk_in_gaia` | pass if `in_gaia` is set; otherwise n.a. |
| `chk_recipe_health` | For rows in gaiaCatalog: the most recent result in `docs/deployment-test/log-*.md` and `docs/readiness/`: ok = pass, broken = fail, untested = not_checked |

## Summary columns (computed last)

- `checks_applicable`, `checks_passed`, `checks_warned`, `checks_failed`.
- `health_score`: 0–100, with weights listed in the report. Suggested weights:
  - link_live 20;
  - soft404 and withdrawn 10;
  - license 15;
  - unit 15;
  - temporal and recency 15;
  - access 10;
  - join_key 10;
  - machine_metadata 5.

  Normalize over the checks that apply.
- `all_passing`: TRUE if every applicable check is `pass`.
- `verify_tier`:
  - **Gold:** all of these pass: link_live, soft404, withdrawn, license, unit, temporal, access.
  - **Silver:** link_live passes, with no fail among license, unit and temporal (warns allowed).
  - **Bronze:** link_live passes or warns, but content checks are not done or are incomplete.
  - **Failed:** link_live, withdrawn or soft404 fails.
  - **Browser needed:** blocked.
- `verify_blockers`: the names of the failed or warned checks, separated by `;`.
- `verified_on`: the date of the most recent check.

## History, the monitoring part of the POC

- **Append every check result** to `docs/discovery/verify-log.csv` in long form: `row_id, check, result, detail, evidence_url, http_status, checked_at, run_id`. Never overwrite it. A re-run appends a new `run_id`.
- **Write `scripts/verify_links.py` so it can be re-run on its own** (for example monthly). It should compare against the previous run, flag changes (pass→fail, new redirect, new withdrawal), and write `verify-changes-<date>.md`.

## Outputs

1. **`inventory-working.csv`:** add all the `chk_*`, `_detail`, `_evidence` and summary columns.
2. **`verify-log.csv`:** the long-form history described above.
3. **`browser-queue-2026-10-21.csv`:** the blocked shortlist rows, with the URL and what a person should confirm.
4. **Promotion:** copy Gold and Silver rows into `inventory.csv`, which still holds only its header row. Map `dataset_name`→title, `organization`→publisher, `theme`→domain, `site_url`→landing_url, `access_type`→access, `geography_units`→geography, `evidence_url`→evidence, `verified_on`→last_checked. Fill `in_gaia` and `recipe_health`.
5. **A new workbook, `place-data-inventory-2026-10-21-verified.xlsx`.** Keep the original. Copy it and:
   - add a **Verification** tab: one row per dataset, its tier, its score, and every `chk_*` column, colour-coded (green pass, amber warn, red fail, grey n.a./not_checked);
   - add **URL health** and **Tier** breakdowns to Summary, as formulas.

   Use openpyxl, with Arial throughout. Recalculate, and confirm there are no formula errors.
6. **`verify-report-2026-10-21.md` (one page):**
   - counts per check (pass / warn / fail / n.a.);
   - tiers;
   - the top failure reasons;
   - dead and withdrawn datasets, with any archive snapshot;
   - domains that blocked;
   - how long each stage took, and roughly how much usage;
   - what a monthly re-check would cost;
   - what to automate next.
7. **Update `docs/discovery/README.md`:** the status line, the files table and the next steps.

Run stage 1 across all 1,018 rows first, then print a short interim summary. Then do stage 2 on the shortlist, in batches of 25. Stop after the report. Don't start new harvesting.
