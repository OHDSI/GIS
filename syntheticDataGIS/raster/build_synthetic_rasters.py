#!/usr/bin/env python3
"""Writes the synthetic raster test layers and their answer key (needs numpy; GeoTIFFs are written without GDAL).

  raster/build_synthetic_rasters.py [--out syntheticDataGIS/raster/data] [--points 500]

Layers (all EPSG:5070, a 10 km window around downtown Los Angeles, grid cells aligned to the origin like ST_SquareGrid):
  synthetic_raster_surface_{100m,1km,10km}.tif   the same Gaussian random fields as the vector synthetic_surface_* entries
                                                 (same random Fourier features), one value per cell centre
  synthetic_raster_annual_{2014..2019}.tif       250 m field with a known annual trend and a nodata hole
  synthetic_raster_landcover.tif                 100 m land cover classes (NLCD codes), uint8
Answer key: expected_raster_values.csv, for the test points in raster_test_points.csv.
"""
import argparse, csv, math, os, random, struct
import numpy as np

# Must match tract/build_surface_entries.py
SCALES = {"100m": (100.0, 25.0), "1km": (1000.0, 250.0), "10km": (10000.0, 2500.0)}
MEAN, SD, SEED = 9.0, 1.9, 20261020
CENTER = (-118.25, 34.05)
HALF_WINDOW = 5000.0
FEATURES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tract", "data")

YEARS = list(range(2014, 2020))
ANNUAL_CELL = 250.0
TREND_BASE, TREND_GRADIENT = 0.30, 0.20      # ug/m3 per year, rising by 0.20 from the west to the east edge
HOLE_CENTER_OFFSET, HOLE_CELLS = (1000.0, -1000.0), 3   # nodata hole (a "lake") relative to the window centre
NODATA_FLOAT, NODATA_BYTE = -9999.0, 255

LC_CELL, LC_LENGTH, LC_SEED = 100.0, 500.0, SEED + 7
LC_CLASSES = [(-0.85, 11, "Open Water"), (0.20, 21, "Developed, Open Space"), (1.00, 41, "Deciduous Forest"), (math.inf, 81, "Pasture/Hay")]
BUFFERS_M = [250.0, 1000.0]
POINT_MARGIN = 1500.0

# EPSG:5070, NAD83 / Conus Albers (GRS80)
A, F = 6378137.0, 1 / 298.257222101
E2 = F * (2 - F); E = math.sqrt(E2)
LAT1, LAT2, LAT0, LON0 = map(math.radians, (29.5, 45.5, 23.0, -96.0))


def _m(p): return math.cos(p) / math.sqrt(1 - E2 * math.sin(p) ** 2)
def _q(p):
    s = math.sin(p)
    return (1 - E2) * (s / (1 - E2 * s * s) - math.log((1 - E * s) / (1 + E * s)) / (2 * E))


_N = (_m(LAT1) ** 2 - _m(LAT2) ** 2) / (_q(LAT2) - _q(LAT1))
_C = _m(LAT1) ** 2 + _N * _q(LAT1)
_RHO0 = A * math.sqrt(_C - _N * _q(LAT0)) / _N


def to_5070(lon, lat):
    p, l = math.radians(lat), math.radians(lon)
    rho = A * math.sqrt(_C - _N * _q(p)) / _N
    th = _N * (l - LON0)
    return rho * math.sin(th), _RHO0 - rho * math.cos(th)


def from_5070(x, y):
    rho = math.hypot(x, _RHO0 - y)
    th = math.atan2(x, _RHO0 - y)
    q = (_C - (rho * _N / A) ** 2) / _N
    p = math.asin(q / 2)
    for _ in range(20):
        s = math.sin(p)
        p += (1 - E2 * s * s) ** 2 / (2 * math.cos(p)) * (q / (1 - E2) - s / (1 - E2 * s * s) + math.log((1 - E * s) / (1 + E * s)) / (2 * E))
    return math.degrees(LON0 + th / _N), math.degrees(p)


