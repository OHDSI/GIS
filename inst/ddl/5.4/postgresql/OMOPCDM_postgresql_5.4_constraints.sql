--postgresql CDM Foreign Key Constraints for OMOP Common Data Model 5.4
ALTER TABLE @cdmDatabaseSchema.location_history  ADD CONSTRAINT fpk_location_history_location_id FOREIGN KEY (location_id) REFERENCES @cdmDatabaseSchema.location (location_id);
ALTER TABLE @cdmDatabaseSchema.location_history  ADD CONSTRAINT fpk_location_history_relationship_type_concept_id FOREIGN KEY (relationship_type_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_location_id FOREIGN KEY (location_id) REFERENCES @cdmDatabaseSchema.location (location_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.person (person_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_exposure_concept_id FOREIGN KEY (exposure_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_exposure_type_concept_id FOREIGN KEY (exposure_type_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_exposure_relationship_concept_id FOREIGN KEY (exposure_relationship_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_exposure_source_concept_id FOREIGN KEY (exposure_source_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_operator_concept_id FOREIGN KEY (operator_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_value_as_concept_id FOREIGN KEY (value_as_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.external_exposure  ADD CONSTRAINT fpk_external_exposure_unit_concept_id FOREIGN KEY (unit_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
