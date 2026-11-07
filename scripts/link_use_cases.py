#!/usr/bin/env python3
"""Suggest datasets for open use cases.

Reads the data needs in rmd/data/use-case-data-needs.json, the use cases and
catalog requests in rmd/data/status.json, and the Data Inventory in
rmd/data/inventory.json. Writes rmd/data/use-case-links.json.

  --dry-run  print the suggestions, write and post nothing
  --post     also post one comment per use case issue (updated in place) and set
             the "Data match" field on the project board

Maintainers answer in the issue comments: "/confirm <id>", "/reject <id>" or
"/no-data-needed". Decisions are re-read from the comments on every run.
Environment: GITHUB_TOKEN (issues: write) for comments; BOARD_TOKEN (project
write) for the board field.
"""

import json
import os
import re
import subprocess
import sys
import urllib.request
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
ORG = "OHDSI"
MARKER = "<!-- gaia-data-links -->"
WRITERS = {"OWNER", "MEMBER", "COLLABORATOR"}
TOKEN = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
TIER = {"Gold": 2.0, "Silver": 1.0, "Bronze": 0.0}
VERIFIED = {"file-verified": 1.0, "file-verified (partly)": 0.7, "page-verified": 0.5}


def api(path, method="GET", body=None):
    req = urllib.request.Request(f"https://api.github.com{path}", method=method)
    req.add_header("Accept", "application/vnd.github+json")
    if TOKEN:
        req.add_header("Authorization", f"Bearer {TOKEN}")
    data = json.dumps(body).encode() if body is not None else None
    with urllib.request.urlopen(req, data=data, timeout=30) as r:
        return json.load(r)


def comments(number):
    items, page = [], 1
    while True:
        batch = api(f"/repos/{ORG}/GIS/issues/{number}/comments?per_page=100&page={page}")
        items += batch
        if len(batch) < 100:
            return items
        page += 1


def decisions_from(items, valid_ids):
    """Fold /confirm, /reject and /no-data-needed replies, oldest first, from people with write access."""
    state = {"confirmed": [], "rejected": [], "no_data_needed": False}
    for c in items:
        if MARKER in c["body"] or c["author_association"] not in WRITERS:
            continue
        for line in c["body"].splitlines():
            m = re.match(r"^\s*/(confirm|reject|no-data-needed)\b\s*(\S*)", line)
            if not m:
                continue
            cmd, arg = m.groups()
            if cmd == "no-data-needed":
                state["no_data_needed"] = True
            elif arg in valid_ids:
                other = "rejected" if cmd == "confirm" else "confirmed"
                target = "confirmed" if cmd == "confirm" else "rejected"
                state[other] = [x for x in state[other] if x != arg]
                if arg not in state[target]:
                    state[target].append(arg)
                state["no_data_needed"] = False
    return state


def candidate(row, s, why, requests, known):
    req = row["wg"] if row["wg"] in requests else None
    return {
        "id": row["id"], "name": row["n"], "owner": row["o"], "tier": row["t"],
        "region": row["rg"], "unit": row["u"], "latest": row["ly"],
        "in_catalog_request": req, "already_dependency": bool(req and req in known),
        "score": round(s, 1), "why": why, "url": row["url"],
    }


def comment_body(entry):
    lines = [MARKER, "### Candidate datasets", "",
             "Suggested weekly from this issue's data needs against the "
             "[Data Inventory](https://ohdsi.github.io/GIS/inventory.html) and the catalog requests. "
             "These are suggestions, not decisions.", ""]

    def table(rows):
        out = ["| Dataset | Tier | Why | Catalog request |", "|---|---|---|---|"]
        for c in rows:
            req = f'OHDSI/{c["in_catalog_request"]}' if c["in_catalog_request"] else ""
            out.append(f'| [{c["name"]}]({c["url"]}) `{c["id"]}` | {c["tier"]} | {"; ".join(c["why"])} | {req} |')
        return out

    if entry["confirmed"]:
        lines += ["**Confirmed**", ""] + table(entry["confirmed"]) + [""]
    if entry["candidates"]:
        lines += ["**Suggested**", ""] + table(entry["candidates"]) + [""]
    lines += ["Reply with `/confirm <id>` or `/reject <id>` using the id in backticks, "
              "or `/no-data-needed` if this use case needs no external dataset. "
              "Only people with write access are counted."]
    return "\n".join(lines)


def post_comment(number, body):
    mine = [c for c in comments(number) if MARKER in c["body"]]
    if mine:
        if mine[0]["body"] != body:
            api(f'/repos/{ORG}/GIS/issues/comments/{mine[0]["id"]}', "PATCH", {"body": body})
            return "updated"
        return "unchanged"
    api(f"/repos/{ORG}/GIS/issues/{number}/comments", "POST", {"body": body})
    return "created"


