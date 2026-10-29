# PROMPT 1: finish round 1 (run this first)

Claude Code prompt. Run from `D:\workspace\gaia`. Expected: 20-40 minutes, scripts only.

## Context

Round 1 of the place-data discovery is complete:
- `docs/discovery/inventory-refined-2026-10-28.csv`: 571 kept rows; Gold 33, Silver 156, Bronze 192, Browser needed 150, Failed 40.
- `docs/discovery/close-report-2026-10-28.md` and `ticket-2026-10-28/`.
- `browser-sample-2026-10-28.md` and `.csv`.
- The round 2 pilot (`round2/round2-candidates-2026-10-28.csv`): 25 facility-registry candidates; 24 new, 1 already in the inventory. Part A has been run on them; part B has not.

This prompt closes round 1 so there is one stable inventory to explore and to measure overlap against.

## Rules

- No web access, no sub-agents, no part B, no new page reads. Scripts only, one process.
- Write only under `docs/discovery/`, plus the Dataset discovery row in `STATUS.md`. Member repos are read-only. Don't commit or push.
- Don't delete files. Move superseded files to `_to_delete/`.

## Steps

1. **Combined inventory.** Write `inventory-combined-2026-10-28.csv`:
   - the 571 round 1 rows, plus the 24 new round 2 rows;
   - same columns as the refined file, with blanks where round 2 has no value;
   - add a column `round` = `1` or `2-pilot`.

   Round 2 rows get a tier from part A only, using the existing tier rules. Never put them above Bronze, because part B was not run. The one round 2 row already in the inventory (HRSA health-center sites) stays a single round 1 row; record the round 2 id in its notes.
2. **Workbook.** Rebuild with the existing builder (`scripts/build_polished_workbook.py`, or the 10-28 build path) as `place-data-inventory-2026-10-28-final.xlsx`. Add a "Round 2 pilot" sheet. Check that the Summary formulas evaluate with no errors.
3. **Numbers check.** Write one script that recomputes, from the CSVs, every count quoted in:
   - `close-report-2026-10-28.md`;
   - `ticket-2026-10-28/ISSUE-update-2026-10-28.md`;
   - `browser-sample-2026-10-28.md`;
   - `round2/round2-report-2026-10-28.md`.

   The counts to check:
   - the funnel: 3,337 / 3,160 / 1,018 / 570 → 571;
   - part B read: 430;
   - not read: 131 = 77 + 28 + 25 + 1, plus 10 browser-checked only;
   - tiers: 33 / 156 / 192 / 150 / 40;
   - verified: 189;
   - browser sample: 23 visited, 18 opened;
   - round 2: 24 new; link health 14 / 7 / 3.

   Write `numbers-check-2026-10-28.md` as a table: claim · file · recomputed value · match. Fix a mismatch in the markdown only when it is a clear typo. Otherwise, list it under "Needs Robert".
4. **Index.** Add a short "Round 1: final deliverables (2026-10-28)" section at the top of `docs/discovery/README.md`, one line per deliverable:
   - combined CSV;
   - final workbook;
   - `ticket-2026-10-28/`;
   - close report;
   - browser sample;
   - round 2 pilot report;
   - decisions memo;
   - Tim notes;
   - numbers check.

   Update the Dataset discovery row in `STATUS.md` to "Round 1 complete; landscape assessment next".
5. **Print** the row counts by round and tier, the files written, and any "Needs Robert" items.
