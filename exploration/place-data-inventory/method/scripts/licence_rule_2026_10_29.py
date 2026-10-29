#!/usr/bin/env python3
"""PROMPT 1.5 (2026-10-29): federal licence rule + working-group targets.   python scripts/licence_rule_2026_10_29.py   (run from docs/discovery)

Reads inventory-combined-2026-10-28.csv. Writes inventory-combined-2026-10-29.csv, federal-publishers-2026-10-29.csv,
federal-rule-rows-2026-10-29.csv (every federal-looking row examined: set pass / kept back / not federal), inventory.csv (Gold+Silver).
Tier logic is the refine_2026_10_28.py rule, with B_done taken from the row's state BEFORE the rule (so a row never read for content does not
become Silver just because its licence check flipped to pass).
"""
import csv, os, re, sys
from collections import Counter, OrderedDict
import urllib.parse as up

D = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
sys.path.insert(0, os.path.join(D, "scripts"))
import verify_links as VL
SRC = "inventory-combined-2026-10-28.csv"; OUT = "inventory-combined-2026-10-29.csv"; TODAY = "2026-10-29"
A_CHECKS = VL.CHECKS
B_CHECKS = ["chk_license", "chk_temporal", "chk_recency", "chk_cadence", "chk_version", "chk_unit", "chk_coverage", "chk_access", "chk_join_key", "chk_format_gaia"]
ALL_CHECKS = A_CHECKS + B_CHECKS + ["chk_in_gaia", "chk_recipe_health"]
WEIGHTS = {"chk_link_live": 20, "chk_soft404": 10, "chk_withdrawn": 10, "chk_license": 15, "chk_unit": 15, "chk_temporal": 7.5, "chk_recency": 7.5,
           "chk_access": 10, "chk_join_key": 10, "chk_machine_metadata": 5}
VAL = {"pass": 1.0, "warn": 0.5, "fail": 0.0}
rows = list(csv.DictReader(open(f"{D}/{SRC}", encoding="utf-8-sig")))
cols = list(rows[0].keys()) + ["wg_request"]
by_id = {r["id"]: r for r in rows}
for r in rows:
    r.setdefault("wg_request", "")

