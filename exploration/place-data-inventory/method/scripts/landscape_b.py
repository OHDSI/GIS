"""PROMPT 2 phase B: merge the DataCite quiver and the phase E sample into landscape/candidates-<date>.csv and triage by rules. No web.
python scripts/landscape_b.py   (from docs/discovery)"""
import csv, re, os, random, collections, html

D = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
T = "2026-10-29"
rd = lambda p: list(csv.DictReader(open(f"{D}/{p}", encoding="utf-8")))
anchors = {a["anchor_id"]: a for a in rd("landscape/anchors.csv")}
inv = rd("inventory-combined-2026-10-29-geo.csv")
inv_doi = {re.sub(r"^(https?://(dx\.)?doi\.org/|doi:)", "", (x["persistent_id"] or "").lower()): x["id"] for x in inv if x["persistent_id"]}

STOP = [  # (reason, regex on title)
    ("species or plant census", r"\b(species|plant community|vegetation plots?|forest inventory|tree census|stomatal|microb|fish communit|bird|mistletoe|biodiversity|flora|seedling|pollinat|frog|petrel|penguin|albatross|wildlife)"),
    ("marine heatwave or ocean", r"marine heat ?wave|sea surface temperature anomal|coral bleaching"),
    ("greenhouse-gas emission factors", r"emission factors?|greenhouse gas inventory|carbon footprint|life cycle assessment"),
    ("quantum or acoustic noise", r"quantum|acoustic|noise[- ]induced|shot noise|phonon"),
    ("paleoclimate or model output", r"\bBP\b.*TIME-RANGE|ECHAM|palaeo|paleo|ice core|snow accumulation|holocene|last glacial"),
    ("cell or molecular biology", r"methylation|ovarian cancer|single[- ]cell|proteom|genom|transcriptom|neural|fmri|\bmri\b|synap|neuron"),
    ("clinical or restricted survey (v1.1)", r"marine air temperature|clinical data|posttraumatic|restricted release"),
    ("planetary science", r"OSIRIS|mars\b|lunar|asteroid"),
]
STOP_PUB = [("archaeology data series", r"edition topoi")]
SUPP = r"^(additional file \d+|supplementary (file|table|material)|supplement \d+|figure \d+|table s?\d+|data from:)"
EVENT = r"\b(hurricane|typhoon|cyclone|earthquake|tsunami|wildfire of|bushfire of|flood of)\b.*\b(19|20)\d\d\b|\b(19|20)\d\d (hurricane|earthquake|bushfires?|black summer)\b"

