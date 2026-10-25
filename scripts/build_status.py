#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "rmd" / "data" / "status-config.json"
OUT = ROOT / "rmd" / "data" / "status.json"
ORG = "OHDSI"
TOKEN = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")

_cache = {}


def api(path):
    req = urllib.request.Request(f"https://api.github.com{path}")
    req.add_header("Accept", "application/vnd.github+json")
    if TOKEN:
        req.add_header("Authorization", f"Bearer {TOKEN}")
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def all_issues(repo):
    items, page = [], 1
    while True:
        batch = api(f"/repos/{ORG}/{repo}/issues?state=all&per_page=100&page={page}")
        items += [i for i in batch if "pull_request" not in i]
        if len(batch) < 100:
            return items
        page += 1


def get_issue(repo, number):
    key = (repo, number)
    if key not in _cache:
        try:
            _cache[key] = api(f"/repos/{ORG}/{repo}/issues/{number}")
        except urllib.error.HTTPError:
            _cache[key] = None
    return _cache[key]


def key_of(repo, number):
    return f"{repo}#{number}"


REF = re.compile(
    r"(?:github\.com/OHDSI/(?P<r1>[\w.-]+)/issues/(?P<n1>\d+))"
    r"|(?:OHDSI/(?P<r2>[\w.-]+)#(?P<n2>\d+))"
    r"|(?:(?<![\w/])#(?P<n3>\d+))"
)


def dependency_refs(body, repo, self_number):
    """Issue references in task-list items or after a 'Depends on' heading."""
    refs, in_section = [], False
    for line in (body or "").splitlines():
        s = line.strip()
        if re.match(r"^#+\s*depends on", s, re.I) or re.match(r"^depends on:?$", s, re.I):
            in_section = True
            continue
        if re.match(r"^#+\s", s) and in_section and not re.search(r"dataset", s, re.I):
            in_section = False
        if in_section or re.match(r"^[-*]\s*\[[ xX]\]", s):
            for m in REF.finditer(s):
                if m.group("n1"):
                    r, n = m.group("r1"), int(m.group("n1"))
                elif m.group("n2"):
                    r, n = m.group("r2"), int(m.group("n2"))
                else:
                    r, n = repo, int(m.group("n3"))
                if (r, n) != (repo, self_number) and (r, n) not in refs:
                    refs.append((r, n))
    return refs


BOARD_STATUS = {
    "idea": "Idea", "proposed": "Proposed", "todo": "To do",
    "in progress": "In progress", "blocked": "Blocked", "done": "Complete",
}


def board_status(raw):
    """Map a board Status option ('🏃‍♀ In Progress') to a plain label."""
    plain = re.sub(r"[^a-z ]", "", (raw or "").lower()).strip()
    return BOARD_STATUS.get(plain)


def fetch_board(project):
    try:
        res = subprocess.run(
            ["gh", "project", "item-list", str(project), "--owner", ORG,
             "--limit", "2000", "--format", "json"],
            capture_output=True, text=True, timeout=120, check=True)
        items = json.loads(res.stdout)["items"]
    except (OSError, subprocess.SubprocessError, ValueError, KeyError) as e:
        print(f"warning: could not read project board ({e}); keeping previous board values",
              file=sys.stderr)
        return None
    board = {}
    for it in items:
        m = re.search(r"OHDSI/([^/]+)/issues/(\d+)", (it.get("content") or {}).get("url", ""))
        if not m:
            continue
        rank = it.get("rank")
        board[(m.group(1), int(m.group(2)))] = {
            "status": board_status(it.get("status")),
            "rank": rank if isinstance(rank, (int, float)) else None,
        }
    return board


def clean_title(t):
    t = re.sub(r"^\s*\[[^\]]*\]\s*:?\s*", "", t).strip()
    t = re.sub(r"^(Data Request:\s*)", "", t, flags=re.I)
    return t[:1].upper() + t[1:] if t else t


def date(s):
    return s[:10] if s else None


