#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "rmd" / "data"
OUT = DATA / "use-case-links.json"
TOP = 5
MIN_SCORE = 5

# use-case template theme -> inventory themes ("th")
THEMES = {
    "Air quality": ["Air pollution"],
    "Heat / temperature / climate": ["Heat and temperature"],
    "Water": ["Water quality", "Floods, drought, wildfire and hazards"],
    "Green space / built environment": ["Built environment"],
    "Food access": ["Built environment"],
    "Deprivation / socioeconomic indices": ["Deprivation and vulnerability indices", "Census and socioeconomic"],
    "Demographics / population": ["Census and socioeconomic"],
    "Health services / care access": ["Care sites and health services", "Health outcomes and surveys"],
    "Hazards / disasters": ["Floods, drought, wildfire and hazards", "Toxic releases and industrial sites"],
    "Crime / violence": ["Other"],
}

# use-case geography option -> inventory units ("u")
GEOGRAPHY = {
    "Point / address": {"point", "points", "address"},
    "Census block group or tract": {"tract", "block_group", "block"},
    "ZIP / postal code": {"zip", "postcode_small_area"},
    "County": {"county", "admin2"},
    "State or country": {"state", "country", "admin1"},
}

# free-text region -> inventory regions ("rg") it can be served by
REGIONS = [
    ("united states", {"United States"}),
    ("sub-saharan africa", {"Africa", "HDX (humanitarian)"}),
    ("africa", {"Africa", "HDX (humanitarian)"}),
    ("europe", {"Europe", "United Kingdom"}),
    ("united kingdom", {"United Kingdom"}),
    ("canada", {"Canada"}),
    ("australia", {"Australia", "Oceania"}),
    ("asia", {"Asia"}),
    ("latin america", {"Latin America"}),
]
TIER = {"Gold": 2.0, "Silver": 1.0, "Bronze": 0.0}
VERIFIED = {"file-verified": 1.0, "file-verified (partly)": 0.7, "page-verified": 0.5}


def regions_for(text):
    t = (text or "").lower()
    found = set()
    for needle, rg in REGIONS:
        if needle in t:
            found |= rg
    return found


def score(need, row):
    """Return (score, reasons) for one inventory row against one use case's needs."""
    if row["t"] not in TIER:
        return 0, []
    s, why = 0.0, []
    name = f'{row["n"]} {row["o"]}'.lower()

    wanted = {th for t in need.get("themes", []) for th in THEMES.get(t, [])}
    hit = wanted & set(row["th"])
    if hit:
        s += 3 + (1 if len(hit) > 1 else 0)
        why.append("theme: " + ", ".join(sorted(hit)))

    kws = [k for k in need.get("keywords", []) if k.lower() in name]
    if kws:
        s += min(8, 4 * len(kws))
        why.append("named: " + ", ".join(kws))

    if not hit and not kws:
        return 0, []

    units = GEOGRAPHY.get(need.get("geography"), set())
    if units and row["u"] in units:
        s += 2
        why.append(f'unit: {row["u"]}')

    wr = regions_for(need.get("region"))
    if wr:
        if row["rg"] in wr:
            s += 2
            why.append(f'region: {row["rg"]}')
        elif row["rg"] == "Global":
            s += 1
            why.append("region: global")
        else:
            return 0, []

    s += TIER[row["t"]] + VERIFIED.get(row["lv"], 0)
    return s, why


def main():
    dry = "--dry-run" in sys.argv
    needs = json.loads((DATA / "use-case-data-needs.json").read_text())["needs"]
    status = json.loads((DATA / "status.json").read_text())
    inventory = json.loads((DATA / "inventory.json").read_text())

    open_ucs = {u["key"]: u for u in status["use_cases"] if u["state"] == "open"}
    requests = {d["key"]: d for d in status["datasets"]}
    result = {}
    for key, need in sorted(needs.items()):
        uc = open_ucs.get(key)
        if not uc or not (need.get("themes") or need.get("keywords")):
            continue
        if need.get("confidence", "").startswith("low"):
            print(f"\n{key}  skipped: data needs are a low-confidence draft; review them first")
            continue
        known = {d["key"] for d in uc["depends_on"]}
        ranked = []
        for row in inventory["rows"]:
            s, why = score(need, row)
            if s >= MIN_SCORE:
                ranked.append((s, row, why))
        ranked.sort(key=lambda x: (-x[0], x[1]["n"]))
        cands = []
        for s, row, why in ranked[:TOP]:
            req = row["wg"] if row["wg"] in requests else None
            cands.append({
                "id": row["id"], "name": row["n"], "owner": row["o"], "tier": row["t"],
                "region": row["rg"], "unit": row["u"], "latest": row["ly"],
                "in_catalog_request": req, "already_dependency": bool(req and req in known),
                "score": round(s, 1), "why": why, "url": row["url"],
            })
        result[key] = {"title": uc["title"], "url": uc["url"], "candidates": cands}

    out = {"asof": inventory["asof"], "links": result}
    for key, r in result.items():
        print(f'\n{key}  {r["title"]}')
        if not r["candidates"]:
            print("   (no candidates)")
        for c in r["candidates"]:
            tag = f' [{c["in_catalog_request"]}]' if c["in_catalog_request"] else ""
            print(f'   {c["score"]:>4}  {c["tier"]:<6} {c["name"][:60]} ({c["owner"][:30]}, {c["region"]}, {c["unit"]}){tag}')
            print(f'         {"; ".join(c["why"])}')
    if not dry:
        text = json.dumps(out, indent=1) + "\n"
        if not OUT.exists() or OUT.read_text() != text:
            OUT.write_text(text)
        print(f"\nwrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
