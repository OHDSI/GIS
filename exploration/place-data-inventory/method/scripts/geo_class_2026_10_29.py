#!/usr/bin/env python3
"""PROMPT 2 phase A (2026-10-29): geometry type, place-key type, geometry source and dependency for every row, plus the re-tier.
python scripts/geo_class_2026_10_29.py   (run from docs/discovery)

Reads inventory-combined-2026-10-29.csv and unit-vocabulary.csv (terms only; the rules below are the code, new terms go in the vocabulary).
Writes inventory-combined-2026-10-29-geo.csv, inventory.csv (regenerated), landscape/geometry-unlocks-<date>.csv,
landscape/place-keys-by-region-<date>.csv, landscape/geo-class-handcheck-<date>.csv.
New tier rule only: reference_specific with geometry_dependency TBD caps a row at Silver.
"""
import csv, os, re, sys
from collections import Counter, OrderedDict

D = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TODAY = "2026-10-29"
SRC = f"{D}/inventory-combined-2026-10-29.csv"
OUT = f"{D}/inventory-combined-2026-10-29-geo.csv"
os.makedirs(f"{D}/landscape", exist_ok=True)

rows = list(csv.DictReader(open(SRC, encoding="utf-8")))
cols = list(rows[0].keys())
ids = {r["id"] for r in rows}
vocab = {(v["kind"], v["term"]) for v in csv.DictReader(open(f"{D}/unit-vocabulary.csv", encoding="utf-8-sig"))}

# ---------------------------------------------------------------- region
AF = set("TZ NG UG KE ZA GH ET MA EG SN RW ZM MZ SL SS CD AF ETH KEN NGA TZA UGA GHA ZAF".split())
AS = set("CN IN KH LA MM TH VN JP KR PH ID TR BD SA NP IN IND IDN PHL NPL MMR BGD JPN KOR".split())
LA = set("PE BR MX CO AR CL VE BRA COL VEN MEX ARG CHL PER".split())
EUC = set("DE FR ES IT NL SE NO DK PL IE BE CH AT PT FI GR".split())
OTH = {"NZ": "other"}


def region_of(r):
    cov = (r["coverage"] or "").strip()
    toks = [t for t in re.split(r"[;,()\s]+", cov) if t]
    first = toks[0] if toks else ""
    pre = r["id"].split("_")[0].lower()
    if first.lower() == "global" or first.lower().startswith("global"):
        return "global"
    if first.startswith("US") or first == "North":
        return "US"
    if first == "EU":
        return "EU"
    if first in ("GB", "UK"):
        return "UK"
    if first == "CA":
        return "Canada"
    if first == "AU":
        return "Australia"
    if first in AF or first in ("Africa",):
        return "Africa"
    if first in AS or any(t in AS for t in toks) and first in ("KH",):
        return "Asia"
    if first in LA or first in ("Latin", "Caribbean"):
        return "Latin America"
    if first in EUC:
        return "EU"
    if first in OTH:
        return "other"
    return {"us": "US", "eu": "EU", "gb": "UK", "ca": "Canada", "au": "Australia", "global": "global", "tz": "Africa", "ng": "Africa", "ke": "Africa",
            "ug": "Africa", "gh": "Africa", "br": "Latin America", "mx": "Latin America", "pe": "Latin America", "co": "Latin America", "hh": "Latin America",
            "in": "Asia", "cn": "Asia", "ph": "Asia", "tr": "Asia", "ma": "Africa", "sa": "Asia", "nz": "other", "tt": "Latin America"}.get(pre, "global" if not cov else "other")


# ---------------------------------------------------------------- unit and geometry type
def unit_of(txt):
    t = txt.lower()
    for pat, u in [(r"grid|raster|pixel|hex|h3", "grid"), (r"block[_ ]group|bgrp", "block_group"), (r"\bblock\b|meshblock", "block"), (r"tract", "tract"), (r"zcta", "zcta"),
                   (r"\bzip|postal|postcode", "zip"), (r"lsoa|msoa|output_area|\boa\b|small area|small_area|seccion|iris|deso|sa1|sa2|grunnkrets|sector|barangay|mahalle|\bda\b|ward|setor",
                                                   "small_area"), (r"county", "county"), (r"admin3|commune|\blau\b|municip", "admin3"), (r"admin2|district|upazila|\bsa3\b", "admin2"),
                   (r"admin1|state|province|region|\buf\b|entidad", "state"), (r"admin0|country|nation|national", "country"),
                   (r"point|address|station|facility|monitor|site|sensor|hospital|clinic|settlement|locality|poi\b|building", "point"), (r"line|road|stream|polyline|route", "line"),
                   (r"polygon|boundar|catchment|huc|park|area", "polygon")]:
        if re.search(pat, t):
            return u
    return ""


