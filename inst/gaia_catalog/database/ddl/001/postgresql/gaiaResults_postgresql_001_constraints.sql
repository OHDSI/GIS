--postgresql CDM Foreign Key Constraints for Gaia Results Exposure Occurrence 001
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_location_id FOREIGN KEY (location_id) REFERENCES @cdmDatabaseSchema.location (location_id);
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_person_id FOREIGN KEY (person_id) REFERENCES @cdmDatabaseSchema.person (person_id);
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_exposure_concept_id FOREIGN KEY (exposure_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_exposure_type_concept_id FOREIGN KEY (exposure_type_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_exposure_relationship_concept_id FOREIGN KEY (exposure_relationship_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_exposure_source_concept_id FOREIGN KEY (exposure_source_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_operator_concept_id FOREIGN KEY (operator_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_value_as_concept_id FOREIGN KEY (value_as_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT fpk_exposure_occurrence_unit_concept_id FOREIGN KEY (unit_concept_id) REFERENCES @cdmDatabaseSchema.concept (concept_id);
