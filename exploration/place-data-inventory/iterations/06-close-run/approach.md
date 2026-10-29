# Claude Code prompt: closing run, items 1 and 4 (part B on the rest, loose ends, draft package)

Paste everything below the line into Claude Code, run from `D:\workspace\gaia`, with web access on. It runs unattended. **Time-box: about 4 hours.** Robert wraps a draft package this evening, so the package must exist at the end even if part B is incomplete.

---

You are closing the first-round assessment of the OHDSI GIS place-based data inventory. Don't stop to ask questions: make the reasonable choice and log it under "Choices made" in the report.

## Read first

- `docs/discovery/README.md`;
- `docs/discovery/refine-report-2026-10-23.md`: the last run, its choices and what it left;
- `docs/discovery/partB/BRIEF.md`: the part-B agent brief. **Reuse it unchanged** for agents;
- `scripts/refine_2026_10_23.py`, which holds the merge, tier, workbook and ticket logic. **Reuse it** rather than rewriting it.

**Input:** `docs/discovery/inventory-refined-2026-10-23.csv` (574 rows, with `verify_tier`).

## Rules

- **Write only under `docs/discovery/`.** Don't change `repos/`. Don't commit or push. Don't delete files; move superseded ones to `_to_delete/`.
- **Back up first:** copy `inventory-refined-2026-10-23.csv`, `inventory.csv` and the `ticket-2026-10-23/` folder to `_to_delete/` before anything else.
- **Same safety rules as before:** no dataset downloads, no bypassing bot protection or certificate errors, no guessing (every confirmed value carries its evidence URL), and the polite user agent.
- **Save after every batch.** If you're close to the time-box or a usage limit, stop part B at a batch boundary and go straight to step 4.
- **Another Claude Code session may be running a round-2 gap sweep under `docs/discovery/round2/`.** Don't read or write that folder, and don't append to `verify-log.csv` from more than one process at a time. This run owns `verify-log.csv`.

## Step 1: part B on the remaining unread rows

**Scope:** rows with `verify_tier = Bronze` and no part-B result. That's about 202 rows; exclude any dead or blocked.

**Order** (most useful first):

1. health relevance 3 with gaia_fit `unknown` or `not_linkable`;
2. health relevance 2, `needs_aggregation`;
3. health relevance 2, `needs_raster`;
4. health relevance 1 (reference layers);
5. everything else.

**Method:** same as `refine-report-2026-10-23.md`. Queue file `partB/queue-close.json`; batches of 25; 5 agents per batch, 5 rows each; results in `partB/results/` named `D<batch>-a<agent>.json`. Merge results and recompute tiers with the existing logic.

## Step 2: the 174 possible-duplicate groups

These are the `dup_group` / `dup_role` columns, wherever they survived into the refined file, along with any listed in `harvest-2026-10-20-dedupe-report.md` that are among the kept rows. No web needed: decide from title, publisher, URL, coverage, unit and years.

For each group, decide one of:

- **same product:** keep the primary, and record the alternates' URLs in the primary's `access_url` or notes. Mark alternates `keep = N` with the reason "duplicate of <id>";
- **mirror or host copy:** same treatment, with the reason "host copy of <id>";
- **distinct products:** keep both, and clear the flag.

Write `dupe-review-2026-10-28.csv` (group, ids, decision, one-line reason) and apply the decisions to the inventory.

## Step 3: loose ends (small)

1. **Licenses for the 4 mirrors** (`us_epa_ejscreen_pedp`, `us_ceq_cejst_pedp`, `us_hifld_next_pedp`, `us_usgs_3dhp`). Look for an About, terms, Dataverse or GitHub LICENSE page, and fill `chk_license` with evidence. If none is stated, record that, and propose wording for a question to the maintainers.
2. **Tim note.** Update `notes-for-tim-2026-10-23.md` with anything step 1 found about catalog sources, and save it as `notes-for-tim-2026-10-28.md`. It's still a draft; don't send it.
3. **Decision memo for Robert,** `decisions-needed-2026-10-28.md`, no longer than a page. For each item, give two or three options with a recommendation; Robert decides:
   - the gaiaCatalog entries `mdc_5000_addresses_normalized` (test address list) and a person-level registry layer (name withheld pending a WG decision) (sensitive person-level layer): keep, flag or remove;
   - the manuscript's "113 curated datasets" claim: suggested qualifying wording, based on what the 113 folders actually hold (synthetic layers, per-year night lights, 3 without JSON-LD);
   - the 4 mirrors without a license: include, include-flagged, or exclude.

## Step 4: draft package (always do this, even if step 1 is incomplete)

1. **Recompute** tiers, summary columns and `public_access`. Write `inventory-refined-2026-10-28.csv`. Rewrite `inventory.csv` with Gold and Silver only.
2. **Workbook `place-data-inventory-2026-10-28.xlsx`:** same tabs and logic as the 2026-10-23 workbook, with these additions:
   - a **Coverage of assessment** block in Summary: rows read by part B vs not, browser queue, failed;
   - a **Duplicates resolved** tab.
3. **Ticket package `ticket-2026-10-28/`:**
   - the same four CSVs;
   - `1-verified.csv` must include `license_confirmed`, `license_class`, `public_access`, `latest_year`, `finest_unit_confirmed`, `join_key_confirmed` and `evidence` columns;
   - `ISSUE-update-2026-10-28.md`, saying what changed since 2026-10-23: counts moved between tiers, rows newly read, duplicates resolved, mirrors' licenses.
4. **`close-report-2026-10-28.md` (one page):**
   - the funnel, now with "read by part B: N of 574";
   - tier counts before and after;
   - the duplicate decisions;
   - choices made;
   - time and tokens;
   - what remains. Expect: the browser queue, round-2 gap sweeps, and Robert's decisions.
5. **Update `docs/discovery/README.md`** (status, files, next steps) **and the Dataset discovery row in `STATUS.md`.**

Finish by printing the close report.
