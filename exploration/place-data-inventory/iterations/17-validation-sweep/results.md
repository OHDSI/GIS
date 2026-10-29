# Validation sweep report (PROMPT 3, 2026-10-30)

> **This assumes:** (1) the tier rules in `licence_rule_2026_10_29.py` are unchanged, so a `warn` does not make Gold; (2) the US federal licence rule stands; (3) a page read by script counts as a read only where the fact appears in the page's static text. Counts come from the files (`numbers_check_2026_10_30.py`, output in `numbers-check-2026-10-30.txt`).

## What changed in method (read this first)

Robert was away, so I made these calls:

- **Pages were fetched by a script, not WebFetch.** `validation/fetch.py` uses the required user-agent, honours robots.txt, makes 1 request per second per domain, never downloads data files, and records a challenge or JS shell as blocked. I judged the text myself. The cost: JS-rendered pages (Miami-Dade Hub, Copernicus, Earthdata) show nothing.
- **Most V1 gaps were real answers, not unread facts.** Of 113 queued Silver rows, 28 unit and 19 temporal gaps were already `warn` with a stated reason (for example "finer than the listed unit"). I did not push any warn to pass, and I read 80 (the cap), taking open gaps first.
- **Searches:** 13 in total (V4: 10, V5: 3). V4 stopped at 10 because search results gave leads only; I confirmed each successor with a page fetch.

## Per phase

| Phase | Queued | Read | Blocked | Result |
|---|---|---|---|---|
| V1 Silver to Gold | 113 | 80 | 10 | 18 checks changed: 1 to pass (Annual NLCD unit, 30 m), 17 `not_checked` to warn (registration: Earthdata Login, Copernicus CDS). 2 Silver to Gold from V1/V5 together (below) |
| V2 never-read Bronze | 46 | 46 | 22 | 24 read; 4 licences pass (PDAPS, CC BY 4.0); 22 need a browser (Miami-Dade Hub, ICPSR/NaNDA, HDX, IAEA, one timeout, one row with no URL) |
| V3 licence fails | 80 | 80 | 1 (NYC, HTTP 403) | 6 pass, 13 warn, 61 unchanged fail |
| V4 Failed | 44 | 44 | – | 7 `successor_found` (live, HTTP 200), 9 `confirmed_retired`, 28 `unresolved` |
| V5 geometry | 8 lookups | 3 searches + 3 reads | – | 2.2 found, 2.3 answered (no official source), 3 of 4 TBD rows named or explained |

## Tiers

| | Gold | Silver | Bronze | Browser needed | Failed | Total |
|---|---|---|---|---|---|---|
| Before | 84 | 261 | 140 | 137 | 44 | 666 |
| After | 89 | 284 | 113 | 137 | 44 | 667 |

30 rows moved (`tier-moves-2026-10-30.csv`): 25 Bronze to Silver (17 from V3 licence changes, 8 from V2 reads), 2 Silver to Gold (Annual NLCD; the SDWIS lead service line inventory, whose "dependency TBD" cap lifted), 2 Bronze to Gold (ONS NSPL, ABS Census DataPacks, once the site terms settled their only gap), and the new EPA row at Gold. Gold+Silver is 373 (was 345). **Caution:** the four PDAPS rows became Silver on a licence read alone, because the Silver rule needs only one B check with no fails. Their years, unit and access are unchecked.

## Publishers whose terms page settled the licence

- **Pass (named open licence):** ABS (CC BY 4.0, 2 rows), ONS (Open Government Licence), Welsh Government (OGL), Statistics Canada (Open Licence), World Bank (CC BY 4.0 default for its own datasets).
- **Warn (terms exist, grant unclear or limited):** WHO (6 rows; "for public health purposes"), FAO (2; CC BY 4.0 covers statistical databases, not these map products), SSB, Eurostat GISCO, INEGI, NASA NCCS, JRC INFORM.
- **Unchanged:** NYC (3; terms page blocked), PEDP, paid or agreement-only sources, and publishers whose terms page I did not look up.

## Failed rows

Successors found (live, content not yet checked against the row, so the rows stay Failed): Nomis Census 2021 (the earlier DNS failure looks transient), HUD Location Affordability Index v3 (data.gov), NOAA Climate at a Glance (NCEI bulk nClimDiv directory), GRIP4 (Zenodo), Statistics Finland Paavo, the German GISD (Zenodo; GitHub copy is CC BY-NC-ND), Pakistan census 2023 results. No confirmed replacement: EA RoFRS, BKG VG250, EPA NPL boundaries.

## V5 geometry answers

Full text in `v5-answers.md`. **2.2:** EPA Public Water System Service Areas v3 (March 2026), PWSID key, about 55 percent system-sourced and the rest modelled; added as `us_epa_pws_service_areas`. **2.3:** no official ZIP-to-ZCTA crosswalk; UDS Mapper sunset in early 2024; HUD-USPS has no ZCTA and its API needs a key (those two points are from search, not a page read). **TBD rows:** SDWIS and the lead line inventory now depend on the PWS service areas; GHGRP points to the FRS national file but the GHGRP link field was not found; AidData has no source found.

## Still open, and why

- 22 never-read rows and 10 V1 rows need a real browser.
- 92 of the 113 queued V1 Silver rows still have a `warn` on their gap check (unit, temporal, licence or registration), 17 of them newly settled as registration: they stay Silver unless Robert decides warns can count (TODO 4.9).
- 28 Failed rows are `unresolved` because searching was capped (TODO 2.14).
- The optional regional boundary sources (V5 item 4) were not done.
- Whether site-wide terms count as a dataset licence (TODO 4.8).
