--bigquery CDM Foreign Key Constraints for OMOP Common Data Model 5.4
alter table @cdmDatabaseSchema.location_history add constraint fpk_location_history_location_id foreign key (location_id) references @cdmDatabaseSchema.location (location_id);
alter table @cdmDatabaseSchema.location_history add constraint fpk_location_history_relationship_type_concept_id foreign key (relationship_type_concept_id) references @cdmDatabaseSchema.concept (concept_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_location_id foreign key (location_id) references @cdmDatabaseSchema.location (location_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_person_id foreign key (person_id) references @cdmDatabaseSchema.person (person_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_exposure_concept_id foreign key (exposure_concept_id) references @cdmDatabaseSchema.concept (concept_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_exposure_type_concept_id foreign key (exposure_type_concept_id) references @cdmDatabaseSchema.concept (concept_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_exposure_relationship_concept_id foreign key (exposure_relationship_concept_id) references @cdmDatabaseSchema.concept (concept_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_exposure_source_concept_id foreign key (exposure_source_concept_id) references @cdmDatabaseSchema.concept (concept_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_operator_concept_id foreign key (operator_concept_id) references @cdmDatabaseSchema.concept (concept_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_value_as_concept_id foreign key (value_as_concept_id) references @cdmDatabaseSchema.concept (concept_id);
alter table @cdmDatabaseSchema.external_exposure add constraint fpk_external_exposure_unit_concept_id foreign key (unit_concept_id) references @cdmDatabaseSchema.concept (concept_id);
