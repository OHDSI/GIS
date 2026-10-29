"""PROMPT 2 phase E spike: top 10 x 3 anchors x 3 collections, Dataverse file/variable lookups, overlap. python scripts/landscape_e.py"""
import csv, json, re, sys, os, difflib, collections
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from landscape_lib import *
T = "2026-10-29"
A3 = ["care_sites", "deprivation_indices", "air_pollution"]
anchors = {a["anchor_id"]: a for a in csv.DictReader(open(f"{D}/landscape/anchors.csv", encoding="utf-8"))}
inv = list(csv.DictReader(open(f"{D}/inventory-combined-2026-10-29-geo.csv", encoding="utf-8")))
orq = lambda ts, sep: sep.join('"%s"' % t.strip() for t in ts)
recs = ckpt("E-recs") or []
done = {(r["collection"], r["anchor"]) for r in recs}


def terms(a):
    return anchors[a]["query_terms"].split(";")


def first(v):
    if isinstance(v, dict):
        return v.get("en") or next(iter(v.values()), "")
    return v or ""


for a in A3:
    ts = terms(a)
    if ("Harvard Dataverse", a) not in done:
        r, e = get("https://dataverse.harvard.edu/api/search", {"q": orq(ts, " OR "), "type": "dataset", "per_page": 10, "sort": "score", "order": "desc"})
        for i, d in enumerate(r.json()["data"]["items"], 1):
            recs.append(dict(collection="Harvard Dataverse", anchor=a, rank=i, title=d.get("name", ""), doi=(d.get("global_id", "") or "").replace("doi:", ""), url=d.get("url", ""),
                             publisher=d.get("publisher", ""), year=(d.get("published_at", "") or "")[:4], description=(d.get("description", "") or "")[:200], pid=d.get("global_id", "")))
    if ("data.europa.eu", a) not in done:
        r, e = get("https://data.europa.eu/api/hub/search/search", {"q": orq(ts, " | "), "limit": 10, "filter": "dataset"})
        for i, d in enumerate(r.json()["result"]["results"], 1):
            pub = first(d.get("publisher") or {})
            if isinstance(pub, dict):
                pub = first(pub.get("name", ""))
            dist = d.get("distributions") or []
            fm = sorted({str(first((x.get("format") or {}).get("id", "")) if isinstance(x.get("format"), dict) else x.get("format", "")) for x in dist})
            recs.append(dict(collection="data.europa.eu", anchor=a, rank=i, title=first(d.get("title")), doi="", url="https://data.europa.eu/data/datasets/" + str(d.get("id", "")),
                             publisher=str(pub), year=(d.get("issued", "") or d.get("modified", "") or "")[:4], description="", pid=d.get("id", ""), n_dist=len(dist),
                             dist_formats="; ".join(fm)[:80]))
    if ("data.gov", a) not in done:
        r, e = get("https://catalog.data.gov/search", {"q": orq(ts, " OR "), "per_page": 10})
        for i, d in enumerate(r.json()["results"][:10], 1):
            dc = d.get("dcat", {})
            pub = (dc.get("publisher") or {}).get("name", "")
            recs.append(dict(collection="data.gov", anchor=a, rank=i, title=d.get("title") or dc.get("title", ""), doi="", url=dc.get("landingPage", "") or "", publisher=pub,
                             year=(dc.get("issued") or dc.get("modified") or "")[:4], description=(dc.get("description", "") or "")[:200], pid=d.get("slug", "") or dc.get("identifier", "")))
    ckpt("E-recs", recs)
print(len(recs), "records", flush=True)

dv = [r for r in recs if r["collection"] == "Harvard Dataverse"]
pick = [r for r in dv if r["rank"] <= 4][:10]
KEYPAT = [("GEOID/FIPS", r"geoid|fips|tract|statefp|countyfp"), ("ZIP/ZCTA", r"\bzip|zcta|postal"), ("coordinates", r"\blat|\blon|latitude|longitude|x_coord|y_coord"),
          ("admin code", r"nuts|iso_?3|admin[0-3]|county|state"), ("facility/site ID", r"facility|site_?id|hospital_?id|provider")]