def gh(*args):
    env = dict(os.environ, GH_TOKEN=os.environ["BOARD_TOKEN"])
    r = subprocess.run(["gh", *args], capture_output=True, text=True, env=env)
    if r.returncode:
        raise RuntimeError(r.stderr.strip())
    return r.stdout


def set_board_fields(states):
    """states: {issue number: 'Suggested' | 'Confirmed' | 'None found' | 'Not needed'}"""
    pid = json.loads(gh("project", "view", "26", "--owner", ORG, "--format", "json"))["id"]
    fields = json.loads(gh("project", "field-list", "26", "--owner", ORG, "--format", "json"))["fields"]
    field = next(f for f in fields if f["name"] == "Data match")
    options = {o["name"]: o["id"] for o in field["options"]}
    items = json.loads(gh("project", "item-list", "26", "--owner", ORG, "--format", "json", "-L", "500"))["items"]
    for it in items:
        c = it.get("content") or {}
        if c.get("repository") != f"{ORG}/GIS" or c.get("number") not in states:
            continue
        want = states[c["number"]]
        if it.get("data match") == want:
            continue
        gh("project", "item-edit", "--id", it["id"], "--project-id", pid,
           "--field-id", field["id"], "--single-select-option-id", options[want])
        print(f'   board: GIS#{c["number"]} Data match -> {want}')


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
    post = "--post" in sys.argv and not dry
    needs = json.loads((DATA / "use-case-data-needs.json").read_text())["needs"]
    status = json.loads((DATA / "status.json").read_text())
    inventory = json.loads((DATA / "inventory.json").read_text())
    previous = json.loads(OUT.read_text())["links"] if OUT.exists() else {}
    by_id = {r["id"]: r for r in inventory["rows"]}

    open_ucs = {u["key"]: u for u in status["use_cases"] if u["state"] == "open"}
    requests = {d["key"]: d for d in status["datasets"]}
    result, board = {}, {}
    for key, need in sorted(needs.items()):
        uc = open_ucs.get(key)
        if not uc or not (need.get("themes") or need.get("keywords")):
            continue
        if need.get("confidence", "").startswith("low"):
            print(f"\n{key}  skipped: data needs are a low-confidence draft; review them first")
            continue
        known = {d["key"] for d in uc["depends_on"]}
        try:
            dec = decisions_from(comments(uc["number"]), set(by_id))
        except Exception as e:  # offline or rate limited: keep last run's decisions
            print(f"   (could not read comments for {key}: {e}; using previous decisions)")
            dec = previous.get(key, {}).get("decisions") or {"confirmed": [], "rejected": [], "no_data_needed": False}
        ranked = []
        for row in inventory["rows"]:
            if row["id"] in dec["rejected"] or row["id"] in dec["confirmed"]:
                continue
            s, why = score(need, row)
            if s >= MIN_SCORE:
                ranked.append((s, row, why))
        ranked.sort(key=lambda x: (-x[0], x[1]["n"]))
        cands = [candidate(r, s, w, requests, known) for s, r, w in ranked[:TOP]]
        confirmed = [candidate(by_id[i], *score(need, by_id[i]), requests, known) for i in dec["confirmed"]]
        state = ("Not needed" if dec["no_data_needed"] else "Confirmed" if confirmed
                 else "Suggested" if cands else "None found")
        result[key] = {"title": uc["title"], "url": uc["url"], "state": state, "decisions": dec,
                       "confirmed": confirmed, "candidates": cands}
        board[uc["number"]] = state

    out = {"asof": inventory["asof"], "links": result}
    for key, r in result.items():
        print(f'\n{key}  {r["title"]}  [{r["state"]}]')
        for label, rows in (("confirmed", r["confirmed"]), ("suggested", r["candidates"])):
            for c in rows:
                tag = f' [{c["in_catalog_request"]}]' if c["in_catalog_request"] else ""
                print(f'   {label:<9} {c["score"]:>4}  {c["tier"]:<6} {c["name"][:60]} ({c["owner"][:30]}, {c["region"]}, {c["unit"]}){tag}')
    if dry:
        return
    text = json.dumps(out, indent=1) + "\n"
    if not OUT.exists() or OUT.read_text() != text:
        OUT.write_text(text)
    print(f"\nwrote {OUT.relative_to(ROOT)}")
    if post:
        for key, r in result.items():
            if r["state"] in ("Suggested", "Confirmed"):
                n = int(key.split("#")[1])
                print(f"   comment on {key}: {post_comment(n, comment_body(r))}")
        if os.environ.get("BOARD_TOKEN"):
            set_board_fields(board)
        else:
            print("   BOARD_TOKEN not set: board field left unchanged")


if __name__ == "__main__":
    main()
