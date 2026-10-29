# PROMPT 1.5: working-group targets and the federal licence rule

Claude Code prompt. Run from `D:\workspace\gaia` on Sonnet (`/model sonnet`), after Prompt 1 and before Prompt 2. Expected: about 1 to 1.5 hours, small.

## Context

Round 1 is closed. The working inventory is `docs/discovery/inventory-combined-2026-10-28.csv` (595 rows: 571 round 1, 24 round 2 pilot).

On 2026-10-28 evening Robert made two decisions (`decisions-needed-2026-10-28.md`, final section):
- **US federal licence rule, adopted.** US federal works are public domain (17 U.S.C. 105) unless the page states otherwise.
- **PEDP mirrors** (EJScreen, CEJST, HIFLD Next) stay Bronze until PEDP states terms. They are not federal, so the rule does not apply to them.

The working group's use-case and dataset-request page is https://ohdsi.github.io/GIS/status.html (refreshed 2026-10-25). Of its dataset requests, 4 are missing from the inventory and 5 are present only weakly.

## Rules

- **No parallel agents.** At most one sub-agent at a time, or none: do the page reads in this session.
- **Page reads follow `partB/BRIEF.md`:** the landing page plus at most one documentation page; every confirmed value gets an evidence URL; no downloads; no bot-protection workarounds; no sign-ins.
- **Cap: 60 page fetches in total.** Blocked sites become Browser needed; don't retry them.
- Write only under `docs/discovery/`, plus the Dataset discovery row in `STATUS.md`. Don't touch `landscape/` or `round2/`. Member repos are read-only. Don't commit. Don't delete: move superseded files to `_to_delete/`.
- If a usage limit stops you, don't retry. Finish steps 3 and 4 with what exists.

## Step 1: apply the federal licence rule (script, no web)

1. **Decide which rows are US federal works.** Use the publisher (`organization`) and the landing-page domain:
   - **Federal:** federal agencies and their `.gov` / `.mil` domains, e.g. Census, EPA, CDC, NOAA, NASA, USGS, HUD, HRSA, CMS, AHRQ, USDA, DOT/BTS, FEMA, DOE/EIA, NIH.
   - **Not federal:** state and local `.gov` sites; universities; non-profits (IHME, NRDC, Eviction Lab); PEDP mirrors; commercial vendors; federally funded but university-published data (NaNDA/ICPSR, the Brandeis COI).

   Write the federal publisher list to `federal-publishers-2026-10-29.csv` (publisher, domains, rule) so it can be reviewed.
2. **For federal rows where `chk_license` is fail or not_checked and no page states other terms:**
   - set `chk_license = pass`;
   - set `license_class = public_domain_us_federal`;
   - set `chk_license_detail` to "US federal work, public domain under 17 U.S.C. 105 (WG rule, 2026-10-28); no other terms stated on the pages read".

   Keep any row where a page states other terms (a restricted, registration or third-party note) as it is, and list it.
3. **Re-tier with the existing tier rules** (`scripts/refine_2026_10_28.py` logic). Don't change any other check.

## Step 2: the nine working-group targets

**Find the request.** For each request, read its GitHub issue first, to see what was actually asked. These are `https://github.com/OHDSI/gaiaCatalog/issues/<n>`; the HTML page is fine.

**Missing (4): find the dataset, add a row, run a part B read.**

| Request | What to look for |
|---|---|
| gaiaCatalog#28, Multidimensional Deprivation Index | Find which one is meant: the US Census Bureau's experimental MDI, or the global Multidimensional Poverty Index (UNDP/OPHI), sub-national where possible. If the issue is ambiguous, add both and note it |
| gaiaCatalog#23, CyAN | The Cyanobacteria Assessment Network (EPA/NASA/NOAA/USGS) satellite products and the CyAN app/data |
| gaiaCatalog#31, DIVA-GIS | Country- and global-level boundary and geometry data. Also note in the report that boundaries are now the separate place-identifiers backlog (`backlog-place-identifiers-2026-10-28.md`) |
| gaiaCatalog#26, Dataset Repository for Suicide Risk | Read the issue. If it names datasets, add them. If it is only a placeholder, add no row and report what it would need |

**Weak (5): run a part B read on the existing row, or add the specific product if the existing row is generic.**

| Request | Row |
|---|---|
| gaiaCatalog#29, Environmental Justice Index | `us_cdc_eji` (Bronze) |
| gaiaCatalog#35, TRI Basic Data files | `us_epa_tri` (Bronze) |
| gaiaCatalog#32, EPA AQS sites | `us_epa_aqs_data_mart_api` is generic. Add or confirm a monitoring-sites listing (AQS site and monitor files) |
| gaiaCatalog#38, UCMR 3 (2013-2015) | `us_epa_ucmr` is generic. Confirm that UCMR 3 data are available and add it as its own row if needed |
| gaiaCatalog#34, SDG indicators | `global_un_sdg_global_database` (Browser needed). Try the page; also add one or two sub-national sources if found within the cap, such as Global Data Lab's sub-national HDI or the DHS sub-national estimates |

**Tag the requests.** Add a column `wg_request`, e.g. `gaiaCatalog#29` or `GIS#288`. Fill it for these nine, and for the requests already covered: ACS 5-year #37, AHRQ (now the CLH Database) #36, COI #30, EM-DAT #27, and EEA European air quality #41.

## Step 3: rebuild

1. Write `inventory-combined-2026-10-29.csv` and rebuild the workbook as `place-data-inventory-2026-10-29.xlsx` with the existing builder.
2. Regenerate `inventory.csv` (Gold and Silver).
3. Re-run `scripts/numbers_check_2026_10_28.py` against the new files where it applies, or write a short check of the new counts.

## Step 4: report

Write `exploration-1.5-report-2026-10-29.md`, about 1 page:
- **The licence rule:** how many rows were federal; how many moved; tier counts before and after (from Gold 33, Silver 156, Bronze 192, Browser needed 150, Failed 40); rows kept back because a page states other terms.
- **The nine targets:** a table of request, what was asked, the row id(s), tier, the key fields (unit, years, licence, access) and evidence URL.
- **Coverage of the working group's dataset requests:** how many are now Silver or better.
- **What remains**, including the requests that need the working group to define them.

Update the Dataset discovery row in `STATUS.md`. Print the before/after tier counts and the files written.