def gtype_of(r, u, fmt):
    if u == "grid" or re.search(r"geotiff|\btif|netcdf|grib|raster|\bnc\b", fmt) or r["gaia_fit"] == "needs_raster":
        return "raster"
    if u == "point":
        return "point"
    if u == "line":
        return "line"
    if re.search(r"line;polygon|point;line|polyline", (r["geography_units"] or "").lower()) and u in ("line", "polygon", "point"):
        return "line" if u == "line" else u
    if u in ("block_group", "block", "tract", "zcta", "zip", "county", "state", "country", "admin3", "admin2", "small_area", "polygon"):
        return "polygon"
    return "none"


# ---------------------------------------------------------------- place keys
NEG = re.compile(r"\b(no|not|without|only as)\b[^;.]*", re.I)
KEYS = [("GEOID/FIPS", r"geoid|fips|tract id|state_code|state2kx|cvegeo|census tract (id|code)|census block|logrecno"), ("ZCTA", r"zcta"),
        ("ZIP code", r"\bzip\b|zip code|postal code"), ("NUTS", r"\bnuts"), ("LAU", r"\blau\b"), ("ONS GSS", r"lsoa|msoa|\bgss\b|\bons\b|\bdz22|\boa\b|nspl"),
        ("StatCan SGC/DGUID", r"dguid|\bsgc\b|statcan|pruid"), ("ASGS", r"asgs|sa[1-4]_code|mb_code|poa_code"), ("OCHA P-code", r"p-?code"),
        ("ISO 3166", r"iso ?3166|iso3|boundaryiso|iso code|code_insee|\bid_0\b"), ("GADM", r"gadm"), ("geoBoundaries", r"boundaryid"), ("H3 index", r"\bh3\b|hex8"),
        ("HUC", r"\bhuc"), ("coordinates", r"lat/?lon|latitude|longitude|intptlat|coordinate|lon/lat"),
        ("embedded geometry", r"geometry|shapefile|geopackage|geojson|raster|\bgrid\b|netcdf|geotiff|\bshp\b|gdb|kml|grib|wkt"),
        ("non-geographic ID", r"pws ?id|pwsid|facility id|station id|registry id|site id|site_number|project id|grant id")]


def keys_in(txt):
    txt = ";".join(seg for seg in txt.split(";") if not NEG.search(seg))
    return [k for k, p in KEYS if re.search(p, txt, re.I)]


def fallback_keys(u, reg, gt):
    if gt == "raster" or u in ("grid", "polygon"):
        return ["embedded geometry"]
    if u in ("tract", "block_group", "block", "county") and reg == "US":
        return ["GEOID/FIPS"]
    if u == "state" and reg == "US":
        return ["GEOID/FIPS"]
    if u == "zcta":
        return ["ZCTA"]
    if u == "zip":
        return ["ZIP code"]
    if u == "point":
        return ["coordinates"]
    if u == "small_area":
        return {"UK": ["ONS GSS"], "EU": ["NUTS"], "Canada": ["StatCan SGC/DGUID"], "Australia": ["ASGS"]}.get(reg, [])
    if u in ("admin2", "admin3") and reg not in ("EU", "global"):
        return ["national statistical code"]
    if u in ("state", "admin2", "admin3", "country"):
        return ["ISO 3166"] if reg != "EU" else ["NUTS"]
    return []


STD_DEP = {"GEOID/FIPS": "Census TIGER {u}", "ZCTA": "Census TIGER ZCTAs", "ZIP code": "ZIP-to-ZCTA crosswalk + Census TIGER ZCTAs", "NUTS": "Eurostat GISCO NUTS",
           "LAU": "Eurostat GISCO LAU", "ONS GSS": "ONS Open Geography Portal boundaries", "StatCan SGC/DGUID": "ca_statcan_census_boundary_files_2021",
           "ASGS": "au_abs_asgs_boundaries", "OCHA P-code": "OCHA COD-AB (HDX)", "ISO 3166": "global_gadm_boundaries", "GADM": "global_gadm_boundaries",
           "geoBoundaries": "global_geoboundaries", "H3 index": "H3 library (computed)", "HUC": "USGS Watershed Boundary Dataset"}