CX, CY = to_5070(*CENTER)
XMIN, XMAX, YMIN, YMAX = CX - HALF_WINDOW, CX + HALF_WINDOW, CY - HALF_WINDOW, CY + HALF_WINDOW


class Grid:
    """Square cells aligned to the origin (as ST_SquareGrid), covering the window; row 0 is the northern row."""
    def __init__(self, cell):
        self.cell = cell
        self.i0, self.i1 = math.floor(XMIN / cell), math.ceil(XMAX / cell)
        self.j0, self.j1 = math.floor(YMIN / cell), math.ceil(YMAX / cell)
        self.ncol, self.nrow = self.i1 - self.i0, self.j1 - self.j0
        self.x0, self.ytop = self.i0 * cell, self.j1 * cell

    def centres(self):
        xs = (np.arange(self.ncol) + self.i0 + 0.5) * self.cell
        ys = (self.j1 - np.arange(self.nrow) - 0.5) * self.cell
        return np.meshgrid(xs, ys)          # arrays of shape (nrow, ncol)

    def index(self, x, y):
        c, r = math.floor((x - self.x0) / self.cell), math.floor((self.ytop - y) / self.cell)
        return (r, c) if 0 <= r < self.nrow and 0 <= c < self.ncol else None


def load_features(length, seed_offset=None):
    """The published random Fourier features of a vector surface, or generated ones (as tract/build_surface_entries.py)."""
    if seed_offset is None:
        with open(os.path.join(FEATURES_DIR, f"surface_{SCALE_KEYS[length]}_features.csv")) as fh:
            rows = [(float(r["w1"]), float(r["w2"]), float(r["phase"])) for r in csv.DictReader(fh)]
        return np.array(rows)
    rng = random.Random(seed_offset)
    rows = []
    for _ in range(1000):
        z0 = rng.gauss(0, 1)
        rows.append((rng.gauss(0, 1) / (length * abs(z0)), rng.gauss(0, 1) / (length * abs(z0)), rng.uniform(0, 2 * math.pi)))
    return np.array(rows)


SCALE_KEYS = {v[0]: k for k, v in SCALES.items()}


def unit_field(feat, X, Y, chunk=50):
    """sqrt(2/N) * sum cos(w1 x + w2 y + phase): zero mean, unit variance."""
    acc = np.zeros(X.shape)
    for k in range(0, len(feat), chunk):
        w1, w2, ph = (feat[k:k + chunk, i][:, None] for i in range(3))
        acc += np.cos(w1 * X.ravel() + w2 * Y.ravel() + ph).sum(axis=0).reshape(X.shape)
    return acc * math.sqrt(2.0 / len(feat))


