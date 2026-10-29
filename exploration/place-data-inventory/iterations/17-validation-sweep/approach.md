# PROMPT 3: validation sweep (tier the open rows)

Claude Code prompt. Run from `D:\workspace\gaia` in a fresh session, on Sonnet (`/model sonnet`). Unattended; Robert is away. **Time box: about 4.5 hours in total, with a cap for each phase.** Run the phases in order, one at a time. **No sub-agents.**

## Context

Master: `docs/discovery/inventory-combined-2026-10-29-fv.csv` (690 rows; ignore `round = 2-pilot`). The tier is in `verify_tier`; `tier` is an old column, so ignore it. Current state (666 rows): Gold 84, Silver 261, Bronze 140, Browser needed 137, Failed 44.

This run moves rows between tiers by settling the checks that are still open. It finds no new datasets.

| Phase | Target | Rows | Cap | Time |
|---|---|---|---|---|
| V0 | Build the queues (script) | | | 10 min |
| V1 | Silver to Gold: read only the one missing core fact | 112 | 80 | 75 min |
| V2 | Bronze, never read: full part B read | 46 | 46 | 50 min |
| V3 | Bronze, licence = fail: look for a terms page | 80 | 80 | 55 min |
| V4 | Failed: look for a successor, or confirm it is retired | 44 | 44 | 40 min |
| V5 | Geometry gaps: TODO 2.2, 2.3 and the 4 TBD rows | about 8 lookups | 8 | 25 min |
| V6 | Merge, tiers, numbers check, docs, publish package | | | 40 min |

Skip the Browser needed rows: they need a real browser, and a separate pass handles them.

## Rules (for every phase)

- **Reading follows `docs/discovery/partB/BRIEF.md`:**
  - the landing page plus at most one documentation page;
  - an evidence URL for every value, using the fixed check vocabulary;
  - no downloads, no sign-ins, no bot-protection or certificate workarounds;
  - if a page is blocked, mark the row `blocked` and move on.
- **Web search is allowed only in V4 and V5**, capped at 2 searches per row or lookup. Anything found by search still needs a page read for evidence.
- **Writes go only to `docs/discovery/validation/`** until V6. Don't edit the inventory, `landscape/`, `fileverify/`, `backfill/` or `partB/`. Don't commit or push. Don't delete files; to replace one, write a new file with a new name.
- **User-agent:** `OHDSI-GIS-WG-inventory-check/0.1 (+https://ohdsi.github.io/GIS/)`. Never put any personal email or name in requests.
- **Checkpoints:** after each row batch (about 10 rows), append to `validation/checkpoint.jsonl` (phase, ids done). To resume, read it and skip what's done.
- **Limits:**
  - if a phase reaches its cap or time, stop it, note that in the report, and start the next phase;
  - if a usage limit stops you, don't retry anything: go straight to V6 with what exists;
  - **V6 always runs.**
- **Don't change the tier rules.** Tiers come from `tier_of()` in `docs/discovery/scripts/licence_rule_2026_10_29.py`. The US federal licence rule stays as it is (`license_class = public_domain_us_federal`). The 2 person-level registry rows stay out of everything.

## V0: queues (script, no reads)

Write `validation/queues.csv` (id, phase, priority, gap) and print the counts per phase.

- **V1:** `verify_tier = Silver` and exactly 3 of `chk_license`, `chk_unit`, `chk_temporal`, `chk_access` are `pass` or `n.a.`. `gap` is the missing one (expect about unit 37, access 32, temporal 25, licence 18).
  - Order by priority: rows with `wg_request` set first; then rows in the priority 1 anchor categories (Care sites, Deprivation, Census and socioeconomic, Heat, Floods/drought/wildfire/hazards); then Health policy; then the rest.
  - Also: Silver rows where all four core checks pass but `chk_soft404` or `chk_withdrawn` is `not_checked` (Gold needs those to pass too). Settle those from the same page read.
- **V2:** `verify_tier = Bronze` and `partB_pages_read` is empty.
- **V3:** `verify_tier = Bronze` and `chk_license = fail`. Drop rows already in V2.
- **V4:** `verify_tier = Failed`.

## V1: Silver to Gold (cap 80)

For each row, read the landing page, plus one documentation page only if that is where the missing fact will be. Settle just the gap check, and `chk_soft404` / `chk_withdrawn` if they are open. Record `result`, `detail`, `evidence` and the `*_confirmed` value.

**A warn is a real answer.** For example, the page gives only a release year, or the unit is coarser than listed. Don't push a warn to a pass.

Output: `validation/v1-results.csv`. Columns: id, the check columns you changed (with `_detail` / `_evidence`), the `*_confirmed` fields, pages_read, blocked.

## V2: Bronze, never read (cap 46)

Run the full part B check set from the BRIEF, plus:
- `finest_unit_confirmed` (vocabulary: `docs/discovery/unit-vocabulary.csv`);
- `geometry_source` (embedded / reference_standard / reference_specific / none);
- `geometry_dependency`.

Output: `validation/v2-results.csv`, with the same columns as `fileverify/` and `backfill/proposed-rows-*.csv` use for checks.

