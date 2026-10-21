#!/usr/bin/env python3
"""Generates the synthetic tower dataset. Usage: build_tower_dataset.py [--out DIR] [--seed N]"""
import argparse, csv, gzip, json, math, os, random
from datetime import date, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
TUTORIAL_DATA = os.path.join(HERE, "..", "data")

P = {
    "seed": (20261021, "Random seed"),
    "n_floors": (100, "Floors in the building"),
    "n_persons": (10000, "Persons (an equal number on every floor)"),
    "floor_width_m": (30.0, "Floor extent along the flattened strip (x), metres"),
    "floor_depth_m": (30.0, "Floor extent across the strip (y), metres"),
    "metres_per_deg_lon": (111319.49079327357, "Metres per degree of longitude at the equator"),
    "metres_per_deg_lat": (110574.0, "Metres per degree of latitude at the equator"),
    "period_start": ("2019-01-01", "First day of the sensor series and of the observation period"),
    "period_end": ("2019-12-31", "Last day (daily series, 365 days)"),
    "pm25_floor1_ugm3": (6.0, "Expected PM2.5 on floor 1 before seasonal, weather and sensor terms"),
    "pm25_slope_per_floor": (0.12, "Increase of the expected PM2.5 per floor (ug/m3)"),
    "pm25_season_amp": (1.0, "Amplitude of the annual cycle shared by all floors"),
    "pm25_weather_sd": (0.6, "SD of the building-wide AR(1) weather term"),
    "pm25_weather_rho": (0.8, "Day-to-day autocorrelation of the weather term"),
    "pm25_sensor_noise_sd": (0.5, "SD of the daily noise of every sensor reading"),
    "pm25_sensor_offset_sd": (0.05, "SD of the fixed random offset of every sensor"),
    "pm25_ref": (12.0, "Reference PM2.5 for the outcome model (about the building mean)"),
    "ses_slope_per_floor": (0.2, "Person SES index rises by this many points per floor (confounder)"),
    "ses_sd": (15.0, "SD of the person SES index around its floor mean"),
    "mover_share": (0.10, "Share of persons who move once to another floor"),
    "move_window": ("2019-02-01/2019-11-30", "Move dates are uniform in this window"),
    "floor_frailty_sd": (0.15, "SD of the shared floor-level random effect on the log-odds of every outcome"),
    "age_ref": (54.0, "Reference age for the risk model"),
}
SENSORS = [("window", 3.0, 5.0, 0.40), ("window", 27.0, 5.0, 0.40), ("window", 15.0, 27.0, 0.0), ("core", 15.0, 15.0, -0.80)]
OUTCOMES = [
    ("COPD", 255573, "Respiratory", 0.07, 0.150, -0.20, 0.45, 0.00, False),
    ("ASTHMA", 317009, "Respiratory", 0.095, 0.080, -0.15, 0.00, 0.25, False),
    ("CKD", 46271022, "Cardiometabolic", 0.08, 0.000, -0.50, 0.50, 0.05, True),
    ("T2DM", 201826, "Cardiometabolic", 0.12, 0.000, -0.40, 0.30, -0.10, True),
]
RESIDENCE_RELATIONSHIP = 2052496995
PERSON_DOMAIN = 1147314
SES_CONCEPT = 2052497744             # the SES index concept of the tutorial's county SES entry

def tutorial_header(table):
    with open(os.path.join(TUTORIAL_DATA, table + ".csv"), newline="") as fh:
        return next(csv.reader(fh))

def write_csv(path, header, rows):
    with open(path, "w", newline="") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)

