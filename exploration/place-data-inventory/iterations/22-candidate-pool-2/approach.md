# PROMPT 5: candidate pool, round 2 (TODO 3.10)

Claude Code prompt. Run from `D:\workspace\gaia` in a fresh session, on Sonnet (`/model sonnet`). Unattended. **Time box: about 3 hours in total, with a cap for each phase.** Run the phases in order, one at a time. **No sub-agents.** Run this job alone (not while PROMPT-4 runs): only one job writes inventory masters at a time.

## Context

- **Master:** the newest `docs/discovery/inventory-combined-*.csv` by date suffix (it will include PROMPT-4's rows if that ran first). Ignore `round = 2-pilot`.
- **Input:** `docs/discovery/run-2026-11-03/a-families.csv` (734 product families from the DataCite candidates; about 540 in scope). Iteration #20 worked the top of this list: read `run-2026-11-03/report-2026-11-03.md` first.
- **Question:** continue #20's method (about 27 rows per hour, a third Gold) on the next families, reading through repository APIs.
- This run adds rows only. It does not re-check existing rows or change tier rules.

| Phase | Target | Cap | Time |
|---|---|---|---|
| C0 | Endpoint test; rebuild the queue (script) | | 15 min |
| C1 | DataCite enrichment of the next families (metadata only) | 200 families | 30 min |
| C2 | Filter and rank (script) | 90 shortlisted | 15 min |
| C3 | Read through repository APIs | 60 rows | 90 min |
| C4 | Merge, tiers, numbers check, docs (always runs) | | 30 min |

## Rules (every phase)

Same as PROMPT-4 (`PROMPT-4-publisher-fanout.md`, section "Rules"), with the run folder `docs/discovery/run-p5-pool2/` and `round = p5-pool2`. In short: writes only to the run folder until C4; evidence URL for every value; repository API records count as reads, DataCite alone does not settle licence; BRIEF reading limits; no downloads, sign-ins or bot-check workarounds; 1 request per second per host; the user-agent string; checkpoints every 10 items; F4/C4 always runs; don't change tier rules.

## C0: queue (script)

1. Test the endpoints listed in PROMPT-4 F0; write `endpoints.csv`.
2. Load `a-families.csv`. Remove families already in the master using **normalized matching** (DOI roots without version suffixes, ICPSR numbers, title Jaccard 0.6 or more) and the 27 ids added in #20 (`round = 20-candidates`).
3. Scope: year 2000 or later; a place unit in the title or a geolocation.
4. Order: the #20 ranking (anchor priority, citations, regional gap, geolocation) but **skip families whose representative DOI is a known no-API host** (ResearchGate, Taylor & Francis supplements on figshare `tandf.figshare.com`) and Earthdata MODIS/VIIRS versions already represented by a family row.
5. Write `queue.csv`.

## C1: DataCite enrichment (metadata only)

For the next 200 families in the queue: rights, resourceTypeGeneral, geoLocations count, formats, url host, `IsSupplementTo` flag, citationCount, and the first 400 characters of the description. Write `enriched.csv`.

## C2: filter and rank (script)

- Drop: supplements (`IsSupplementTo`) unless the title names a place unit and a reusable dataset; clinical, qualitative or survey-of-a-few-villages records; microdata; projections only (SSP-only) unless the anchor is heat or hazards; records with no repository API (keep up to 10 of these for page reads).
- Rank: repository API available (Zenodo, figshare, Dataverse, Pangaea, CKAN) first; then open licence in DataCite rights; then anchor priority; then regional gap (Africa, Latin America, Asia, Australia, EU ahead of US).
- Shortlist 90 to `shortlist.csv`.

## C3: read through repository APIs (cap 60 rows)

- Zenodo: `https://zenodo.org/api/records/<id>` (licence, version, files, description, publication date).
- figshare: `https://api.figshare.com/v2/articles/<id>` (licence, files, description).
- Dataverse: `<host>/api/datasets/:persistentId/?persistentId=doi:<doi>` (licence, version, release time, files).
- Pangaea: the DataCite record plus the landing page per BRIEF.
- Others: landing page per BRIEF.

Record rows exactly as in PROMPT-4 F3 (`records.jsonl`, same fields). One row per product family: list sibling DOIs in `notes`. Unit from the record only (grids as `grid_<res>`; areas as vocabulary terms). Also write `blocked.csv`.

## C4: merge and record (always runs)

As PROMPT-4 F4, with `inventory-combined-<today>-p5.csv`, `run-p5-pool2/records.jsonl`, `run-p5-pool2/report.md`, the next iteration number, a `PR-next.md` section, and TODO 3.10 marked with the date and verdict. Report the remaining in-scope families so the next round can be sized.

## Resume prompt

"Resume PROMPT-5 from `run-p5-pool2/checkpoint.jsonl`: skip completed phases and items, continue the current phase within its cap, then run C4."
