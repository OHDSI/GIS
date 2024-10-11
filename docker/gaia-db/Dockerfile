FROM postgis/postgis:16-3.4-alpine

RUN mkdir /csv
COPY inst/csv/data_source.csv /csv/data_source.csv
COPY inst/csv/variable_source.csv /csv/variable_source.csv
COPY vocabularies/gis_vocabs_vocabulary_stage_v1.csv /csv/gis_vocabulary_fragment.csv
COPY vocabularies/gis_vocabs_concept_class_stage_v1.csv /csv/gis_concept_class_fragment.csv
COPY vocabularies/gis_vocabs_domain_stage_v1.csv /csv/gis_domain_fragment.csv
COPY vocabularies/gis_vocabs_concept_stage_v1.csv /csv/gis_concept_fragment.csv
COPY vocabularies/gis_vocabs_relationship_stage_v1.csv /csv/gis_relationship_fragment.csv
COPY vocabularies/gis_vocabs_concept_relationship_stage_v1.csv /csv/gis_concept_relationship_fragment.csv
COPY docker/gaia-db/init.sql /docker-entrypoint-initdb.d/init.sql