UNIT = r"tract|block group|census|count(y|ies)|zip|zcta|postcode|postal|lsoa|msoa|municipal|district|nationwide|national|global|gridded|\bgrid\b|\b\d+ ?km\b|\bcity\b|cities|region|sub-?national|small[- ]area|neighbou?rhood|\bLGA\b|\bSA[1-4]\b|\bstate(s|-level)?\b|province|prefecture|by hospital|facilit|spatial|geocoded|map(s|ped|ping)?\b|travel time|accessibility|\bgis\b"
GEO = r"united states|\bU\.?S\.?A?\b|america|australia|china|india|africa|europe|\bEU\b|\bUK\b|england|britain|scotland|wales|canada|brazil|mexico|kenya|nigeria|uganda|tanzania|germany|france|italy|spain|japan|new zealand|texas|california|florida|new york|chicago|london|pennsylvania|queensland|victoria|tasmania|sydney|melbourne|global|world"
TERMS = {  # anchor-term test on the title (query terms plus close variants)
    "care_sites": r"hospital|clinic|health facilit|health service|radiotherap|radiation oncology|cancer cent|oncology|dialysis|pharmac|travel time to|distance to|access to (care|health)|emergency department|primary care|aged care",
    "deprivation_indices": r"deprivation|social vulnerability|\bSVI\b|opportunity index|environmental justice|\bEJI\b|\bADI\b|\bSEIFA\b|disadvantage|index of multiple",
    "census_ses": r"census|american community survey|\bACS\b|income|poverty|education|housing|socioeconomic|socio-economic|small area|household",
    "heat": r"heat|temperature|wet bulb|heatwave|heat wave|urban heat",
    "water_hazards_fire": r"precipitation|rainfall|drought|\bSPEI\b|flood|wildfire|bushfire|burned area|burnt area|fire (history|perimeter|severity)",
    "health_policy": r"state law|policy surveillance|prescription drug monitoring|opioid|medicaid|abortion|tobacco|alcohol (policy|law)|legislation|laws? (and|on)|policy (data|database|surveillance)",
    "air_pollution": r"PM ?2\.?5|particulate|ozone|nitrogen dioxide|\bNO2\b|air quality|air pollution",
    "subnational_development": r"human development|\bDHS\b|demographic and health|poverty map|SDG|sub-?national|mortality",
    "toxic_releases": r"toxic|release inventory|industrial emission|E-PRTR|pollutant release",
    "drinking_water": r"drinking water|\bUCMR\b|lead service|PFAS|water quality|contaminant",
    "algal_blooms": r"algal|cyanobacteri|\bCyAN\b|chlorophyll|water quality",
    "built_environment": r"food (access|desert)|green ?space|NDVI|tree canopy|walkab|noise|eviction|housing quality|land cover|impervious|urban",
}
REGION = [("Australia", r"australia|queensland|victoria\b|tasmania|sydney|melbourne|new south wales|\bNSW\b|\bACT\b|adelaide|perth|brisbane"), ("UK", r"\bUK\b|united kingdom|england|britain|scotland|wales|lsoa|msoa|london"),
          ("Canada", r"canada|ontario|quebec|alberta|british columbia"), ("US", r"united states|\bU\.?S\.?A?\b|america|county|counties|census tract|zip|texas|california|florida|new york|chicago|pennsylvania|\bstates?\b"),
          ("EU", r"europe|\bEU\b|germany|france|italy|spain|netherlands|sweden|poland|nuts"), ("Africa", r"africa|kenya|nigeria|uganda|tanzania|ghana|ethiopia|malawi"),
          ("Asia", r"china|india|japan|korea|vietnam|thailand|asia|bangladesh|indonesia|nepal"), ("Latin America", r"brazil|mexico|colombia|peru|chile|argentina|latin america"), ("global", r"global|world")]


def norm_doi(d):
    return re.sub(r"^(https?://(dx\.)?doi\.org/|doi:)", "", (d or "").strip().lower())


def ntitle(t):
    return re.sub(r"[^a-z0-9 ]", "", html.unescape(t or "").lower()).strip()


cands = collections.OrderedDict()
skipped = []


def add(src, d):
    key = norm_doi(d.get("doi")) or (ntitle(d["title"]) + "|" + ntitle(d.get("publisher", "")))
    if key in cands:
        c = cands[key]
        c["source_collection"] = "; ".join(sorted(set(c["source_collection"].split("; ")) | {src}))
        c["anchors"] = "; ".join(sorted(set(c["anchors"].split("; ")) | {d["anchor"]}))
        c["in_inventory"] = c["in_inventory"] or d.get("in_inventory", "")
        c["citations"] = max(int(c["citations"] or 0), int(d.get("citations") or 0))
        return
    cands[key] = dict(source_collection=src, doi=norm_doi(d.get("doi")), title=html.unescape(d["title"]), publisher=d.get("publisher", ""), year=d.get("year", ""), anchors=d["anchor"],
                      region="", place_unit_in_title="", paper_supplement=d.get("paper_supplement", ""), citations=int(d.get("citations") or 0), in_inventory=d.get("in_inventory", ""),
                      has_geolocation=d.get("has_geolocation", ""), australia_in_title=d.get("australia_in_title", ""), url=d.get("url", ""), e_rank=d.get("rank", ""), e_variable_place_keys=d.get("variable_place_keys", ""))


for d in rd("quiver/datacite-pilot-2026-10-29.csv"):
    add("DataCite pilot", d)
for d in rd("quiver/datacite-australia-2026-10-29.csv"):
    if d["australia_in_title"] == "Y":
        add("DataCite Australia", d)
    else:
        skipped.append(dict(doi=d["doi"], title=d["title"], publisher=d["publisher"], year=d["year"], anchor=d["anchor"], reason="australia_in_title is not Y"))
