# Tract-level benchmark dataset

A second, more detailed synthetic dataset for the manuscript benchmark. The tutorial dataset (`../data`, built by
`../build_tutorial_dataset.sh`) is not affected by anything in this folder.

| | Tutorial dataset | Tract benchmark |
|---|---|---|
| Geography | about 2,700 real US counties | 10,200 census tracts in AL, AZ, CA, OR (2010 tract vintage, TIGER 2019) |
| Persons | 10,000 | 40,000 (state shares AL 25%, AZ 20%, CA 40%, OR 15%; tracts by population) |
| Generator's exposure | county monthly PM2.5 | tract monthly PM2.5 (CDC EPHTN Downscaler, mean of the daily predictions) |
| Coarser resolution | none | county monthly PM2.5 joined through the same index as a second variable |
| SES | simulated, per county | simulated, per tract (county SES plus a tract deviation correlated with the tract's PM2.5 deviation) |
| Population weights | Census county estimates | CDC/ATSDR SVI 2018 tract totals (ACS 2014-2018) |

Everything goes through the Gaia catalog and spatial join: `us_2019_tract_tl`, `us_2014_2019_monthly_pm25_by_tract_cdc` and
`synthetic_tract_ses` are gaiaCatalog entries (the state list comes from the `TRACT_STATES` environment variable of the gaia-db
container). `build_tract_benchmark.sh` mirrors the tutorial build; stage 2 (`../sql/stage2_clinical.sql`) is reused unchanged
because it runs before the county-level PM2.5 is joined, so it only sees the tract-level exposure.

```sh
CATALOG_OVERLAY=<gaiaCatalog>/datastore/data tract/build_tract_benchmark.sh --clean --keep-running
```

`CATALOG_OVERLAY` is only needed until the three entries are part of the pinned gaiaCatalog commit. The first build pre-stages
the tract SES source file (`tract_ses.csv`, written to `build/out`); publish it as `syntheticDataGIS/tract/data/tract_ses.csv`,
where the catalog entry downloads it from. The CDC tract query is slow (several minutes per request).

Outputs (`tract/build/out`, not committed): the dump `synthetic_omop_gis_tract.sql.gz`, one CSV per table, the exposure rows
`external_exposure_fallback_tract.csv.gz` (tract PM2.5, county PM2.5 and tract SES, told apart by `exposure_source_value`), the raw
monthly series (`tract_pm25_monthly.csv.gz`, `county_pm25_monthly.csv.gz`) and `timings.csv` (Gaia join times).

## Geocoding-error Monte Carlo

`geocoding_error_mc.sh` displaces every residence location by a distance drawn from an empirical geocoding error distribution
(urban and rural strata) in a random direction, and records the tract and county each displaced point falls in.
`../benchmark/geocoding_error_propagation.R` turns the assignments into exposure error and re-fits every outcome per replicate.

```sh
tract/geocoding_error_mc.sh --errors errors.csv --reps 200      # errors.csv: stratum (urban|rural|all), error_m
```