def write_geotiff(path, arr, grid, nodata):
    """Uncompressed single-band GeoTIFF in EPSG:5070 (float32 or uint8); one strip."""
    nrow, ncol = arr.shape
    is_float = arr.dtype == np.float32
    data = arr.astype("<f4" if is_float else "u1").tobytes()
    nod = (f"{nodata:g}" if is_float else f"{int(nodata)}").encode() + b"\0"
    geokeys = [1, 1, 0, 4, 1024, 0, 1, 1, 1025, 0, 1, 1, 3072, 0, 1, 5070, 3076, 0, 1, 9001]
    scale = struct.pack("<3d", grid.cell, grid.cell, 0.0)
    tie = struct.pack("<6d", 0, 0, 0, grid.x0, grid.ytop, 0)
    gk = struct.pack(f"<{len(geokeys)}H", *geokeys)
    ntags = 14
    ifd_size = 2 + ntags * 12 + 4
    extra_off = 8 + ifd_size
    # values of 4 bytes or less are stored inline in the IFD entry, not at an offset
    blobs = [("scale", scale), ("tie", tie), ("gk", gk)] + ([("nod", nod)] if len(nod) > 4 else [])
    offs, cur = {}, extra_off
    for name, b in blobs:
        offs[name] = cur; cur += len(b) + (len(b) % 2)
    data_off = cur
    bps, fmt = (32, 3) if is_float else (8, 1)

    def tag(code, typ, count, value):
        packed = struct.pack("<I", value) if typ == 4 else struct.pack("<HH", value, 0) if typ == 3 else struct.pack("<I", value)
        return struct.pack("<HHI", code, typ, count) + packed
    tags = [tag(256, 4, 1, ncol), tag(257, 4, 1, nrow), tag(258, 3, 1, bps), tag(259, 3, 1, 1), tag(262, 3, 1, 1),
            tag(273, 4, 1, data_off), tag(277, 3, 1, 1), tag(278, 4, 1, nrow), tag(279, 4, 1, len(data)), tag(339, 3, 1, fmt),
            tag(33550, 12, 3, offs["scale"]), tag(33922, 12, 6, offs["tie"]), tag(34735, 3, len(geokeys), offs["gk"]),
            tag(42113, 2, len(nod), offs["nod"]) if len(nod) > 4 else struct.pack("<HHI", 42113, 2, len(nod)) + nod.ljust(4, b"\0")]
    assert len(tags) == ntags
    with open(path, "wb") as fh:
        fh.write(b"II*\0" + struct.pack("<I", 8))
        fh.write(struct.pack("<H", ntags) + b"".join(tags) + struct.pack("<I", 0))
        for _, b in blobs:
            fh.write(b + (b"\0" if len(b) % 2 else b""))
        fh.write(data)


def read_geotiff_values(path):
    """Minimal reader for the files above (used by the self-check)."""
    raw = open(path, "rb").read()
    n = struct.unpack_from("<H", raw, 8)[0]
    t = {}
    for i in range(n):
        code, typ, cnt = struct.unpack_from("<HHI", raw, 10 + i * 12)
        t[code] = (typ, cnt, struct.unpack_from("<I", raw, 18 + i * 12)[0] if typ != 3 else struct.unpack_from("<H", raw, 18 + i * 12)[0])
    w, h, off, bps = t[256][2], t[257][2], t[273][2], t[258][2]
    return np.frombuffer(raw, dtype="<f4" if bps == 32 else "u1", count=w * h, offset=off).reshape(h, w)


def lookup(arr, grid, x, y, nodata):
    ix = grid.index(x, y)
    if ix is None or arr[ix] == nodata:
        return None
    return float(arr[ix])


