set search_path to @devVocabSchema;

ALTER TABLE CONCEPT DROP CONSTRAINT fpk_CONCEPT_domain_id;
ALTER TABLE CONCEPT DROP CONSTRAINT fpk_CONCEPT_vocabulary_id;
ALTER TABLE CONCEPT DROP CONSTRAINT fpk_CONCEPT_concept_class_id;
ALTER TABLE VOCABULARY DROP CONSTRAINT fpk_VOCABULARY_vocabulary_concept_id;
ALTER TABLE DOMAIN DROP CONSTRAINT fpk_DOMAIN_domain_concept_id;
ALTER TABLE concept_class DROP CONSTRAINT fpk_concept_class_concept_class_concept_id;
ALTER TABLE CONCEPT_RELATIONSHIP DROP CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_1;
ALTER TABLE CONCEPT_RELATIONSHIP DROP CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_2;
ALTER TABLE CONCEPT_RELATIONSHIP DROP CONSTRAINT fpk_CONCEPT_RELATIONSHIP_relationship_id;
ALTER TABLE RELATIONSHIP DROP CONSTRAINT fpk_RELATIONSHIP_relationship_concept_id;

delete from concept_relationship where concept_id_1 > 2000000000;
delete from concept_relationship where concept_id_2 > 2000000000;
delete from concept_class where concept_class_concept_id > 2000000000;
delete from domain where domain_concept_id > 2000000000;
delete from relationship where relationship_concept_id > 2000000000;
delete from vocabulary where vocabulary_concept_id > 2000000000;
delete from concept_ancestor where ancestor_concept_id > 2000000000;
delete from concept_ancestor where descendant_concept_id > 2000000000;
delete from concept where concept_id > 2000000000;

ALTER TABLE CONCEPT ADD CONSTRAINT fpk_CONCEPT_domain_id FOREIGN KEY (domain_id) REFERENCES DOMAIN (DOMAIN_ID);
ALTER TABLE CONCEPT ADD CONSTRAINT fpk_CONCEPT_vocabulary_id FOREIGN KEY (vocabulary_id) REFERENCES VOCABULARY (VOCABULARY_ID);
ALTER TABLE CONCEPT ADD CONSTRAINT fpk_CONCEPT_concept_class_id FOREIGN KEY (concept_class_id) REFERENCES CONCEPT_CLASS (CONCEPT_CLASS_ID);
ALTER TABLE VOCABULARY ADD CONSTRAINT fpk_VOCABULARY_vocabulary_concept_id FOREIGN KEY (vocabulary_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE DOMAIN ADD CONSTRAINT fpk_DOMAIN_domain_concept_id FOREIGN KEY (domain_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_CLASS ADD CONSTRAINT fpk_CONCEPT_CLASS_concept_class_concept_id FOREIGN KEY (concept_class_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_1 FOREIGN KEY (concept_id_1) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_2 FOREIGN KEY (concept_id_2) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_relationship_id FOREIGN KEY (relationship_id) REFERENCES RELATIONSHIP (RELATIONSHIP_ID);
ALTER TABLE RELATIONSHIP ADD CONSTRAINT fpk_RELATIONSHIP_relationship_concept_id FOREIGN KEY (relationship_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
