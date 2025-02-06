--redshift CDM Primary Key Constraints for OMOP Common Data Model 5.4
ALTER TABLE @cdmDatabaseSchema.external_exposure ADD CONSTRAINT xpk_external_exposure PRIMARY KEY (external_exposure_id);
