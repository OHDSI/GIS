-- OMOP Location table https://github.com/OHDSI/CommonDataModel

--HINT DISTRIBUTE ON RANDOM
CREATE TABLE location
(
  location_id			BIGINT			NOT NULL ,
  address_1				VARCHAR(50)		NULL ,
  address_2				VARCHAR(50)		NULL ,
  city					VARCHAR(50)		NULL ,
  state					VARCHAR(2)		NULL ,
  zip					VARCHAR(9)		NULL ,
  county				VARCHAR(20)		NULL ,
  country				VARCHAR(100)	NULL ,
  location_source_value VARCHAR(50)		NULL ,
  latitude				NUMERIC			NULL ,
  longitude				NUMERIC			NULL
)
;
ALTER TABLE location ADD CONSTRAINT xpk_location PRIMARY KEY ( location_id ) ;
