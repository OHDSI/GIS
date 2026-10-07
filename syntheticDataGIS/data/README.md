# Synthetic dataset CSV export

A CSV snapshot of the dataset produced by [`build_tutorial_dataset.sh`](../build_tutorial_dataset.sh) (generator v3.0, built 2026-10-05 with the pinned gaia-db image and gaiaCatalog commit listed in `build_info.csv`), for anyone who wants to explore the data without standing up PostgreSQL. Each file is one table from the `omopgis` or `demo` schema, sorted by its first column. The dataset includes a **mini vocabulary** (see [`../vocabulary/README.md`](../vocabulary/README.md)) so concept-based tools such as Capr, FeatureExtraction and CohortMethod work without a separate vocabulary download.

**`external_exposure` is not included.** It is empty in the published dataset: participants derive it with gaiaDB in Exercise 2. A prebuilt copy is included as a fallback in case the pipeline does not run: [`external_exposure_fallback.csv.gz`](external_exposure_fallback.csv.gz) (10.9 MB, 720,925 monthly PM2.5 rows plus 10,955 SES rows in `external_exposure` column order). Load it with `gunzip -c external_exposure_fallback.csv.gz | psql ... -c "\\copy omopgis.external_exposure FROM STDIN WITH (FORMAT csv, HEADER true)"`.

The build is deterministic, so rebuilding with the same pinned image and catalog commit reproduces these files exactly. See the [generator README](../README.md) for how the data are produced, the risk model and true coefficients, the fixtures, and known caveats. In particular, the simulated PM2.5 effects are deliberately exaggerated and are not real-world effect sizes.

## Files

`synthetic_omop_gis.sql.gz` (3.3 MB) is the whole dataset as a PostgreSQL dump (schemas `omopgis` and `demo`, without exposure rows); restore it with `gunzip -c synthetic_omop_gis.sql.gz | psql -d <database>`. It is what Exercise 2 loads. The CSVs below are the same data table by table.

| File | Rows | Table |
|---|---|---|
| `build_info.csv` | 8 | `demo.build_info`, build provenance |
| `cdm_source.csv` | 1 | `CDM_SOURCE` |
| `concept.csv` | 9,996 | `CONCEPT`, mini vocabulary: the standard concepts used plus the OMOP GIS, SDoH and Exposome concepts |
| `concept_ancestor.csv` | 9,997 | `CONCEPT_ANCESTOR` (mini vocabulary) |
| `concept_class.csv` | 45 | `CONCEPT_CLASS` (mini vocabulary) |
| `concept_relationship.csv` | 19,994 | `CONCEPT_RELATIONSHIP` (mini vocabulary, restricted to included concepts) |
| `concept_synonym.csv` | 261 | `CONCEPT_SYNONYM` (mini vocabulary) |
| `condition_occurrence.csv` | 18,171 | `CONDITION_OCCURRENCE`, 14 conditions |
| `county_reference.csv` | 3,099 | `COUNTY_REFERENCE`, demo dimension: one row per real county |
| `county_ses.csv` | 3,099 | Source file of the simulated county SES index (`geoid`, `ses_index`), the download of the `synthetic_county_ses` catalog entry |
| `domain.csv` | 17 | `DOMAIN` (mini vocabulary) |
| `drug_exposure.csv` | 13,904 | `DRUG_EXPOSURE`, 15 drugs |
| `episode.csv` | 2 | `EPISODE`, the two pregnancy fixtures |
| `expected_result.csv` | 24 | `demo.expected_result`, the answer key |
| `fixture_person.csv` | 7 | `demo.fixture_person` |
| `generator_params.csv` | 10 | `demo.generator_params` |
| `generator_truth.csv` | 14 | `demo.generator_truth`, the true simulated coefficients |
| `location.csv` | 10,955 | `LOCATION` (includes `county_ref_id`) |
| `location_history.csv` | 10,955 | `LOCATION_HISTORY` (Gaia extension) |
| `measurement.csv` | 21,902 | `MEASUREMENT`, 16 measurements |
| `observation.csv` | 119,999 | `OBSERVATION`, 12 county-level SDOH indicators (one is missing for one fixture person) |
| `observation_period.csv` | 10,000 | `OBSERVATION_PERIOD` |
| `person.csv` | 10,000 | `PERSON` |
| `procedure_occurrence.csv` | 6,099 | `PROCEDURE_OCCURRENCE`, 7 procedures |
| `rejected_exposure_row.csv` | 4 | `demo.rejected_exposure_row`, four bad staging rows for the QA drill |
| `relationship.csv` | 4 | `RELATIONSHIP` (mini vocabulary) |
| `vocabulary.csv` | 12 | `VOCABULARY` (mini vocabulary) |

See [Dataset Visualizations](https://ohdsi.github.io/GIS/tutorial-data-visualization.html) and [Data Description](https://ohdsi.github.io/GIS/tutorial-data-description.html) for query-and-chart pairs and a narrative description of the schema.
