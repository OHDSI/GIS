"""PROMPT 2 phase D spike: collections table + anchor counts (10 collections x 12 anchors). python scripts/landscape_d.py (from docs/discovery)"""
import csv, json, sys, os, re, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from landscape_lib import *
T = "2026-10-29"
anchors = list(csv.DictReader(open(f"{D}/landscape/anchors.csv", encoding="utf-8")))
for a in anchors:
    a["terms"] = [t.strip() for t in a["query_terms"].split(";") if t.strip()]
res = ckpt("D-counts") or {}
notes = ckpt("D-notes") or {}


def put(coll, aid, n, note=""):
    res[f"{coll}|{aid}"] = n
    if note: notes[f"{coll}|{aid}"] = note
    ckpt("D-counts", res); ckpt("D-notes", notes)


def todo(coll, aid): return f"{coll}|{aid}" not in res


def jr(url, params):
    r, e = get(url, params)
    if r is None: return None, e
    if r.status_code != 200: return None, f"HTTP {r.status_code}"
    try: return r.json(), ""
    except Exception: return None, "non-JSON"


or_ = lambda ts, sep=" OR ": sep.join(f'"{t}"' for t in ts)
# DataCite, Dataverse, Zenodo, europa, HDX, data.gov.au
for a in anchors:
    aid, ts = a["anchor_id"], a["terms"]
    if todo("DataCite", aid):
        j, e = jr("https://api.datacite.org/dois", {"query": f"({or_(ts)}) AND publicationYear:[2000 TO *]", "resource-type-id": "dataset", "page[size]": 0})
        put("DataCite", aid, j["meta"]["total"] if j else None, e)
    if todo("Harvard Dataverse", aid):
        j, e = jr("https://dataverse.harvard.edu/api/search", {"q": or_(ts), "type": "dataset", "per_page": 1})
        put("Harvard Dataverse", aid, j["data"]["total_count"] if j else None, e)
    if todo("Zenodo", aid):
        j, e = jr("https://zenodo.org/api/records", {"q": f"({or_(ts)}) AND publication_date:[2000-01-01 TO *]", "type": "dataset", "size": 1})
        put("Zenodo", aid, j["hits"]["total"] if j else None, e)
    if todo("data.europa.eu", aid):
        j, e = jr("https://data.europa.eu/api/hub/search/search", {"q": or_(ts, " | "), "limit": 0, "filter": "dataset"})
        put("data.europa.eu", aid, j["result"]["count"] if j else None, e)
    if todo("HDX", aid):
        j, e = jr("https://data.humdata.org/api/3/action/package_search", {"q": "*:*", "fq": f"text:({or_(ts)})", "rows": 0})
        put("HDX", aid, j["result"]["count"] if j else None, e)
    if todo("data.gov.au", aid):
        j, e = jr("https://data.gov.au/data/api/3/action/package_search", {"q": "*:*", "fq": f"text:({or_(ts)})", "rows": 0})
        put("data.gov.au", aid, j["result"]["count"] if j else None, e)
    if todo("data.gov", aid):
        j, e = jr("https://api.gsa.gov/technology/datagov/v3/action/package_search", {"q": "*:*", "fq": f"text:({or_(ts)})", "rows": 0})
        put("data.gov", aid, j["result"]["count"] if j and "result" in j else None, e or "")
print("phase 1 done", flush=True)
# NASA CMR: one keyword per call; union of concept ids per anchor
for a in anchors:
    aid = a["anchor_id"]
    if not todo("NASA CMR", aid): continue
    ids, err = set(), ""
    for t in a["terms"]:
        pg = 1
        while True:
            r, e = get("https://cmr.earthdata.nasa.gov/search/collections.json", {"keyword": t, "page_size": 2000, "page_num": pg})
            if r is None or r.status_code != 200: err = f"{t}: {e or r.status_code}"; break
            ent = r.json()["feed"]["entry"]; ids |= {x["id"] for x in ent}
            if len(ent) < 2000: break
            pg += 1
    put("NASA CMR", aid, len(ids) if not err else None, ("union of per-term keyword hits (CMR has no OR); " + err).strip())
# Earth Engine: title match over the full dataset listing (provider catalogs)
ee = ckpt("D-ee")
if ee is None:
    r, e = get("https://earthengine-stac.storage.googleapis.com/catalog/catalog.json")
    prov = [l["href"] for l in r.json()["links"] if l.get("rel") == "child"]
    ee = []
    for h in prov:
        r, e = get(h, gap=0.3)
        if r is None or r.status_code != 200: continue
        for l in r.json().get("links", []):
            if l.get("rel") == "child": ee.append({"title": l.get("title", ""), "href": l["href"]})
    ckpt("D-ee", ee)
    save_raw("earthengine-catalog-listing", ee)
for a in anchors:
    aid = a["anchor_id"]
    n = sum(1 for d in ee if any(t.lower() in d["title"].lower() for t in a["terms"]))
    put("Earth Engine", aid, n, f"title-only match over full listing of {len(ee)} entries")
for a in anchors:
    put("ICPSR", a["anchor_id"], None, "skipped: Cloudflare challenge (403) on search; not bypassed")
print("done")
