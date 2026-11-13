#!/usr/bin/env python3
"""Simulated monitor networks sampling a known exposure field, persons to assign them to, and the answer key.

  monitors/build_monitors.py [--out monitors/data]      (needs numpy)

The field is the 1 km Gaussian random field of the raster example plus its annual trend (the annual layers), over the same
10 km window around downtown Los Angeles (EPSG:5070). 200 monitors are placed at random, at least MIN_SEP apart; the networks of
20, 60 and 200 monitors are nested (the first n). A monitor reads the true field at its site plus noise, once a year 2014-2019.
The persons are the raster example's 500 test points, living at the point 2014-2019.

Outputs (data/):
  monitors_{20,60,200}.csv          catalog sources: monitor_id, WKT point (lon/lat), annual jsonb series
  monitor_sites.csv                 id, x/y (EPSG:5070), lon/lat of the 200 sites
  expected_monitor_assignment.csv   the answer key: nearest monitor, distance, monitors in range, nearest and k=3 inverse-distance values (planar distances in EPSG:5070) per network, point and year
  monitor_error_summary.csv         error of the estimators against the true field, per network
"""
import argparse, csv, json, math, os, random, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "raster"))
from build_synthetic_rasters import (MEAN, SD, XMIN, XMAX, YMIN, YMAX, CX, CY, HALF_WINDOW, YEARS, TREND_BASE, TREND_GRADIENT,
                                     from_5070, load_features, unit_field)

SEED = 20261113
NETWORKS = [20, 60, 200]
MIN_SEP = 150.0
NOISE_SD = 0.3
RADII = [1000.0, 2500.0]
IDW_K, IDW_POWER = 3, 2.0
POINTS_CSV = os.path.join(HERE, "..", "raster", "data", "raster_test_points.csv")
FEAT = None


def truth(x, y, year):
    """The true annual exposure at (x, y): the 1 km field plus the trend that grows from west to east."""
    global FEAT
    if FEAT is None:
        FEAT = load_features(1000.0)
    x = np.atleast_1d(np.asarray(x, dtype=float)); y = np.atleast_1d(np.asarray(y, dtype=float))
    field = MEAN + SD * unit_field(FEAT, x, y)
    return field + (TREND_BASE + TREND_GRADIENT * (x - XMIN) / (2 * HALF_WINDOW)) * (year - YEARS[0])


def place_monitors(n, rng):
    sites = []
    while len(sites) < n:
        x, y = rng.uniform(XMIN, XMAX), rng.uniform(YMIN, YMAX)
        if all(math.hypot(x - a, y - b) >= MIN_SEP for a, b in sites):
            sites.append((x, y))
    return np.array(sites)


def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--out", default=os.path.join(HERE, "data"))
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
    rng = random.Random(SEED); nrng = np.random.default_rng(SEED)
    sites = place_monitors(max(NETWORKS), rng)
    obs = np.stack([truth(sites[:, 0], sites[:, 1], yr) + nrng.normal(0, NOISE_SD, len(sites)) for yr in YEARS], axis=1)   # (200, 6)
    ll = [from_5070(x, y) for x, y in sites]

    with open(os.path.join(a.out, "monitor_sites.csv"), "w", newline="") as fh:
        w = csv.writer(fh); w.writerow(["monitor_id", "x_5070", "y_5070", "longitude", "latitude"])
        for i, ((x, y), (lo, la)) in enumerate(zip(sites, ll), 1):
            w.writerow([i, f"{x:.3f}", f"{y:.3f}", f"{lo:.9f}", f"{la:.9f}"])
    for n in NETWORKS:
        with open(os.path.join(a.out, f"monitors_{n}.csv"), "w", newline="") as fh:
            w = csv.writer(fh); w.writerow(["monitor_id", "wkt", "pm25_monitor"])
            for i in range(n):
                series = json.dumps({f"{yr}-01-01/{yr}-12-31": round(float(obs[i, k]), 4) for k, yr in enumerate(YEARS)}, separators=(",", ":"))
                w.writerow([i + 1, f"POINT ({ll[i][0]:.9f} {ll[i][1]:.9f})", series])
    obs = np.round(obs, 4)   # the key uses the published values

    with open(POINTS_CSV) as fh:
        pts = [(int(r["point_id"]), float(r["x_5070"]), float(r["y_5070"])) for r in csv.DictReader(fh)]
    px = np.array([p[1] for p in pts]); py = np.array([p[2] for p in pts])
    tru = np.stack([truth(px, py, yr) for yr in YEARS], axis=1)   # (500, 6)

    rows, summary = [], []
    for n in NETWORKS:
        d = np.hypot(px[:, None] - sites[None, :n, 0], py[:, None] - sites[None, :n, 1])   # (500, n)
        order = np.argsort(d, axis=1, kind="stable")
        near = order[:, 0]; d1 = d[np.arange(len(pts)), near]; d2 = d[np.arange(len(pts)), order[:, 1]]
        est = {"network_mean": np.repeat(obs[:n].mean(axis=0, keepdims=True), len(pts), axis=0), "nearest": obs[near]}
        for r in RADII:
            m = d <= r
            cnt = m.sum(axis=1)
            mean = np.where(cnt[:, None] > 0, (m[:, :, None] * obs[None, :n, :]).sum(axis=1) / np.maximum(cnt, 1)[:, None], np.nan)
            est[f"mean_within_{int(r)}m"] = mean
        k = order[:, :IDW_K]; dk = np.take_along_axis(d, k, axis=1); wk = 1.0 / np.maximum(dk, 1e-6) ** IDW_POWER
        est[f"idw_k{IDW_K}"] = (wk[:, :, None] * obs[k]).sum(axis=1) / wk.sum(axis=1)[:, None]
        for j, (pid, x, y) in enumerate(pts):
            for kk, yr in enumerate(YEARS):
                rows.append([pid, n, yr, near[j] + 1, f"{d1[j]:.3f}", f"{d2[j] - d1[j]:.3f}", f"{obs[near[j], kk]:.4f}", f"{tru[j, kk]:.6f}",
                             int((d[j] <= RADII[0]).sum()), int((d[j] <= RADII[1]).sum()), f"{est[f'idw_k{IDW_K}'][j, kk]:.4f}"])
        for name, e in est.items():
            ok = ~np.isnan(e[:, 0]); err = e[ok] - tru[ok]
            # correlation within each year (the years differ by the trend), averaged; undefined for a constant estimate
            cor = "" if name == "network_mean" else f"{np.mean([np.corrcoef(e[ok][:, k], tru[ok][:, k])[0, 1] for k in range(len(YEARS))]):.4f}"
            summary.append([n, name, int(ok.sum()), f"{math.sqrt(float((err ** 2).mean())):.4f}", f"{float(err.mean()):.4f}", cor])
    with open(os.path.join(a.out, "expected_monitor_assignment.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["point_id", "network", "year", "nearest_monitor_id", "distance_m", "tie_margin_m", "monitor_value", "true_value", "monitors_within_1000m", "monitors_within_2500m", "idw_k3_value"])
        w.writerows(rows)
    with open(os.path.join(a.out, "monitor_error_summary.csv"), "w", newline="") as fh:
        w = csv.writer(fh); w.writerow(["network", "estimator", "persons_with_estimate", "rmse", "bias", "correlation_within_year"]); w.writerows(summary)
    print(f"wrote {len(NETWORKS)} networks ({', '.join(map(str, NETWORKS))} monitors), {len(pts)} persons x {len(YEARS)} years to {a.out}")
    for r in summary: print("  ", *r)


if __name__ == "__main__":
    main()
