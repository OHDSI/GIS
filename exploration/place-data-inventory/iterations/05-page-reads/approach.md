# Claude Code prompt: overnight refinement run (re-check, part B, refined workbook)

Paste everything below the line into Claude Code, run from `D:\workspace\gaia`, with web access on. It is written to run unattended.

---

You are finishing the place-based data inventory for the OHDSI GIS WG so that Robert has a **refined, verified set to share tomorrow (2026-10-23)**. You'll run unattended: don't stop to ask questions. Make the reasonable choice, note it in the report under "Choices made", and carry on.

## Read first

- `docs/discovery/README.md`;
- `docs/discovery/verify-prompt-2026-10-21.md`: the full verification design. This run does its parts B and C and the summary columns;
- `docs/discovery/verify-A-report-2026-10-21.md`;
- `docs/discovery/trim-2026-10-22-report.md`.

**The input is `docs/discovery/trim-2026-10-22.csv`.** It holds 1,018 rows with `keep` Y/N, `trim_reason`, `latest_year`, all the part-A `chk_*` columns, and `priority`. Work only on `keep = Y` rows (570), unless a step says otherwise.

## Rules (from the workspace and the design)

- **Write only under `docs/discovery/`.** Don't change `repos/`. Don't commit or push. Don't delete files; move anything superseded to `docs/discovery/_to_delete/`.
- **Back up first:** copy `trim-2026-10-22.csv` to `_to_delete/` before changing it.
- **Never download a dataset.** Never bypass bot protection or certificate errors. Never guess: a field is only confirmed if you read it on a page, and its evidence URL is stored with it.
- **Be polite to sites:** the user agent in `scripts/verify_links.py`, 1 request per second per domain.
- **Save progress after every batch,** so a stop or a usage limit loses at most one batch. If you hit a usage limit, write the partial report with what is done, and list exactly where to resume.

## Step 1: re-check the transient failures (scripted, no LLM)

Run `scripts/verify_links.py --redo-ids` on every `keep = Y` row whose part-A result is any of these:

- HTTP 5xx;
- a timeout;
- a connection error;
- a DNS failure.

Expect data.gov.ie, NOAA NCEI, Global Data Lab, stat.fi, INE PT, IDEP and others. Record the new results; `verify-log.csv` gets a new `run_id`.

**TLS failures:** check once, with `certifi`'s current bundle, whether the chain is merely incomplete. Record it as `tls_incomplete_chain` or `tls_invalid` in the detail. Don't bypass it either way; leave those rows for the browser queue.

Then recompute `url_health`.

## Step 2: content verification (part B) on the shortlist

**Scope:** `keep = Y` and `priority` set. That's 168 rows, minus any that are still `dead` after step 1, and minus `blocked` rows, which go to the browser queue.

**Order:**

1. The 124 "strong candidates" in `ticket-2026-10-22/1-strong-candidates.csv` (match them on `id`). These were posted for show and tell, so confirm them first.
2. The rest of the shortlist.

For each row, an agent reads the landing page and its linked documentation, and fills the part-B checks from the design, each with `_detail` and `_evidence`:

- `chk_license` (+ `license_confirmed`, `license_class`);
- `chk_temporal` (+ `latest_year` confirmed);
- `chk_recency`: **recency rule changed.** pass = data runs to 2020 or later, or is ongoing; warn = latest year 2000–2019; fail = before 2000 or discontinued. Medical data starts around 2000 (Robert, 2026-10-22);
- `chk_cadence`;
- `chk_version`;
- `chk_unit`: confirm or correct `finest_unit`;
- `chk_coverage`;
- `chk_access`;
- `chk_join_key`;
- `chk_format_gaia`.

**How to run it:**

- Work in batches of 25. You may use parallel subagents within a batch, each given the design's check definitions and the row data.
- Follow one documentation link per row at most, if the landing page lacks the facts.
- About 2–3 minutes per row is the budget; leave a check `not_checked` rather than going deeper.
- Rows that turn out to be **blocked** at the content step go to the browser queue.

**Part C (workspace only, no web):**

- `chk_in_gaia`;
- `chk_recipe_health`, from `docs/deployment-test/log-*.md` and `docs/readiness/`.

## Step 3: extend part B if there is time

If the shortlist is done and there's usage left, run part B on the other `keep = Y` rows, in this order:

1. health_relevance 3 and gaia_fit `needs_aggregation` (points, lines);
2. health_relevance 3 and gaia_fit `needs_raster`;
3. health_relevance 2 and gaia_fit `now`.

Stop cleanly at a batch boundary.

## Step 4: withdrawn tools with community mirrors

The trim dropped these because their publisher pages say they were withdrawn:

- EPA EJScreen;
- CEQ CEJST;
- HIFLD Open;
- USGS NHD (retired but still downloadable).