# ---------------------------------------------------------------- step 1: federal publishers
# (publisher regex on `organization`, landing domains). A row is federal only if the publisher matches AND the landing domain is .gov/.mil or catalog.data.gov/healthdata.gov.
FED = [
    ("US EPA", r"^(U\.S\. )?EPA\b|^US EPA|^U\.S\. EPA", "epa.gov; aqs.epa.gov; airnow.gov"),
    ("NASA (incl. GES DISC)", r"^NASA( GES DISC)?$|^NASA GES", "nasa.gov"),
    ("NOAA", r"^NOAA", "noaa.gov; climate.gov; heat.gov"),
    ("USGS", r"^(USGS|U\.S\. Geological Survey)", "usgs.gov; mrlc.gov; mtbs.gov"),
    ("CDC / ATSDR / NCHS", r"^(CDC|Centers for Disease Control)", "cdc.gov"),
    ("CMS", r"^Centers for Medicare", "cms.gov; data.cms.gov; healthdata.gov"),
    ("HRSA", r"^Health Resources and Services", "hrsa.gov"),
    ("AHRQ", r"^Agency for Healthcare Research", "ahrq.gov"),
    ("NIH / NIEHS / NCI", r"^(NIEHS|NIH$|NIH NCATS|National Cancer Institute)", "nih.gov; cancer.gov"),
    ("HHS", r"^U\.S\. Department of Health and Human", "hhs.gov"),
    ("US Census Bureau", r"^U\.S\. Census Bureau", "census.gov"),
    ("HUD", r"^(HUD|U\.S\. Department of Housing)", "huduser.gov; hud.gov"),
    ("USDA (ERS, FNS, AMS, Forest Service)", r"^(USDA|U\.S\. Department of Agriculture)", "usda.gov; fs.usda.gov; landfire.gov"),
    ("DOT / BTS / FHWA / FTA / PHMSA", r"^(U\.S\. Department of Transportation|US DOT)", "dot.gov; bts.gov"),
    ("FEMA", r"^FEMA", "fema.gov"),
    ("DOE / EIA", r"^(U\.?S\.? Energy Information|US Energy Information)", "eia.gov"),
    ("Commerce / NTIA", r"^U\.S\. Department of Commerce", "ntia.gov"),
    ("Treasury / CDFI Fund", r"^U\.S\. Department of the Treasury", "cdfifund.gov"),
    ("FCC", r"^Federal Communications Commission", "fcc.gov"),
    ("VA", r"^U\.S\. Department of Veterans", "va.gov"),
    ("NRC", r"^US Nuclear Regulatory", "nrc.gov"),
    ("NIFC (interagency of federal fire agencies)", r"^National Interagency Fire Center", "nifc.gov"),
]
NOT_FED = [  # listed so the exclusions can be reviewed
    ("PEDP mirrors (EJScreen, CEJST, HIFLD Next)", "Not federal: mirrors by Public Environmental Data Partners; Bronze until PEDP states terms (WG decision 2026-10-28)"),
    ("NASA SEDAC / CIESIN (Columbia University)", "Not federal: university-operated data centre"),
    ("DHS data via DataLumos / Data Rescue Project", "Not federal: archive copy under DataLumos/ICPSR terms"),
    ("NaNDA / ICPSR (University of Michigan)", "Not federal: federally funded, university published"),
    ("Brandeis COI, IHME, NRDC, Eviction Lab", "Not federal: university / non-profit"),
    ("State, county and city .gov (Miami-Dade, NYC, Chicago, States of CA/CT/MD)", "Not federal: state and local government"),
    ("Smithsonian (volcano.si.edu), Oak Ridge National Lab (Daymet), National Water Quality Monitoring Council (waterqualitydata.us)", "Not clearly 17 U.S.C. 105 works (trust instrumentality; contractor-operated lab; multi-party council): left for review"),
    ("NIH-funded but not federal-hosted: ECHO cohort (echochildren.org), HHEAR (hhearprogram.org)", "Not federal: consortium or university run; ECHO also states a DURA"),
]
KEEP_BACK = {  # federal publisher, but the row carries other terms
    "us_nci_seer_research_data": "page states a Data Use Agreement and application for every product",
    "us_nih_allofus_ses_zip3": "listing: restricted access (All of Us controlled data)",
    "us_ncats_n3c": "listing: restricted access (N3C data use agreement)",
    "us_niehs_pegs": "listing: access by request",
    "global_nasa_nex_gddp_cmip6": "listing: 'CMIP6 Terms of Use' on the STAC record; page also shows an NCCS copyright footer",
    "us_eia_national_oil_gas_gateway": "co-published with the Ground Water Protection Council (state agencies); not a pure federal work",
}
fed_re = [(n, re.compile(rx), d) for n, rx, d in FED]


def domain(u):
    return up.urlparse(u).netloc.lower().replace("www.", "")


def is_gov(d):
    return d.endswith(".gov") or d.endswith(".mil") or d in ("catalog.data.gov", "healthdata.gov", "hudgis-hud.opendata.arcgis.com", "data-nifc.opendata.arcgis.com")


RULE_TXT = "US federal work, public domain under 17 U.S.C. 105 (WG rule, 2026-10-28); no other terms stated on the pages read"


def summarise(r):
    app = [c for c in ALL_CHECKS if r.get(c) in VAL]
    r["checks_applicable"] = len(app); r["checks_passed"] = sum(1 for c in app if r[c] == "pass")
    r["checks_warned"] = sum(1 for c in app if r[c] == "warn"); r["checks_failed"] = sum(1 for c in app if r[c] == "fail")
    wsum = sum(WEIGHTS[c] for c in app if c in WEIGHTS)
    r["health_score"] = round(100 * sum(WEIGHTS[c] * VAL[r[c]] for c in app if c in WEIGHTS) / wsum) if wsum else ""
    r["all_passing"] = "TRUE" if app and r["checks_passed"] == len(app) else "FALSE"
    r["verify_blockers"] = ";".join([c[4:] for c in ALL_CHECKS if r.get(c) == "fail"] + [c[4:] + "(warn)" for c in ALL_CHECKS if r.get(c) == "warn"])


