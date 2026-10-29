# Claude Code prompt: round-2 gap sweeps (item 3). A separate session, preview only

Paste everything below the line into a **second** Claude Code session, run from `D:\workspace\gaia`, with web access on. It may run alongside the closing run. It writes only under `docs/discovery/round2/`. **Time-box: about 3 hours, and stop early if usage gets tight; the closing run has priority.**

---

You are running a **preview of round 2** of the OHDSI GIS place-based data inventory: targeted sweeps for the gaps that round 1 left. It's a preview, so the goal is a short, well-sourced candidate list per gap, link-checked, **not** merged into the round-1 inventory.

## Read first

- `docs/discovery/README.md`;
- the "Known gaps" section of `docs/discovery/harvest-2026-10-20-summary.md`;
- `docs/discovery/verify-prompt-2026-10-21.md` (sections A and B);
- `docs/discovery/trim-2026-10-22-report.md`: the trim rules. New rows must pass the same rules: 2000 or later, not a one-off, not hyper-local, health-relevant;
- `docs/discovery/inventory-refined-2026-10-23.csv` (read only), so you don't re-add datasets already listed.

## Rules

- **Write only under `docs/discovery/round2/`.** Never modify any other file in `docs/discovery/`; another session is working there. Don't append to `docs/discovery/verify-log.csv`. Write your own `round2/verify-log-round2.csv`.
- **Never download a dataset, bypass bot protection, or guess.** Every field has an evidence URL. Polite crawling.
- **Run `scripts/verify_links.py` logic on your rows only,** writing to `round2/`. If the script can't take an output path, copy it to `round2/verify_links_round2.py` and change only its paths.

## The five sweeps (cap: 30 candidates each)

1. **Health-facility registries:** national master facility lists, CMS/NPPES/HRSA (US), WHO/healthsites.io, and national ministries (UK ODS, CIHI, AIHW, others).
2. **Transport and access:** road networks with traffic volume, transit stops and frequency (GTFS aggregators), travel time to care (MAP accessibility, Oxford/Weiss), walkability outside the US.
3. **Hazards and events, as time series:** wildfire perimeters and smoke (multi-year), flood events (multi-year), heat-wave and extreme-heat days by area, and disaster declarations. Multi-year series only; no single events.
4. **Food access outside the US:** UK, Canada, Australia, EU, and LMIC food-environment or food-insecurity indices at sub-national level.
5. **Sub-national health outcomes outside the US:** small-area disease or mortality estimates (for example UK Fingertips/OHID, Canada CHSI, Australia PHIDU, EU NUTS-level Eurostat health, IHME LBD and GBD sub-national, DHS sub-national).

## For each candidate

- Fill the round-1 columns: `id`, `dataset_name`, `organization`, `site_url`, `access_url`, `theme`, `variables_examples`, `geography_units`, `coverage`, `temporal`, `versions`, `format`, `access_type`, `license`, `source_of_listing = round2_<sweep>`, `evidence_url`, `confidence`, `notes`.
- Add `finest_unit`, `health_relevance` and `gaia_fit`, using the round-1 rubric.
- Apply the trim rules, recording `keep` and `trim_reason`.
- Run part-A link checks on the kept rows.
- **Optional, only if time allows:** part B for the top 10 per sweep, using `docs/discovery/partB/BRIEF.md` unchanged.

## Outputs (all under `docs/discovery/round2/`)

- `round2-candidates-2026-10-28.csv`;
- `round2-report-2026-10-28.md` (one page): per sweep, the candidates found, kept and link-healthy, with 3–5 named highlights; overlap with round 1; what each sweep couldn't find; time and tokens; a recommendation on whether each sweep is worth a full round 2.

Don't touch any file outside `round2/`. Finish by printing the report.
