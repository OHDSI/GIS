"""Merge Prompt 1.7 file verification (fileverify/) into the inventory.
Input:  inventory-combined-2026-10-29-geo.csv (Prompt 2 phase A), fileverify/fileverify-2026-10-29.csv, fileverify/proposed-rows-2026-10-29.csv,
        wg-open-checks-2026-10-29.md (browser checks; applied by hand below)
Output: inventory-combined-2026-10-29-fv.csv, inventory.csv (Gold + Silver), fileverify/merge-log-2026-10-29.csv
Rules: add file_* columns; apply only corrections the file evidence supports; never raise a tier on file evidence alone except where noted."""
import csv
D = "."
FV = "2026-10-29"
rows = list(csv.DictReader(open(f"{D}/inventory-combined-2026-10-29-geo.csv", encoding="utf-8-sig")))
cols = list(rows[0].keys())
fv = {r["id"]: r for r in csv.DictReader(open(f"{D}/fileverify/fileverify-2026-10-29.csv", encoding="utf-8-sig"))}
prop = list(csv.DictReader(open(f"{D}/fileverify/proposed-rows-2026-10-29.csv", encoding="utf-8-sig")))
NEW = ["file_verified", "file_status", "file_url", "file_type", "columns_found", "place_key_found", "geometry_found", "crs",
       "row_count", "years_found", "file_latest_date", "file_mismatches", "file_notes", "verification_level"]
cols += [c for c in NEW if c not in cols]
log = []
def setv(r, c, v, why):
    old = r.get(c, "")
    if old != v:
        r[c] = v; log.append({"id": r["id"], "column": c, "old": old, "new": v, "why": why})
byid = {r["id"]: r for r in rows}
for i, f in fv.items():
    r = byid.get(i)
    if not r: continue
    st = f["status"]
    for a, b in [("file_status", "status"), ("file_url", "file_url"), ("file_type", "file_type"), ("columns_found", "columns_found"),
                 ("place_key_found", "place_key_found"), ("geometry_found", "geometry_found"), ("crs", "crs"), ("row_count", "row_count"),
                 ("years_found", "years_found"), ("file_latest_date", "latest_date"), ("file_mismatches", "mismatches"), ("file_notes", "notes")]:
        r[a] = f.get(b, "")
    r["file_verified"] = FV if st in ("verified", "partly") else ""
for r in rows:
    if r.get("file_status") == "verified": r["verification_level"] = "file-verified"
    elif r.get("file_status") == "partly": r["verification_level"] = "file-verified (partly)"
    elif r["verify_tier"] in ("Gold", "Silver"): r["verification_level"] = "page-verified"
    else: r["verification_level"] = ""
# --- corrections supported by the files (see fileverify-report-2026-10-29.md) ---
u3 = byid["us_epa_ucmr3_occurrence"]
setv(u3, "temporal_confirmed", "2013-2016 (collection dates in the file; the inventory said 2013-2015)", "file: dates to 2016-12-14")
setv(u3, "latest_year_confirmed", "2016", "file")
for i in ("us_epa_ucmr3_occurrence", "us_epa_ucmr"):
    r = byid[i]
    setv(r, "place_key_type", "non-geographic ID; ZIP code", "file: UCMR*_ZIPCodes.txt maps PWSID to ZIP codes served")
    setv(r, "geometry_source", "reference_standard", "file: ZIP codes served give a standard-geography route (approximate: a system serves several ZIPs)")
    setv(r, "geometry_dependency", "ZIP-to-ZCTA crosswalk + Census TIGER ZCTAs (via PWSID-to-ZIP file); water-system service areas would be exact", "file")