def tier_of(r, b_done):
    ll = r["chk_link_live"]
    if r["url_health"] == "blocked":
        t = "Browser needed"
    elif ll == "fail" or r["chk_withdrawn"] == "fail" or r["chk_soft404"] == "fail" or r["chk_recency"] == "fail":
        t = "Failed"
    elif all(r[c] == "pass" for c in ("chk_link_live", "chk_soft404", "chk_withdrawn", "chk_license", "chk_unit", "chk_temporal", "chk_access")) and r["chk_recency"] in ("pass", "warn"):
        t = "Gold"
    elif ll == "pass" and b_done and not any(r[c] == "fail" for c in ("chk_license", "chk_unit", "chk_temporal", "chk_recency")):
        t = "Silver"
    elif ll in ("pass", "warn", "n.a."):
        t = "Bronze"
    else:
        t = "Failed"
    if r.get("browser_tier"):
        t = r["browser_tier"]
    return t


before = {r["id"]: r["verify_tier"] for r in rows}
pre_bdone = {r["id"]: any(r[c] in VAL for c in B_CHECKS) for r in rows}
log = []  # (id, publisher, domain, action, reason)
moved = []
for r in rows:
    org = r["organization"]; dom = domain(r["site_url"])
    hit = next((n for n, rx, d in fed_re if rx.search(org)), None)
    if not hit or r["chk_license"] not in ("fail", "not_checked"):
        continue
    if r["id"] in KEEP_BACK:
        log.append((r["id"], org, dom, "kept back", KEEP_BACK[r["id"]])); continue
    if not is_gov(dom):
        log.append((r["id"], org, dom, "not federal (domain)", f"publisher looks federal but landing domain {dom} is not .gov/.mil")); continue
    if r["license_class"] in ("restricted", "registration", "non-commercial") or re.search(r"data use agreement|DUA|DURA|restricted", r["chk_license_detail"] or "", re.I):
        log.append((r["id"], org, dom, "kept back", "licence detail states other terms: " + (r["chk_license_detail"] or "")[:100])); continue
    read = bool(r["partB_source"] or r["browser_tier"])
    old = r["chk_license"]
    r["chk_license"] = "pass"; r["license_class"] = "public_domain_us_federal"
    r["chk_license_detail"] = RULE_TXT + ("" if read else "; landing page not read for content")
    moved.append(r["id"])
    log.append((r["id"], org, dom, "set pass", f"was {old}; " + ("content page read, no terms found" if read else "page not read (rule applied to the publisher)")))

# ---------------------------------------------------------------- step 2: the working-group targets (page reads of 2026-10-29)
BLANK = {c: "" for c in cols}


def new_row(**kw):
    r = dict(BLANK)
    for c in ALL_CHECKS:
        r[c] = "not_checked"; r[c + "_detail"] = ""
    for c in B_CHECKS:
        r[c + "_evidence"] = ""
    r.update(round="2-wg", url_health="healthy", http_status="200", checked_at=TODAY, last_checked=TODAY, source_of_listing="WG dataset request (gaiaCatalog issue)",
             record_type="dataset", chk_in_gaia="n.a.", chk_in_gaia_detail="not in gaiaCatalog", chk_recipe_health="n.a.", chk_recipe_health_detail="not in gaiaCatalog",
             chk_link_live="pass", chk_link_live_detail=f"page read {TODAY}", chk_soft404="pass", chk_soft404_detail="page has content",
             chk_withdrawn="pass", chk_withdrawn_detail="no withdrawal notice on the page read", partB_source="WG-1.5", partB_blocked="FALSE", confidence="medium", gaia_fit="unknown")
    r.update(kw)
    return r


def chk(r, key, res, detail, ev=""):
    r[key] = res; r[key + "_detail"] = detail
    if key in B_CHECKS:
        r[key + "_evidence"] = ev


EV_MDI = "https://www.census.gov/library/working-papers/2021/demo/SEHSD-WP2021-03.html"
mdi = new_row(id="us_census_mdi", dataset_name="Census Multidimensional Deprivation Index (experimental; SEHSD WP2021-03)", organization="U.S. Census Bureau", theme="socioeconomic",
              site_url=EV_MDI, access_url=EV_MDI, evidence_url=EV_MDI, wg_request="gaiaCatalog#28", health_relevance="2", finest_unit="state",
              geography_units="national; state; demographic groups (as reported in the paper)", coverage="US", temporal="2017 estimates (earlier report 2009-2017)", format="pdf", access_type="open_download")
