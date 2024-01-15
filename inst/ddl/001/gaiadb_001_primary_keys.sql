-- Primary Key Constraints for gaiaDB version 001
ALTER TABLE backbone.data_source  ADD CONSTRAINT xpk_data_source PRIMARY KEY (data_source_uuid);
ALTER TABLE backbone.variable_source  ADD CONSTRAINT xpk_variable_source PRIMARY KEY (variable_source_id);
ALTER TABLE backbone.attr_index  ADD CONSTRAINT xpk_attr_index PRIMARY KEY (attr_index_id);
ALTER TABLE backbone.geom_index  ADD CONSTRAINT xpk_geom_index PRIMARY KEY (geom_index_id);
ALTER TABLE backbone.attr_template  ADD CONSTRAINT xpk_attr_template PRIMARY KEY (attr_record_id);
ALTER TABLE backbone.geom_template  ADD CONSTRAINT xpk_geom_template PRIMARY KEY (geom_record_id);
