#!/usr/bin/env python3
"""Round 1 close-out (PROMPT-1, 2026-10-28), step 3: recompute, from the CSVs, the counts quoted in four reports and write numbers-check-2026-10-28.md.

  python scripts/numbers_check_2026_10_28.py        (run from docs/discovery)

Documents checked (never edited by this script):
  CR = close-report-2026-10-28.md
  IS = ticket-2026-10-28/ISSUE-update-2026-10-28.md
  BS = browser-sample-2026-10-28.md
  R2 = round2/round2-report-2026-10-28.md
Each claim is read out of the document text (table cell or regex), so the "claimed" column is what the document says, not what this script
believes it says; a claim that cannot be found is reported as NOT FOUND. Recomputed values come only from the CSV/JSON files named in the table.
Needs-Robert items are listed by hand at the foot (written after reading the mismatches), keyed by claim number.
"""
import csv, glob, json, os, re, sys
from collections import Counter

D = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
DATE = "2026-10-28"; PREV = "2026-10-23"


def rc(p):
    return list(csv.DictReader(open(os.path.join(D, p), encoding="utf-8")))


def rt(p):
    return open(os.path.join(D, p), encoding="utf-8").read()


DOCS = {"CR": f"close-report-{DATE}.md", "IS": f"ticket-{DATE}/ISSUE-update-{DATE}.md", "BS": f"browser-sample-{DATE}.md", "R2": f"round2/round2-report-{DATE}.md"}
TXT = {k: rt(v) for k, v in DOCS.items()}

# ----------------------------------------------------------------------------- data
R1 = rc(f"inventory-refined-{DATE}.csv")
COMB = rc(f"inventory-combined-{DATE}.csv")
R2 = [r for r in COMB if r["round"] == "2-pilot"]
P = {r["id"]: r for r in rc(f"_to_delete/inventory-refined-{PREV}-before-close.csv")}
TRIM = rc("trim-2026-10-22.csv")
MIR = rc(f"partB/mirrors-{PREV}.csv")
DUPES = rc(f"dupe-review-{DATE}.csv")
BQ = rc(f"browser-queue-{DATE}.csv")
BQ_OLD = rc(f"browser-queue-{PREV}.csv")
BSAMP = rc(f"browser-sample-{DATE}.csv")
CAND = rc(f"round2/round2-candidates-{DATE}.csv")
RA = rc(f"round2/verify-A-{DATE}.csv")
RLOG = rc("round2/verify-log-round2.csv")
RBQ = rc(f"round2/browser-queue-{DATE}.csv")
META = json.load(open(os.path.join(D, "round2/sweeps-meta.json"), encoding="utf-8"))
QUEUE = [x[0] for x in json.load(open(os.path.join(D, "partB/queue-close.json"), encoding="utf-8"))]
USAGE = json.load(open(os.path.join(D, "partB/usage-close.json"), encoding="utf-8"))
tier = Counter(r["verify_tier"] for r in R1)
ptier = Counter(r["verify_tier"] for r in P.values())
partB_ids = {}
for f in sorted(glob.glob(os.path.join(D, "partB/results/*.json"))):
    for r in json.load(open(f, encoding="utf-8")).get("rows", []):
        partB_ids[r["id"]] = os.path.basename(f)
D_files = sorted(glob.glob(os.path.join(D, "partB/results/D*.json")))
kept_ids = {r["id"] for r in R1}
browser_trimmed = [r["id"] for r in TRIM if r["keep"] == "Y" and r["id"] not in kept_ids]

# ----------------------------------------------------------------------------- claim machinery
ROWS = []  # (n, doc, label, claimed, recomputed, ok, source, note)


def norm(s):
    return re.sub(r"\s+", " ", s)


def add(doc, label, claimed, recomputed, source, note=""):
    ok = "NOT FOUND" if claimed is None else ("✓" if claimed == recomputed else "✗")
    ROWS.append((len(ROWS) + 1, doc, label, claimed, recomputed, ok, source, note))


def nums_in(line):
    out = []
    for cell in line.strip().strip("|").split("|")[1:]:
        c = cell.strip().replace("**", "").replace(",", "")
        if re.fullmatch(r"-?\d+", c):
            out.append(int(c))
    return out


def row_claim(doc, prefix, labels, recomputed, source, note=""):
    """Find the table line that starts with `prefix`; compare its integer cells with `recomputed` (list), one claim per cell."""
    line = next((l for l in TXT[doc].split("\n") if l.startswith(prefix)), None)
    got = nums_in(line) if line else []
    for i, (lab, rec) in enumerate(zip(labels, recomputed)):
        add(doc, lab, got[i] if line and i < len(got) else None, rec, source, note if i == 0 else "")


def rx(doc, pattern, labels, recomputed, source, note=""):
    m = re.search(pattern, norm(TXT[doc]))
    for i, (lab, rec) in enumerate(zip(labels, recomputed)):
        claimed = None
        if m:
            g = m.group(i + 1)
            claimed = int(g.replace(",", "")) if re.fullmatch(r"[\d,]+", g) else g
        add(doc, lab, claimed, rec, source, note if i == 0 else "")


# ----------------------------------------------------------------------------- recomputed quantities (round 1)
nB = sum(1 for r in R1 if r["partB_source"])
nB22 = sum(1 for r in R1 if r["partB_source"] and not r["partB_source"].startswith("D"))
nB28 = sum(1 for r in R1 if r["partB_source"].startswith("D"))
nBb = sum(1 for r in R1 if r["partB_blocked"] == "TRUE")
bt_any = [r for r in R1 if r["browser_tier"]]
bt_changed = [r for r in R1 if r["browser_tier"] and r["browser_tier"] != "Browser needed"]
browser_only = [r for r in bt_any if not r["partB_source"]]
rest = [r for r in R1 if not r["partB_source"] and not r["browser_tier"]]
close_left = [i for i in QUEUE if i not in partB_ids]
rest_q = sum(1 for r in rest if r["url_health"] == "blocked")
rest_dead = sum(1 for r in rest if r["url_health"] == "dead")
rest_nourl = sum(1 for r in rest if r["url_health"] == "n.a.")
rest_left = sum(1 for r in rest if r["id"] in close_left)
newly = [r for r in R1 if r["partB_source"].startswith("D")]
newly_ok = [r for r in newly if r["partB_blocked"] != "TRUE"]
newly_bl = [r for r in newly if r["partB_blocked"] == "TRUE"]
moves = Counter((P[r["id"]]["verify_tier"], r["verify_tier"]) for r in R1 if r["id"] in P and P[r["id"]]["verify_tier"] != r["verify_tier"])
B_CHECKS = ["chk_license", "chk_temporal", "chk_recency", "chk_cadence", "chk_version", "chk_unit", "chk_coverage", "chk_access", "chk_join_key", "chk_format_gaia"]
GS = [r for r in R1 if r["verify_tier"] in ("Gold", "Silver")]
theme_gs = Counter(r["theme"] for r in GS)
dn = {d["group"]: d["ids"].split(";") for d in DUPES}
dgroups = [g for g in dn if g.startswith("D")]
dec = Counter(d["decision"] for d in DUPES)
dropped_kept = sum(1 for d in DUPES if d["decision"] in ("same product", "host copy") for a in d["ids"].split(";")[1:] if a in P)
SRC_F = "inventory-refined-2026-10-28.csv"