mdi["notes"] = ("Issue #28 links only this Census working paper (January 2021; page revised October 2021), so the Census MDI is the one meant; the global UNDP/OPHI MPI was not added. "
                "The page offers a PDF only: no data tables or files, and no tract or county estimates. Someone should check whether Census publishes MDI tables elsewhere.")
chk(mdi, "chk_license", "fail", "no licence statement on the page", EV_MDI)
chk(mdi, "chk_temporal", "warn", "2017 data used for comparisons; earlier report covers 2009-2017; year range of new estimates not stated", EV_MDI)
chk(mdi, "chk_recency", "warn", "latest year 2017", EV_MDI)
mdi.update(temporal_confirmed="2017 (earlier report 2009-2017)", latest_year_confirmed="2017", latest_year="2017", finest_unit_confirmed="state", coverage_confirmed="US", formats_confirmed="pdf", partB_pages_read=EV_MDI, partB_notes="paper only; no dataset")
chk(mdi, "chk_unit", "warn", "national, state and demographic-group comparisons in the paper; no small-area data offered", EV_MDI)
chk(mdi, "chk_coverage", "pass", "US", EV_MDI)
chk(mdi, "chk_access", "fail", "only a PDF is offered; no data files", EV_MDI)
chk(mdi, "chk_join_key", "fail", "no data, so no geographic key", EV_MDI)
chk(mdi, "chk_format_gaia", "fail", "PDF only", EV_MDI)
chk(mdi, "chk_version", "warn", "working paper 'Revised and Updated' (released 2021-01-19)", EV_MDI)

EV_CY = "https://www.earthdata.nasa.gov/data/projects/cyan"
cy = new_row(id="global_nasa_cyan", dataset_name="Cyanobacteria Assessment Network (CyAN): Cyanobacteria Index satellite products", organization="NASA", sub_organization="OB.DAAC (with EPA, NOAA, USGS)",
             theme="water", site_url=EV_CY, access_url="https://oceandata.sci.gsfc.nasa.gov/directdataaccess/", evidence_url=EV_CY, wg_request="gaiaCatalog#23", health_relevance="2",
             finest_unit="grid_300m", geography_units="300 m raster tiles (CONUS and Alaska)", coverage="Contiguous US and Alaska (lakes and estuaries)",
             temporal="MERIS 2002-2012; Sentinel-3A OLCI 2016-present; 3B 2018-present", versions="Version 6", format="geotiff", access_type="open_download", gaia_fit="needs_raster")
cy["notes"] = ("Issue #23 asks for NASA OB.DAAC CyAN, version 5, GeoTIFF tiles. The project page now cites Version 6 (6.0). The old oceancolor.gsfc.nasa.gov/about/projects/cyan URL "
               "redirects (301) to the Earthdata page. The page links a 'Data Use and Citation Guidance' page (not read); whether the File Search Tool needs an Earthdata login is not stated.")
chk(cy, "chk_license", "fail", "no licence statement; page links a Data Use and Citation Guidance page (not read)", EV_CY)
chk(cy, "chk_temporal", "pass", "2002-2012 (MERIS), 2016-present (OLCI-A), 2018-present (OLCI-B)", EV_CY)
chk(cy, "chk_recency", "pass", "ongoing (Sentinel-3 OLCI)", EV_CY)
chk(cy, "chk_cadence", "warn", "temporal resolution 'depends on the sensor and date'; daily and 7-day composites", EV_CY)
chk(cy, "chk_version", "pass", "Version 6 (6.0)", EV_CY)
chk(cy, "chk_unit", "pass", "300 m resolution raster tiles", EV_CY)
chk(cy, "chk_coverage", "pass", "contiguous US and Alaska", EV_CY)
chk(cy, "chk_access", "warn", "CyAN File Search Tool at oceandata.sci.gsfc.nasa.gov; login requirement not stated", EV_CY)
chk(cy, "chk_join_key", "warn", "raster tiles by column/row; shapefiles of CONUS tiles and lakes offered; no attribute key", EV_CY)
chk(cy, "chk_format_gaia", "pass", "GeoTIFF dailies and 7-day composites; DN-coded values", EV_CY)
cy.update(temporal_confirmed="2002-2012; 2016-present", latest_year_confirmed="2026", latest_year="2026", update_cadence_confirmed="daily and 7-day composites", version_confirmed="Version 6 (6.0)",
          finest_unit_confirmed="grid_300m", coverage_confirmed="CONUS and Alaska", access_confirmed="open_download (tool; login not stated)", join_key_confirmed="geometry (raster; tile and lake shapefiles)",
          formats_confirmed="geotiff; shp (tiles, lakes)", partB_pages_read=EV_CY)