for d in rd("landscape/spike-e-2026-10-29.csv"):
    d2 = dict(d, anchor=d["anchor"], in_inventory="Y" if d["match_inventory"] and "possible" not in d["match_kind"] else "")
    add("spike E: " + d["collection"], d2)

stop_rows = []
for c in cands.values():
    t = c["title"]; a0 = c["anchors"].split("; ")
    c["in_inventory"] = c["in_inventory"] or ("Y" if c["doi"] in inv_doi else "")
    c["paper_supplement"] = c["paper_supplement"] or ("Y" if re.search(SUPP, t, re.I) else "")
    c["place_unit_in_title"] = "Y" if re.search(UNIT, t, re.I) else ""
    geo = bool(re.search(GEO, t, re.I))
    c["region"] = next((r for r, p in REGION if (r == "Australia" and (c["australia_in_title"] == "Y" or re.search(p, t, re.I))) or (r != "Australia" and re.search(p, t, re.I))), "unspecified")
    anchor_term = any(re.search(TERMS[a], t, re.I) for a in a0 if a in TERMS)
    try:
        yr = int(c["year"])
    except ValueError:
        yr = 0
    stop = next((r for r, p in STOP if re.search(p, t, re.I)), None) or next((r for r, p in STOP_PUB if re.search(p, c["publisher"], re.I)), None)
    event = bool(re.search(EVENT, t, re.I))
    c.update(anchor_term_in_title="Y" if anchor_term else "", geography_word_in_title="Y" if geo else "", stoplist=stop or "")
    if stop:
        tri = "unlikely"; why = "stop-list: " + stop
    elif yr and yr < 2000:
        tri = "unlikely"; why = "year before 2000"
    elif event:
        tri = "unlikely"; why = "single event"
    elif anchor_term and (c["place_unit_in_title"] or geo) and c["paper_supplement"] != "Y":
        tri = "likely_relevant"; why = "anchor term + place unit/geography word, not a supplement"
    elif (anchor_term or c["place_unit_in_title"]) and c["paper_supplement"] != "Y":
        tri = "maybe"; why = "anchor term or place unit only"
    else:
        tri = "unlikely"; why = "supplement" if c["paper_supplement"] == "Y" else "no anchor term or place unit"
    c["triage"] = tri; c["triage_reason"] = why
    if stop:
        stop_rows.append((c["title"][:90], stop))

cols = ["source_collection", "doi", "title", "publisher", "year", "anchors", "region", "place_unit_in_title", "anchor_term_in_title", "geography_word_in_title", "paper_supplement", "citations",
        "in_inventory", "has_geolocation", "triage", "triage_reason", "stoplist", "url", "e_rank", "e_variable_place_keys"]


def w(p, rows, c):
    with open(f"{D}/{p}", "w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=c, extrasaction="ignore"); wr.writeheader(); wr.writerows(rows)


L = list(cands.values())
w(f"landscape/candidates-{T}.csv", L, cols)
w(f"landscape/candidates-skipped-{T}.csv", skipped, ["doi", "title", "publisher", "year", "anchor", "reason"])
w("landscape/stoplist-2026-10-29.csv", [dict(reason=r, pattern=p) for r, p in STOP] + [dict(reason="publisher: " + r, pattern=p) for r, p in STOP_PUB], ["reason", "pattern"])
random.seed(11)
lr = [c for c in L if c["triage"] == "likely_relevant"]
smp = random.sample(lr, min(100, len(lr)))
if not os.path.exists(f"{D}/landscape/candidates-precision-sample-{T}.csv"): w(f"landscape/candidates-precision-sample-{T}.csv", [dict(c, my_label="") for c in smp], ["doi", "title", "publisher", "year", "anchors", "my_label"])
print("input rows: pilot 1006 + australia 1903 (Y kept: %d, skipped %d) + E 90" % (sum(1 for d in rd("quiver/datacite-australia-2026-10-29.csv") if d["australia_in_title"] == "Y"), len(skipped)))
print("unique candidates", len(L)); print(collections.Counter(c["triage"] for c in L)); print("stoplisted", len(stop_rows), collections.Counter(r for _, r in stop_rows))
print("in_inventory", sum(1 for c in L if c["in_inventory"] == "Y"))
print(collections.Counter(c["region"] for c in lr)); print(collections.Counter(a for c in lr for a in c["anchors"].split("; ")))