# ============================================================================= CR: close-report
rx("CR", r"the 2026-10-23 refined set \((\d+) kept rows\)", ["CR 'This assumes': size of the 10-23 refined set"], [len(P)], f"_to_delete/inventory-refined-{PREV}-before-close.csv")
row_claim("CR", "| Harvested |", ["CR funnel: harvested"], [len(rc("_to_delete/harvest-2026-10-20-before-dedupe.csv"))], "_to_delete/harvest-2026-10-20-before-dedupe.csv (rows); = 3,160 + 177 in harvest-removed-duplicates.csv")
row_claim("CR", "| After de-duplication |", ["CR funnel: after de-duplication"], [len(rc("harvest-2026-10-20.csv"))], "harvest-2026-10-20.csv (rows)")
row_claim("CR", "| Curated, or a lead with a stated unit |", ["CR funnel: curated or lead with a stated unit"], [len(TRIM)], "trim-2026-10-22.csv (rows); verify-A-2026-10-21.csv has the same 1,018")
row_claim("CR", "| Kept after trimming |", ["CR funnel: kept after trimming"], [sum(1 for r in TRIM if r["keep"] == "Y")], "trim-2026-10-22.csv (keep = Y)")
row_claim("CR", "| + mirrors", ["CR funnel: mirrors added"], [len(MIR)], f"partB/mirrors-{PREV}.csv (rows)")
row_claim("CR", "| − dropped as duplicates", ["CR funnel: dropped as duplicates"], [dropped_kept], f"dupe-review-{DATE}.csv (alternates that were kept rows in the 10-23 file)")
row_claim("CR", "| − trimmed after a browser check", ["CR funnel: trimmed after a browser check"], [len(browser_trimmed)], "trim-2026-10-22.csv keep=Y rows absent from the refined CSV")
row_claim("CR", "| Kept |", ["CR funnel: kept"], [len(R1)], SRC_F + " (rows)")
rx("CR", r"Read by part B: (\d+) of (\d+)\*\* \(22 Oct: (\d+); 28 Oct: (\d+); blocked at the content step: (\d+)\)",
   ["CR read by part B", "CR … of (kept rows)", "CR … read on 22 Oct", "CR … read on 28 Oct", "CR … blocked at the content step"], [nB, len(R1), nB22, nB28, nBb], SRC_F + " (partB_source, partB_blocked)")
row_claim("CR", "| Checked in a real browser only", ["CR funnel: checked in a browser only, not read by part B"], [len(browser_only)], SRC_F + " (browser_tier set and no partB_source)")
rx("CR", r"Not read: browser queue (\d+), dead (\d+), no URL (\d+), left in the close queue (\d+) \| (\d+) \|",
   ["CR not read: browser queue", "CR not read: dead", "CR not read: no URL", "CR not read: left in the close queue", "CR not read: total"],
   [rest_q, rest_dead, rest_nourl, rest_left, len(rest)], SRC_F + " (no partB_source and no browser_tier; url_health; partB/queue-close.json)",
   "recomputed on rows that are neither read nor browser-checked, so the three lines are disjoint")
rx("CR", r"430 \+ 10 \+ 131 = (\d+)", ["CR 430 + 10 + 131 ="], [nB + len(browser_only) + len(rest)], SRC_F)
rx("CR", r"Verified: Gold (\d+) \+ Silver (\d+)\*\* \| \*\*(\d+)\*\*", ["CR verified: Gold", "CR verified: Silver", "CR verified: total"], [tier["Gold"], tier["Silver"], tier["Gold"] + tier["Silver"]], SRC_F)
rx("CR", r"Browser sample: (\d+) rows visited\. (\d+) were trimmed, leaving (\d+) in the kept set with a `browser_tier`; (\d+) of those had also been read by part B",
   ["CR footnote: rows visited", "CR footnote: trimmed", "CR footnote: kept with a browser_tier", "CR footnote: also read by part B"],
   [sum(1 for b in BSAMP if b["opens"] != "skipped"), len(browser_trimmed), len(bt_any), sum(1 for r in bt_any if r["partB_source"])], f"browser-sample-{DATE}.csv; {SRC_F}")
# tier table
for t in ("Gold", "Silver", "Bronze", "Browser needed", "Failed"):
    row_claim("CR", f"| {t} | ", [f"CR tiers: {t} 10-23", f"CR tiers: {t} 10-28", f"CR tiers: {t} of which shortlist"],
              [ptier[t], tier[t], sum(1 for r in R1 if r["verify_tier"] == t and r["priority"])], f"{SRC_F}; _to_delete/inventory-refined-{PREV}-before-close.csv (priority = shortlist)")
mv_doc = re.search(r"Movements: (.+?)\.\n", TXT["CR"])
mv_claim = {}
if mv_doc:
    for part in mv_doc.group(1).split(", "):
        a, b, n = re.match(r"(.+?) → (.+?): (\d+)", part).groups(); mv_claim[(a, b)] = int(n)
for k in sorted(set(mv_claim) | set(moves), key=lambda k: -moves.get(k, 0)):
    add("CR", f"CR tier movement: {k[0]} → {k[1]}", mv_claim.get(k), moves.get(k, 0), f"{SRC_F} vs 10-23 refined file")
# step 1
qh = lambda f: sum(1 for i in QUEUE if f(P[i]))
rx("CR", r"Queue `partB/queue-close.json`: (\d+) Bronze rows never read", ["CR queue: rows in partB/queue-close.json"], [len(QUEUE)], "partB/queue-close.json")
rx("CR", r"unknown/non-linkable unit \((\d+)\), health 2 needing a count/distance step \((\d+)\), health 2 needing raster \((\d+)\), reference layers \((\d+)\)",
   ["CR queue: health 3, unit unknown/non-linkable", "CR queue: health 2, count/distance step", "CR queue: health 2, raster", "CR queue: reference layers (health 1)"],
   [qh(lambda p: p["health_relevance"] == "3" and p["gaia_fit"] in ("unknown", "not_linkable")), qh(lambda p: p["health_relevance"] == "2" and p["gaia_fit"] == "needs_aggregation"),
    qh(lambda p: p["health_relevance"] == "2" and p["gaia_fit"] == "needs_raster"), qh(lambda p: p["health_relevance"] == "1")], f"partB/queue-close.json + 10-23 refined file")
rx("CR", r"Done: (\d+) of (\d+) in (\d+) agent runs \((\d+) batches\); (\d+) left", ["CR close queue: done", "CR close queue: size", "CR close queue: agent runs", "CR close queue: batches", "CR close queue: left"],
   [sum(1 for i in QUEUE if i in partB_ids), len(QUEUE), len(D_files), len({os.path.basename(f).split("-")[0] for f in D_files}), len(close_left)], "partB/results/D*.json; partB/queue-close.json")
m = re.search(r"\d+ left: (.+?)…", TXT["CR"])
doc_left = m.group(1).split(", ") if m else None
add("CR", "CR close queue: first 12 ids left (in order)", ", ".join(doc_left) if doc_left else None, ", ".join(close_left[:12]), "partB/queue-close.json order", "compared as text")
nt = Counter(r["verify_tier"] for r in newly_ok)
rx("CR", r"Results on the newly read rows: Bronze (\d+), Silver (\d+), Browser needed (\d+), Gold (\d+), Failed (\d+) \(blocked at the content step: (\d+)",
   ["CR newly read: Bronze", "CR newly read: Silver", "CR newly read: Browser needed", "CR newly read: Gold", "CR newly read: Failed", "CR newly read: blocked at the content step"],
   [Counter(r["verify_tier"] for r in newly)["Bronze"], Counter(r["verify_tier"] for r in newly)["Silver"], Counter(r["verify_tier"] for r in newly)["Browser needed"], Counter(r["verify_tier"] for r in newly)["Gold"],
    Counter(r["verify_tier"] for r in newly)["Failed"], len(newly_bl)], SRC_F + " (partB_source starts with D)")
