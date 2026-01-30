CREATE VIEW omopgis.concept AS
    (SELECT * FROM vocabulary.concept
     UNION
     SELECT * FROM omopgis.concept_gis);

CREATE VIEW omopgis.concept_relationship AS
    (SELECT * FROM vocabulary.concept_relationship
     UNION
     SELECT * FROM omopgis.concept_relationship_gis);

CREATE VIEW omopgis.concept_ancestor AS
    (SELECT * FROM vocabulary.concept_ancestor
     UNION
     SELECT * FROM omopgis.concept_ancestor_gis);

CREATE VIEW omopgis.concept_class AS
    (SELECT * FROM vocabulary.concept_class
     UNION
     SELECT * FROM omopgis.concept_class_gis);

CREATE VIEW omopgis.concept_recommended AS
    (SELECT * FROM vocabulary.concept_recommended
     UNION
     SELECT * FROM omopgis.concept_recommended_gis);

CREATE VIEW omopgis.concept_synonym AS
    (SELECT * FROM vocabulary.concept_synonym
     UNION
     SELECT * FROM omopgis.concept_synonym_gis);

CREATE VIEW omopgis.domain AS
    (SELECT * FROM vocabulary.domain
     UNION
     SELECT * FROM omopgis.domain_gis);

CREATE VIEW omopgis.drug_strength AS
    (SELECT * FROM vocabulary.drug_strength
     UNION
     SELECT * FROM omopgis.drug_strength_gis);

CREATE VIEW omopgis.relationship AS
    (SELECT * FROM vocabulary.relationship
     UNION
     SELECT * FROM omopgis.relationship_gis);

CREATE VIEW omopgis.source_to_concept_map AS
    (SELECT * FROM vocabulary.source_to_concept_map
     UNION
     SELECT * FROM omopgis.source_to_concept_map_gis);

CREATE VIEW omopgis.vocabulary AS
    (SELECT * FROM vocabulary.vocabulary
     UNION
     SELECT * FROM omopgis.vocabulary_gis);