def main():
    cfg = json.loads(CONFIG.read_text())
    internal = {u.lower() for u in cfg["internal_members"]}
    exclude = set(cfg.get("exclude", {}))
    overrides = cfg.get("overrides", {})

    previous = {}
    if OUT.exists():
        old_out = json.loads(OUT.read_text())
        previous = {x["key"]: x for x in old_out["use_cases"] + old_out["datasets"]}
    board = fetch_board(cfg.get("project_number", 26))

    gis = all_issues("GIS")
    cat = all_issues("gaiaCatalog")
    for i in gis:
        i["_repo"] = "GIS"
    for i in cat:
        i["_repo"] = "gaiaCatalog"

    def labels(i):
        return {l["name"] for l in i["labels"]}

    use_cases, datasets = [], []
    for i in gis + cat:
        k = key_of(i["_repo"], i["number"])
        if k in exclude:
            continue
        L = labels(i)
        forced = overrides.get(k, {}).get("kind")
        if forced:
            kind = forced
        elif i["_repo"] == "GIS" and "Use Case" in L:
            kind = "use_case"
        elif "data request" in L or "data source request" in L or k in cfg.get("include_datasets", []):
            kind = "dataset"
        else:
            continue
        (use_cases if kind == "use_case" else datasets).append(i)

    tracked = {key_of(i["_repo"], i["number"]): ("use_case" if i in use_cases else "dataset")
               for i in use_cases + datasets}
    by_key = {key_of(i["_repo"], i["number"]): i for i in gis + cat}

    def person(login):
        return {"login": login, "url": f"https://github.com/{login}"}

    def build(i, kind):
        repo, n = i["_repo"], i["number"]
        k = key_of(repo, n)
        o = overrides.get(k, {})
        L = labels(i)
        assignees = [a["login"] for a in i["assignees"]]
        internal_owners = o.get("internal_owner") or [a for a in assignees if a.lower() in internal]
        author = i["user"]["login"]
        if "external_owner" in o:
            ext = o["external_owner"]
        elif author.lower() in internal:
            ext = None
        else:
            ext = f"@{author}"

        deps = []
        for r, num in dependency_refs(i.get("body"), repo, n):
            dk = key_of(r, num)
            d = by_key.get(dk) or get_issue(r, num)
            if not d:
                continue
            deps.append({
                "key": dk, "repo": r, "number": num, "title": clean_title(d["title"]),
                "state": d["state"], "url": d["html_url"], "tracked_as": tracked.get(dk),
            })
        for dk in o.get("depends_on", []):
            r, num = dk.split("#")
            d = by_key.get(dk) or get_issue(r, int(num))
            if d and all(x["key"] != dk for x in deps):
                deps.append({
                    "key": dk, "repo": r, "number": int(num), "title": clean_title(d["title"]),
                    "state": d["state"], "url": d["html_url"], "tracked_as": tracked.get(dk),
                })

        if board is not None:
            on_board = board.get((repo, n), {})
            b_status, rank = on_board.get("status"), on_board.get("rank")
        else:
            b_status, rank = previous.get(k, {}).get("board_status"), previous.get(k, {}).get("rank")

        if "status" in o:
            status = o["status"]
        elif i["state"] == "closed":
            status = "Complete"
        elif "On Hold" in L:
            status = "On hold"
        elif b_status:
            status = b_status
        elif "in progress" in L:
            status = "In progress"
        elif internal_owners:
            status = "Assigned"
        else:
            status = "Proposed" if kind == "use_case" else "Requested"

        return {
            "key": k, "repo": repo, "number": n, "kind": kind,
            "title": o.get("title") or clean_title(i["title"]),
            "url": i["html_url"], "state": i["state"], "status": status,
            "status_note": o.get("status_note"),
            "requested": date(i["created_at"]), "updated": date(i["updated_at"]),
            "closed": date(i["closed_at"]),
            "requester": person(author),
            "external_owner": ext,
            "internal_owners": [person(u) for u in internal_owners],
            "board_status": b_status,
            "rank": rank,
            "labels": sorted(L),
            "depends_on": deps,
            "needed_by": [],
            "deps_closed": sum(1 for d in deps if d["state"] == "closed"),
            "deps_total": len(deps),
        }

    ucs = [build(i, "use_case") for i in use_cases]
    dss = [build(i, "dataset") for i in datasets]
    by_out = {x["key"]: x for x in ucs + dss}

    for x in ucs + dss:
        for d in x["depends_on"]:
            tgt = by_out.get(d["key"])
            if tgt:
                tgt["needed_by"].append({"key": x["key"], "title": x["title"], "url": x["url"],
                                         "state": x["state"], "kind": x["kind"]})

    def sort_key(x):
        return (x["rank"] is None, x["rank"] or 0, x["state"] == "closed", x["requested"])

    ucs.sort(key=sort_key)
    dss.sort(key=sort_key)

    out = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "sources": [f"https://github.com/{ORG}/GIS/issues?q=label%3A%22Use+Case%22",
                    f"https://github.com/{ORG}/gaiaCatalog/issues?q=label%3A%22data+source+request%22"],
        "use_cases": ucs,
        "datasets": dss,
    }
    if OUT.exists():
        old = json.loads(OUT.read_text())
        if {k: v for k, v in old.items() if k != "generated_at"} == \
                {k: v for k, v in out.items() if k != "generated_at"}:
            out["generated_at"] = old["generated_at"]  # unchanged data: keep the file byte-identical
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(ucs)} use cases, {len(dss)} dataset requests")


if __name__ == "__main__":
    try:
        main()
    except urllib.error.URLError as e:
        sys.exit(f"GitHub API error: {e}")