for c in B_CHECKS:
    cnt = Counter(r[c] for r in R1)
    row_claim("CR", f"| `{c}` |", [f"CR part B {c}: {k}" for k in ("pass", "warn", "fail", "n.a.", "not_checked")], [cnt.get(k, 0) for k in ("pass", "warn", "fail", "n.a.", "not_checked")], SRC_F)
for t in sorted(theme_gs):
    row_claim("CR", f"| {t} |", [f"CR Gold/Silver by theme {t}: Gold", f"… Silver", f"… total"],
              [sum(1 for r in GS if r["theme"] == t and r["verify_tier"] == "Gold"), sum(1 for r in GS if r["theme"] == t and r["verify_tier"] == "Silver"), theme_gs[t]], SRC_F)
H = rc("harvest-2026-10-20.csv")
rx("CR", r"Of the (\d+) groups flagged in the harvest, only (\d+) touch a kept row \((\d+) with two or more kept members\)", ["CR dupes: groups flagged in the harvest", "CR dupes: groups touching a kept row", "CR dupes: … with two or more kept members"],
   [len({h["dup_group"] for h in H if h.get("dup_group")}), len(dgroups), sum(1 for g in dgroups if sum(1 for i in dn[g] if i in P) >= 2)], "harvest-2026-10-20.csv (dup_group); dupe-review csv; 10-23 refined ids")
rx("CR", r"added (\d+) groups \(X-numbered\)", ["CR dupes: X groups"], [sum(1 for g in dn if g.startswith("X"))], f"dupe-review-{DATE}.csv")
rx("CR", r"distinct products (\d+), same product (\d+), host copy (\d+)\. Kept rows dropped: (\d+)", ["CR dupes: distinct products", "CR dupes: same product", "CR dupes: host copy", "CR dupes: kept rows dropped"],
   [dec["distinct products"], dec["same product"], dec["host copy"], dropped_kept], f"dupe-review-{DATE}.csv")
rx("CR", r"\| (\d+) groups \| distinct products \|", ["CR dupes table: distinct-product groups"], [dec["distinct products"]], f"dupe-review-{DATE}.csv")
# browser sample paragraph
opens_yes = sum(1 for b in BSAMP if b["opens"].startswith("yes"))
rx("CR", r"25 Browser-needed rows were opened.*?: (\d+) visited, (\d+) opened\.", ["CR browser sample: visited", "CR browser sample: opened"], [sum(1 for b in BSAMP if b["opens"] != "skipped"), opens_yes], f"browser-sample-{DATE}.csv")
rx("CR", r"(\d+) Browser-needed rows were opened", ["CR browser sample: rows sampled"], [len(BSAMP)], f"browser-sample-{DATE}.csv")
applied = Counter(r["browser_tier"] for r in R1 if r["browser_tier"]); applied["Trimmed"] = len(browser_trimmed)
rx("CR", r"suggested status changes were applied: Silver (\d+), Failed (\d+), Trimmed (\d+), Gold (\d+), Bronze (\d+), Browser needed (\d+)",
   ["CR statuses applied: Silver", "CR statuses applied: Failed", "CR statuses applied: Trimmed", "CR statuses applied: Gold", "CR statuses applied: Bronze", "CR statuses applied: Browser needed"],
   [applied["Silver"], applied["Failed"], applied["Trimmed"], applied["Gold"], applied["Bronze"], applied["Browser needed"]], SRC_F + " (browser_tier) + trimmed rows",
   "recomputed = what the refined CSV actually carries, not what browser-sample-2026-10-28.md suggests")
byid = {r["id"]: r for r in R1}
for rid, want in (("us_epa_ejscreen_pedp", "fail"), ("us_ceq_cejst_pedp", "fail"), ("us_hifld_next_pedp", "fail"), ("us_usgs_3dhp", "pass")):
    mm = re.search(r"\| `%s` \|.*?\| (pass|fail) \|" % rid, TXT["CR"])
    add("CR", f"CR mirror licence result: {rid}", mm.group(1) if mm else None, byid[rid]["chk_license"], SRC_F + " (chk_license)")
rx("CR", r"\(`(us_mdc_2024_dormir_study)`\)", ["CR the one Bronze row without a URL"], [", ".join(r["id"] for r in R1 if r["verify_tier"] == "Bronze" and r["url_health"] == "n.a.")], SRC_F + " (Bronze and url_health n.a.)")
rx("CR", r"\((\d+) Summary formulas evaluated; (\d+) mismatches or errors\)", ["CR workbook: Summary formulas evaluated", "CR workbook: mismatches or errors"], [None, 0], f"place-data-inventory-{DATE}.xlsx",
   "recomputed below from the workbook")
# fill the formula count from the 10-28 workbook (all formula cells except the one funnel line =B15+C15, which the 10-28 evaluator did not cover)
import openpyxl
wb_old = openpyxl.load_workbook(os.path.join(D, f"place-data-inventory-{DATE}.xlsx"))
nf_old = sum(1 for row in wb_old["Summary"].iter_rows() for c in row if isinstance(c.value, str) and c.value.startswith("="))
last = ROWS[-2]; ROWS[-2] = (last[0], last[1], last[2], last[3], nf_old - 1, "✓" if last[3] == nf_old - 1 else "✗", last[6], "formula cells in the Summary sheet (243) minus the funnel's =B15+C15, which the 10-28 evaluator did not cover")
rx("CR", r"Part B close run: (\d+) agent runs \(5 rows each\), (\d+) rows; subagent usage as reported by the harness: ([\d.]+)M tokens", ["CR tokens: agent runs", "CR tokens: rows", "CR tokens: total (M)"],
   [len(D_files), len(newly), None], "partB/results/D*.json; partB/usage-close.json")
last = ROWS[-1]; tot = round(sum(USAGE.values()) / 1e6, 2); claimed = float(last[3]) if last[3] is not None else None
ROWS[-1] = (last[0], last[1], last[2], claimed, tot, "✓" if claimed == tot else "✗", last[6], "")
for k in sorted(USAGE):
    mm = re.search(r"%s (\d+)k" % k, TXT["CR"])
    add("CR", f"CR tokens: {k} (k)", int(mm.group(1)) if mm else None, round(USAGE[k] / 1e3), "partB/usage-close.json")
