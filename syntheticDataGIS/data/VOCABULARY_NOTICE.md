# Vocabulary content in the tutorial dataset

The tutorial dataset includes a **minimal extract of the OMOP Standardized Vocabularies**, so that the exercises run without a vocabulary download. It is meant for the tutorial only, not for clinical, research or production use. Obtain the full vocabularies from [Athena](https://athena.ohdsi.org) under their own licenses.

## What is included

| Source vocabulary | Concepts | Where they are used |
|---|---|---|
| SNOMED CT | 25 | the 14 simulated conditions, pregnancy, procedures, qualifiers |
| RxNorm | 15 | drug ingredients |
| LOINC | 15 | measurements and clinical observations |
| UCUM | 12 | units |

The extract also contains the synonym rows for these concepts (258), and relationship and ancestor rows between them and the other tutorial concepts. The other concepts in the mini vocabulary (OMOP Exposome, OMOP SDOH, OMOP GIS and a few OMOP-maintained concepts) are produced by the OHDSI GIS Working Group.

To list the extract: `concept.csv` filtered to `vocabulary_id` in `SNOMED`, `RxNorm`, `LOINC`, `UCUM`; the same concepts appear in the `omopgis` schema of `synthetic_omop_gis.sql.gz`.

## Attribution and terms

The extract retains the terms of its sources. Please keep the notices below with any redistribution of these files.

- **SNOMED CT.** This material includes SNOMED Clinical Terms® (SNOMED CT®), which is used by permission of SNOMED International. All rights reserved. SNOMED CT® is a registered trademark of SNOMED International.
- **RxNorm.** RxNorm is produced by the U.S. National Library of Medicine (NLM), National Institutes of Health. This product uses publicly available data courtesy of the NLM; the NLM is not responsible for the product and does not endorse or recommend it.
- **LOINC.** This material contains content from LOINC (http://loinc.org). LOINC is copyright © Regenstrief Institute, Inc. and the Logical Observation Identifiers Names and Codes (LOINC) Committee and is available at no cost under the license at http://loinc.org/license. LOINC® is a registered United States trademark of Regenstrief Institute, Inc.
- **UCUM.** The Unified Code for Units of Measure (https://ucum.org) is maintained by the Regenstrief Institute and the UCUM organization.

The wording above follows each licensor's usual attribution statement; check the current text on the licensor's site before relying on it.

## Questions

If you represent a licensor and would like this extract changed or removed, open an issue at https://github.com/OHDSI/GIS/issues.