For each, find the maintained mirror or successor if one exists: for example the PEDP reconstruction of EJScreen, a CEJST mirror, HIFLD on DataLumos, or 3DHP for NHD. Verify it with parts A and B. Add it as a new `keep = Y` row, with `notes` saying "community mirror of <original id>" and the original id in a `mirror_of` column. Don't add a mirror you can't reach and read.

## Step 5: summary columns and tiers

Compute the summary columns from the design for every `keep = Y` row:

- `checks_applicable`, `checks_passed`, `checks_warned`, `checks_failed`;
- `health_score`, using the design's weights, normalized over the applicable checks;
- `all_passing`;
- `verify_blockers`;
- `verified_on`;
- `verify_tier`, with the recency change above:
  - **Gold:** all of these pass: link_live, soft404, withdrawn, license, unit, temporal, access; recency is pass or warn.
  - **Silver:** link_live passes; no `fail` among license, unit, temporal and recency.
  - **Bronze:** link_live passes or warns; content not checked or incomplete.
  - **Failed:** link_live, withdrawn or soft404 fails after step 1, or recency fails.
  - **Browser needed:** blocked.

## Step 6: outputs

1. **`docs/discovery/inventory-refined-2026-10-23.csv`:** all `keep = Y` rows, with every check, summary and evidence column.
2. **Promote Gold and Silver rows into `docs/discovery/inventory.csv`,** which still holds only its header row. Map `dataset_name`→title, `organization`→publisher, `theme`→domain, `site_url`→landing_url, `access_type`→access, `geography_units`→geography, `evidence_url`→evidence, `verified_on`→last_checked. Fill `in_gaia` and `recipe_health`. Fill `license`, `temporal`, `format` and `update_cadence` from the confirmed values.
3. **`docs/discovery/browser-queue-2026-10-23.csv`:** every row still `blocked` or with a TLS failure, with its URL and a short list of what a person should confirm. Group the rows by domain, so that one browser visit covers several rows.
4. **`docs/discovery/notes-for-tim-2026-10-23.md` (draft only, not sent):** gaiaCatalog sources whose links are dead, blocked or withdrawn. Part A already found `us_nuclear_power_plants` (404), `global_pm25_concentration_1998_2016` (SEDAC blocked) and `hh_lagunas_ana` / `hh_rios_ana` (timeouts). Give the catalog folder, the URL, the result, and a suggested replacement if you found one.
5. **The shareable workbook, `docs/discovery/place-data-inventory-2026-10-23-refined.xlsx`,** built with openpyxl. Arial throughout, header row frozen, filters on, landing pages as hyperlinks. Recalculate, and confirm there are no formula errors. Tabs, in order:
   - **About:**
     - what the inventory is and how it was built: harvest → de-duplication → split → score → trim → URL health → content checks;
     - what "verified" means: a short legend per check and tier;
     - the assumptions;
     - the date.
   - **Summary:** live formulas only, no hardcoded counts except the funnel, which names its source files. Include:
     - counts by tier × theme;
     - URL health;
     - license class;
     - finest unit;
     - Gaia fit × health relevance;
     - how many datasets are already in gaiaCatalog.
   - **Refined set:** Gold and Silver rows only, sorted by theme, then health relevance (descending), then dataset name. Columns:
     - dataset, publisher, theme, coverage;
     - finest unit, years, latest year, license class;
     - access, format, Gaia fit, health relevance;
     - in gaiaCatalog, tier, landing page.
   - **Verification:** every `keep = Y` row. Tier and score, then each `chk_*` column, colour-coded: green = pass, amber = warn, red = fail, grey = n.a. or not_checked.
   - **Browser queue:** the rows from item 3.
   - **Trimmed:** the 448 trimmed rows, with `trim_reason`, so a reader can see what was left out and why.
6. **`docs/discovery/refine-report-2026-10-23.md` (one page):**
   - the funnel;
   - per-check results;
   - tier counts;
   - the Gold/Silver list size by theme;
   - what step 1 recovered;
   - the mirrors added;
   - the browser queue size;
   - **Choices made** (anything you decided without asking);
   - usage and time taken;
   - what's left.
7. **Refresh the GitHub ticket package** into `docs/discovery/ticket-2026-10-23/`, with the same four CSVs as `ticket-2026-10-22/`:
   - `1-verified.csv`: Gold and Silver;
   - `2-to-investigate.csv`: Bronze and Browser needed, each with `what_to_check` saying what is still missing;
   - `3-reference-layers.csv`;
   - `4-trimmed.csv`: the trimmed rows plus any new Failed rows, with the reason.

   Also write an `ISSUE-update.md` comment that says what changed since the 2026-10-22 post (counts moved between files, licenses confirmed, links recovered). Flag registered-access datasets, such as the All of Us Researcher Workbench, in a `public_access` column (open / registration / restricted).
8. **Update `docs/discovery/README.md`** (status line, files table, next steps) **and the Dataset discovery row in `STATUS.md`.**

Finish by printing the report.

If usage runs out before step 6, still produce step 6 items 1, 5 (with whatever is verified so far) and 6, marking unverified rows as Bronze.