UNIT_TXT = {"tract": "tracts", "block_group": "block groups", "block": "blocks", "county": "counties", "state": "states"}

# Hand overrides (reference_specific): the geometry dataset a non-geographic ID points at. TBD where the page or the inventory does not name one.
SPECIFIC = {
    "us_epa_ucmr": ("TBD", "PWS ID only; water-system service-area boundaries not in the inventory (candidate: EPA SABS, unverified)"),
    "us_epa_ucmr3_occurrence": ("TBD", "PWS ID plus ZIP-code file per issue #38; service-area boundaries not in the inventory"),
    "us_epa_sdwis_federal": ("TBD", "PWS ID only; service-area boundaries not in the inventory"),
    "us_epa_sdwis_lead_service_line_inventory": ("TBD", "PWS ID, state; service-area boundaries not in the inventory"),
    "us_epa_airdata_pregenerated_files": ("us_epa_aqs_sites_monitors", "by monitor; AQS site file is the geometry dependency (gaiaCatalog#32, R)"),
    "us_epa_ghgrp": ("TBD", "GHGRP Facility ID, no lat/lon named on the pages; a crosswalk to FRS (us_epa_frs) is likely but not read on a page"),
    "ca_eccc_climate_normals": ("ECCC Composite Station Inventory", "station ID; coordinates are in the station inventory, not described on the page"),
    "us_noaa_sea_level_trends": ("NOAA CO-OPS station metadata API", "station ID as the API parameter; lat/lon only as query inputs"),
}
EMBED_FORCE = {"global_noaa_ghcn_daily": "ghcnd-stations.txt ships lat/lon in the same dataset", "us_noaa_us_climate_normals": "station files carry lat/lon",
               "us_epa_aqs_data_mart_api": "latitude/longitude in the API output", "us_epa_echo_downloads": "lat/lon in ECHO Exporter", "us_epa_frs": "geospatial downloads"}
TITLE_KEY_OVERRIDE = {"us_epa_aqs_data_mart_api": ["coordinates", "non-geographic ID"]}

out = []
for r in rows:
    reg = region_of(r)
    conf_unit = r["finest_unit_confirmed"].strip()
    list_unit = r["finest_unit"].strip()
    if list_unit in ("unknown", "postcode_small_area") and r["geography_units"]:
        list_unit = r["geography_units"]
    unit_src = conf_unit or (list_unit if list_unit != "unknown" else "") or r["geography_units"]
    u = unit_of(unit_src)
    if not u and r["geography_units"]:
        u = unit_of(r["geography_units"])
    fmt = ((r["formats_confirmed"] or "") + " " + (r["format"] or "")).lower()
    gt = gtype_of(r, u, fmt)
    jk = r["join_key_confirmed"].strip()
    basis = "inferred"
    ks = []
    if jk:
        ks = keys_in(jk)
        if ks:
            basis = "listed" if jk.lower().startswith("implied") else "confirmed"
    if not ks and r["geography_units"]:
        ks = [k for k in keys_in(r["geography_units"]) if k != "non-geographic ID" or re.search(r"pws", r["geography_units"], re.I)]
        if ks:
            basis = "listed"
    if r["id"] in TITLE_KEY_OVERRIDE:
        ks = TITLE_KEY_OVERRIDE[r["id"]]
    if not ks:
        ks = fallback_keys(u, reg, gt)
        basis = "inferred"
    name = (r["dataset_name"] + " " + r["id"]).lower()
    if not ks and re.search(r"boundar|malha|limites|zoning|parcel|street|red_vial|district|station|stops|librar|catastro|mgn|marco_geo|territorial|buurtkaart|centros_poblados|flood_zone|park|zone|zona", name):
        ks = ["embedded geometry"]
        gt = "line" if re.search(r"street|red_vial|road", name) else "point" if re.search(r"station|stops|librar", name) else "polygon"
    if ks == ["none"] or not ks:
        if u in ("small_area", "block", "admin3", "admin2") and reg not in ("US", "global"):
            ks = ["national statistical code"]
    if u == "point" and gt != "point":
        gt = "point"
    if ks and ks[0] in ("GEOID/FIPS", "ZIP code") and "embedded geometry" not in ks and "coordinates" not in ks:
        pass
    ks = list(OrderedDict.fromkeys(ks))
    if r["gaia_fit"] == "not_linkable" and not ks:
        ks = ["none"]
    if not ks:
        ks = ["none"]
    # geometry source
    note = ""
    dep = ""
    standard = [k for k in ks if k in STD_DEP]
    if r["id"] in SPECIFIC:
        src = "reference_specific"; dep, note = SPECIFIC[r["id"]]
    elif r["id"] in EMBED_FORCE:
        src = "embedded"; dep = "self"; note = EMBED_FORCE[r["id"]]
    elif "embedded geometry" in ks or "coordinates" in ks or gt in ("raster",):
        src = "embedded"; dep = "self"
    elif standard:
        src = "reference_standard"
        k = standard[0]
        dep = STD_DEP[k].format(u=UNIT_TXT.get(u, u))
        if k == "ISO 3166" and u == "country":
            dep = "global_gadm_boundaries (ADM0)"
    elif "national statistical code" in ks:
        src = "reference_standard"; dep = f"National statistics office boundary file ({reg}); not identified in the inventory"
    elif "non-geographic ID" in ks:
        src = "reference_specific"; dep = "TBD"
    else:
        src = "none"; dep = "n/a"
    if src == "reference_specific" and dep == "TBD":
        gt = "none"
    if src == "none" and r["gaia_fit"] != "not_linkable" and ks == ["none"] and gt == "none":
        basis = "inferred"
    if src == "none" and not u:
        basis = "inferred"
    # confirmed requires both a confirmed key and a confirmed unit-or-geometry; otherwise downgrade to listed
    out.append(dict(r, region=region_of(r), geometry_type=gt, place_key_type="; ".join(ks), geometry_source=src, geometry_dependency=dep, geo_class_basis=basis, geo_class_note=note, unit_class=u))

