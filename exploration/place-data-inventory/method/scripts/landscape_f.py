"""PROMPT 2 phase F: metadata enrichment of the 275 Gold+Silver rows (DataCite, data.gov, data.europa.eu) and citation signal for up to 200
likely_relevant candidates with DOIs (DataCite citationCount, OpenAIRE ScholeXplorer links). python scripts/landscape_f.py (from docs/discovery)"""
import csv, re, sys, os, math, difflib, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from landscape_lib import *
T = "2026-10-29"
inv = {x["id"]: x for x in csv.DictReader(open(f"{D}/inventory-combined-2026-10-29-fv.csv", encoding="utf-8"))}
gs = list(csv.DictReader(open(f"{D}/inventory.csv", encoding="utf-8")))
state = ckpt("F-enrich") or {}


def nt(t):
    return re.sub(r"[^a-z0-9 ]", "", (t if isinstance(t, str) else "").lower()).strip()


def sim(a, b):
    return difflib.SequenceMatcher(None, nt(a), nt(b)).ratio()


def first(v):
    if isinstance(v, dict):
        return v.get("en") or next(iter(v.values()), "")
    return v or ""


def years(s):
    return sorted({int(y) for y in re.findall(r"(?:19|20)\d\d", s or "")})


def lic_tok(s):
    s = (s or "").lower()
    for k, p in [("cc0", r"cc0|publicdomain/zero|zero v1"), ("cc-by", r"cc[- ]by|creative commons attribution"), ("public domain", r"public domain|publicdomain|us government work"), ("odbl", r"odbl|open database"),
                 ("ogl", r"open government licen|\bogl\b"), ("open", r"openaccess|open access|open data")]:
        if re.search(p, s):
            return k
    return ""


def jget(url, params=None):
    r, e = get(url, params)
    if r is None or r.status_code != 200:
        return None
    try:
        return r.json()
    except Exception:
        return None


rows = []
for g in gs:
    rid = g["id"]
    if rid in state:
        rows.append(state[rid]); continue
    x = inv[rid]; title = x["dataset_name"]; url = g["landing_url"]
    o = dict(id=rid, title=title, tier=x["verify_tier"], dc_match="", dc_doi="", dc_license="", dc_years="", dc_spatial="", gov_match="", gov_license="", gov_years="", gov_spatial="",
             eu_match="", eu_license="", eu_years="", eu_spatial="")
    # DataCite: DOI first, then URL, then title
    doi = re.sub(r"^(https?://(dx\.)?doi\.org/|doi:)", "", x["persistent_id"] or "")
    d = None; how = ""
    if doi:
        j = jget("https://api.datacite.org/dois/" + doi)
        if j:
            d, how = j["data"]["attributes"], "doi"
    if not d and url:
        j = jget("https://api.datacite.org/dois", {"query": 'url:"%s"' % url, "page[size]": 1})
        if j and j["data"]:
            d, how = j["data"][0]["attributes"], "url"
    if not d:
        j = jget("https://api.datacite.org/dois", {"query": 'titles.title:"%s"' % title.replace('"', ""), "page[size]": 3})
        for c in (j or {}).get("data", []):
            if sim(c["attributes"]["titles"][0]["title"], title) >= 0.9:
                d, how = c["attributes"], "title"; break
    if d:
        o["dc_match"] = how; o["dc_doi"] = d.get("doi", "")
        o["dc_license"] = "; ".join(filter(None, [(r.get("rightsIdentifier") or r.get("rights") or r.get("rightsUri") or "") for r in d.get("rightsList", [])]))
        o["dc_years"] = "; ".join(str(y) for y in years(" ".join(str(dd.get("date", "")) for dd in d.get("dates", []))) + [d.get("publicationYear")] if y)
        o["dc_spatial"] = "; ".join(str(g2.get("geoLocationPlace") or "box/point") for g2 in d.get("geoLocations", []))[:150]
    # data.gov
    j = jget("https://catalog.data.gov/search", {"q": '"%s"' % title.replace('"', ""), "per_page": 3})
    for c in (j or {}).get("results", []):
        dc = c.get("dcat", {}); lp = dc.get("landingPage") or ""
        if sim(c.get("title") or dc.get("title"), title) >= 0.9 or (isinstance(lp, str) and url and lp.rstrip("/") == url.rstrip("/")):
            o["gov_match"] = c.get("slug", "") or "yes"
            o["gov_license"] = str(dc.get("license", ""))[:120]
            o["gov_years"] = "; ".join(map(str, years(str(dc.get("temporal", "")) + " " + str(dc.get("issued", "")) + " " + str(dc.get("modified", "")))))
            o["gov_spatial"] = str(dc.get("spatial", ""))[:150]
            break
    # data.europa.eu
    j = jget("https://data.europa.eu/api/hub/search/search", {"q": '"%s"' % title.replace('"', ""), "limit": 3, "filter": "dataset"})
    for c in (j or {}).get("result", {}).get("results", []):
        if sim(first(c.get("title")), title) >= 0.9:
            o["eu_match"] = c.get("id", "")
            lic = [first((dist.get("license") or {}).get("resource", "") if isinstance(dist.get("license"), dict) else dist.get("license", "")) for dist in (c.get("distributions") or [])]
            o["eu_license"] = "; ".join(sorted({str(l) for l in lic if l}))[:150]
            o["eu_years"] = "; ".join(map(str, years(str(c.get("issued", "")) + " " + str(c.get("modified", "")))))
            o["eu_spatial"] = str(c.get("spatial", ""))[:100]
            break
    state[rid] = o; rows.append(o); ckpt("F-enrich", state)
