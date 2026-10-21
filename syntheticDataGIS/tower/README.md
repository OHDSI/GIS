# Synthetic tower: exposure that changes with height

A 100-floor building flattened to a row of adjacent floor polygons, four particle sensors on every floor, 10,000 persons placed in different parts of the floors, and PM2.5 that rises with height. It is a small, fully known test bed for questions where the exposure varies over a short distance, here the floor you live on, and for the point-sensor sources that the other synthetic datasets do not have.

Everything is synthetic. The particle levels are **illustrative, not physical** (outdoor PM2.5 usually falls with height); they rise with the floor by design so that the gradient is known exactly.

## The geometry

Floor *k* (1 to 100) is the 30 m by 30 m rectangle with x from 30(*k*-1) to 30*k* m and y from 0 to 30 m, so **height is the x axis** and the whole building is a strip 3 km long. Gaia's join is 2D, so the flattening is how the vertical position is carried. The strip is placed at longitude 0, latitude 0 (open ocean: no real census unit lies underneath) and converted to degrees with fixed metres-per-degree constants. Neighbouring floors share an edge exactly.

Each floor has four sensors at the same relative positions: three near the windows and one at the core, so 400 point sensors. People are placed uniformly at random inside their floor polygon, 100 per floor. About 10% of persons move once to another floor between 1 February and 30 November 2019, so their exposure is the day-weighted average of two floors (intervals are whole days, so unlike a monthly series no day is split).

## The particle model

For sensor *s* on floor *k* on day *t*:

`PM2.5 = 6 + 0.12 (k - 1)  +  1.0 cos(annual cycle)  +  weather(t)  +  sensor offset  +  noise`

with a building-wide AR(1) weather term (SD 0.6, autocorrelation 0.8), a fixed offset per sensor (window +0.4 or 0, core -0.8, plus a random part with SD 0.05) and daily noise (SD 0.5). The expected floor mean rises from 6.0 to 17.9 ug/m3. The floor series is the mean of its four sensors, one value per day of 2019 (365 days). A person's exposure is the day-weighted mean of the floor series over their residences; across persons it has mean 11.9 and SD 3.4.

## Persons and outcomes

10,000 adults (18 to 90), OMOP-shaped like the tutorial data. A **person-level SES index** (mean 50 + 0.2 per floor, SD 15) rises with the floor, so SES confounds the PM2.5 effect in the opposite direction to the tutorial: higher floors have more PM2.5 and higher SES, and higher SES protects. Four outcomes are drawn from a logistic model in PM2.5, SES, age, sex and a floor-level random effect (SD 0.15), with the same coefficients as in the tutorial generator:

| Outcome | True PM2.5 effect (log-odds per ug/m3) | Adjusted estimate (SE) | Crude estimate (SE) |
|---|---|---|---|
| COPD | 0.15 | 0.171 (0.012) | 0.140 (0.011) |
| Asthma | 0.08 | 0.077 (0.010) | 0.065 (0.010) |
| CKD (null) | 0 | 0.013 (0.010) | -0.040 (0.009) |
| T2DM (null) | 0 | -0.012 (0.009) | -0.050 (0.009) |

Without SES in the model, the effects are biased down and the nulls look protective: the "penthouse" confounding.

## Files

| File | What it does |
|---|---|
| `build_tower_dataset.py` | Generator (standard library only, deterministic): writes `data/` |
| `data/tower_floors.csv`, `data/tower_sensors.csv` | The two catalog sources: WKT geometry and a daily jsonb series |
| `data/person.csv`, `location.csv`, `location_history.csv`, `observation_period.csv`, `condition_occurrence.csv`, `observation.csv` | OMOP-shaped persons (`location.floor_number` replaces the tutorial's `county_ref_id`; the person's SES index is an observation) |
| `data/person_exposure_truth.csv`, `floor_reference.csv`, `generator_params.csv`, `generator_truth.csv` | The answer key |
| `build_tower_entries.py` | Writes the gaiaCatalog entries `synthetic_tower_floors` (polygons) and `synthetic_tower_sensors` (points) into `catalog/` |
| `verify_tower_gaia.sh` | Runs the Gaia pipeline on the tower in a throwaway gaia-db container and compares it with the answer key |
| `load_for_qgis.sh` | Loads `tower_floors`, `tower_sensors` and `tower_people` into a running gaia-db for QGIS |
| `floor_misclassification.R` | The floor-error experiment below |
| `tower_figure.R` | The figure on the website's Examples page (PM2.5 by floor and the floor-error result) |

