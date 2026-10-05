# Mini vocabulary

The tutorial dataset ships with a small OMOP vocabulary so that concept-based tools (Capr, FeatureExtraction, CohortMethod, SQL joins to `concept`) work without downloading the full vocabulary from Athena.

## Contents

- **Standard slice (CSV files in this folder).** The 73 standard concepts that appear anywhere in the dataset (conditions, drugs, procedures, measurements, units, genders, routes, type concepts, the pregnancy episode concepts and a few metadata concepts), with the matching rows of `vocabulary`, `domain`, `concept_class`, `relationship`, `concept_relationship` and `concept_synonym`, and `concept_ancestor`. Relationships and ancestors are restricted to pairs of concepts that are both in the slice. Extracted from OMOP Standardized Vocabularies release **v5.0 27-FEB-25**.
- **OMOP GIS, SDoH and Exposome concepts** from [`../vocab_temp/`](../vocab_temp/) (about 9,900 concepts, with their synonyms and `Maps to` relationships restricted to included concepts).

`build_tutorial_dataset.sh` loads both into the `omopgis` schema (`stage1_vocabulary_*.sql`), and `sql/verify.sql` fails the build if any concept id used by the clinical tables or by the Gaia exposure is missing from the vocabulary, is not a standard concept, or is in the wrong domain.

## Content notices

The standard slice contains concept names and codes from SNOMED CT, LOINC, RxNorm and UCUM, distributed through the OMOP vocabularies. These sources carry their own license terms (for example the LOINC license and the SNOMED CT affiliate license), and the slice contains only 73 concepts. Review the terms for your distribution before redistributing this folder outside the tutorial. CPT4 content is deliberately not included.

## Regenerating the slice

The slice is extracted from an OMOP vocabulary database with the concept ids in the dataset (see the `\copy` queries used to produce the CSVs: select the ids listed by the clinical and exposure tables from `concept`, and restrict the other tables to those ids). When the generator changes which concepts it uses, extract the new ids and rerun the build: `verify.sql` names any concept that is missing.

## Notes on specific concepts

- `SPIROMETRY` uses SNOMED `Spirometry` (4133840), which the vocabulary places in the Measurement domain; the license-free alternatives in the Procedure domain do not exist.
- Pregnancy episodes use the `Disease Episode` concept (32533) with the `Pregnancy` condition (4299535) as the episode object, because the vocabulary has no dedicated pregnancy-episode concept.
- Residences in `LOCATION_HISTORY` use the OMOP GIS concept `Patient Residence` (2052496995) as the relationship; the domain is the CDM table concept `person` (1147314).