print("enrich done", len(rows), flush=True)

# agreement with part B
pb = {"license": [0, 0, 0, 0], "temporal": [0, 0, 0, 0], "spatial": [0, 0, 0, 0]}  # agree, disagree, partb_only/meta_only, both_missing  (see below)
out = []
for o in rows:
    x = inv[o["id"]]
    meta_lic = " ".join([o["dc_license"], o["gov_license"], o["eu_license"]]).strip()
    partb_lic = " ".join([x["license_confirmed"], x["license_class"]]).strip()
    o["any_match"] = "Y" if (o["dc_match"] or o["gov_match"] or o["eu_match"]) else ""
    a, b = lic_tok(meta_lic), lic_tok(partb_lic)
    o["license_agree"] = "n/a (no match)" if not o["any_match"] else ("both empty" if not meta_lic and not partb_lic else "metadata empty" if not meta_lic else "part B empty" if not partb_lic else ("agree" if a and a == b else "differ" if a and b else "cannot compare"))
    my = sorted({int(y) for y in re.findall(r"\d{4}", " ".join([o["dc_years"], o["gov_years"], o["eu_years"]]))})
    by = years(x["temporal_confirmed"] or x["temporal"])
    o["temporal_agree"] = "n/a (no match)" if not o["any_match"] else ("metadata empty" if not my else "part B empty" if not by else ("agree" if my and by and max(my) >= min(by) - 1 and min(my) <= max(by) + 1 else "differ"))
    msp = " ".join([o["dc_spatial"], o["gov_spatial"], o["eu_spatial"]]).strip()
    o["spatial_agree"] = "n/a (no match)" if not o["any_match"] else ("metadata empty" if not msp else "metadata has a spatial field (part B coverage: %s)" % (x["coverage_confirmed"] or x["coverage"])[:30])
    o["partb_license"] = partb_lic[:80]; o["partb_temporal"] = (x["temporal_confirmed"] or x["temporal"])[:60]
    out.append(o)
cols = ["id", "title", "tier", "any_match", "dc_match", "dc_doi", "gov_match", "eu_match", "dc_license", "gov_license", "eu_license", "partb_license", "license_agree", "dc_years", "gov_years", "eu_years",
        "partb_temporal", "temporal_agree", "dc_spatial", "gov_spatial", "eu_spatial", "spatial_agree"]
with open(f"{D}/landscape/enrichment-275-{T}.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore"); w.writeheader(); w.writerows(out)
import collections
print("any match", sum(1 for o in out if o["any_match"]), "dc", sum(1 for o in out if o["dc_match"]), "gov", sum(1 for o in out if o["gov_match"]), "eu", sum(1 for o in out if o["eu_match"]))
for k in ("license_agree", "temporal_agree", "spatial_agree"):
    print(k, collections.Counter(o[k][:40] for o in out))

# citations for up to 200 likely_relevant candidates with DOIs
pri = {a["anchor_id"]: int(a["priority"]) for a in csv.DictReader(open(f"{D}/landscape/anchors.csv", encoding="utf-8"))}
L = [c for c in csv.DictReader(open(f"{D}/landscape/candidates-{T}.csv", encoding="utf-8")) if c["triage"] == "likely_relevant" and c["doi"] and c["in_inventory"] != "Y"]


def score(x):
    s = max(4 - pri[a] for a in x["anchors"].split("; ") if a in pri) + math.log10(1 + int(x["citations"] or 0)) * 1.5 + (1 if x["has_geolocation"] == "Y" else 0)
    return s - 5 if re.search(r"WPA household|SBC LTER|Additional file", x["title"]) else s


L.sort(key=score, reverse=True)
sel = L[:200]
cit = ckpt("F-cit") or {}
for c in sel:
    k = c["doi"]
    if k in cit:
        continue
    o = dict(datacite_citations="", datacite_references="", views="", downloads="", scholix_links_as_source="", scholix_links_as_target="")
    j = jget("https://api.datacite.org/dois/" + k)
    if j:
        a = j["data"]["attributes"]
        o.update(datacite_citations=a.get("citationCount"), datacite_references=a.get("referenceCount"), views=a.get("viewCount"), downloads=a.get("downloadCount"))
    for side, key in (("scholix_links_as_source", "sourcePid"), ("scholix_links_as_target", "targetPid")):
        j = jget("https://api.scholexplorer.openaire.eu/v3/Links", {key: k})
        if j:
            o[side] = j.get("totalLinks")
    cit[k] = o; ckpt("F-cit", cit)
rows2 = []
for c in sel:
    o = cit[c["doi"]]
    rows2.append(dict(doi=c["doi"], title=c["title"], publisher=c["publisher"], year=c["year"], anchors=c["anchors"], quiver_citations=c["citations"], **o))
with open(f"{D}/landscape/citations-200-{T}.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(rows2[0].keys())); w.writeheader(); w.writerows(rows2)
num = lambda v: int(v) if str(v).isdigit() else 0
print("citations rows", len(rows2), "with datacite_citations>0", sum(1 for r in rows2 if num(r["datacite_citations"]) > 0), "with any scholix link", sum(1 for r in rows2 if num(r["scholix_links_as_source"]) + num(r["scholix_links_as_target"]) > 0),
      "quiver citations >0", sum(1 for r in rows2 if num(r["quiver_citations"]) > 0))
print("done")
