# Synthetic OMOP + GIS dataset

Generator for the synthetic cohort used in the OHDSI GIS tutorial: 10,000 adult persons placed in real US counties (2014-2019) with residence histories, SDOH indicators and 14 respiratory / cardiometabolic conditions whose risk depends on **real** county-level PM2.5.

Everything about the persons is synthetic. The exposure behind the conditions is real, but it is **not shipped**: `omopgis.external_exposure` is empty in the published dataset and participants derive it with gaiaDB in Session 2.

## Build

```sh
./build_tutorial_dataset.sh            # outputs to ./build/out
./build_tutorial_dataset.sh --clean    # full rebuild from scratch
```

Requires docker, git, curl and python3 (standard library). The first run downloads about 0.5 GB (TIGER counties and CDC PM2.5) and, because the `gaia-db` image is linux/amd64 only, is slow on Apple Silicon; later runs reuse the database volume. County population (Census 2019) is downloaded on the fly. The script defaults to a pinned gaia-db image digest and gaiaCatalog commit (override with `GAIA_DB_IMAGE` and `GAIA_CATALOG_REF`); both are recorded in `demo.build_info`. With the pinned values, rebuilds are byte-identical, including from a fresh gaiaDB ingest.

## The stages

| Step | File | What happens |
|---|---|---|
| 1 | gaiaCatalog + `backbone.ingest_datasource()` | Ingest Census TIGER 2023 counties and the CDC monthly county PM2.5 dataset |
| 2 | `sql/stage1_ddl.sql`, `sql/stage1_vocabulary_*.sql`, `sql/stage1_population.sql` | Create the OMOP 5.4 + Gaia extension tables, load the [mini vocabulary](vocabulary/README.md), then persons, real-county residences (random points inside the real polygons), ~10% movers, `LOCATION` / `LOCATION_HISTORY` (exported as CSV) |
| 3 | gaiaDB | `working.load_location_data()`, `backbone.gdsc_load_all_variables()`, `working.spatial_join_from_catalog('pm25_mean_pred', ...)` derive monthly exposure rows |
| 4 | `sql/stage2_clinical.sql` | Draw conditions, SDOH, drugs, procedures and measurements from the gaiaDB exposure; fixtures and the answer key |
| 5 | `sql/verify.sql` | Invariants (adult ages, residence intervals, points inside polygons, 72 months per person, empty `external_exposure`) |
| 6 | build script | `synthetic_omop_gis.sql.gz`, one CSV per non-empty table, `external_exposure_fallback.csv.gz`, `BUILD_INFO.txt` |

The build is deterministic given the same gaia-db image and gaiaCatalog commit (`setseed`, seeded point generation).

## The model and the answer key

Conditions follow a logistic model in PM2.5 (day-weighted over a person's residences), county SES, age, sex and a shared county random effect. All parameters, and the true effects, are in `demo.generator_params` and `demo.generator_truth`. County SES is simulated and correlated with county PM2.5 (about -0.3), so SES confounds the crude PM2.5 effect.

**The PM2.5 coefficients are deliberately exaggerated.** Real county PM2.5 varies little across 10,000 persons (SD about 1.4 ug/m3), so the true effects (for example COPD, OR about 1.16 per ug/m3) are much larger than epidemiologic estimates to make them recoverable. They are not real-world effect sizes. Outcomes with a simulated effect of zero (`is_pm25_null_outcome`) can serve as negative controls.

## Fixtures (schema `demo`)

`demo.fixture_person` lists seven persons for the exercises: two pregnancies (one static, one who moves counties mid-pregnancy), four persons with one bad exposure staging row each (`demo.rejected_exposure_row`: duplicate, unit mismatch, non-overlapping interval, NULL value) and one person with a missing SDOH observation. `demo.expected_result` holds the answer key, including the day-weighted vs naive mean PM2.5 during pregnancy and the expected exposure row counts.

## Known caveats

- gaiaDB currently leaves `unit_concept_id` and `dose_unit_source_value` empty on the exposure rows it derives, and uses its own exposure concept (2052499839) and geometry-based type concepts.
- The concepts used by the dataset are checked against the mini vocabulary at build time. The residence relationship is the OMOP GIS concept `Patient Residence` (2052496995), not the type concept used in gaiaDB's example file; confirm with the GIS vocabulary owners.
- `data/` holds the CSV snapshot of the 2026-10-05 build (without `external_exposure`, plus the gzipped fallback exposure file); it is copied from `build/out/csv` by hand, not by the build script.
