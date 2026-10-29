# PROMPT 2.1: priority sources (spike)

Claude Code prompt. Run from `D:\workspace\gaia` in a fresh session, on Sonnet. Prompt 2 is done; this can run alongside Prompt 1.8, because it writes only its own files. Time box: about 30-40 minutes.

**A spike, not a full listing.** Test five sources to learn whether listing priority 1-2 sources in full is worth doing at scale.

## Rules

Same as Prompt 2:
- one process, no sub-agents;
- metadata only, no data downloads;
- polite rate limits, and the same user-agent with no email address.

Write only `landscape/spike-2.1-<date>.csv` and a section appended to `landscape/landscape-report-<date>.md` (create the file if Prompt 2 hasn't run).

## The five sources

| Source | Group |
|---|---|
| The IAEA's radiotherapy-centre directory (DIRAC) | Care sites, priority 1; radiotherapy is an active use case |
| The CMS provider data catalog | Care sites. List the datasets, not the providers |
| PDAPS (prescription drug and opioid laws) | Health policy, priority 2 |
| LawAtlas (policy surveillance datasets) | Health policy, priority 2 |
| NaNDA (the ICPSR series) | Curated peer catalog |

## For each source

1. **Find out how it can be listed:** API, downloadable list, catalog page, or manual only.
2. **List up to 10 items:** datasets, measure families or policy topics.
3. For each item, record:
   - anchor;
   - unit, and for policy data whether it carries effective dates;
   - years, license and access;
   - `geometry_source` and `geometry_dependency`, using the vocabulary in `unit-vocabulary.csv` from Prompt 2 phase A. If it doesn't exist yet, record free text;
   - whether the item is already in `inventory-combined-2026-10-29-fv.csv` (604 rows; it also has `category` and `geometry_source` columns).
4. **Note what blocked or slowed you.**

## Report section 2.1

- **What each source holds**, and how it can be listed.
- **The strongest additions** for care sites (radiotherapy) and for policy.
- **A spike verdict per source:** list it in full? (yes / no / manual only), and the estimated time to do so.