# ---------------------------------------------------------------- re-tier
capped = []
for r in out:
    r["verify_tier_before_geo"] = r["verify_tier"]
    if r["geometry_source"] == "reference_specific" and r["geometry_dependency"] == "TBD" and r["verify_tier"] == "Gold":
        r["verify_tier"] = "Silver"
        r["notes"] = (r["notes"] + "; " if r["notes"] else "") + "capped at Silver: geometry dependency TBD (2026-10-29 rule)"
        capped.append(r["id"])
    # a reference_specific row with TBD that is already Silver stays Silver; lower tiers unchanged
tb_rows = [r for r in out if r["geometry_source"] == "reference_specific" and r["geometry_dependency"] == "TBD"]

# ---------------------------------------------------------------- write
newcols = cols + ["region", "unit_class", "geometry_type", "place_key_type", "geometry_source", "geometry_dependency", "geo_class_basis", "geo_class_note", "verify_tier_before_geo"]


def wcsv(p, data, c):
    with open(p, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=c, extrasaction="ignore"); w.writeheader()
        for r in data:
            w.writerow({k: r.get(k, "") for k in c})


assert len(out) == 601
wcsv(OUT, out, newcols)
INV_COLS = ["id", "title", "publisher", "domain", "landing_url", "access", "geography", "coverage", "temporal", "format", "license", "update_cadence", "in_gaia", "recipe_health",
            "last_checked", "evidence", "notes", "geometry_type", "place_key_type", "geometry_source", "geometry_dependency"]
prom = []
for r in out:
    if r["verify_tier"] in ("Gold", "Silver") and r["round"] != "2-pilot":
        ev = "; ".join(OrderedDict.fromkeys(x for x in [r.get("chk_license_evidence"), r.get("chk_temporal_evidence"), r.get("chk_unit_evidence"), r.get("evidence_url")] if x))
        prom.append({"id": r["id"], "title": r["dataset_name"], "publisher": r["organization"], "domain": r["theme"], "landing_url": r["site_url"],
                     "access": r.get("access_confirmed") or r["access_type"], "geography": r.get("finest_unit_confirmed") or r["geography_units"] or r["finest_unit"],
                     "coverage": r.get("coverage_confirmed") or r["coverage"], "temporal": r.get("temporal_confirmed") or r["temporal"], "format": r.get("formats_confirmed") or r["format"],
                     "license": r.get("license_confirmed") or r["license"], "update_cadence": r.get("update_cadence_confirmed") or r["update_cadence"], "in_gaia": r["in_gaia"],
                     "recipe_health": r["recipe_health"], "last_checked": r["verified_on"], "evidence": ev,
                     "notes": f"verify_tier {r['verify_tier']}; health_score {r['health_score']}; " + (f"mirror of {r['mirror_of']}; " if r["mirror_of"] else "") + (r["notes"] or "")[:300],
                     "geometry_type": r["geometry_type"], "place_key_type": r["place_key_type"], "geometry_source": r["geometry_source"], "geometry_dependency": r["geometry_dependency"]})