```sh
python3 tower/build_tower_dataset.py          # data/
python3 tower/build_tower_entries.py          # catalog/ (copy the folders into gaiaCatalog/datastore/data)
tower/verify_tower_gaia.sh                    # Gaia join against the answer key (needs docker; about a minute)
tower/load_for_qgis.sh                        # QGIS: host localhost, port 5433, database gaiacore; style tower_floors by pm25_annual_mean
```

## What was checked

`verify_tower_gaia.sh` ingests both catalog entries, loads the 11,000 residences and runs `spatial_join_from_catalog` on the floor series: **3,650,000 exposure rows** (365 for every person, movers included), and for every person the number of rows, the period and the sum of the 365 values agree with the answer key, which is computed without any spatial operation (worst absolute difference of a 365-day sum 0.0002, the rounding of the key). Before that it checks that every residence lies in the polygon of its own floor, every sensor in the polygon of its own floor, every floor has four sensors and neighbouring floors touch.

The v1 join assigns each person the **floor mean** of the sensors. The sensors are ingested as a point source but are not joined to persons: that needs a nearest-sensor (or sensors within a distance) operation, which Gaia does not have yet, and is the natural next use of this dataset.

## Floor misclassification

A 2D geocoder does not know the floor. `floor_misclassification.R` reassigns every residence to a different floor under several error models, recomputes the exposure and refits the outcome models (200 replicates for the random scenarios). The result for the two outcomes with an effect (share of the estimate at the true floor that is recovered; the prediction is the regression-dilution factor):

| Scenario | COPD recovered (predicted) | Asthma recovered (predicted) |
|---|---|---|
| True floor | 1.00 | 1.00 |
| Floor off by a normal error, SD 1 floor | 1.00 (1.00) | 1.00 (1.00) |
| SD 3 floors | 0.99 (0.99) | 0.99 (0.99) |
| SD 10 floors | 0.91 (0.91) | 0.90 (0.91) |
| SD 30 floors | 0.56 (0.56) | 0.55 (0.56) |
| Zones of 10 floors (each resident gets the zone mid-floor) | 1.00 (1.00) | 1.00 (1.00) |
| Zones of 25 floors | 0.96 (0.99) | 0.94 (0.99) |
| Random floor | 0.00 (0.00) | 0.00 (0.00) |

With a gradient this smooth, errors of a few floors cost almost nothing, much like the 10 km exposure surface in the geocoding stress test; it takes errors of about 10 floors to lose 10% of the effect. Grouping floors into zones is a **Berkson-type** error and loses little, whereas a random error of the same size attenuates the effect. If the floor is not known at all, everyone gets the ground floor or the building mean, there is no contrast between persons and the effect cannot be estimated (a random floor loses all of it).

Results are in `output/floor_misclassification.csv`.

## Caveats

- The gradient is linear by construction and the particle levels are not physical.
- Everyone on a floor shares one exposure value (the floor mean), so there is no within-floor variation in the exposure; the within-floor sensor offsets only enter through the mean.
- SES is simulated at the person level, with a correlation of about 0.33 with PM2.5; the outcome effects are deliberately larger than epidemiologic estimates.
- As in the other synthetic datasets, Gaia leaves `unit_concept_id` empty on the rows it derives; the catalog declares the unit (32964, micrograms per cubic meter).
