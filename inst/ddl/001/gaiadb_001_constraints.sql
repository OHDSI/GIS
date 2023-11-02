-- Foreign Key Constraints for gaiaDB version 001
ALTER TABLE backbone.variable_source ADD CONSTRAINT fpk_variable_source_geom_dependency_uuid FOREIGN KEY (geom_dependency_uuid) REFERENCES backbone.data_source (data_source_uuid);
ALTER TABLE backbone.variable_source ADD CONSTRAINT fpk_variable_source_data_source_uuid FOREIGN KEY (data_source_uuid) REFERENCES backbone.data_source (data_source_uuid);
ALTER TABLE backbone.attr_index ADD CONSTRAINT fpk_attr_index_variable_source_id FOREIGN KEY (variable_source_id) REFERENCES backbone.variable_source (variable_source_id);
ALTER TABLE backbone.attr_index ADD CONSTRAINT fpk_attr_index_attr_of_geom_index_id FOREIGN KEY (attr_of_geom_index_id) REFERENCES backbone.geom_index (geom_index_id);
ALTER TABLE backbone.attr_index ADD CONSTRAINT fpk_attr_index_data_source_id FOREIGN KEY (data_source_id) REFERENCES backbone.data_source (data_source_uuid);
ALTER TABLE backbone.geom_index ADD CONSTRAINT fpk_geom_index_geom_type_concept_id FOREIGN KEY (geom_type_concept_id) REFERENCES backbone.concept (concept_id);
ALTER TABLE backbone.geom_index ADD CONSTRAINT fpk_geom_index_data_source_id FOREIGN KEY (data_source_id) REFERENCES backbone.data_source (data_source_uuid);
ALTER TABLE backbone.attr_template ADD CONSTRAINT fpk_attr_template_geom_record_id FOREIGN KEY (geom_record_id) REFERENCES backbone.geom_template (geom_record_id);
ALTER TABLE backbone.attr_template ADD CONSTRAINT fpk_attr_template_variable_source_record_id FOREIGN KEY (variable_source_record_id) REFERENCES backbone.variable_source (variable_source_id);
ALTER TABLE backbone.attr_template ADD CONSTRAINT fpk_attr_template_attr_concept_id FOREIGN KEY (attr_concept_id) REFERENCES backbone.concept (concept_id);
ALTER TABLE backbone.attr_template ADD CONSTRAINT fpk_attr_template_value_as_concept_id FOREIGN KEY (value_as_concept_id) REFERENCES backbone.concept (concept_id);
ALTER TABLE backbone.attr_template ADD CONSTRAINT fpk_attr_template_unit_concept_id FOREIGN KEY (unit_concept_id) REFERENCES backbone.concept (concept_id);
ALTER TABLE backbone.attr_template ADD CONSTRAINT fpk_attr_template_qualifier_concept_id FOREIGN KEY (qualifier_concept_id) REFERENCES backbone.concept (concept_id);
ALTER TABLE backbone.attr_template ADD CONSTRAINT fpk_attr_template_attr_source_concept_id FOREIGN KEY (attr_source_concept_id) REFERENCES backbone.concept (concept_id);
