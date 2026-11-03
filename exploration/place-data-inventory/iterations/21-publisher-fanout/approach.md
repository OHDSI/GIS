# PROMPT 4: publisher-family fan-out (TODO 3.9)

Claude Code prompt. Run from `D:\workspace\gaia` in a fresh session, on Sonnet (`/model sonnet`). Unattended. **Time box: about 3 hours in total, with a cap for each phase.** Run the phases in order, one at a time. **No sub-agents.** Run this job alone: no other job may write inventory masters while it runs.

## Context

- **Master:** the newest `docs/discovery/inventory-combined-*.csv` by date suffix (at writing: `inventory-combined-2026-11-03b.csv`, 726 rows; Gold 120, Silver 427). Ignore rows with `round = 2-pilot`.
- **Question:** publishers that already have Gold or Silver rows usually publish sibling datasets. Does listing each publisher's catalog find new, verifiable rows faster than topic searches? Iteration #20 found NaNDA alone had 8 products missing.
- This run adds rows and reads only what it adds. It does not re-check existing rows or change tier rules.
- Method references: `docs/discovery/partB/BRIEF.md` (how a read records checks), `run-2026-11-03/report-2026-11-03.md` (repository APIs as reads), `unit-vocabulary.csv`, `landscape/anchors.csv`.

| Phase | Target | Cap | Time |
|---|---|---|---|
| F0 | Endpoint test and publisher list (script) | 25 publishers | 15 min |
| F1 | List siblings per publisher (APIs, metadata only) | 15 per publisher | 45 min |
| F2 | Filter, dedupe against the inventory, rank (script) | 80 shortlisted | 15 min |
| F3 | Read shortlisted siblings (APIs first; page per BRIEF otherwise) | 60 rows | 75 min |
| F4 | Merge, tiers, numbers check, docs (always runs) | | 30 min |

## Rules (every phase)

- **Writes go only to `docs/discovery/run-p4-fanout/`** until F4. Don't edit masters, `inventory.csv`, `TODO.md` or reports before F4. Don't commit, push or delete; to replace a file, write a new name.
- **Evidence URL for every value.** A repository API record (Zenodo, figshare, Dataverse, CKAN, ArcGIS Hub item, Socrata) is the dataset's own page and counts as a read. A DataCite record alone does not settle licence. Never use memory of a dataset as evidence.
- Reading follows BRIEF: the landing page or API record plus at most one documentation page. No downloads, no sign-ins, **no bot-check or certificate workarounds**: if a host shows a challenge (ICPSR, openICPSR and nanda.isr.umich.edu did on 2026-11-03), record `blocked` and move on.
- User-agent: `OHDSI-GIS-WG-inventory-check/0.1 (+https://ohdsi.github.io/GIS/)`. No personal names or emails in requests. At most 1 request per second per host.
- **Checkpoints:** after every 10 items, append to `run-p4-fanout/checkpoint.jsonl` (phase, ids done). To resume, read it and skip what's done.
- **Limits:** if a phase hits its cap or time, stop it, note it, go on. On a usage limit, don't retry anything: go straight to F4. **F4 always runs.**
- Don't change `tier_of()` or the federal licence rule. Keep the person-level registry entry out of everything.

## F0: endpoints and publishers (script)

1. Test each API once and record reachable / refused in `run-p4-fanout/endpoints.csv`: `https://api.datacite.org/dois?query=x&page[size]=1`, `https://zenodo.org/api/records?q=x&size=1`, `https://api.figshare.com/v2/articles?page_size=1`, `https://dataverse.harvard.edu/api/search?q=x&per_page=1`, `https://catalog.data.gov/api/3/action/package_search?rows=1`, `https://data.humdata.org/api/3/action/package_search?rows=1`.
2. From the master, group Gold and Silver rows by publisher (`organization`, falling back to the site host). Keep publishers with 2 or more Gold/Silver rows **and** a listable catalog (one of: ArcGIS Hub search API, CKAN organization, Socrata catalog, Dataverse subtree or publisher, Zenodo community or creator, DataCite `publisher` query). Rank by Gold/Silver count, then by anchor priority of their rows. Take 25. Write `publishers.csv` (publisher, n_gold, n_silver, catalog_kind, catalog_query).