import datetime
mt = sorted(datetime.datetime.fromtimestamp(os.path.getmtime(f), datetime.timezone.utc) for f in D_files)
mm = re.search(r"first D result written (\S+ \S+), last (\S+ \S+) UTC", TXT["CR"])
add("CR", "CR wall time: first D result written (UTC)", mm.group(1) if mm else None, mt[0].strftime("%Y-%m-%d %H:%M"), "partB/results/D*.json (file times)")
add("CR", "CR wall time: last D result written (UTC)", mm.group(2) if mm else None, mt[-1].strftime("%Y-%m-%d %H:%M"), "partB/results/D*.json (file times)")
doms = {x["domain"] for x in BQ}
rx("CR", r"Browser queue: (\d+) rows on (\d+) domains \(`browser-queue-2026-10-28.csv`\), including the (\d+) JavaScript-only pages", ["CR remains: browser queue rows", "CR remains: browser queue domains", "CR remains: JavaScript-only pages found today"],
   [len(BQ), len(doms), len(newly_bl)], f"browser-queue-{DATE}.csv; {SRC_F} (D-batch rows with partB_blocked)")
rx("CR", r"\((\d+) rows at fail\)", ["CR remains: rows at licence fail"], [sum(1 for r in R1 if r["chk_license"] == "fail" and r["partB_blocked"] != "TRUE")], SRC_F + " (chk_license = fail, not blocked)")
rx("CR", r"(\d+) close-queue rows not read", ["CR remains: close-queue rows not read"], [len(close_left)], "partB/queue-close.json")

# ============================================================================= IS: ISSUE update
rx("IS", r"The remaining live, unread datasets \((\d+) rows", ["IS: rows sent to the content check"], [len(newly)], SRC_F)
rx("IS", r"(\d+) of them turned out to be JavaScript-only", ["IS: of them JavaScript-only/challenge"], [len(newly_bl)], SRC_F)
rx("IS", r"(\d+) of (\d+) have been read for content", ["IS: read for content", "IS: … of (kept rows)"], [nB, len(R1)], SRC_F)
for t in ("Gold", "Silver", "Bronze", "Browser needed", "Failed"):
    row_claim("IS", f"| {t} | ", [f"IS tiers: {t} was", f"IS tiers: {t} now"], [ptier[t], tier[t]], SRC_F)
mv_is = re.search(r"Tier movements: (.+?)\.\n", TXT["IS"])
add("IS", "IS tier movements = CR tier movements (text)", mv_is.group(1) if mv_is else None, ", ".join(f"{a} → {b}: {n}" for (a, b), n in sorted(moves.items(), key=lambda x: -x[1])), SRC_F, "compared as text")
VER = [r for r in R1 if r["health_relevance"] in ("2", "3") and r["verify_tier"] in ("Gold", "Silver")]
INV = [r for r in R1 if r["health_relevance"] in ("2", "3") and r["verify_tier"] in ("Bronze", "Browser needed")]
REF = [r for r in R1 if r["health_relevance"] not in ("2", "3") and r["verify_tier"] != "Failed"]
FAIL = [r for r in R1 if r["verify_tier"] == "Failed"]
T_N = sum(1 for r in TRIM if r["keep"] != "Y") + len(browser_trimmed)
OLD = {k: rc(f"ticket-{PREV}/{k}.csv") for k in ("1-verified", "2-to-investigate", "3-reference-layers", "4-trimmed")}
NEW = {k: rc(f"ticket-{DATE}/{k}.csv") for k in OLD}
row_claim("IS", "| `1-verified.csv` |", ["IS files: 1-verified rows", "IS files: 1-verified was"], [len(VER), len(OLD["1-verified"])], f"{SRC_F}; ticket-{PREV}/",
          f"ticket-{DATE}/1-verified.csv has {len(NEW['1-verified'])} rows")
row_claim("IS", "| `2-to-investigate.csv` |", ["IS files: 2-to-investigate rows", "IS files: 2-to-investigate was"], [len(INV), len(OLD["2-to-investigate"])], f"{SRC_F}; ticket-{PREV}/", f"ticket csv has {len(NEW['2-to-investigate'])}")
row_claim("IS", "| `3-reference-layers.csv` |", ["IS files: 3-reference-layers rows", "IS files: 3-reference-layers was"], [len(REF), len(OLD["3-reference-layers"])], f"{SRC_F}; ticket-{PREV}/", f"ticket csv has {len(NEW['3-reference-layers'])}")
row_claim("IS", "| `4-trimmed.csv` |", ["IS files: 4-trimmed rows", "IS files: 4-trimmed was"], [T_N + len(FAIL), len(OLD["4-trimmed"])], f"trim csv + {SRC_F}; ticket-{PREV}/", f"ticket csv has {len(NEW['4-trimmed'])}")
rx("IS", r"trimmed rows plus (\d+) that failed verification and (\d+) dropped as duplicates", ["IS files: failed rows in 4-trimmed", "IS files: dropped as duplicates"], [len(FAIL), dropped_kept], SRC_F)
old_ids = {k: {x.get("id") for x in v} for k, v in OLD.items()}
cls_now = {}
for r in R1:
    cls_now[r["id"]] = "verified" if r in VER else "to investigate" if r in INV else "reference layers" if r in REF else "trimmed or failed"
was = lambda i: "verified" if i in old_ids["1-verified"] else "to investigate" if i in old_ids["2-to-investigate"] else "reference layers" if i in old_ids["3-reference-layers"] else "trimmed or failed" if i in old_ids["4-trimmed"] else "new row"
mvf = Counter((was(i), n) for i, n in cls_now.items() if was(i) != n)
for k, label in ((("to investigate", "verified"), "IS file moves: to investigate → verified"), (("to investigate", "trimmed or failed"), "IS file moves: to investigate → trimmed or failed"), (("reference layers", "trimmed or failed"), "IS file moves: reference layers → trimmed or failed")):
    mm = re.search(r"\| %s \| %s \| (\d+) \|" % k, TXT["IS"])
    add("IS", label, int(mm.group(1)) if mm else None, mvf.get(k, 0), f"{SRC_F}; ticket-{PREV}/ ids",
        "the 3 rows trimmed after the browser check (also moved into 4-trimmed) are not in the doc's move table" if k == ("to investigate", "trimmed or failed") else "")
rx("IS", r"(\d+) datasets sent to the content check on 2026-10-28; (\d+) read, (\d+) blocked", ["IS newly read: sent", "IS newly read: read", "IS newly read: blocked"], [len(newly), len(newly_ok), len(newly_bl)], SRC_F)
rx("IS", r"Of the (\d+) read: Bronze (\d+), Silver (\d+), Gold (\d+), Failed (\d+)", ["IS newly read: n", "IS newly read: Bronze", "IS newly read: Silver", "IS newly read: Gold", "IS newly read: Failed"],
   [len(newly_ok), nt["Bronze"], nt["Silver"], nt["Gold"], nt["Failed"]], SRC_F)
lc = Counter(r["license_class"] for r in R1 if r["license_class"])
rx("IS", r"Licences read on the page now cover (\d+) datasets: unknown (\d+), open (\d+), attribution (\d+), non-commercial (\d+), restricted (\d+), registration (\d+)",
   ["IS licences: datasets covered (licence_confirmed filled)", "IS licences: unknown", "IS licences: open", "IS licences: attribution", "IS licences: non-commercial", "IS licences: restricted", "IS licences: registration"],
   [sum(1 for r in R1 if r["license_confirmed"]), lc["unknown"], lc["open"], lc["attribution"], lc["non-commercial"], lc["restricted"], lc["registration"]], SRC_F + " (license_confirmed, license_class)")
