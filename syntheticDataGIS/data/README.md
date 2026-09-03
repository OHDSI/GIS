# Synthetic dataset CSV export

A one-time CSV snapshot of the dataset produced by [`createSimpleSyntheticSet.sql`](../createSimpleSyntheticSet.sql), for anyone who wants to explore the data without standing up PostgreSQL. Each file is one table from the `omopgis` schema, exported with `psql \copy ... TO '<table>.csv' WITH CSV HEADER` after loading the script into a fresh PostgreSQL 16 instance. Empty tables (no rows populated by the script, e.g. `visit_occurrence`, `care_site`) are omitted.

Because the script uses `random()` throughout, this snapshot's exact values won't match a fresh run of the script — the distributions and correlations (urban density → PM2.5, county SES → SDOH/comorbidity risk) will, but not the row-for-row numbers. Treat this as a representative sample, not a fixed reference dataset.

To regenerate:

```sh
psql -h <host> -U <user> -f ../createSimpleSyntheticSet.sql
psql -h <host> -U <user> -c "\copy omopgis.<table> TO '<table>.csv' WITH CSV HEADER"
```

## Files

| File | Rows | Table |
|---|---|---|
| `person.csv` | 10,000 | `PERSON` |
| `location.csv` | 10,000 | `LOCATION` (includes `county_ref_id`) |
| `county_reference.csv` | 3,103 | `COUNTY_REFERENCE` — demo dimension table, one row per synthetic county |
| `location_history.csv` | 10,000 | `LOCATION_HISTORY` (Gaia extension) |
| `external_exposure.csv` | 60,000 | `EXTERNAL_EXPOSURE` (Gaia extension) — PM2.5, PM10, Ozone, NO2, Noise, Tree Canopy |
| `condition_occurrence.csv` | 13,443 | `CONDITION_OCCURRENCE` — 14 conditions |
| `drug_exposure.csv` | 10,159 | `DRUG_EXPOSURE` — 15 drugs |
| `procedure_occurrence.csv` | 4,085 | `PROCEDURE_OCCURRENCE` — 7 procedures |
| `measurement.csv` | 16,324 | `MEASUREMENT` — 16 measurements |
| `observation.csv` | 120,000 | `OBSERVATION` — 12 county-level SDOH indicators |
| `observation_period.csv` | 10,000 | `OBSERVATION_PERIOD` |
| `cdm_source.csv` | 1 | `CDM_SOURCE` |

Row counts reflect the snapshot exported on 2026-09-03; a fresh run will differ slightly due to `random()`.

See [Dataset Visualizations](https://ohdsi.github.io/GIS/tutorial-data-visualization.html) and [Data Description](https://ohdsi.github.io/GIS/tutorial-data-description.html) for query-and-chart pairs and a narrative description of the schema.
