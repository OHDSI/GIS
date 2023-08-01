/*@targetDialect OMOP CDM Indices

  There are no unique indices created because it is assumed that the primary key constraints have been run prior to
  implementing indices.
*/

/************************

gaiaResults Exposure Occurrence

************************/

CREATE CLUSTERED INDEX idx_exposure_person_id ON @cdmDatabaseSchema.exposure_occurrence (person_id ASC);
CREATE INDEX idx_exposure_concept ON @cdmDatabaseSchema.exposure_occurrence (exposure_concept_id ASC);