add("IS", "IS licences: sum of the listed classes vs 'cover N datasets'", 205, sum(lc.values()), SRC_F + " (license_class)", "the breakdown is of all rows with a class (incl. 'unknown'), so it does not sum to the 205 in the same sentence")
rx("IS", r"Spatial unit confirmed for (\d+) datasets, corrected for (\d+); years confirmed for (\d+); (\d+) found discontinued", ["IS: unit confirmed (chk_unit pass)", "IS: unit corrected (chk_unit warn)", "IS: years confirmed (chk_temporal pass)", "IS: discontinued/pre-2000 (chk_recency fail)"],
   [sum(1 for r in R1 if r["chk_unit"] == "pass"), sum(1 for r in R1 if r["chk_unit"] == "warn"), sum(1 for r in R1 if r["chk_temporal"] == "pass"), sum(1 for r in R1 if r["chk_recency"] == "fail")], SRC_F)
rx("IS", r"`public_access` flags (\d+) registered or restricted", ["IS: public_access registered/restricted (Gold/Silver/Bronze)"],
   [sum(1 for r in R1 if r["public_access"] in ("registration", "restricted") and r["verify_tier"] in ("Gold", "Silver", "Bronze"))], SRC_F)
rx("IS", r"(\d+) groups reviewed \(`dupe-review-2026-10-28.csv`\): distinct products (\d+), same product (\d+), host copy (\d+)\. Only (\d+) of the (\d+) groups",
   ["IS dupes: groups reviewed", "IS dupes: distinct products", "IS dupes: same product", "IS dupes: host copy", "IS dupes: groups touching a kept row", "IS dupes: groups flagged in the harvest"],
   [len(DUPES), dec["distinct products"], dec["same product"], dec["host copy"], len(dgroups), len({h["dup_group"] for h in H if h.get("dup_group")})], f"dupe-review-{DATE}.csv; harvest-2026-10-20.csv")
rx("IS", r"(\d+) kept rows dropped as duplicates", ["IS dupes: kept rows dropped"], [dropped_kept], f"dupe-review-{DATE}.csv")
oc = Counter(b["opens"] for b in BSAMP)
rx("IS", r"opened 25 Browser-needed rows.*?: (\d+) visited, (\d+) opened fine, (\d+) bot challenge, (\d+) sign-in or gone, (\d+) not found, (\d+) hosts unreachable",
   ["IS browser sample: visited", "IS browser sample: opened fine", "IS browser sample: bot challenge", "IS browser sample: sign-in or gone", "IS browser sample: not found", "IS browser sample: hosts unreachable"],
   [sum(1 for b in BSAMP if b["opens"] != "skipped"), opens_yes, sum(1 for b in BSAMP if "bot challenge" in b["opens"]), sum(1 for b in BSAMP if "login" in b["opens"]),
    sum(1 for b in BSAMP if "404" in b["opens"]), sum(1 for b in BSAMP if "unreachable" in b["opens"])], f"browser-sample-{DATE}.csv")
rx("IS", r"The suggested statuses were applied: Silver (\d+), Failed (\d+), Trimmed (\d+), Gold (\d+), Bronze (\d+), Browser needed (\d+)",
   ["IS statuses applied: Silver", "IS statuses applied: Failed", "IS statuses applied: Trimmed", "IS statuses applied: Gold", "IS statuses applied: Bronze", "IS statuses applied: Browser needed"],
   [applied["Silver"], applied["Failed"], applied["Trimmed"], applied["Gold"], applied["Bronze"], applied["Browser needed"]], SRC_F + " (browser_tier) + trimmed rows")
rx("IS", r"Browser queue: (\d+) rows on (\d+) domains", ["IS: browser queue rows", "IS: browser queue domains"], [len(BQ), len(doms)], f"browser-queue-{DATE}.csv")

# ============================================================================= BS: browser sample
vis = sum(1 for b in BSAMP if b["opens"] != "skipped")
rx("BS", r"Sampled \| 25 \((\d+) already-trimmed HDX rows skipped, so (\d+) visited\)", ["BS: rows skipped", "BS: rows visited"], [sum(1 for b in BSAMP if b["opens"] == "skipped"), vis], f"browser-sample-{DATE}.csv")
add("BS", "BS: rows sampled", 25, len(BSAMP), f"browser-sample-{DATE}.csv")
rx("BS", r"Opened fine in a browser\*\* \| \*\*(\d+) of (\d+) \((\d+)%\)", ["BS: opened fine", "BS: … of visited", "BS: … percent"], [opens_yes, vis, round(100 * opens_yes / vis)], f"browser-sample-{DATE}.csv")
rx("BS", r"Bot challenge \(Cloudflare CAPTCHA\) \| (\d+) ", ["BS: bot challenge"], [sum(1 for b in BSAMP if "bot challenge" in b["opens"])], f"browser-sample-{DATE}.csv")
rx("BS", r"Sign-in required or item gone \| (\d+) ", ["BS: sign-in required or gone"], [sum(1 for b in BSAMP if "login" in b["opens"])], f"browser-sample-{DATE}.csv")
rx("BS", r"Page not found \(404 in a browser too\) \| (\d+) ", ["BS: page not found"], [sum(1 for b in BSAMP if "404" in b["opens"])], f"browser-sample-{DATE}.csv")
rx("BS", r"Host unreachable \| (\d+) ", ["BS: host unreachable"], [sum(1 for b in BSAMP if "unreachable" in b["opens"])], f"browser-sample-{DATE}.csv")
add("BS", "BS: the five result rows add up to the visited rows", vis, 18 + 1 + 1 + 1 + 2 + 0, "table rows above")
wb_ = Counter(b["would_be"] for b in BSAMP if b["opens"].startswith("yes"))
gs_ = sum(v for k, v in wb_.items() if k.startswith(("Gold", "Silver")))
rx("BS", r"Would-be Gold or Silver: (\d+) of (\d+)", ["BS: would-be Gold or Silver", "BS: … of visited"], [gs_, vis], f"browser-sample-{DATE}.csv (would_be column)")
n_gold_text = len(re.findall(r"HUD CHAS|COI 3\.0", re.search(r"\*\*Gold:\*\*.*", TXT["BS"]).group(0)))
add("BS", "BS: rows the text calls Gold (HUD CHAS, COI 3.0)", n_gold_text, sum(v for k, v in wb_.items() if k == "Gold" or k.startswith("Gold if")), f"browser-sample-{DATE}.csv (would_be starts with Gold)")
reclass = sum(1 for b in BSAMP if b["opens"].startswith("yes") and b["would_be"] in ("trim", "Portal", "not linkable", "Bronze"))
rx("BS", r"Should be trimmed or reclassified: (\d+)\.", ["BS: should be trimmed or reclassified"], [reclass], f"browser-sample-{DATE}.csv (would_be: trim, Portal, not linkable, Bronze)")
add("BS", "BS: would-be Gold/Silver + trim/reclassify = rows opened", gs_ + 5, opens_yes, "the two lines above")
lic = [b["license"] for b in BSAMP if b["opens"].startswith("yes")]
rx("BS", r"Open, as stated on the page:\*\* (\d+),", ["BS licences: open as stated (CC BY)"], [sum(1 for l in lic if l.startswith("CC BY"))], f"browser-sample-{DATE}.csv")
rx("BS", r"US government, public domain assumed but not stated:\*\* (\d+)\.", ["BS licences: US government, public domain assumed"], [sum(1 for l in lic if "assumed" in l)], f"browser-sample-{DATE}.csv")
rx("BS", r"Restricted:\*\* (\d+)\.", ["BS licences: restricted (non-commercial, cite-as, commercial)"], [sum(1 for l in lic if any(w in l for w in ("non-commercial", "cite-as", "commercial / proprietary")))], f"browser-sample-{DATE}.csv")
rx("BS", r"Not seen on the landing page:\*\* (\d+)\.", ["BS licences: not seen on the landing page"], [sum(1 for l in lic if l in ("not seen", "not stated") or l.startswith("not stated"))], f"browser-sample-{DATE}.csv")
rx("BS", r"remaining ~(\d+) queue rows", ["BS: remaining queue rows (10-23 queue minus the 25 sampled)"], [len(BQ_OLD) - len(BSAMP)], f"browser-queue-{PREV}.csv (130 rows) minus the sample")
# the suggested-status table: does the refined CSV carry each status?
tbl = {}
for line in TXT["BS"].split("\n"):
    mm = re.match(r"\| (.+?) \| Browser needed \| (Silver|Gold|Trimmed|Bronze|Failed|Browser needed)", line)
    if mm:
        for i in re.split(r",\s*", mm.group(1)):
            tbl[i.strip()] = mm.group(2)