EV_DV = "https://diva-gis.org/data.html"
dv = new_row(id="global_diva_gis", dataset_name="DIVA-GIS country-level spatial data (administrative areas, water, roads, elevation, land cover, population, climate)", organization="DIVA-GIS",
             theme="boundaries", site_url=EV_DV, access_url=EV_DV, evidence_url=EV_DV, wg_request="gaiaCatalog#31", health_relevance="1", finest_unit="admin2",
             geography_units="administrative areas (levels vary by country); grids at 30 arc-seconds", coverage="any country", temporal="not stated (population 2000; 'old')",
             format="shp; gridfile; geotiff; dbf", access_type="open_download", gaia_fit="now")
dv["notes"] = ("Issue #31 asks for country- and global-level geometry to support the SDG database (#34). The www.diva-gis.org host did not resolve; diva-gis.org/data.html loads. "
               "Administrative areas come from GADM (see global_gadm_boundaries). Boundaries are now the separate place-identifiers backlog (backlog-place-identifiers-2026-10-28.md); "
               "the DIVA-GIS pages are dated ('old', 'very old now'), and GADM and geoBoundaries rows already cover the need.")
chk(dv, "chk_license", "fail", "no licence or terms on the page; names source providers only (administrative areas: GADM)", EV_DV)
chk(dv, "chk_temporal", "not_checked", "no vintage stated; population described as 'old', gazetteer 'very old now'", EV_DV)
chk(dv, "chk_unit", "warn", "'The level of subdivisions that is available varies between countries'", EV_DV)
chk(dv, "chk_coverage", "pass", "any country in the world, chosen from a drop-down", EV_DV)
chk(dv, "chk_access", "pass", "choose country, subject and format; ZIP delivered", EV_DV)
chk(dv, "chk_join_key", "pass", "vector data are ESRI shapefiles", EV_DV)
chk(dv, "chk_format_gaia", "pass", "ESRI shapefiles; GeoTIFF; DBF gazetteer", EV_DV)
dv.update(finest_unit_confirmed="admin (varies by country)", coverage_confirmed="global (country by country)", access_confirmed="open_download", join_key_confirmed="geometry (shapefile)",
          formats_confirmed="shp; geotiff; dbf", partB_pages_read=EV_DV)

EV_AQ = "https://aqs.epa.gov/aqsweb/airdata/download_files.html"
aq = new_row(id="us_epa_aqs_sites_monitors", dataset_name="EPA AirData: AQS site listing (aqs_sites.zip) and monitor listing (aqs_monitors.zip)", organization="US EPA",
             sub_organization="Air Quality System (AQS)", theme="air quality", site_url=EV_AQ, access_url="https://aqs.epa.gov/aqsweb/airdata/aqs_sites.zip", evidence_url=EV_AQ,
             wg_request="gaiaCatalog#32", health_relevance="3", finest_unit="point", geography_units="monitoring sites (points)", coverage="US",
             temporal="current listing (updated twice a year)", format="csv (zipped)", access_type="open_download", gaia_fit="now")
aq["notes"] = ("Issue #32: aqs_sites.zip is the geom_dependency for all EPA daily sources. The page lists aqs_sites.zip (20,994 rows) and aqs_monitors.zip (370,090 rows) under 'Site and Monitor Descriptions'. "
               "The columns (state/county/site code, latitude, longitude) are not listed on the page, so unit and join key are warn; open one file to confirm.")
chk(aq, "chk_license", "fail", "no licence or terms on the page", EV_AQ)
chk(aq, "chk_temporal", "not_checked", "single current files; page gives no year range", EV_AQ)
chk(aq, "chk_cadence", "pass", "'EPA will update these files twice per year; in the spring and fall (late May and November)'", EV_AQ)
chk(aq, "chk_unit", "warn", "site listing implies point locations; coordinate columns not shown on the page", EV_AQ)
chk(aq, "chk_coverage", "warn", "US monitoring network implied; not stated on the page", EV_AQ)
chk(aq, "chk_access", "pass", "direct zip download; API also available", EV_AQ)
chk(aq, "chk_join_key", "warn", "columns not listed on the page; site identifiers implied by 'Site Listing'", EV_AQ)
chk(aq, "chk_format_gaia", "pass", "'comma separated text with a header' (zipped)", EV_AQ)
aq.update(update_cadence_confirmed="twice a year", finest_unit_confirmed="point", access_confirmed="open_download", formats_confirmed="csv (zip)", partB_pages_read=EV_AQ)