## V3: Bronze licence fails (cap 80)

Most of these say "no licence on the dataset page". Look for a **site- or publisher-wide terms or licence page** linked from the landing page or the site footer: one page per publisher, then reuse it for all of that publisher's rows. Many share one (WHO 6, NYC 3, PEDP 3, ABS 2, …).

Decide each row:
- **pass:** the terms page explicitly grants reuse of the site's data under a named open licence. Examples: ABS "CC BY 4.0", ONS "Open Government Licence", SSB "NLOD", Eurostat's reuse notice. Set `license_class` to that licence, and add `license_basis = site_terms` in the detail.
- **warn:** terms exist, but the grant is generic or unclear, or non-commercial, or needs registration.
- **fail (unchanged):** paid, a subscription, a data use agreement, or still nothing found.

Never apply the federal rule here, except to a publisher already listed in `federal-publishers-2026-10-29.csv`.

PEDP mirrors stay Bronze; their licence question is waiting on Robert's email.

Output: `validation/v3-results.csv` and `validation/v3-publisher-terms.csv` (publisher, terms_url, licence, decision).

## V4: Failed (cap 44)

For each row:
- **Dead link or wrong access URL:** search for the dataset's current home (publisher site first, then DataCite or another repository). If found, read it per the BRIEF and record `successor_url`; the row gets re-checked in V6 by running `verify_links.py` logic on the new URL.
- **Archived or withdrawn:** check whether a newer edition or replacement exists, and record it the same way.
- **Data before 2000 or recency fail:** confirm it, and say whether a newer equivalent exists (`successor_url`, or none).

Each row gets a verdict: `successor_found`, `confirmed_retired` or `unresolved`.

Output: `validation/v4-results.csv`.

## V5: geometry gaps (8 lookups)

1. **TODO 2.2: US public water-system service-area boundaries.** Find the current national dataset (EPA / ORD or another public source). Read its page for licence, years, coverage and the join key (PWSID).
2. **TODO 2.3: ZIP-to-ZCTA crosswalk.** Find a public, scriptable source: HUD-USPS (needs a key?), UDS Mapper, or the Census relationship files. Read its page.
3. **The 4 rows with `geometry_dependency = TBD`:** name the boundary source for each, or say none exists.
4. **Optional, if time allows:** one national statistics-office boundary source each for Latin America, Africa and Asia, matching the rows that say "not identified in the inventory".

New datasets found here go into `validation/v5-proposed-rows.csv` as new inventory rows, with `round = 3-validation` and the full part B checks. Dependency fixes go into `validation/v5-geometry-updates.csv`.

## V6: merge, numbers, docs (always runs)

1. **Merge script.** Write `docs/discovery/scripts/merge_validation_2026_10_30.py`. It:
   - applies V1–V5 to a copy of the master;
   - recomputes the counts and `verify_blockers` exactly as `licence_rule_2026_10_29.py` does;
   - re-tiers every row with `tier_of()`;
   - re-runs `scripts/categories_2026_10_29.py` logic for any new rows;
   - re-runs `verify_links.py` on V4 successor URLs and V5 new rows only, capped at 60 requests;
   - writes `docs/discovery/inventory-combined-2026-10-30-val.csv` (new file; the old master stays);
   - writes `docs/discovery/inventory.csv` (Gold and Silver);
   - writes `validation/tier-moves-2026-10-30.csv` (id, name, category, tier before, tier after, reason).
2. **Numbers check.** Run the `numbers_check_2026_10_28.py` logic against the new master. Every count quoted in the report must come from the file.
3. **Point the builders at the new master.** Change the input filename in:
   - `scripts/build_publish_package.py` (`INV_ALL`, at the workspace root);
   - `docs/discovery/scripts/build_workbook_2026_10_29_fv.py` and `patch_workbook_about_2026_10_29.py`.

   Then rebuild `place-data-inventory-2026-10-29.xlsx` under a new name (`…-2026-10-30.xlsx`), and update the publish builder to copy that one.
4. **Docs:**
   - `validation/validation-report-2026-10-30.md`, about 1.5 pages. Include:
     - per phase: queued, read, blocked and the tier moves;
     - the tier table before and after;
     - the publishers whose terms page settled the licence;
     - Failed rows with successors;
     - the V5 geometry answers;
     - what's still open, and why.
   - `iterations/README.md`: add row 17, "validation sweep".
   - `TODO.md`:
     - update the state line and mark 2.2 and 2.3 (and anything V5 settled);
     - add any new follow-ups;
     - leave the "Needs people" section alone, except to add questions this run raised (for example, whether site-wide terms count as a dataset licence).
   - In `scripts/build_publish_package.py`, add iteration `17-validation-sweep` (approach: this prompt; results: the report) next to the existing 16 entries.
5. **Rebuild the publish package** with `python scripts/build_publish_package.py` and print its summary line. Don't copy anything into `D:\workspace\GIS-pr`, and don't commit. Robert reviews and opens the PR.
6. **Finish:** print a 10-line summary: tier table before and after, rows moved, anything that needs Robert.