actual = {i: ("Trimmed" if i in browser_trimmed else byid[i]["browser_tier"] if i in byid else "(not in refined CSV)") for i in tbl}
add("BS", "BS suggested-status table: rows listed (25 sampled − 2 skipped − 1 with no suggestion)", 22, len(tbl), "browser-sample md table")
add("BS", "BS suggested statuses carried in the refined CSV (rows where browser_tier / trim = suggestion)", len(tbl), sum(1 for i in tbl if actual[i] == tbl[i]), SRC_F + " (browser_tier); trim csv",
    "differences: " + "; ".join(f"{i}: suggested {tbl[i]}, refined CSV {actual[i] or 'no browser_tier (tier ' + byid[i]['verify_tier'] + ')'}" for i in tbl if actual[i] != tbl[i]))
OBS = []
bm = Counter(was(i) for i in browser_trimmed)
OBS.append("IS file-move table: the " + str(len(browser_trimmed)) + " rows trimmed by the browser check also moved into `4-trimmed.csv` (from: " + ", ".join(f"{k} {v}" for k, v in bm.items()) + "), but the table counts only the Failed-tier rows (7 + 1), so it omits them.")
egis = "us_hud_egis_open_data"
OBS.append(f"BS says `{egis}` (HUD eGIS) 'a portal, not a dataset' should be trimmed or reclassified, but it has no row in the suggested-status table and the refined CSV still has it at {byid[egis]['verify_tier']} (browser_tier empty).")
OBS.append("BS says Gold: HUD CHAS and COI 3.0; its own suggested-status table (and the refined CSV) make only HUD CHAS Gold, and COI Silver.")

# ============================================================================= R2: round 2 report
new_ids = [r["id"] for r in R2]
kept2 = sum(1 for c in CAND if c["keep"] == "Y")
row_claim("R2", "| Candidates written by the sweep |", ["R2: candidates written by the sweep"], [len(CAND)], f"round2/round2-candidates-{DATE}.csv")
row_claim("R2", "| Kept after the trim rules", ["R2: kept after the trim rules"], [kept2], f"round2/round2-candidates-{DATE}.csv (keep = Y)")
row_claim("R2", "| Already in inventory", ["R2: already in inventory"], [sum(1 for c in CAND if c["already_in_inventory"])], f"round2/round2-candidates-{DATE}.csv (already_in_inventory)")
row_claim("R2", "| **New**", ["R2: new rows"], [len(R2)], f"inventory-combined-{DATE}.csv (round = 2-pilot)")
m = re.search(r"(?i)already in inventory.*?= `(\w+)`", TXT["R2"])
add("R2", "R2: the round 1 id the HRSA candidate matches", m.group(1) if m else None, next(c["already_in_inventory"] for c in CAND if c["already_in_inventory"]), f"round2/round2-candidates-{DATE}.csv")
rx("R2", r"Also recognised as round-1 products and not written as rows \| (\d+) \(", ["R2: recognised as round-1 products and not written"], [len(META["sweep1-facilities"]["overlap_round1"])], "round2/sweeps-meta.json (overlap_round1)")
mt1 = META["sweep1-facilities"]
t0 = datetime.datetime.strptime(mt1["started"], "%Y-%m-%dT%H:%M:%SZ"); t1 = datetime.datetime.strptime(mt1["finished"], "%Y-%m-%dT%H:%M:%SZ")
rx("R2", r"cap 30; (\d+) searches, (\d+) pages read, (\d+) minutes, 2026-10-28 (\d\d:\d\d) to (\d\d:\d\d) UTC", ["R2 sweep 1: searches", "R2 sweep 1: pages read", "R2 sweep 1: minutes", "R2 sweep 1: start (UTC)", "R2 sweep 1: end (UTC)"],
   [mt1["searches_run"], mt1["pages_fetched"], round((t1 - t0).total_seconds() / 60), t0.strftime("%H:%M"), t1.strftime("%H:%M")], "round2/sweeps-meta.json")
cov_claim = re.search(r"Coverage of the 24 new rows: (.+?)\. Confidence", norm(TXT["R2"]))
pref = Counter(i.split("_")[0] for i in new_ids)
names = {"US": "us", "GB": "gb", "CA": "ca", "AU": "au", "NZ": "nz", "DE": "de", "FR": "fr", "ES": "es", "BR": "br", "IN": "in", "KE": "ke", "NG": "ng", "sub-Saharan Africa": "ssa", "SL": "sl", "ZM": "zm", "global": "global"}
for label, pf in names.items():
    mm = re.search(r"(?:^|, )%s (\d+)(?: \(|,|$)" % re.escape(label), cov_claim.group(1)) if cov_claim else None
    add("R2", f"R2 coverage: {label}", int(mm.group(1)) if mm else None, pref.get(pf, 0), f"inventory-combined-{DATE}.csv (id prefix)")
add("R2", "R2 coverage: the sixteen groups add up to the new rows", len(R2), sum(pref.values()), f"inventory-combined-{DATE}.csv")
cf24 = Counter(r["confidence"] for r in R2)
rx("R2", r"Confidence: high (\d+), medium (\d+), low (\d+)", ["R2 confidence: high", "R2 confidence: medium", "R2 confidence: low"], [cf24["high"], cf24["medium"], cf24["low"]], f"inventory-combined-{DATE}.csv (24 new rows)",
   f"the 25 candidates give high {Counter(c['confidence'] for c in CAND)['high']}, medium {Counter(c['confidence'] for c in CAND)['medium']}, low {Counter(c['confidence'] for c in CAND)['low']}")