EV_UC = "https://www.epa.gov/dwucmr/occurrence-data-unregulated-contaminant-monitoring-rule"
uc = new_row(id="us_epa_ucmr3_occurrence", dataset_name="EPA UCMR 3 (2013-2015) occurrence data", organization="US EPA", sub_organization="Unregulated Contaminant Monitoring Rule", theme="water",
             site_url=EV_UC, access_url=EV_UC, evidence_url=EV_UC, wg_request="gaiaCatalog#38", health_relevance="3", finest_unit="pws",
             geography_units="public water system (PWS ID); ZIP codes per issue #38", coverage="US public water systems", temporal="2013-2015", versions="UCMR 3",
             format="txt (zip); by state; by method classification", access_type="open_download", gaia_fit="needs_aggregation")
uc["notes"] = ("UCMR 3 is its own downloadable dataset on the page: text files (zip), by state (zip), by method classification (zip). Issue #38 (kzollove comment) says the zip holds UCMR3_All.txt plus "
               "UCMR3_ZipCodes.txt, which must be merged; the page does not mention ZIP codes (that claim is from the issue, not verified here). Other cycles on the same page: UCMR 1 (2001-2005), "
               "2 (2008-2010), 4 (2018-2020), 5 (2023-2025; final dataset released August 2026); see the generic row us_epa_ucmr.")
chk(uc, "chk_license", "fail", "no licence or terms on the page", EV_UC)
chk(uc, "chk_temporal", "pass", "UCMR 3 (2013-2015)", EV_UC)
chk(uc, "chk_recency", "warn", "latest year 2015", EV_UC)
chk(uc, "chk_cadence", "warn", "cycle complete; UCMR repeats in cycles; page last updated 2026-10-15", EV_UC)
chk(uc, "chk_unit", "warn", "records tied to public water systems (PWS ID); no standard geography confirmed on the page", EV_UC)
chk(uc, "chk_access", "pass", "zip downloads, no sign-in", EV_UC)
chk(uc, "chk_join_key", "warn", "PWS ID on the page; ZIP codes only per issue #38", EV_UC)
chk(uc, "chk_format_gaia", "warn", "zipped text files; spatial key only via the separate ZIP-code file", EV_UC)
uc.update(temporal_confirmed="2013-2015", latest_year_confirmed="2015", latest_year="2015", update_cadence_confirmed="one cycle, complete", finest_unit_confirmed="pws (water system)",
          access_confirmed="open_download", join_key_confirmed="PWS ID (ZIP code file per issue #38)", formats_confirmed="txt (zip)", partB_pages_read=EV_UC)

EV_DHS = "https://spatialdata.dhsprogram.com/home/"
dh = new_row(id="global_dhs_spatial_data_repository", dataset_name="DHS Program Spatial Data Repository (sub-national indicator estimates and boundaries)", organization="The DHS Program (ICF)",
             theme="health surveys", site_url=EV_DHS, access_url=EV_DHS, wg_request="gaiaCatalog#34", health_relevance="3", finest_unit="admin1", access_type="registration",
             url_health="blocked", http_status="403", partB_blocked="TRUE", confidence="low", chk_link_live="warn", chk_link_live_detail="HTTP 403 to a script",
             chk_soft404="not_checked", chk_soft404_detail="", chk_withdrawn="not_checked", chk_withdrawn_detail="")
dh["notes"] = ("Candidate sub-national source for SDG health indicators (issue #34). Added by name from the request context only; the page returned 403 and nothing about it is confirmed. "
               "A person should open it. Browser needed.")
dh["partB_notes"] = "403; no facts read"


def note(r, t):
    r["notes"] = ((r["notes"].rstrip("; ") + "; ") if r["notes"] else "") + t