def logit(p):
    return math.log(p / (1 - p))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "data")); ap.add_argument("--seed", type=int, default=P["seed"][0])
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    v = {k: x[0] for k, x in P.items()}; v["seed"] = a.seed
    rng = random.Random(v["seed"])
    nF, W, D = v["n_floors"], v["floor_width_m"], v["floor_depth_m"]
    LON, LAT = v["metres_per_deg_lon"], v["metres_per_deg_lat"]
    d0, d1 = date.fromisoformat(v["period_start"]), date.fromisoformat(v["period_end"])
    days = [d0 + timedelta(i) for i in range((d1 - d0).days + 1)]
    nD = len(days)
    key = [f"{d.isoformat()}/{d.isoformat()}" for d in days]

    def lon(x): return x / LON
    def lat(y): return y / LAT
    def floor_wkt(k):
        x0, x1 = (k - 1) * W, k * W
        return (f"POLYGON (({lon(x0)!r} {lat(0)!r}, {lon(x1)!r} {lat(0)!r}, {lon(x1)!r} {lat(D)!r}, {lon(x0)!r} {lat(D)!r}, {lon(x0)!r} {lat(0)!r}))")

    weather, w = [], rng.gauss(0, v["pm25_weather_sd"])
    for _ in range(nD):
        weather.append(w)
        w = v["pm25_weather_rho"] * w + math.sqrt(1 - v["pm25_weather_rho"] ** 2) * rng.gauss(0, v["pm25_weather_sd"])
    season = [v["pm25_season_amp"] * math.cos(2 * math.pi * (d.timetuple().tm_yday - 15) / 365) for d in days]
    sensor_rows, floor_series = [], {}
    sid = 0
    for k in range(1, nF + 1):
        expected = v["pm25_floor1_ugm3"] + v["pm25_slope_per_floor"] * (k - 1)
        per_sensor = []
        for stype, su, sv, off in SENSORS:
            sid += 1
            offset = off + rng.gauss(0, v["pm25_sensor_offset_sd"])
            vals = [round(max(0.5, expected + season[i] + weather[i] + offset + rng.gauss(0, v["pm25_sensor_noise_sd"])), 3) for i in range(nD)]
            per_sensor.append(vals)
            x, y = (k - 1) * W + su, sv
            sensor_rows.append((sid, k, stype, f"POINT ({lon(x)!r} {lat(y)!r})", json.dumps(dict(zip(key, vals)), separators=(",", ":"))))
        floor_series[k] = [round(sum(s[i] for s in per_sensor) / len(per_sensor), 4) for i in range(nD)]
    write_csv(os.path.join(a.out, "tower_sensors.csv"), ["sensor_id", "floor_number", "sensor_type", "wkt", "pm25_sensor"], sensor_rows)
    write_csv(os.path.join(a.out, "tower_floors.csv"), ["floor_id", "floor_number", "wkt", "pm25_floor_mean"],
              [(k, k, floor_wkt(k), json.dumps(dict(zip(key, floor_series[k])), separators=(",", ":"))) for k in range(1, nF + 1)])
    pref = {k: [0.0] for k in floor_series}
    for k, s in floor_series.items():
        for x in s: pref[k].append(pref[k][-1] + x)

    def interval_sum(k, a_, b_):
        return pref[k][b_ + 1] - pref[k][a_]

    frailty = {o[0]: {k: rng.gauss(0, v["floor_frailty_sd"]) for k in range(1, nF + 1)} for o in OUTCOMES}
    per_floor = v["n_persons"] // nF
    assert per_floor * nF == v["n_persons"]
    floors_of = [k for k in range(1, nF + 1) for _ in range(per_floor)]
    rng.shuffle(floors_of)
    movers = set(rng.sample(range(1, v["n_persons"] + 1), int(round(v["mover_share"] * v["n_persons"]))))
    m0, m1 = (date.fromisoformat(s) for s in v["move_window"].split("/"))

    def point(k):
        return (k - 1) * W + rng.uniform(0.5, W - 0.5), rng.uniform(0.5, D - 0.5)

    ph, lh_, lch = tutorial_header("person"), tutorial_header("location_history"), tutorial_header("location")
    loc_header = [c if c != "county_ref_id" else "floor_number" for c in lch]
    person_rows, loc_rows, lh_rows, op_rows, obs_rows, cond_rows, truth_rows = [], [], [], [], [], [], []
    loc_id = cond_id = 0
    for pid in range(1, v["n_persons"] + 1):
        k1 = floors_of[pid - 1]
        age = rng.randint(18, 90)
        female = rng.random() < 0.5
        ses = min(100.0, max(0.0, rng.gauss(50 + v["ses_slope_per_floor"] * (k1 - (nF + 1) / 2), v["ses_sd"])))
        stays = [(k1, d0, d1)]
        if pid in movers:
            k2 = rng.choice([k for k in range(1, nF + 1) if k != k1])
            md = m0 + timedelta(rng.randint(0, (m1 - m0).days))
            stays = [(k1, d0, md - timedelta(1)), (k2, md, d1)]
        total, n = 0.0, 0
        for k, s0, s1 in stays:
            loc_id += 1
            x, y = point(k)
            unit = rng.randint(1, 40)
            loc_rows.append([loc_id, f"Floor {k}, Unit {unit}", "", "Tower", "", "", "", f"FLOOR-{k:03d}", "", "", repr(lat(y)), repr(lon(x)), k])
            lh_rows.append([loc_id, RESIDENCE_RELATIONSHIP, PERSON_DOMAIN, pid, s0.isoformat(), s1.isoformat()])
            ia, ib = (s0 - d0).days, (s1 - d0).days
            total += interval_sum(k, ia, ib); n += ib - ia + 1
        assert n == nD
        pm = total / n
        person_rows.append([pid, 8532 if female else 8507, 2019 - age, rng.randint(1, 12), "", "", 0, 0, loc_id, "", "", f"FAKE PERSON: tower-{pid}", "F" if female else "M", "", "", "", "", ""])
        op_rows.append([pid, pid, d0.isoformat(), d1.isoformat(), 32817])
        obs_rows.append([pid, pid, SES_CONCEPT, d0.isoformat(), "", 32817, round(ses, 3), "", "", "", 0, "", "", "", "SES_INDEX", SES_CONCEPT, "index (0-100)", "", "", "", ""])
        for name, concept, cat, prev, b_pm, b_ses, b_age, b_f, null in OUTCOMES:
            lg = (logit(prev) + b_pm * (pm - v["pm25_ref"]) + b_ses * (ses - 50) / v["ses_sd"] + b_age * (age - v["age_ref"]) / 10
                  + b_f * female + sum(frailty[name][k] for k, _, _ in stays) / len(stays))
            if rng.random() < 1 / (1 + math.exp(-lg)):
                cond_id += 1
                cond_rows.append([cond_id, pid, concept, (d0 + timedelta(rng.randint(0, nD - 1))).isoformat(), "", "", "", 32817, "", "", "", "", "", name, concept, ""])
        truth_rows.append([pid, stays[0][0], stays[-1][0], n, round(pm, 6), round(ses, 3), age, int(female)])
    last_loc = {r[3]: r[0] for r in lh_rows}
    for r in person_rows: r[8] = last_loc[r[0]]
    write_csv(os.path.join(a.out, "person.csv"), ph, person_rows)
    write_csv(os.path.join(a.out, "location.csv"), loc_header, loc_rows)
    write_csv(os.path.join(a.out, "location_history.csv"), lh_, lh_rows)
    write_csv(os.path.join(a.out, "observation_period.csv"), tutorial_header("observation_period"), op_rows)
    write_csv(os.path.join(a.out, "observation.csv"), tutorial_header("observation"), obs_rows)
    write_csv(os.path.join(a.out, "condition_occurrence.csv"), tutorial_header("condition_occurrence"), cond_rows)

    write_csv(os.path.join(a.out, "person_exposure_truth.csv"),
              ["person_id", "floor_first", "floor_last", "days", "pm25_day_weighted", "ses_index", "age", "female"], truth_rows)
    write_csv(os.path.join(a.out, "floor_reference.csv"),
              ["floor_number", "pm25_expected_no_noise", "pm25_annual_mean"] + [f"frailty_{o[0].lower()}" for o in OUTCOMES],
              [[k, round(v["pm25_floor1_ugm3"] + v["pm25_slope_per_floor"] * (k - 1), 4), round(pref[k][-1] / nD, 4)]
               + [round(frailty[o[0]][k], 5) for o in OUTCOMES] for k in range(1, nF + 1)])
    write_csv(os.path.join(a.out, "generator_params.csv"), ["param", "value", "notes"], [[k, v[k], P[k][1]] for k in P])
    write_csv(os.path.join(a.out, "generator_truth.csv"),
              ["outcome_name", "condition_concept_id", "category", "prevalence_ref", "beta_pm25_per_ugm3", "beta_ses_per_sd", "beta_age_per_decade", "beta_female", "is_pm25_null_outcome"],
              [[o[0], o[1], o[2], o[3], f"{o[4]:.3f}", o[5], o[6], o[7], "t" if o[8] else "f"] for o in OUTCOMES])

    annual = [pref[k][-1] / nD for k in range(1, nF + 1)]
    assert all(b > a_ for a_, b in zip(annual, annual[1:])), "annual mean PM2.5 must rise with floor"
    assert len(person_rows) == v["n_persons"] and len(lh_rows) == v["n_persons"] + len(movers)
    print(f"floors {nF}, sensors {len(sensor_rows)}, persons {len(person_rows)} ({len(movers)} movers), residences {len(lh_rows)}, "
          f"conditions {len(cond_rows)}; floor-mean PM2.5 {annual[0]:.2f} to {annual[-1]:.2f} ug/m3")
    for o in OUTCOMES:
        print(f"  {o[0]:6s} {sum(1 for r in cond_rows if r[13] == o[0])} persons")

if __name__ == "__main__":
    main()