add("R2", "R2: all 24 are point or address data (finest_unit)", 24, sum(1 for r in R2 if r["finest_unit"] in ("point", "address")), f"inventory-combined-{DATE}.csv")
add("R2", "R2: all 24 have gaia_fit = needs_aggregation", 24, sum(1 for r in R2 if r["gaia_fit"] == "needs_aggregation"), f"inventory-combined-{DATE}.csv")
uh = Counter(r["url_health"] for r in R2)
row_claim("R2", "| healthy |", ["R2 link health: healthy"], [uh["healthy"]], f"round2/verify-A-{DATE}.csv")
row_claim("R2", "| degraded |", ["R2 link health: degraded"], [uh["degraded"]], f"round2/verify-A-{DATE}.csv")
row_claim("R2", "| blocked |", ["R2 link health: blocked"], [uh["blocked"]], f"round2/verify-A-{DATE}.csv")
hy = [a for a in RA if a["url_health"] == "healthy"]
rx("R2", r"(\d+) of them also pass the access-URL check", ["R2 link health: healthy rows that 'pass the access-URL check' (strict: chk_access_url = pass)"], [sum(1 for a in hy if a["chk_access_url"] == "pass")], f"round2/verify-A-{DATE}.csv",
   f"chk_access_url among the 14 healthy rows: {dict(Counter(a['chk_access_url'] for a in hy))}; pass + n.a. = {sum(1 for a in hy if a['chk_access_url'] in ('pass', 'n.a.'))}")
named7 = {"us_cms_dialysis_facility_listing", "us_cms_home_health_care_agencies", "us_cms_hospice_general_information", "us_cms_nppes_npi_file", "gb_cqc_care_directory", "es_sanidad_catalogo_nacional_hospitales", "br_datasus_cnes_estabelecimentos"}
add("R2", "R2: the 7 degraded rows are the 3 CMS + NPPES, CQC, Spain, CNES it names", 7, len(named7 & {a["id"] for a in RA if a["url_health"] == "degraded"}), f"round2/verify-A-{DATE}.csv")
add("R2", "R2: CMS provider-data download URLs that answer 404 (dialysis, home health, hospice)", 3, sum(1 for a in RA if a["id"].startswith("us_cms_") and "404" in a["chk_access_url_detail"]), f"round2/verify-A-{DATE}.csv")
add("R2", "R2: the four rows said to have no machine-readable metadata (NPPES, CQC, Spain, CNES) have chk_machine_metadata = fail", 4,
    sum(1 for a in RA if a["id"] in ("us_cms_nppes_npi_file", "gb_cqc_care_directory", "es_sanidad_catalogo_nacional_hospitales", "br_datasus_cnes_estabelecimentos") and a["chk_machine_metadata"] == "fail"), f"round2/verify-A-{DATE}.csv")
add("R2", "R2: withdrawn pages", 0, sum(1 for a in RA if a["chk_withdrawn"] != "pass" and a["chk_withdrawn"] not in ("not_checked", "n.a.")), f"round2/verify-A-{DATE}.csv (chk_withdrawn warn or fail)")
rx("R2", r"Wayback snapshots exist for (\d+) of (\d+)", ["R2: Wayback snapshots exist for", "R2: … of"], [sum(1 for a in RA if a["wayback_url"]), len(RA)], f"round2/verify-A-{DATE}.csv (wayback_url)")
rx("R2", r"(\d+) log entries in `verify-log-round2.csv`", ["R2: log entries in verify-log-round2.csv"], [len(RLOG)], "round2/verify-log-round2.csv")
rx("R2", r"run `(A-round2-\d+)`, ([\d.]+) minutes", ["R2: run id", "R2: run minutes"], [RLOG[0]["run_id"], None], "round2/verify-log-round2.csv; round2/verify-A-run.log")
mm = re.search(r"done: \d+ rows, ([\d.]+) min", rt("round2/verify-A-run.log"))
last = ROWS[-1]; ROWS[-1] = (last[0], last[1], last[2], float(last[3]) if last[3] is not None else None, float(mm.group(1)), "✓" if last[3] is not None and float(last[3]) == float(mm.group(1)) else "✗", last[6], "")
core7 = ["chk_link_live", "chk_redirect", "chk_tls", "chk_soft404", "chk_withdrawn", "chk_access_url"]
strict = sum(1 for a in RA if a["checks_warned"] == "0" and a["checks_failed"] == "0")
core = sum(1 for a in RA if all(a[c] in ("pass", "n.a.") for c in core7))
core_h = sum(1 for a in RA if all(a[c] in ("pass", "n.a.") for c in core7) and a["url_health"] == "healthy")
rx("R2", r"(\d+) pass every link check", ["R2: rows that 'pass every link check' (strict: no warn or fail among all ten checks)"], [strict], f"round2/verify-A-{DATE}.csv",
   f"round2/verify-A-report-{DATE}.md says all_passing_A is 0 of 24")
add("R2", "R2: same claim, reading 'every link check' as the first six checks (live, redirect, TLS, soft-404, withdrawn, access URL) at pass or n.a., among the 14 healthy rows", 13, core_h, f"round2/verify-A-{DATE}.csv", f"the report does not define the term; over all 24 rows the same reading gives {core}")
n_rbq = len(RBQ)
said = "These are in `browser-queue-2026-10-28.csv`" in TXT["R2"]
add("R2", "R2: blocked rows said to be in round2/browser-queue-2026-10-28.csv (NHS ODS DSE, Health NZ, KMHFL)", 3 if said else None, n_rbq, f"round2/browser-queue-{DATE}.csv", f"queue file lists: {', '.join(x['id'] for x in RBQ)}")
for k, rows_, fin in (("sweeps/sweep2-transport.json", 15, True), ("sweeps/sweep3-hazards.json", 4, False)):
    j = json.load(open(os.path.join(D, "round2", k), encoding="utf-8"))
    add("R2", f"R2: {k.split('/')[1]} rows", rows_, len(j["rows"]), f"round2/{k}")
    add("R2", f"R2: {k.split('/')[1]} marked finished (1 = yes)", 1 if fin else 0, 1 if (j.get("status", "").startswith("complete")) else 0, f"round2/{k} (status)")
rx("R2", r"`round2-candidates-2026-10-28.csv` \((\d+) rows", ["R2 files: rows in round2-candidates csv"], [len(CAND)], f"round2/round2-candidates-{DATE}.csv")
rx("R2", r"inventory-refined-2026-10-28.csv` \((\d+) rows", ["R2 'This assumes': rows in inventory-refined-2026-10-28.csv"], [len(R1)], SRC_F,
   "the 574 is the 10-23 file (before the 3 browser-check trims); the 10-28 file has 571")
mm = re.search(r"(\d+) of 25 candidates were new", norm(TXT["R2"]))
add("R2", "R2: 'of 25 candidates were new'", int(mm.group(1)) if mm else None, len(R2), f"inventory-combined-{DATE}.csv")
rd = rt("README.md")
OBS.append("`README.md` status paragraph (not one of the four reports): says " + ("430 of 574 rows" if "430 of 574" in rd else "?") + " and " + ("256 of 22 Oct" if "256 of 22 Oct" in rd else "?") + "; the files give " + str(nB) + " of " + str(len(R1)) + " and " + str(nB22) + ". Left as is (outside the four reports); the old STATUS.md row had the same 574.")
OBS.append(f"R2 says the Scottish hospital codes file (`gb_phs_hospital_codes`) 'could join as a table now', but the row carries gaia_fit = {next(r['gaia_fit'] for r in R2 if r['id']=='gb_phs_hospital_codes')} like the other 23 (the sweep's field, not changed here).")