for r in pick:
    r.update(n_files="", tabular_files="", variables_sample="", variable_place_keys="", file_note="")
    j, e = get("https://dataverse.harvard.edu/api/datasets/:persistentId/versions/:latest-published/files", {"persistentId": r["pid"]})
    if j is None or j.status_code != 200:
        r["file_note"] = "files lookup failed"
        continue
    files = j.json().get("data", [])
    r["n_files"] = len(files)
    tab = [f for f in files if f.get("dataFile", {}).get("tabularData")]
    r["tabular_files"] = len(tab)
    varnames = []
    for f in tab[:2]:
        x, e = get("https://dataverse.harvard.edu/api/access/datafile/%s/metadata" % f["dataFile"]["id"], headers={"Accept": "*/*"})
        if x is None or x.status_code != 200:
            continue
        try:
            root = ET.fromstring(x.content)
        except Exception:
            continue
        for v in root.iter():
            if v.tag.endswith("}var") or v.tag == "var":
                if v.get("name"):
                    varnames.append(v.get("name"))
    r["variables_sample"] = "; ".join(varnames[:15])
    r["variable_place_keys"] = "; ".join(sorted({k for k, p in KEYPAT for n in varnames if re.search(p, n, re.I)}))
    r["file_note"] = "no tabular files" if not tab else ("no variables read" if not varnames else "")
ckpt("E-recs", recs)


def nurl(u):
    u = re.sub(r"^https?://(www\.)?", "", (u if isinstance(u, str) else "").lower().strip().rstrip("/"))
    return u.split("#")[0].split("?")[0]


def ntitle(t):
    return re.sub(r"[^a-z0-9 ]", "", (t if isinstance(t, str) else "").lower()).strip()


invs = [dict(id=x["id"], title=ntitle(x["dataset_name"]), url=nurl(x["site_url"]), doi=(x["persistent_id"] or "").lower().replace("https://doi.org/", "").replace("doi:", ""),
             org=ntitle(x["organization"])) for x in inv]
for r in recs:
    r["match_inventory"] = r["match_kind"] = r["match_other_collection"] = ""
    for x in invs:
        if r["doi"] and x["doi"] and r["doi"].lower() == x["doi"]:
            r["match_inventory"], r["match_kind"] = x["id"], "doi"; break
        if nurl(r["url"]) and nurl(r["url"]) == x["url"]:
            r["match_inventory"], r["match_kind"] = x["id"], "landing_url"; break
        if r["publisher"] and x["org"] and ntitle(r["publisher"]) == x["org"] and x["title"] and (x["title"] in ntitle(r["title"]) or ntitle(r["title"]) in x["title"]):
            r["match_inventory"], r["match_kind"] = x["id"], "publisher+product"; break
    if not r["match_inventory"]:
        best = max(invs, key=lambda x: difflib.SequenceMatcher(None, ntitle(r["title"]), x["title"]).ratio())
        s = difflib.SequenceMatcher(None, ntitle(r["title"]), best["title"]).ratio()
        if s >= 0.85:
            r["match_inventory"], r["match_kind"] = best["id"], "possible (fuzzy title %.2f)" % s
for i, r in enumerate(recs):
    for q in recs[i + 1:]:
        if q["collection"] == r["collection"]:
            continue
        same = (r["doi"] and r["doi"] == q["doi"]) or (nurl(r["url"]) and nurl(r["url"]) == nurl(q["url"]))
        fz = difflib.SequenceMatcher(None, ntitle(r["title"]), ntitle(q["title"])).ratio() >= 0.9
        if same or fz:
            sfx = "" if same else " (possible)"
            r["match_other_collection"] += "%s:%s%s; " % (q["collection"], q["rank"], sfx)
            q["match_other_collection"] += "%s:%s%s; " % (r["collection"], r["rank"], sfx)
cols = ["collection", "anchor", "rank", "title", "doi", "url", "publisher", "year", "description", "n_files", "tabular_files", "variables_sample", "variable_place_keys", "file_note",
        "n_dist", "dist_formats", "match_inventory", "match_kind", "match_other_collection"]
with open(f"{D}/landscape/spike-e-{T}.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
    w.writeheader()
    w.writerows(recs)
print(collections.Counter(r["collection"] for r in recs), "inv matches", sum(1 for r in recs if r["match_inventory"]), "cross", sum(1 for r in recs if r["match_other_collection"]))
print("dv probed", len(pick), "with keys", sum(1 for r in pick if r["variable_place_keys"]), "tabular", sum(1 for r in pick if r["tabular_files"] not in ("", 0)))
