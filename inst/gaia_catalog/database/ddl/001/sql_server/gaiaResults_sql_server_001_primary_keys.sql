--sql server CDM Primary Key Constraints for Gaia Results Exposure Occurrence 001
ALTER TABLE @cdmDatabaseSchema.exposure_occurrence ADD CONSTRAINT xpk_exposure_occurrence PRIMARY KEY NONCLUSTERED (exposure_occurrence_id);
