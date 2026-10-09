# Benchmark scripts (manuscript)

Everything here runs from the repository root on the CSV snapshot in `syntheticDataGIS/data/` and the exposure file Gaia derived
(`external_exposure_fallback.csv.gz`). Outputs go to `benchmark/output/`. The R scripts run in the `ohdsi/gaia-core:main` image, which includes `sf`, `sandwich`, `geepack`, `glmmTMB` and `blockCV`.

```sh
docker run --rm --platform linux/amd64 -v "$PWD":/repo -w /repo ohdsi/gaia-core:main \
  Rscript syntheticDataGIS/benchmark/<script>.R
```

| Script | What it answers |
|---|---|
| `pm25_effect_recovery.R` | Table 2 / forest plot: CohortMethod estimates (crude and propensity-score-stratified, high versus low PM2.5) against the generator's true coefficients, all 14 outcomes |
| `continuous_model.R` | The continuous-exposure analysis with county-clustered standard errors and a county random-intercept model |
| `coverage_simulation.R` | How often 95% intervals cover the truth when the random parts of the generator are re-drawn (500 replicates): coverage, bias, standard-error calibration, and the chance of at least one miss among 14 outcomes (the T2DM question) |
| `interval_methods.R` | Which confidence interval to use with few, unbalanced county clusters: coverage of model-based, county-clustered (CR1), jackknife (CR3) and mixed-model intervals in a repeated simulation of the generator |
| `exposure_agreement.R` | Gaia's exposure rows against an independent answer key (the generator's county and the raw CDC monthly values; no spatial join) |
| `baseline_join.sh` | The same join as plain PostGIS SQL: exact agreement with Gaia and runtimes (needs a running gaia-db holding the finished build) |
| `geocoding_error_propagation.R` | Exposure misclassification and the bias and spread of the effect estimates when locations are displaced by the empirical geocoding error (tract benchmark dataset; see `../tract/README.md`) |
| `geocoding_error_figure.R` | Four-geocoder comparison figure and summary table from the per-geocoder propagation results (error distributions in `../tract/data/geocoding_errors/`) |
| `geocoding_stress_test.R` | Stress test with a sharply varying exposure: synthetic Gaussian surfaces with correlation lengths of 100 m, 1 km and 10 km, geocoding error from each geocoder, bias and coverage against the regression-dilution prediction |
| `geocoding_gaia_check.R` | Checks the stress test's surfaces through Gaia: ingests `synthetic_surface_*` catalog entries (built by `../tract/build_surface_entries.py`), joins true and displaced locations with `spatial_join_from_catalog` and compares with the analytic surface |
| `geocoding_roads_scenario.R` | Road-proximity scenario: real TIGER road geometry (`us_2019_prisecroads_tl`, `synthetic_road_proximity`, built by `../tract/build_road_entries.py`) with a simulated near-road increment; needs `../tract/geocoding_error_mc.sh --bands synthetic_road_proximity` |
| `spatial_cv_model.R` | The derived exposure as input to a machine-learning workflow: logistic regression and gradient-boosted trees under random and spatially blocked cross-validation |
| `geocoding_stress_figure.R` | Figure of the stress tests: attenuation and coverage against the correlation length (with the regression-dilution prediction) and the road-proximity result |
| `road_bands_gaia_check.R` | Checks Gaia's road-band assignment (`synthetic_road_proximity`) against the exact distance to the nearest road |

The scripts take `--pm25-source` and `--ses-source` (the `exposure_source_value` of the variable) when an exposure file holds several,
as the tract benchmark's does. `exposure_agreement.R` also takes `--resolution tract`.
`pm25_effect_recovery.R` also takes `--design match`, `--strata N` and `--outcome-covariates`, and prints the covariate balance before and after the propensity-score design.
