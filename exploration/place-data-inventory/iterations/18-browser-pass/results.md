# Browser pass, 2026-10-30 (iteration 18)

Claude opened every row the scripts could not read in the Claude desktop app's built-in browser. That is 167 rows: 137 Browser needed, 20 never-read Bronze rows that the validation sweep (#17) found blocked, and 10 Silver rows whose V1 gap check was blocked. Where a site has a public API on its own domain, Claude used that from the same page: ArcGIS Hub search, HDX and CKAN `package_show`, CMS metastore, Harvard Dataverse, NASA CMR. For DOI-only rows, metadata came from DataCite.

- **What was not done:** no sign-ins or form submissions; no cookie or terms dialogs accepted; no bot or security checks worked around; no data downloaded.
- **Record of what was read:** the source is `browser-pass/general-2026-10-30*.jsonl` (flat copy: `browser-pass/browser-pass-results-2026-10-30.csv`). It was applied by `scripts/apply_browser_pass_2026_10_30.py` to a new master, `inventory-combined-2026-10-30-bp.csv`.
- **Tier rules:** unchanged (`tier_of()`).

## Result

| | Gold | Silver | Bronze | Browser needed | Failed | Gold+Silver |
|---|---|---|---|---|---|---|
| Before (after #17) | 89 | 284 | 113 | 137 | 44 | 373 |
| After | 105 | 389 | 106 | 20 | 47 | **494** |

- **Opened:** 145 of 167. Blocked: 11 (security checks or HTTP 403). Unreachable: 11 (network error from this computer, or no URL).
- **Moves:**
  - Browser needed: 93 to Silver, 11 to Gold, 10 to Bronze, 3 to Failed.
  - Never-read Bronze: 18 to Silver.
  - V1 Silver rows: 5 to Gold, 1 to Bronze. The Bronze one is `us_hifld_hospitals`: its licence was already a fail, which an earlier tier override had hidden.
  - The full list is in `browser-pass/tier-moves-2026-10-30-bp.csv`.
- **New Gold rows (16):**
  - HUD QCT/DDA
  - Statbel statistical sectors
  - FCC Broadband Data Collection
  - SNAP retailers (lat/lon)
  - Scottish SIMD (OGL)
  - RCRAInfo (now the HWIP platform)
  - Meta HRSL population
  - Anenberg surface NO2
  - CSIRO LST/UHI
  - two HDX layers
  - UM Miami-Dade LST rasters
  - Harvard SVI block groups
  - CMS hospitals and nursing homes
  - SEDAC PM2.5 for countries and urban areas (Harvard Dataverse copy)

## Read this before quoting Silver

The Silver rule only requires that the link works, that something was read, and that none of licence, unit, years or recency is a fail. Of the 111 rows that became Silver here, about a third have two or fewer of the four core checks (licence, unit, years, access) settled. Most of those are:

- NaNDA and ICPSR rows: years and unit come from DataCite, but the ICPSR terms page is behind a security check;
- national statistics landing pages: portal only, no licence text.

Across the whole inventory, 111 Silver rows have two or fewer core checks settled. Tightening Silver (for example, licence plus one more core check) is still open; see TODO 4.10.

## Findings worth acting on

- **Moved or gone (now Failed):** EFAS "about" page, OECD regional statistics page, Otago NZDep page. All three show "not found" in a real browser and need successor URLs.
- **Silently changed products:**
  - `data.un.org` now opens "UN Data Commons".
  - The AHRQ SDOH Database URL opens the Community-Level Health (CLH) Database (2009-2023, county to block group). It looks like the successor, so the row's name needs checking.
  - The `us_hifld_hospitals` link is a DataLumos project titled "HIFLD OPEN Trauma Levels", not the full hospitals layer.
  - BFS (Switzerland) dropped its English pages.
  - FNS now styles itself the "Food and Nutrition Administration" (fna.usda.gov).
  - NCEI Storm Events and RCRAInfo moved to new platforms; the old URLs redirect.
  - The G2Aging Exposome site carries a banner: "under review for potential modification in compliance with Administration directives".
- **Licences settled by reading:**
  - CC BY: WorldPop, CSIRO, Global Solar Atlas, Statbel, Stats NZ, Bogotá, energydata.info.
  - CC0: HDX Ethiopia and Kenya.
  - OGL: gov.scot.
  - ODC-By: UM Esploro.
- **Restricted or non-commercial:**
  - IHME (non-commercial agreement);
  - UIC NDI (CC BY-NC);
  - USPS vacancy data (sublicence, gov and non-profit only);
  - N3C (DUA);
  - First Street, NatureQuant (commercial).
- **Federal publishers on arcgis.com** (HUD eGIS, NIFC WFIGS): their licence field is a disclaimer and the landing domain is not .gov, so the federal rule was not applied. They stay at licence warn. This is a candidate for the federal-rule edge cases (TODO 1.7), with Smithsonian VOTW and the Water Quality Portal.

## Still Browser needed (20)

- **Security check or 403:** ICPSR (and every ICPSR study page), StatCan, NHS Digital, UNICEF MICS, PSA Philippines, BPS Indonesia, UN-Habitat, MINAM Peru, the INAIGEM GeoNetwork, EDI.
- **Host unreachable from this computer:** PRISM, SEDAC (moved), HHEAR, DANE Colombia, Pobal, START GTD, ANA Peru (3), INGEMMET. These could be transient; retry them from another network before treating them as dead.

## Files

- `browser-pass/queue-2026-10-30.csv`: the 167 rows.
- `browser-pass/general-2026-10-30.jsonl` and `-part2.jsonl`: one record per row, with evidence URLs.
- `browser-pass/tier-moves-2026-10-30-bp.csv`.
- `scripts/apply_browser_pass_2026_10_30.py`.
- `inventory-combined-2026-10-30-bp.csv`: the new master. Builders, the workbook (`place-data-inventory-2026-10-30.xlsx`) and the publish package now read it.
