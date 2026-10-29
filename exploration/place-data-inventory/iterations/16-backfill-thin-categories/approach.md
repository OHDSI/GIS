# PROMPT 1.8: backfill the thin categories

Claude Code prompt. Run from `D:\workspace\gaia` in a fresh session, on Sonnet (`/model sonnet`). Time box: about 1 to 1.5 hours. It can run alongside Prompt 2.1, because each writes only its own files.

## Context

On 2026-10-29 the inventory was retagged into 14 anchor-aligned categories (`scripts/categories_2026_10_29.py`; columns `category` and `categories` in `inventory-combined-2026-10-29-fv.csv`, 604 rows, 276 Gold + Silver). Five categories are thin because no sweep ever targeted them:

| Category | Rows now | Verified | Anchor ids (in `landscape/anchors.csv`) |
|---|---|---|---|
| Health policy | 1 | 0 | `health_policy` |
| Sub-national development | 4 | 0 | `subnational_development` |
| Water quality | 10 | 8 | `drinking_water`, `algal_blooms` |
| Heat and temperature | 10 | 5 | `heat` |
| Deprivation and vulnerability indices | 21 | 9 | `deprivation_indices` |

## Rules

- **One process, no sub-agents.** Read each candidate's landing page plus at most one documentation page, per `partB/BRIEF.md`, and record an evidence URL for every confirmed value. No downloads, no sign-ins, no bot-protection workarounds.
- **Cap: 12 candidates per category, 60 in total.**
- **Writes:** `docs/discovery/backfill/` only. Don't edit the inventory files, `landscape/` or `fileverify/`. Don't commit.
- User-agent: `OHDSI-GIS-WG-inventory-check/0.1 (+https://ohdsi.github.io/GIS/)`. If a usage limit stops you, don't retry; write the report with what exists.

## Step 1: choose candidates (scripts, no page reads)

For each category, in this order:

1. **Start with `landscape/candidates-2026-10-29.csv`.** Keep rows where `triage = likely_relevant`, `in_inventory` is empty, and `anchors` includes one of the category's anchor ids. Rank by the strength of `place_unit_in_title`, then `citations`, then recency. There are about 240 heat, 61 deprivation, 17 water, and only a handful of policy and sub-national rows.
2. **If fewer than 12 remain**, run capped scripted searches (no page reads yet), at most 3 queries per category:
   - DataCite: title search with the anchor's terms plus a place term, datasets, 2015 or later;
   - data.europa.eu: search API, datasets.

   For **health policy**, search for state or county policy datasets with effective dates: policy surveillance, state law database, prescription drug monitoring, Medicaid expansion, tobacco or alcohol law.
3. **De-duplicate** against the inventory by DOI, URL, then name. Prefer distinct products: skip yearly duplicates of one product.

Write `backfill/candidates-chosen-2026-10-29.csv` with: category, source, title, url, why chosen.

## Step 2: page reads

For each chosen candidate, run the part B checks from `partB/BRIEF.md`:
- licence, years, recency, unit, coverage, access, join key, format, each with detail and evidence;
- plus `finest_unit_confirmed`, `geometry_source` (embedded / reference_standard / reference_specific / none) and `geometry_dependency`, using `unit-vocabulary.csv`.

Assign a tier with the existing rules (`scripts/refine_2026_10_28.py` logic), and apply the US federal licence rule where the publisher is a US federal agency.

## Step 3: outputs

1. `backfill/proposed-rows-2026-10-29.csv`: new rows in the inventory's columns, with `category`, `categories`, `round = 1.8-backfill`, tiers, checks and evidence.
2. `backfill/backfill-report-2026-10-29.md`, about 1 page:
   - per category: candidates found, read, and the tier counts;
   - the 3 strongest additions per category;
   - for health policy, whether usable policy datasets exist in these channels at all, or whether Prompt 2.1's sources (LawAtlas, PDAPS and others) are the only route;
   - what remains thin.

Don't merge into the inventory; Claude merges after review.