## F1: list siblings (metadata only)

For each publisher, list up to 15 datasets via its catalog API, newest first, keeping title, id/URL, DOI, date, licence field (if any), formats, and any spatial unit or geography field. Write `siblings.csv`. Don't read pages in this phase.

## F2: filter, dedupe, rank (script)

- Keep siblings that are place-based: a spatial unit, geography word or geometry format in the metadata (use the unit terms in `unit-vocabulary.csv` and the anchor terms in `anchors.csv`).
- Drop: published before 2000; documents, code, slides; single-site or single-event records; microdata.
- **Dedupe against the master** with normalized matching: lowercase DOIs with version suffixes removed (`.v2`, `v1-189241`), ICPSR study numbers, and title similarity (Jaccard on words 0.6 or more). Exact-DOI matching alone understated coverage in #20.
- Rank by anchor priority, then health relevance of the title, then recency. Shortlist 80 to `shortlist.csv`.

## F3: read and record (cap 60 rows)

For each shortlisted item, read the API record (or the landing page per BRIEF) and write one JSON line to `run-p4-fanout/records.jsonl` in this shape (the apply script's format):

```json
{"id": "<region>_<publisher>_<short_name>", "new": true, "ev": "<evidence URL>", "note": "<what was read>",
 "set": {"round": "p4-fanout", "source_of_listing": "publisher fan-out (P4)", "dataset_name": "...", "organization": "...",
         "category": "<one of the 14 categories used in the master>", "categories": "...", "region": "...", "coverage": "...",
         "site_url": "...", "access_url": "...", "persistent_id": "...", "evidence_url": "...", "url_health": "healthy",
         "chk_link_live": "pass", "chk_link_live_detail": "...", "chk_soft404": "pass", "chk_soft404_detail": "...",
         "chk_license": "pass|warn|fail", "chk_license_detail": "...", "chk_license_evidence": "...", "license_confirmed": "...", "license_class": "...",
         "chk_unit": "pass|warn", "chk_unit_detail": "...", "finest_unit": "<unit-vocabulary term>", "finest_unit_confirmed": "...",
         "chk_temporal": "pass", "chk_temporal_detail": "...", "temporal_confirmed": "...", "latest_year_final": "YYYY",
         "chk_recency": "pass|warn|fail", "chk_access": "pass|warn", "chk_access_detail": "...",
         "chk_withdrawn": "pass", "chk_withdrawn_detail": "live record, no withdrawal notice"}}
```

- Set a check only from something read; leave it out otherwise (never guess). `chk_withdrawn = pass` only from a live record with no tombstone or notice.
- Licence: a named open licence on the record = pass; site-wide terms or a named licence whose text you didn't read = warn; no licence stated = warn; non-commercial or registration-only = warn with the reason.
- Recency: latest year 2020 or later = pass; 2000-2019 = warn.
- Unit: only `unit-vocabulary.csv` terms (grids as `grid_<res>`).
- Also write `blocked.csv` for items you could not read, with the reason.

## F4: merge and record (always runs)

From `docs/discovery`:
1. `python scripts/apply_records_2026_11_02.py <newest master> inventory-combined-<today>-p4.csv run-p4-fanout/records.jsonl <today>`. It refuses to overwrite and writes `run-p4-fanout/records-tier-moves.csv`.
2. **Numbers check:** recount tiers from the new master and confirm the deltas equal the tier moves.
3. Write `run-p4-fanout/report.md`: question, scope, counts per phase, rows added by tier and category, publishers that yielded most, blocked hosts, **verdict** (scale / scale with changes / drop, with rows per hour), and lessons.
4. Append an iteration row to `iterations/README.md` (next number) and a section to `../../publish/pr/PR-next.md` (what was added, by tier).
5. In `TODO.md`, mark 3.9 with the date, iteration number and verdict.
6. Don't rebuild the publish package; Robert decides when to publish.

## Resume prompt

"Resume PROMPT-4 from `run-p4-fanout/checkpoint.jsonl`: skip completed phases and items, continue the current phase within its cap, then run F4."