for i, wg in {"us_census_acs_5year": "gaiaCatalog#37", "us_ahrq_sdoh_database": "gaiaCatalog#36", "us_brandeis_coi": "gaiaCatalog#30", "global_cred_emdat": "gaiaCatalog#27",
              "eu_eea_air_quality_ereporting": "gaiaCatalog#41", "us_cdc_eji": "gaiaCatalog#29", "us_epa_tri": "gaiaCatalog#35", "us_epa_aqs_data_mart_api": "gaiaCatalog#32",
              "us_epa_ucmr": "gaiaCatalog#38", "global_un_sdg_global_database": "gaiaCatalog#34", "global_gdl_shdi": "gaiaCatalog#34"}.items():
    by_id[i]["wg_request"] = wg
note(by_id["us_cdc_eji"], "2026-10-29 read (issue #29): landing page confirms census-tract EJI, 36 factors, three modules (https://www.atsdr.cdc.gov/place-health/php/eji/index.html); "
     "the data-download page rendered with no links, so years, formats and the 2022-vs-2024 vintage are not confirmed; issue #29 pointed at the 2022 files on eji.cdc.gov")
note(by_id["us_epa_tri"], "2026-10-29 read (issue #35): page confirms 1987-present, latest 2024 (files as of 2025-11-05), csv with latitude/longitude, year and state/US/Fed/Tribal selectors; "
     "no licence, no stated cadence (https://www.epa.gov/toxics-release-inventory-tri-program/tri-basic-data-files-calendar-years-1987-present)")
note(by_id["us_epa_aqs_data_mart_api"], "generic API row; the monitoring-sites listing is its own row us_epa_aqs_sites_monitors (issue #32)")
note(by_id["us_epa_ucmr"], "generic row; UCMR 3 (2013-2015) is its own row us_epa_ucmr3_occurrence (issue #38). 2026-10-29 read: the page lists cycles 1-5 as zip text files, last updated 2026-10-15 ("
     "https://www.epa.gov/dwucmr/occurrence-data-unregulated-contaminant-monitoring-rule)")
note(by_id["global_un_sdg_global_database"], "2026-10-29: https://unstats.un.org/sdgs/dataportal returned only the title 'UNSDG' (JavaScript app), so it stays Browser needed. Issue #34 mentions the SDG API "
     "(https://unstats.un.org/SDGAPI/swagger/) and small-area estimates. Sub-national candidates: global_gdl_shdi, global_dhs_spatial_data_repository")
g = by_id["global_gdl_shdi"]
EV_G = "https://globaldatalab.org/termsofuse/"
chk(g, "chk_license", "warn", "own terms: indicators 'freely downloaded and used for noncommercial purposes'; credit GDL and the version; commercial use needs written permission", EV_G)
g.update(license_confirmed="GDL terms of use: non-commercial, attribution required", license_class="non-commercial", access_confirmed="registration", formats_confirmed="csv; xlsx")
chk(g, "chk_access", "warn", "free registration with GDL required for downloads; Excel or CSV (https://globaldatalab.org/shdi/)", "https://globaldatalab.org/shdi/")
note(g, "2026-10-29 read (issue #34): coverage, years, version and join key not stated on the SHDI landing or about pages; shapefile not mentioned (https://globaldatalab.org/shdi/about/)")

new_rows = [mdi, cy, dv, aq, uc, dh]
new_ids = {n["id"] for n in new_rows}
for r in new_rows:
    by_id[r["id"]] = r; pre_bdone[r["id"]] = any(r[c] in VAL for c in B_CHECKS); before[r["id"]] = ""
    r["latest_year_final"] = r.get("latest_year_confirmed") or r.get("latest_year") or ""
rows += new_rows

# the rule applies to the new federal rows too (pages read, no terms stated)
for r in new_rows:
    if r["id"] in ("us_census_mdi", "global_nasa_cyan", "us_epa_aqs_sites_monitors", "us_epa_ucmr3_occurrence"):
        r["chk_license"] = "pass"; r["license_class"] = "public_domain_us_federal"; r["chk_license_detail"] = RULE_TXT; moved.append(r["id"])
        log.append((r["id"], r["organization"], domain(r["site_url"]), "set pass", "new WG row; page read, no terms stated"))
    elif r["id"] == "global_diva_gis":
        log.append((r["id"], r["organization"], domain(r["site_url"]), "not federal", "DIVA-GIS is not a US federal publisher; licence stays fail (nothing stated)"))