wcsv(f"{D}/inventory.csv", prom, INV_COLS)

# unlocks
INV_MAP = {"Census TIGER": "us_census_tiger_line", "Census TIGER counties": "us_census_tiger_line_county", "Census TIGER ZCTAs": "us_census_zcta",
           "ZIP-to-ZCTA crosswalk + Census TIGER ZCTAs": "us_census_zcta", "Eurostat GISCO NUTS": "eu_eurostat_gisco_nuts", "Eurostat GISCO LAU": "eu_eurostat_gisco_lau"}
dep_rows = {}
for r in out:
    if r["geometry_source"] in ("reference_standard", "reference_specific"):
        dep_rows.setdefault(r["geometry_dependency"], []).append(r)
un = []
for d, rs in dep_rows.items():
    key = d.split(" (")[0]
    key = INV_MAP.get(key, INV_MAP["Census TIGER"] if key.startswith("Census TIGER") else key)
    in_inv = key in ids
    un.append(dict(geometry_dependency=d, geometry_source="/".join(sorted({r["geometry_source"] for r in rs})), rows_unlocked=len(rs),
                   gold=sum(r["verify_tier"] == "Gold" for r in rs), silver=sum(r["verify_tier"] == "Silver" for r in rs),
                   gold_silver_before_cap=sum(r["verify_tier_before_geo"] in ("Gold", "Silver") for r in rs),
                   dependency_in_inventory="Y" if in_inv else "N", inventory_id=key if in_inv else "",
                   dependency_tier=next((x["verify_tier"] for x in out if x["id"] == key), ""), example_ids="; ".join(r["id"] for r in rs[:4])))
un.sort(key=lambda x: (-x["rows_unlocked"], x["geometry_dependency"]))
wcsv(f"{D}/landscape/geometry-unlocks-{TODAY}.csv", un, list(un[0].keys()))

# place keys x region
regs = ["US", "EU", "UK", "Canada", "Australia", "Africa", "Asia", "Latin America", "global", "other"]
tab = {}
for r in out:
    for k in r["place_key_type"].split("; "):
        tab.setdefault(k, Counter())[r["region"]] += 1
pk = []
for k, c in sorted(tab.items(), key=lambda kv: -sum(kv[1].values())):
    d = {"place_key_type": k, "total": sum(c.values())}
    d.update({g: c.get(g, 0) for g in regs})
    pk.append(d)
wcsv(f"{D}/landscape/place-keys-by-region-{TODAY}.csv", pk, ["place_key_type", "total"] + regs)
rc = Counter(r["region"] for r in out)
wcsv(f"{D}/landscape/region-counts-{TODAY}.csv", [{"region": g, "rows": rc.get(g, 0)} for g in regs], ["region", "rows"])

HC = ["us_epa_ucmr", "us_epa_aqs_data_mart_api", "us_epa_aqs_sites_monitors"]
print("source", Counter(r["geometry_source"] for r in out)); print("gtype", Counter(r["geometry_type"] for r in out)); print("basis", Counter(r["geo_class_basis"] for r in out))
print("regions", dict(rc)); print("capped", capped); print("TBD rows", len(tb_rows), Counter(r["verify_tier_before_geo"] for r in tb_rows))
T = ["Gold", "Silver", "Bronze", "Browser needed", "Failed"]
print("before", {t: sum(r["verify_tier_before_geo"] == t for r in out) for t in T}); print("after", {t: sum(r["verify_tier"] == t for r in out) for t in T})
print("inventory.csv rows", len(prom))
for r in out:
    if r["id"] in HC:
        print(r["id"], r["unit_class"], r["geometry_type"], r["place_key_type"], r["geometry_source"], r["geometry_dependency"], r["geo_class_basis"], r["verify_tier"])
