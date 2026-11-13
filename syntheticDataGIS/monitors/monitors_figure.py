#!/usr/bin/env python3
"""Figure for the monitors example: Voronoi cells of the 60-monitor network, the error of the estimators by network size, and
what the buffer join gives a person.

  monitors/monitors_figure.py [--out rmd/images/monitors_voronoi.png]   (needs numpy and matplotlib)
"""
import argparse, csv, json, os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__)); DATA = os.path.join(HERE, "data")
ap = argparse.ArgumentParser()
ap.add_argument("--out", default=os.path.join(HERE, "..", "..", "rmd", "images", "monitors_voronoi.png"))
ap.add_argument("--network", type=int, default=60); ap.add_argument("--year", type=int, default=2014)
a = ap.parse_args()

sites = {int(r["monitor_id"]): (float(r["x_5070"]), float(r["y_5070"])) for r in csv.DictReader(open(os.path.join(DATA, "monitor_sites.csv")))}
vals = {}
for r in csv.DictReader(open(os.path.join(DATA, f"monitors_{a.network}.csv"))):
    vals[int(r["monitor_id"])] = json.loads(r["pm25_monitor"])[f"{a.year}-01-01/{a.year}-12-31"]
ids = sorted(vals); xy = np.array([sites[i] for i in ids]); v = np.array([vals[i] for i in ids])
cx, cy = xy[:, 0].mean(), xy[:, 1].mean()
allx = np.array([p[0] for p in sites.values()]); ally = np.array([p[1] for p in sites.values()])
x0, x1 = (allx.min() + allx.max()) / 2 - 5000, (allx.min() + allx.max()) / 2 + 5000
y0, y1 = (ally.min() + ally.max()) / 2 - 5000, (ally.min() + ally.max()) / 2 + 5000

summary = list(csv.DictReader(open(os.path.join(DATA, "monitor_error_summary.csv"))))
key = list(csv.DictReader(open(os.path.join(DATA, "expected_monitor_assignment.csv"))))
networks = sorted({int(r["network"]) for r in summary})

fig, axes = plt.subplots(1, 3, figsize=(10.5, 3.6), constrained_layout=True, gridspec_kw={"width_ratios": [1.15, 1, 1]})

# (a) the cells: the nearest monitor of every location of the window
ax = axes[0]
g = 400
gx = np.linspace(x0, x1, g); gy = np.linspace(y1, y0, g)
X, Y = np.meshgrid(gx, gy)
d = np.hypot(X[..., None] - xy[:, 0], Y[..., None] - xy[:, 1]); lab = d.argmin(axis=2)
im = ax.imshow(v[lab], extent=(x0, x1, y0, y1), cmap="viridis", interpolation="nearest")
edges = (lab[:, 1:] != lab[:, :-1])[:-1, :] | (lab[1:, :] != lab[:-1, :])[:, :-1]
ax.imshow(np.where(edges, 1.0, np.nan), extent=(x0, x1, y0, y1), cmap="gray_r", vmin=0, vmax=1.6, interpolation="nearest")
ax.plot(xy[:, 0], xy[:, 1], "o", ms=2.6, mfc="white", mec="black", mew=0.5)
ax.set_xticks([]); ax.set_yticks([]); ax.set_aspect("equal")
ax.set_title(f"{a.network} monitors and their Voronoi cells ({a.year})", fontsize=9)
cb = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.02); cb.set_label("PM2.5 of the monitor (ug/m3)", fontsize=8); cb.ax.tick_params(labelsize=7)

# (b) error of the estimators against the true field
ax = axes[1]
names = [("network_mean", "one network mean", "#999999", "s"), ("nearest", "nearest monitor (Voronoi)", "#d95f02", "o"),
         ("mean_within_1000m", "mean within 1 km", "#7570b3", "^"), ("idw_k3", "inverse distance, 3 nearest", "#1b9e77", "D")]
for name, label, col, mk in names:
    rows = [r for r in summary if r["estimator"] == name]
    ax.plot([int(r["network"]) for r in rows], [float(r["rmse"]) for r in rows], marker=mk, color=col, label=label, lw=1.4, ms=4)
ax.set_xscale("log"); ax.set_xticks(networks); ax.set_xticklabels([str(n) for n in networks]); ax.minorticks_off()
ax.set_xlabel("monitors in the network", fontsize=8); ax.set_ylabel("RMSE against the true exposure (ug/m3)", fontsize=8)
ax.tick_params(labelsize=7); ax.set_title("Error by network size", fontsize=9); ax.legend(fontsize=6.5, frameon=False)
ax.set_ylim(bottom=0)

# (c) what a buffer of 1 km gives a person
ax = axes[2]
share = {}
for n in networks:
    c = np.array([int(r["monitors_within_1000m"]) for r in key if int(r["network"]) == n and r["year"] == "2014"])
    share[n] = (np.mean(c == 0), np.mean(c == 1), np.mean(c > 1))
xs = np.arange(len(networks)); bottom = np.zeros(len(networks))
for k, (lab, col) in enumerate([("no monitor", "#bbbbbb"), ("one monitor", "#1b9e77"), ("several monitors", "#d95f02")]):
    h = np.array([share[n][k] for n in networks]); ax.bar(xs, h, bottom=bottom, color=col, label=lab, width=0.6); bottom += h
ax.set_xticks(xs); ax.set_xticklabels([str(n) for n in networks]); ax.set_xlabel("monitors in the network", fontsize=8)
ax.set_ylabel("share of persons", fontsize=8); ax.tick_params(labelsize=7)
ax.set_title("Monitors within 1 km of a person", fontsize=9); ax.legend(fontsize=6.5, frameon=False, loc="upper center", bbox_to_anchor=(0.5, -0.18), ncol=3)
os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
fig.savefig(a.out, dpi=200, bbox_inches="tight")
print("wrote", os.path.abspath(a.out))
