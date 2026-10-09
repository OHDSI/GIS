#!/usr/bin/env python3
"""Fails unless the exposure rows agree with the independent answer key (exposure_agreement.csv written by benchmark/exposure_agreement.R)."""
import csv, sys

TOLERANCE = 1e-9
rows = list(csv.DictReader(open(sys.argv[1])))
by = {}
for r in rows:
    by.setdefault(r["exposure"], {})[r["metric"]] = float(r["value"])
failures = []
if len(by) < 2:
    failures.append(f"expected PM2.5 and SES blocks, found {len(by)}")
for name, m in by.items():
    key, matched = m["rows in the answer key"], m["rows matched on person, location and interval"]
    if key == 0 or m["rows derived by Gaia"] != key: failures.append(f"{name}: {m['rows derived by Gaia']:.0f} derived rows against {key:.0f} in the key")
    if matched != key: failures.append(f"{name}: only {matched:.0f} of {key:.0f} rows matched on person, location and interval")
    if m["rows only in the key (missing from Gaia)"] or m["rows only in Gaia (not in the key)"]: failures.append(f"{name}: rows missing or extra")
    if m["matched rows with the same value (within 1e-9)"] != matched: failures.append(f"{name}: values differ")
    if m["maximum absolute difference in value"] > TOLERANCE: failures.append(f"{name}: maximum value difference {m['maximum absolute difference in value']:.3g}")
    if m["maximum absolute difference in the person-level day-weighted mean"] > TOLERANCE: failures.append(f"{name}: person-level mean differs")
    if m["persons compared"] != 10000: failures.append(f"{name}: {m['persons compared']:.0f} persons compared, expected 10,000")
if failures:
    print("Exposure agreement check FAILED:\n  " + "\n  ".join(failures)); sys.exit(1)
print("Exposure agreement check passed:", {k: int(v["rows in the answer key"]) for k, v in by.items()})
