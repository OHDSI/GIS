#!/usr/bin/env python3
"""Figure for the raster example: the three simulated surfaces, the land cover and one test point with its 1 km buffer.

  raster/raster_figure.py [--out rmd/images/raster_surfaces_landcover.png]   (needs numpy and matplotlib)
"""
import argparse, csv, os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap, BoundaryNorm
from matplotlib.patches import Circle, Patch
from build_synthetic_rasters import Grid, SCALES, XMIN, XMAX, YMIN, YMAX, CX, CY, LC_CLASSES, read_geotiff_values

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data")
ap = argparse.ArgumentParser()
ap.add_argument("--out", default=os.path.join(HERE, "..", "..", "rmd", "images", "raster_surfaces_landcover.png"))
ap.add_argument("--point", type=int, default=1, help="test point to draw with its 1 km buffer")
a = ap.parse_args()

with open(os.path.join(DATA, "raster_test_points.csv")) as fh:
    pts = {int(r["point_id"]): (float(r["x_5070"]), float(r["y_5070"])) for r in csv.DictReader(fh)}
px, py = pts[a.point]

def centred(v):   # kilometres from the centre of the window
    return (v - CX) / 1000.0, (v - CY) / 1000.0

panels = []
for key, (length, cell) in SCALES.items():
    g = Grid(cell)
    arr = read_geotiff_values(os.path.join(DATA, f"synthetic_raster_surface_{key}.tif")).astype(float)
    panels.append((f"{cell:g} m cells", g, arr, "surface"))
g = Grid(100.0)
lc = read_geotiff_values(os.path.join(DATA, "synthetic_raster_landcover.tif"))
panels.append(("100 m cells, land cover", g, lc, "class"))

vmin = min(np.nanmin(p[2]) for p in panels if p[3] == "surface"); vmax = max(np.nanmax(p[2]) for p in panels if p[3] == "surface")
codes = [c for _, c, _ in LC_CLASSES]; names = [n for _, _, n in LC_CLASSES]
lc_colors = ["#4f81bd", "#d98c5f", "#5b9a4b", "#d9cf7a"]
lc_cmap = ListedColormap(lc_colors); lc_norm = BoundaryNorm([c - 0.5 for c in codes] + [codes[-1] + 0.5], lc_cmap.N)
# codes are 11, 21, 41, 81: map them to 0..3 so the boundaries are even
lc_idx = np.vectorize({c: i for i, c in enumerate(codes)}.get)(lc)

fig, axes = plt.subplots(1, 4, figsize=(10, 3.3), constrained_layout=True)
for ax, (title, grid, arr, kind) in zip(axes, panels):
    x0, x1 = (grid.x0 - CX) / 1000.0, (grid.x0 + grid.ncol * grid.cell - CX) / 1000.0
    y0, y1 = (grid.ytop - grid.nrow * grid.cell - CY) / 1000.0, (grid.ytop - CY) / 1000.0
    if kind == "surface":
        im = ax.imshow(arr, extent=(x0, x1, y0, y1), cmap="viridis", vmin=vmin, vmax=vmax, interpolation="nearest")
    else:
        ax.imshow(lc_idx, extent=(x0, x1, y0, y1), cmap=ListedColormap(lc_colors), vmin=-0.5, vmax=3.5, interpolation="nearest")
    cx, cy = (px - CX) / 1000.0, (py - CY) / 1000.0
    ax.add_patch(Circle((cx, cy), 1.0, fill=False, ec="white", lw=1.2, ls="--"))
    ax.plot([cx], [cy], marker="o", ms=4, mfc="white", mec="black", mew=0.8)
    ax.set_xlim(-5, 5); ax.set_ylim(-5, 5); ax.set_aspect("equal")
    ax.set_title(title, fontsize=9); ax.set_xticks([-5, 0, 5]); ax.set_yticks([-5, 0, 5]); ax.tick_params(labelsize=7)
axes[0].set_ylabel("km from the centre of the window", fontsize=8)
cb = fig.colorbar(im, ax=axes[2], fraction=0.046, pad=0.03); cb.set_label("simulated PM2.5 (ug/m3)", fontsize=8); cb.ax.tick_params(labelsize=7)
axes[3].legend(handles=[Patch(fc=c, ec="none", label=f"{k} {n}") for c, k, n in zip(lc_colors, codes, names)],
               loc="upper center", bbox_to_anchor=(0.5, -0.1), fontsize=6.5, frameon=False, ncol=2)
fig.suptitle("Simulated rasters over a 10 km window; one test point and its 1 km buffer (dashed)", fontsize=10)
os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
fig.savefig(a.out, dpi=200, bbox_inches="tight")
print("wrote", os.path.abspath(a.out))
