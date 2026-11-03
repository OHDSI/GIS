# Run 2026-11-02: evidence fixes, edge cases, successors, UCMR 4, GIS#553

One step at a time, each a records file in this folder applied by `scripts/apply_records_2026_11_02.py` to a new master (old masters kept). Decisions by Robert, 2026-11-02: federal edge cases by page read only (TODO 1.7); ZIP-to-ZCTA by the archived UDS crosswalk (2.3); Silver rule to the WG (4.10); GIS#553 solved here, reply drafted for Robert to post.

**Result (steps a-j):** 699 rows (676 counted; 23 still in the pilot): Gold 105 → 111, Silver 389 → 409, Bronze 106 → 106, Browser needed 20, Failed 47 → 30. Gold + Silver 494 → 520, the same in the package, `inventory.csv` and the workbook. Of the 409 Silver rows, 225 have all four core checks settled. Final master `inventory-combined-2026-11-02j.csv`. PR text: `publish/pr/PR-update-2026-11-02.md`.

| Step | Records | Master | Rows | Tier moves |
|---|---|---|---|---|
| a | `a-gpcc-edo.jsonl` | `-11-02a` | EDO/GDO and GPCC: variable lists read (they had come from memory) | none |
| b | `b-federal-edge.jsonl` | `-11-02b` | Daymet (licence on the DOI landing page: "openly shared, without restriction"); Smithsonian GVP (VOTW is US-employee work, per GVP Terms of Use); Water Quality Portal (disclaimer only → warn) | Daymet Bronze → Gold; GVP Silver → Gold |
| c | `c-successors.jsonl` | `-11-02c` | TODO 2.15: NZDep (Otago new URL), OECD (now the "Regions, Cities and Local Areas database" in the OECD Data Explorer), EFAS (EWDS efas-historical), HIFLD hospitals (Data Rescue Project archive), BFS STATPOP (statistik.admin.ch, 2024 edition) | NZDep, OECD, EFAS Failed → Silver; BFS Bronze → Gold; HIFLD stays Bronze (no licence) |
| d | `d-ucmr4.jsonl` | `-11-02d` | New `us_epa_ucmr4_occurrence` (page read; file not opened) | new → Silver |
| e | `e-gis553.jsonl` | `-11-02e` | New `global_csic_speibase`, `us_gridmet_drought`, `global_c3s_era5_heat_utci`, `us_cafe_county_wbgt_utci` | 3 Silver, 1 Gold (CAFE county WBGT/UTCI, CC0) |
| f | `f-pws-service-areas.jsonl` | `-11-02f` | TODO 2.2: CWS feature service has 44,615 polygons, 44,614 distinct PWSID (last edit 2026-05-29) | none (Gold) |

| g | `g-unit-vocab.jsonl` | `-11-02g` | Unit labels: 126 rows moved off non-vocabulary labels (`postcode_small_area` was a ranking bucket from `split_link_score.py`, 2026-10-20, never mapped back; `unknown` where a page read had confirmed point/polygon/line). 92 rows left in `g-unit-vocab-review.csv` for a person. Vocabulary: admin4, admin5, meshblock, tl2, tl3, cbsa, place added | none |
| h | `h-care-sites.jsonl` | `-11-02h` | TODO 2.12: GRID3 NGA Health Facilities v4.0 (70,235 points, NHFR codes) and GRID3 COD Health Facilities v9.0 (38,957 points, DHIS2 and health-zone ids), both free use with attribution; CNES monthly base to 2026-09; PO (oncology panel) as a Bronze lead | 2 new Gold; CNES (pilot row) Bronze → Silver; PO new Bronze |
| i | `i-failed-2-14.jsonl` | `-11-02i` | TODO 2.14, the 28 unresolved Failed rows: 7 successors (GISCO Urban Audit, EA RoFRS, YCEO SUHI via NASA SEDAC, OpenDataPhilly heat vulnerability, EPA NPL boundaries, 2 SEDAC PM2.5 products on NASA Earthdata); 5 live pages scripts could not read (Walk Score, Africapolis, NOAA billion-dollar, DEFRA PCM, HDX Brazil); 2 HDX rows archived; GDL Area Database retired (March 2025, split by theme); INE Portugal in maintenance; 12 with no verified successor (notes record the leads) | 13 Failed → Silver, 1 → Bronze; 14 stay Failed |

| j | `j-checks-from-notes.jsonl` | `-11-02j` | 21 Gold/Silver rows (P2.1 spike: CMS, PDAPS, LawAtlas; plus UCMR 5) had blank `chk_*`; check values derived from their recorded `*_confirmed` findings (no new reads; withdrawn left unchecked). CNES promoted from the pilot (`round = 2-pilot-promoted`, Robert) | none; all 21 now hold Silver under `tier_of()` |

**Also changed:** `landscape/anchors.csv` (heat: UTCI, universal thermal climate index, WBGT, wet bulb globe temperature, thermal comfort, heat stress; water_hazards_fire: standardized precipitation evapotranspiration index, SPI, standardized precipitation index); `TODO.md` and `README.md` (1.6 done; decisions; prompt numbers written P1.8, P2.1). Backups in `_to_delete/`.

**Caveats (read these before sharing):**
- (Resolved in step j.) Re-tiering bug found and fixed in step g: re-tiering a row with blank checks sends it to Failed, and 21 Gold/Silver rows have no `chk_link_live` (20 from the P2.1 spike: PDAPS, LawAtlas, CMS). The apply script now re-tiers only when a check changes. Those 21 rows are Silver by the spike's merge logic, not by `tier_of()`. This is for the WG with 4.10.
- Silver by "no fail" (4.10) also covers Walk Score (commercial, pricing on request; licence not read) and the two archived HDX rows (Sudan, Uganda; 2018 data, withdrawn = warn).
- UCMR PWSID coverage of the service areas: not done. epa.gov returns 403 to both shells, and the README rules out browser downloads. Robert to save the UCMR 3/4/5 zips into `run-2026-11-02/ucmr/`.
- OECD regions reached Silver on a single read check (unit). Its licence and years were not read. This is the loose Silver rule (4.10).
- NZDep and OECD both had `finest_unit = postcode_small_area` and latest year 2023, which looks like a copy error. Both units were corrected from the pages (`meshblock`, `tl3`). Neither term is in `unit-vocabulary.csv` yet.
- EFAS and ERA5-HEAT: the Copernicus licences are named on the pages, but their texts were not read (warn). gridMET Drought's indices come from the Earth Engine catalog; the publisher's own page lists only PDSI.
- Not done:
  - The UDS crosswalk (2.3): it is archived only on the Wayback Machine (https://web.archive.org/web/20231218141557/https://udsmapper.org/zip-code-to-zcta-crosswalk/), which this session's tools may not open. Robert to open it and save one year's file into `run-2026-11-02/`.
  - UCMR PWSID coverage of the service areas: this needs the UCMR files.
  - UNdata (data.un.org is now UN Data Commons): left as is.
- DataCite for the new terms: `datacite-gis553-2026-11-02.md` (100 heat-index and 227 SPEI title hits; shortlist of 13).
- GIS#553 reply draft: `gis553-reply-draft.md`.