def disc_mask(grid, X, Y, x, y, r):
    """Cells whose centre lies within r of (x, y): the pixels an ST_Clip of the buffer keeps."""
    return (X - x) ** 2 + (Y - y) ** 2 <= r * r


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "data"))
    ap.add_argument("--points", type=int, default=500)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    layers = []   # (layer id, grid, array, nodata, year or None, analytic function or None)

    # surfaces: same field as the vector grids
    surfaces = {}
    for key, (length, cell) in SCALES.items():
        g = Grid(cell); X, Y = g.centres()
        feat = load_features(length)
        fn = lambda x, y, feat=feat: MEAN + SD * unit_field(feat, np.array([[x]]), np.array([[y]]))[0, 0]
        arr = (MEAN + SD * unit_field(feat, X, Y)).astype(np.float32)
        layers.append((f"synthetic_raster_surface_{key}", g, arr, NODATA_FLOAT, None, fn))
        surfaces[key] = (g, X, Y, feat)

    # annual stack: the 1 km field plus a trend that grows from west to east, and a nodata hole
    g = Grid(ANNUAL_CELL); X, Y = g.centres()
    feat = load_features(1000.0)
    base = MEAN + SD * unit_field(feat, X, Y)
    slope = TREND_BASE + TREND_GRADIENT * (X - XMIN) / (2 * HALF_WINDOW)
    hx, hy = CX + HOLE_CENTER_OFFSET[0], CY + HOLE_CENTER_OFFSET[1]
    half = HOLE_CELLS * ANNUAL_CELL / 2
    hole = (np.abs(X - hx) <= half) & (np.abs(Y - hy) <= half)
    for yr in YEARS:
        arr = np.where(hole, NODATA_FLOAT, base + slope * (yr - YEARS[0])).astype(np.float32)
        fn = lambda x, y, yr=yr: MEAN + SD * unit_field(feat, np.array([[x]]), np.array([[y]]))[0, 0] + (TREND_BASE + TREND_GRADIENT * (x - XMIN) / (2 * HALF_WINDOW)) * (yr - YEARS[0])
        layers.append((f"synthetic_raster_annual_{yr}", g, arr, NODATA_FLOAT, yr, fn))
    annual_grid, annual_hole = g, hole

    # land cover
    g = Grid(LC_CELL); X, Y = g.centres()
    z = unit_field(load_features(LC_LENGTH, LC_SEED), X, Y)
    codes = np.full(z.shape, LC_CLASSES[-1][1], dtype=np.uint8)
    for upper, code, _ in reversed(LC_CLASSES[:-1]):
        codes = np.where(z < upper, code, codes).astype(np.uint8)
    layers.append(("synthetic_raster_landcover", g, codes, NODATA_BYTE, None, None))

    for lid, grid, arr, nodata, yr, fn in layers:
        write_geotiff(os.path.join(a.out, lid + ".tif"), arr, grid, nodata)
        assert np.array_equal(read_geotiff_values(os.path.join(a.out, lid + ".tif")), arr)

    # test points: inside the window, away from the edge so every buffer fits; none in the nodata hole's cells
    rng = random.Random(SEED + 99)
    pts = []
    while len(pts) < a.points:
        x = rng.uniform(XMIN + POINT_MARGIN, XMAX - POINT_MARGIN); y = rng.uniform(YMIN + POINT_MARGIN, YMAX - POINT_MARGIN)
        pts.append((len(pts) + 1, x, y))
    with open(os.path.join(a.out, "raster_test_points.csv"), "w", newline="") as fh:
        w = csv.writer(fh); w.writerow(["point_id", "longitude", "latitude", "x_5070", "y_5070"])
        for pid, x, y in pts:
            lon, lat = from_5070(x, y); w.writerow([pid, f"{lon:.7f}", f"{lat:.7f}", f"{x:.3f}", f"{y:.3f}"])

    # answer key
    with open(os.path.join(a.out, "expected_raster_values.csv"), "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["point_id", "layer", "year", "method", "radius_m", "class_code", "value", "analytic_value"])
        for lid, grid, arr, nodata, yr, fn in layers:
            X, Y = grid.centres()
            valid = arr != nodata
            is_lc = arr.dtype == np.uint8
            for pid, x, y in pts:
                v = lookup(arr, grid, x, y, nodata)
                ylabel = "" if yr is None else yr
                w.writerow([pid, lid, ylabel, "point", 0, "", "" if v is None else f"{v:.6f}" if not is_lc else int(v),
                            "" if fn is None else f"{fn(x, y):.6f}"])
                for r in BUFFERS_M:
                    if r < grid.cell:
                        continue
                    m = disc_mask(grid, X, Y, x, y, r) & valid
                    if not m.any():
                        continue
                    if is_lc:
                        for _, code, _ in LC_CLASSES:
                            w.writerow([pid, lid, ylabel, "class_fraction", int(r), code, f"{(arr[m] == code).mean():.6f}", ""])
                    else:
                        w.writerow([pid, lid, ylabel, "buffer_mean", int(r), "", f"{arr[m].astype(float).mean():.6f}", ""])
    n_hole = sum(1 for _, x, y in pts if (lambda ix: ix is not None and annual_hole[ix])(annual_grid.index(x, y)))
    print(f"wrote {len(layers)} rasters, {len(pts)} points ({n_hole} in the annual nodata hole) to {a.out}")
    for lid, grid, arr, nodata, yr, _ in layers:
        print(f"  {lid}: {grid.ncol} x {grid.nrow} cells of {grid.cell:g} m, x0={grid.x0:.1f} ytop={grid.ytop:.1f}")


if __name__ == "__main__":
    main()