# ---------------------------------------------------------------- re-tier
BRONZE_CAP = {"us_census_mdi": "paper only: no data files (access and format fail), so capped at Bronze by hand"}
for r in rows:
    if not (r["id"] in moved or r["id"] in new_ids or r["id"] == "global_gdl_shdi"):
        continue
    summarise(r)
    acc = (r.get("access_confirmed") or r.get("access_type") or "").lower()
    r["public_access"] = "open" if acc.startswith(("open_download", "api")) else "registration" if acc in ("registration", "api_key") else "restricted" if acc in ("request", "restricted") else "unknown"
    t = tier_of(r, pre_bdone[r["id"]])
    if r["id"] in BRONZE_CAP and t in ("Gold", "Silver"):
        t = "Bronze"; note(r, BRONZE_CAP[r["id"]])
    r["verify_tier"] = t
    r["verified_on"] = TODAY if (r["id"] in new_ids or r["id"] == "global_gdl_shdi") else max(r.get("verified_on", ""), TODAY)


def wcsv(p, data, c):
    with open(p, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=c, extrasaction="ignore"); w.writeheader()
        for r in data:
            w.writerow({k: r.get(k, "") for k in c})


assert len(rows) == len({r["id"] for r in rows}) == 601, len(rows)
wcsv(f"{D}/{OUT}", rows, cols)
fp = [dict(publisher=n, domains=d, rule="federal agency; the rule applies (US government works, 17 U.S.C. 105) when the pages state no other terms") for n, rx, d in FED] + \
     [dict(publisher=n, domains="", rule=w) for n, w in NOT_FED]
wcsv(f"{D}/federal-publishers-2026-10-29.csv", fp, ["publisher", "domains", "rule"])
wcsv(f"{D}/federal-rule-rows-2026-10-29.csv",
     [dict(id=a, organization=b, domain=c, action=d, reason=e, tier_before=before.get(a, ""), tier_after=by_id[a]["verify_tier"]) for a, b, c, d, e in log],
     ["id", "organization", "domain", "action", "reason", "tier_before", "tier_after"])

INV_COLS = ["id", "title", "publisher", "domain", "landing_url", "access", "geography", "coverage", "temporal", "format", "license", "update_cadence", "in_gaia", "recipe_health", "last_checked", "evidence", "notes"]
prom = []
for r in rows:
    if r["verify_tier"] in ("Gold", "Silver") and r["round"] != "2-pilot":
        ev = "; ".join(OrderedDict.fromkeys(x for x in [r.get("chk_license_evidence"), r.get("chk_temporal_evidence"), r.get("chk_unit_evidence"), r.get("evidence_url")] if x))
        prom.append({"id": r["id"], "title": r["dataset_name"], "publisher": r["organization"], "domain": r["theme"], "landing_url": r["site_url"], "access": r.get("access_confirmed") or r["access_type"],
                     "geography": r.get("finest_unit_confirmed") or r["geography_units"] or r["finest_unit"], "coverage": r.get("coverage_confirmed") or r["coverage"],
                     "temporal": r.get("temporal_confirmed") or r["temporal"], "format": r.get("formats_confirmed") or r["format"], "license": r.get("license_confirmed") or r["license"],
                     "update_cadence": r.get("update_cadence_confirmed") or r["update_cadence"], "in_gaia": r["in_gaia"], "recipe_health": r["recipe_health"], "last_checked": r["verified_on"],
                     "evidence": ev, "notes": f"verify_tier {r['verify_tier']}; health_score {r['health_score']}; " + (f"mirror of {r['mirror_of']}; " if r["mirror_of"] else "") + (r["notes"] or "")[:300]})
wcsv(f"{D}/inventory.csv", prom, INV_COLS)

T = ["Gold", "Silver", "Bronze", "Browser needed", "Failed"]
r1 = [r for r in rows if r["round"] == "1"]
b = Counter(before[r["id"]] for r in r1); a = Counter(r["verify_tier"] for r in r1)
print("round 1 before", {t: b[t] for t in T}, "after", {t: a[t] for t in T})
print("all rows after", {t: Counter(r["verify_tier"] for r in rows)[t] for t in T}, len(rows))
print("log", dict(Counter(x[3] for x in log)), "moved", len(moved))
print(Counter((before[x], by_id[x]["verify_tier"]) for x in moved if before.get(x)))
print("new:", [(n["id"], n["verify_tier"]) for n in new_rows]); print("inventory.csv rows", len(prom))