# the generic UCMR row was capped Gold->Silver only for 'dependency TBD'; that reason no longer holds
g = byid["us_epa_ucmr"]
# Robert, 2026-10-29: keep Silver. ZIP codes served approximate a water system's area; the row is generic (UCMR 1-5); per-cycle rows carry the detail.
setv(g, "notes", (g.get("notes", "") + " | 2026-10-29: kept Silver (Robert). Generic multi-cycle row; per-cycle rows: us_epa_ucmr3_occurrence, us_epa_ucmr5_occurrence. ZIP codes served give only an approximate geography; water-system service areas would be exact").strip(" |"), "decision")
dv = byid["global_diva_gis"]
setv(dv, "license_confirmed", "GADM 2.5 terms in the files: non-commercial use only, no redistribution", "file")
setv(dv, "license_class", "non-commercial", "file")
setv(dv, "temporal_confirmed", "GADM version 2.5 (July 2015)", "file")
sdg = byid["global_un_sdg_global_database"]
setv(sdg, "finest_unit_confirmed", "country (the API's location dimension is ALLAREA/URBAN/RURAL only; no sub-national areas)", "file/API")
setv(sdg, "notes", (sdg.get("notes", "") + " | 2026-10-29 file check: country-level only, does not meet gaiaCatalog#34's sub-national need").strip(" |"), "file/API")
eji = byid["us_cdc_eji"]
setv(eji, "temporal_confirmed", "2022 and 2024 editions (file checked: 2024)", "browser + file")
setv(eji, "formats_confirmed", "CSV (GEOID, 170 columns); Geodatabase (tract MultiPolygon, ESRI:102003); data dictionary included", "file")
coi = byid["us_brandeis_coi"]
setv(coi, "notes", (coi.get("notes", "") + " | 2026-10-29 file check: 2012-2024, 83,959 2020 tracts (geoid20); old access URL redirects, files on public Globus; terms require agreeing to T&C (not read)").strip(" |"), "file")
# --- proposed rows ---
TIER = {"us_epa_ucmr5_occurrence": ("Silver", "US federal work (WG rule); file-verified; unit is the water system, joined via ZIP codes served (approximate)"),
        "eu_eea_aq_stations_rest": ("Bronze", "file-verified geometry layer for EEA e-Reporting; licence not read"),
        "global_dhs_program_api": ("Bronze", "open API with sub-national indicators and WKT boundaries, file-verified; terms not read")}
for p in prop:
    r = {c: "" for c in cols}
    r.update({k: v for k, v in p.items() if k in cols})
    t, why = TIER.get(p["id"], ("Bronze", "proposed"))
    r["verify_tier"] = t; r["round"] = r.get("round") or "1.7-fileverify"; r["file_verified"] = FV; r["file_status"] = "verified"
    r["verification_level"] = "file-verified"; r["notes"] = (r.get("notes", "") + " | added 2026-10-29 from Prompt 1.7: " + why).strip(" |")
    if p["id"] == "us_epa_ucmr5_occurrence":
        r.update({"license_class": "public_domain_us_federal", "temporal_confirmed": "2023-2026 (collection dates to 2026-06-17; final dataset Aug 2026, refreshed 2026-10-15)",
                  "latest_year_confirmed": "2026", "geometry_type": "none", "place_key_type": "non-geographic ID; ZIP code", "geometry_source": "reference_standard",
                  "geometry_dependency": "ZIP-to-ZCTA crosswalk + Census TIGER ZCTAs (via PWSID-to-ZIP file)", "geo_class_basis": "confirmed"})
    if p["id"] == "eu_eea_aq_stations_rest":
        r.update({"geometry_type": "point", "place_key_type": "coordinates", "geometry_source": "embedded", "geo_class_basis": "confirmed"})
    if p["id"] == "global_dhs_program_api":
        r.update({"geometry_type": "polygon", "place_key_type": "embedded geometry", "geometry_source": "embedded", "geo_class_basis": "confirmed"})
    rows.append(r); log.append({"id": p["id"], "column": "(row)", "old": "", "new": f"added, {t}", "why": why})
w = csv.DictWriter(open(f"{D}/inventory-combined-2026-10-29-fv.csv", "w", newline="", encoding="utf-8"), fieldnames=cols); w.writeheader(); w.writerows(rows)
inv_cols = list(csv.DictReader(open(f"{D}/inventory.csv", encoding="utf-8-sig")).fieldnames)
inv_cols += [c for c in ["verification_level", "file_verified", "place_key_found", "geometry_found", "years_found"] if c not in inv_cols]
gs = [r for r in rows if r["verify_tier"] in ("Gold", "Silver")]
w = csv.DictWriter(open(f"{D}/inventory.csv", "w", newline="", encoding="utf-8"), fieldnames=inv_cols, extrasaction="ignore"); w.writeheader()
for r in gs: w.writerow({c: r.get(c, "") for c in inv_cols})
w = csv.DictWriter(open(f"{D}/fileverify/merge-log-2026-10-29.csv", "w", newline="", encoding="utf-8"), fieldnames=["id", "column", "old", "new", "why"]); w.writeheader(); w.writerows(log)
import collections
print(len(rows), collections.Counter(r["verify_tier"] for r in rows))
print("Gold+Silver", len(gs), collections.Counter(r["verification_level"] for r in rows if r["verification_level"]))
print("log entries", len(log))