# ----------------------------------------------------------------------------- write numbers-check-2026-10-28.md
n_ok = sum(1 for r in ROWS if r[5] == "✓"); bad = [r for r in ROWS if r[5] != "✓"]
cell = lambda v: "" if v is None else str(v).replace("|", "/").replace("\n", " ")
out = [f"# Numbers check ({DATE})", "",
       f"**This assumes:** the four reports below are checked as they stand; every recomputed value comes from the CSV/JSON files named in the last column (`inventory-refined-{DATE}.csv`, `inventory-combined-{DATE}.csv`, `_to_delete/inventory-refined-{PREV}-before-close.csv` for the earlier counts, the part B results, the round 2 files); a mismatch is fixed in the markdown only when it is a clear typo, otherwise it is listed under 'Needs Robert'.", "",
       f"Script: `scripts/numbers_check_2026_10_28.py` (re-runnable; reads each claim out of the document text). **{len(ROWS)} claims checked: {n_ok} match, {len(bad)} do not.**", "",
       "Files: CR = `close-report-2026-10-28.md`; IS = `ticket-2026-10-28/ISSUE-update-2026-10-28.md`; BS = `browser-sample-2026-10-28.md`; R2 = `round2/round2-report-2026-10-28.md`.", "",
       "## The counts named in the brief", "",
       "| claim | file | claimed | recomputed | match |", "|---|---|---|---|---|"]
BRIEF = ["CR funnel: harvested", "CR funnel: after de-duplication", "CR funnel: curated or lead with a stated unit", "CR funnel: kept after trimming", "CR funnel: kept",
         "CR read by part B", "CR not read: total", "CR not read: browser queue", "CR not read: dead", "CR not read: no URL", "CR not read: left in the close queue",
         "CR funnel: checked in a browser only, not read by part B", "CR verified: total", "CR browser sample: visited", "CR browser sample: opened", "R2: new rows",
         "R2 link health: healthy", "R2 link health: degraded", "R2 link health: blocked"]
for lab in BRIEF:
    r = next(x for x in ROWS if x[2] == lab)
    out.append(f"| {r[2]} | {DOCS[r[1]]} | {cell(r[3])} | {cell(r[4])} | {r[5]} |")
for t in ("Gold", "Silver", "Bronze", "Browser needed", "Failed"):
    r = next(x for x in ROWS if x[2] == f"CR tiers: {t} 10-28")
    out.append(f"| CR tiers: {t} | {DOCS['CR']} | {cell(r[3])} | {cell(r[4])} | {r[5]} |")
out += ["", f"## Mismatches ({len(bad)})", "", "| # | claim | file | claimed | recomputed | note |", "|---|---|---|---|---|---|"]
for r in bad:
    out.append(f"| {r[0]} | {cell(r[2])} | {DOCS[r[1]]} | {cell(r[3]) or 'NOT FOUND'} | {cell(r[4])} | {cell(r[7])} |")
out += ["", "## Fixed in the markdown", "", "FIXED_PLACEHOLDER", "", "## Needs Robert", "", "ROBERT_PLACEHOLDER", "", "## Also noticed (not counts)", ""] + [f"- {o}" for o in OBS]
out += ["", f"## All {len(ROWS)} claims", "", "| # | claim | file | claimed | recomputed | match | source / note |", "|---|---|---|---|---|---|---|"]
for r in ROWS:
    out.append(f"| {r[0]} | {cell(r[2])} | {DOCS[r[1]]} | {cell(r[3]) or ('NOT FOUND' if r[5] == 'NOT FOUND' else '')} | {cell(r[4])} | {r[5]} | {cell(r[6])}{'; ' + cell(r[7]) if r[7] else ''} |")
FIXED = ["None. Every mismatch below is a stale or loosely worded figure, not a one-character slip, so none was edited. (The 'Failed 4' line, the licence sentence and the round 2 figures need a decision or the right definition.)"]
ROBERT = [
    "1. **Browser-sample statuses: 'Failed 4' is really 3** (CR 'Browser sample' paragraph; IS 'Browser sample' bullet). The refined CSV carries Silver 12, Failed 3, Gold 1, Bronze 1, Browser needed 1 (+ 3 trimmed). `us_hud_public_housing_developments` was suggested Failed ('login required / may be gone') but was never applied: the refine script only applies browser rows whose `opens` starts with yes or no. It is still Browser needed; `us_hud_egis_open_data` ('a portal, not a dataset', BS) has no suggested status and is also still Browser needed. Either apply Failed (and decide eGIS), which moves the tier counts (public housing alone: Browser needed 149, Failed 41), or change the text to 'Failed 3'. I changed neither, because the 33 / 156 / 192 / 150 / 40 tier counts are quoted everywhere.",
    "2. **IS licence sentence**: 'Licences read on the page now cover 205 datasets: unknown 184, open 105, ...' The classes add up to 361, not 205. The 205 are the rows with a `license_confirmed` value: open 105, attribution 26, non-commercial 19, restricted 15, registration 11, one mixed Census/GEOSTAT row, and 28 whose class is 'unknown'. The other 156 of the 184 'unknown' have no licence statement at all (they are the `chk_license` fails). Suggested wording: 'Licences found on the page cover 205 datasets (open 105, attribution 26, non-commercial 19, restricted 15, registration 11, 28 unclassified, 1 mixed); 156 more were read and state none'.",
    "3. **R2 confidence counts**: the report says high 7, medium 11, low 6; the data give high 5, medium 12, low 7 for the 24 new rows (6 / 12 / 7 for all 25 candidates). The 'low' rows are not only the three blocked ones.",
    "4. **R2 'also pass the access-URL check'**: 13 of the 14 healthy rows is only true if n.a. counts as a pass. Strictly 9 pass, 4 have no access URL (n.a.), 1 warns.",
    "5. **R2 'all-pass' / '13 pass every link check'**: `verify-A-report-2026-10-28.md` says 0 of 24 pass every applicable check (persistent ID and Wayback checks warn or fail on nearly all). 13 is reproduced only by reading it as the first six checks (live, redirect, TLS, soft-404, withdrawn, access URL) among the healthy rows. The report should say which reading it means before 'all-pass' is quoted for FINESS and the Geoscience Australia layer.",
    "6. **R2 browser queue**: the report says the three blocked rows (NHS ODS DSE, Health NZ, KMHFL Kenya) are in `round2/browser-queue-2026-10-28.csv`; the file has 2 rows (KMHFL, the timeout, is missing; `verify-A-run.log` also says 2). Add KMHFL to the queue file, or reword.",
    "7. **R2 'This assumes' line**: 'inventory-refined-2026-10-28.csv (574 rows, the same ids as the 10-23 file)'. The 10-28 file has 571 rows (574 is the 10-23 file; three rows were trimmed after the browser check). The same wording is in the `merge_round2.py` comment. Suggested text: '(571 rows: the 574 ids of the 10-23 file less the three trimmed after the browser check)'.",
    "8. **BS Gold wording**: 'Gold: HUD CHAS ..., COI 3.0 (promote once the license is confirmed)' names two Gold, but its own suggested-status table (and the refined CSV) make COI Silver and only HUD CHAS Gold. The 13 total is right either way.",
]
NL = chr(10)
out = [(NL.join(FIXED) if l == "FIXED_PLACEHOLDER" else NL.join(ROBERT) if l == "ROBERT_PLACEHOLDER" else l) for l in out]
path = os.path.join(D, f"numbers-check-{DATE}.md")
prev = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
print(f"{len(ROWS)} claims: {n_ok} match, {len(bad)} do not", file=sys.stderr)
for r in bad:
    print(f"  #{r[0]} {r[5]} {r[2]}: claimed {r[3]!r} recomputed {r[4]!r}", file=sys.stderr)
