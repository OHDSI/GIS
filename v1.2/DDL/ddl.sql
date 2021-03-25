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

create or replace procedure geocode(batch_size int)
language plpgsql
as $$
begin

  drop table if exists addresses_to_geocode;

  create table addresses_to_geocode (
    location_id BIGINT primary key,
    address norm_addy,
    lon numeric,
    lat numeric,
    new_address norm_addy,
    rating integer
  );

  insert into addresses_to_geocode (location_id, address)
    select
      location_id,
      pagc_normalize_address(CONCAT(address_1, ' ' || address_2, ', ', city, ', ', state, ' ', zip, ' ', county)) as address
    from location
  ;

  commit;

  call resume_geocode(batch_size);

end;$$

create or replace procedure resume_geocode(batch_size int)
language plpgsql
as $$
begin

  loop
    exit when (select count(*) from addresses_to_geocode where rating is null) = 0;

    update addresses_to_geocode
      set (rating, new_address, lon, lat)
        = ( coalesce(g.rating,-1), g.addy,
            ST_X(g.geomout)::numeric(8,5), ST_Y(g.geomout)::numeric(8,5) )
    from (
      select location_id, address
      from addresses_to_geocode
      where rating is null
      order by location_id
      limit batch_size
    ) as a
      left join lateral geocode(a.address,1) as g on true
    where a.location_id = addresses_to_geocode.location_id;

    commit;
  end loop;

end;$$

-- Table: public.data_source

-- DROP TABLE public.data_source;

CREATE TABLE public.data_source
(
    data_source_id integer NOT NULL,
    data_source_name character varying(255) COLLATE pg_catalog."default",
    data_source_description character varying(255) COLLATE pg_catalog."default",
    data_source_type_id integer,
    data_source_type_name character varying(255) COLLATE pg_catalog."default",
    document_url character varying(255) COLLATE pg_catalog."default",
    source_version double precision,
    collection_start_date character varying(255) COLLATE pg_catalog."default",
    collection_end_date character varying(255) COLLATE pg_catalog."default",
    timeframe_concept_id integer,
    timeframe_name character varying(255) COLLATE pg_catalog."default",
    timeframe_value integer,
    last_updated_date character varying(255) COLLATE pg_catalog."default",
    data_source_epsg integer,
    data_source_epsg_name character varying COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.data_source
    OWNER to postgres;

-- Table: public.geo_index

-- DROP TABLE public.geo_index;

CREATE TABLE public.geo_index
(
    geo_index_id serial NOT NULL,
    data_type_id integer,
    data_type_name character varying COLLATE pg_catalog."default",
    geo_type_concept_id integer,
    geo_type_source_value character varying COLLATE pg_catalog."default",
    schema character varying COLLATE pg_catalog."default",
    table_name character varying COLLATE pg_catalog."default",
    "desc" character varying COLLATE pg_catalog."default",
    data_source_id integer,
    epsg_local integer,
    epsg_local_name character varying COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE public.geo_index
    OWNER to postgres;


-- Table: public.attr_index

-- DROP TABLE public.attr_index;

CREATE TABLE public.attr_index
(
    attr_index_id serial NOT NULL,
    attr_type_concept_id integer,
    attr_type_source_value character varying COLLATE pg_catalog."default",
    attr_of_geo_id integer,
    schema character varying COLLATE pg_catalog."default",
    table_name character varying COLLATE pg_catalog."default",
    "desc" character varying COLLATE pg_catalog."default",
    data_source_id integer
)

TABLESPACE pg_default;

ALTER TABLE public.attr_index
    OWNER to postgres;

-- Table: public.geo_us_states

-- DROP TABLE public.geo_us_states;

CREATE TABLE public.geo_us_states
(
    geo_record_id serial NOT NULL,
    name character varying COLLATE pg_catalog."default",
    source_id_coding character varying COLLATE pg_catalog."default",
    source_id_value character varying(11) COLLATE pg_catalog."default",
    geom_wgs84 geometry(MultiPolygon,4326),
    geom_local geometry
)

TABLESPACE pg_default;

ALTER TABLE public.geo_us_states
    OWNER to postgres;

-- Table: public.attr_acs5_2018

-- DROP TABLE public.attr_acs5_2018;

CREATE TABLE public.attr_acs5_2018
(
    attr_record_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    geo_record_id integer,
    attr_concept_id integer,
    attr_start_date date,
    attr_end_date date,
    value_as_number double precision,
    value_as_string character varying COLLATE pg_catalog."default",
    value_as_concept_id integer,
    unit_concept_id integer,
    unit_source_value character varying COLLATE pg_catalog."default",
    qualifier_concept_id integer,
    qualifier_source_value character varying COLLATE pg_catalog."default",
    attr_source_concept_id integer,
    attr_source_value character varying COLLATE pg_catalog."default",
    value_source_value character varying COLLATE pg_catalog."default",
    CONSTRAINT attr_acs5_2018_pkey PRIMARY KEY (attr_record_id)
)

TABLESPACE pg_default;

ALTER TABLE public.attr_acs5_2018
    OWNER to postgres;
