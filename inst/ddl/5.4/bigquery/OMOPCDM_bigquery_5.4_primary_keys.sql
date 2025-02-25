--bigquery CDM Primary Key Constraints for OMOP Common Data Model 5.4
alter table @cdmDatabaseSchema.external_exposure add constraint xpk_external_exposure primary key nonclustered (external_exposure_id);
