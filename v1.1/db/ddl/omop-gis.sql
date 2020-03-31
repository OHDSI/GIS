--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = public, pg_catalog;

--
-- Name: attr_florida_tri_2018_record_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE attr_florida_tri_2018_record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attr_florida_tri_2018_record_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: attr_florida_tri_2018; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE attr_florida_tri_2018 (
    attr_record_id integer DEFAULT nextval('attr_florida_tri_2018_record_id_seq'::regclass) NOT NULL,
    geo_record_id integer,
    attr_concept_id integer,
    attr_start_date date,
    attr_end_date date,
    value_as_number double precision,
    value_as_string character varying,
    value_as_concept_id integer,
    unit_concept_id integer,
    unit_source_value character varying,
    qualifier_concept_id integer,
    qualifier_source_value character varying,
    attr_source_concept_id integer,
    attr_source_value character varying,
    value_source_value character varying
);


ALTER TABLE public.attr_florida_tri_2018 OWNER TO postgres;

--
-- Name: attr_index_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE attr_index_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attr_index_id_seq OWNER TO postgres;

--
-- Name: attr_index; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE attr_index (
    attr_index_id integer DEFAULT nextval('attr_index_id_seq'::regclass) NOT NULL,
    attr_type_concept_id integer,
    attr_type_source_value character varying,
    attr_of_geo_id integer,
    schema character varying,
    table_name character varying,
    "desc" character varying,
    data_source_id character varying
);


ALTER TABLE public.attr_index OWNER TO postgres;

--
-- Name: care_site_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE care_site_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.care_site_id_seq OWNER TO postgres;

--
-- Name: care_site; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE care_site (
    care_site_id integer DEFAULT nextval('care_site_id_seq'::regclass) NOT NULL,
    care_site_name character varying(255),
    place_of_service_concept_id integer,
    care_site_source_value character varying(50),
    place_of_service_source_value character varying(50)
);


ALTER TABLE public.care_site OWNER TO postgres;

--
-- Name: data_source; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE data_source (
    data_source_id integer NOT NULL,
    data_source_name character varying(255),
    data_source_description character varying(255),
    data_source_type_id integer,
    data_source_type_name character varying(255),
    document_url character varying(255),
    source_version double precision,
    collection_start_date character varying(255),
    collection_end_date character varying(255),
    timeframe_concept_id integer,
    timeframe_name character varying(255),
    timeframe_value integer,
    last_updated_date character varying(255),
    data_source_epsg integer,
    data_source_epsg_name character varying
);


ALTER TABLE public.data_source OWNER TO postgres;

--
-- Name: dd_att_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE dd_att_cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dd_att_cat_id_seq OWNER TO postgres;

--
-- Name: dd_att_category; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE dd_att_category (
    id integer DEFAULT nextval('dd_att_cat_id_seq'::regclass) NOT NULL,
    name character varying(50)
);


ALTER TABLE public.dd_att_category OWNER TO postgres;

--
-- Name: dd_att_name_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE dd_att_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dd_att_name_id_seq OWNER TO postgres;

--
-- Name: dd_att_name; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE dd_att_name (
    id integer DEFAULT nextval('dd_att_name_id_seq'::regclass) NOT NULL,
    name character varying(50)
);


ALTER TABLE public.dd_att_name OWNER TO postgres;

--
-- Name: dd_att_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE dd_att_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dd_att_unit_id_seq OWNER TO postgres;

--
-- Name: dd_att_unit; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE dd_att_unit (
    id integer DEFAULT nextval('dd_att_unit_id_seq'::regclass) NOT NULL,
    name character varying(50)
);


ALTER TABLE public.dd_att_unit OWNER TO postgres;

--
-- Name: dd_attribute_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE dd_attribute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dd_attribute_id_seq OWNER TO postgres;

--
-- Name: dd_attribute; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE dd_attribute (
    dd_category_id integer,
    demographic_division_id integer,
    dd_unit_id integer,
    id integer DEFAULT nextval('dd_attribute_id_seq'::regclass) NOT NULL,
    value double precision,
    dd_name_id integer,
    dd_source_id integer
);


ALTER TABLE public.dd_attribute OWNER TO postgres;

--
-- Name: dd_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE dd_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dd_type_id_seq OWNER TO postgres;

--
-- Name: dd_type; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE dd_type (
    id integer DEFAULT nextval('dd_type_id_seq'::regclass) NOT NULL,
    name character varying,
    "desc" character varying
);


ALTER TABLE public.dd_type OWNER TO postgres;

--
-- Name: demographic_division; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE demographic_division (
    id integer NOT NULL,
    geom geometry(Polygon,4326),
    dd_type_id integer,
    code character varying(11),
    "desc" character varying,
    dd_source_id integer,
    local_geom geometry
);


ALTER TABLE public.demographic_division OWNER TO postgres;

--
-- Name: demographic_division_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE demographic_division_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.demographic_division_id_seq OWNER TO postgres;

--
-- Name: demographic_division_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE demographic_division_id_seq OWNED BY demographic_division.id;


--
-- Name: geo_florida_tri_2018_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE geo_florida_tri_2018_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geo_florida_tri_2018_id_seq OWNER TO postgres;

--
-- Name: geo_florida_tri_2018; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE geo_florida_tri_2018 (
    geo_record_id integer DEFAULT nextval('geo_florida_tri_2018_id_seq'::regclass) NOT NULL,
    name character varying,
    source_id_coding character varying,
    source_id_value character varying,
    geom_wgs84 geometry(Point,4326),
    geom_local geometry
);


ALTER TABLE public.geo_florida_tri_2018 OWNER TO postgres;

--
-- Name: geo_florida_tri_2018_record_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE geo_florida_tri_2018_record_id_seq
    START WITH 686
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geo_florida_tri_2018_record_id_seq OWNER TO postgres;

--
-- Name: geo_index_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE geo_index_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geo_index_id_seq OWNER TO postgres;

--
-- Name: geo_index; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE geo_index (
    geo_index_id integer DEFAULT nextval('geo_index_id_seq'::regclass) NOT NULL,
    data_type_id integer,
    data_type_name character varying,
    geo_type_concept_id integer,
    geo_type_source_value character varying,
    geo_id integer,
    schema character varying,
    table_name character varying,
    "desc" character varying,
    data_source_id integer,
    epsg_local integer,
    epsg_local_name character varying
);


ALTER TABLE public.geo_index OWNER TO postgres;

--
-- Name: geo_miamidade_census_tract_2018_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE geo_miamidade_census_tract_2018_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geo_miamidade_census_tract_2018_id_seq OWNER TO postgres;

--
-- Name: geo_miamidade_census_tract_2018; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE geo_miamidade_census_tract_2018 (
    geo_record_id integer DEFAULT nextval('geo_miamidade_census_tract_2018_id_seq'::regclass) NOT NULL,
    name character varying,
    source_id_coding character varying,
    source_id_value character varying(11),
    geom_wgs84 geometry(Polygon,4326),
    geom_local geometry
);


ALTER TABLE public.geo_miamidade_census_tract_2018 OWNER TO postgres;

--
-- Name: hz_point_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hz_point_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hz_point_id_seq OWNER TO postgres;

--
-- Name: hazard_point; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE hazard_point (
    id integer DEFAULT nextval('hz_point_id_seq'::regclass) NOT NULL,
    hz_type_id integer,
    name character varying(100),
    "desc" character varying(100),
    geom geometry(Geometry,4326),
    hazard_source_value character varying,
    hz_source_id integer,
    local_geom geometry
);


ALTER TABLE public.hazard_point OWNER TO postgres;

--
-- Name: hz_att_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hz_att_cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hz_att_cat_id_seq OWNER TO postgres;

--
-- Name: hz_att_category; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE hz_att_category (
    id integer DEFAULT nextval('hz_att_cat_id_seq'::regclass) NOT NULL,
    name character varying(50)
);


ALTER TABLE public.hz_att_category OWNER TO postgres;

--
-- Name: hz_att_name_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hz_att_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hz_att_name_id_seq OWNER TO postgres;

--
-- Name: hz_att_name; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE hz_att_name (
    id integer DEFAULT nextval('hz_att_name_id_seq'::regclass) NOT NULL,
    name character varying(80)
);


ALTER TABLE public.hz_att_name OWNER TO postgres;

--
-- Name: hz_att_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hz_att_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hz_att_unit_id_seq OWNER TO postgres;

--
-- Name: hz_att_unit; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE hz_att_unit (
    id integer DEFAULT nextval('hz_att_unit_id_seq'::regclass) NOT NULL,
    name character varying(50)
);


ALTER TABLE public.hz_att_unit OWNER TO postgres;

--
-- Name: hz_attribute_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hz_attribute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hz_attribute_id_seq OWNER TO postgres;

--
-- Name: hz_attribute; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE hz_attribute (
    hz_category_id integer,
    hz_point_id integer,
    hz_unit_id integer,
    id integer DEFAULT nextval('hz_attribute_id_seq'::regclass) NOT NULL,
    value double precision,
    hz_name_id integer,
    hz_att_source_id integer,
    collection_start_date date,
    collection_end_date date
);


ALTER TABLE public.hz_attribute OWNER TO postgres;

--
-- Name: hz_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hz_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hz_type_id_seq OWNER TO postgres;

--
-- Name: hz_type; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE hz_type (
    id integer DEFAULT nextval('hz_type_id_seq'::regclass) NOT NULL,
    name character varying(50),
    "desc" character varying(50)
);


ALTER TABLE public.hz_type OWNER TO postgres;

--
-- Name: location_history; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE location_history (
    location_id integer NOT NULL,
    relationship_type_concept_id character varying(50),
    domain_id character varying(50),
    entity_id integer NOT NULL,
    start_date date,
    end_date date
);


ALTER TABLE public.location_history OWNER TO postgres;

--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.locations_id_seq OWNER TO postgres;

--
-- Name: locations; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE locations (
    location_id integer DEFAULT nextval('locations_id_seq'::regclass) NOT NULL,
    address_1 character varying(50),
    address_2 character varying(50),
    city character varying(50),
    state character varying(2),
    zip character varying(9),
    county character varying(20),
    country character varying(100),
    location_source_value character varying(150),
    latitude double precision,
    longitude double precision,
    geom geometry(Geometry,4326),
    geom_source_id integer,
    local_geom geometry
);


ALTER TABLE public.locations OWNER TO postgres;

--
-- Name: persons; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE persons (
    person_id integer NOT NULL,
    census_tract integer,
    county integer,
    state integer,
    gender_concept_id character varying,
    ethnicity_concept_id character varying,
    race_concept_id character varying,
    year_of_birth character varying,
    census_string_id character varying(6)
);


ALTER TABLE public.persons OWNER TO postgres;

--
-- Name: site_history; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE site_history (
    site_id integer NOT NULL,
    relationship_type_concept_id character varying(50),
    domain_id character varying(50),
    entity_id integer NOT NULL,
    start_date date,
    end_date date
);


ALTER TABLE public.site_history OWNER TO postgres;

--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sites_id_seq OWNER TO postgres;

--
-- Name: sites; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE sites (
    site_id integer DEFAULT nextval('sites_id_seq'::regclass) NOT NULL,
    address_1 character varying(50),
    address_2 character varying(50),
    city character varying(50),
    state character varying(2),
    zip character varying(9),
    county character varying(20),
    country character varying(100),
    location_source_value character varying(150),
    latitude double precision,
    longitude double precision,
    geom geometry(Geometry,4326),
    geom_source_id integer,
    local_geom geometry
);


ALTER TABLE public.sites OWNER TO postgres;

--
-- Name: utm_grid; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE utm_grid (
    id integer NOT NULL,
    geom geometry(MultiPolygon,4326),
    hemisphere character varying(3),
    zone character varying(5),
    zone_hemi character varying(5)
);


ALTER TABLE public.utm_grid OWNER TO postgres;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY demographic_division ALTER COLUMN id SET DEFAULT nextval('demographic_division_id_seq'::regclass);


--
-- Name: attr_index_id_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY attr_index
    ADD CONSTRAINT attr_index_id_pkey PRIMARY KEY (attr_index_id);


--
-- Name: care_site_id_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY care_site
    ADD CONSTRAINT care_site_id_pkey PRIMARY KEY (care_site_id);


--
-- Name: data_source_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY data_source
    ADD CONSTRAINT data_source_pkey PRIMARY KEY (data_source_id);


--
-- Name: dd_att_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY dd_att_category
    ADD CONSTRAINT dd_att_cat_pkey PRIMARY KEY (id);


--
-- Name: dd_att_name_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY dd_att_name
    ADD CONSTRAINT dd_att_name_pkey PRIMARY KEY (id);


--
-- Name: dd_attribute_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY dd_attribute
    ADD CONSTRAINT dd_attribute_pkey PRIMARY KEY (id);


--
-- Name: dd_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY demographic_division
    ADD CONSTRAINT dd_pkey PRIMARY KEY (id);


--
-- Name: dd_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY dd_type
    ADD CONSTRAINT dd_type_pkey PRIMARY KEY (id);


--
-- Name: dd_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY dd_att_unit
    ADD CONSTRAINT dd_unit_pkey PRIMARY KEY (id);


--
-- Name: florida_tri_2018_attr_table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY attr_florida_tri_2018
    ADD CONSTRAINT florida_tri_2018_attr_table_pkey PRIMARY KEY (attr_record_id);


--
-- Name: geo_florida_tri_2018_record_id_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY geo_florida_tri_2018
    ADD CONSTRAINT geo_florida_tri_2018_record_id_pkey PRIMARY KEY (geo_record_id);


--
-- Name: geo_index_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY geo_index
    ADD CONSTRAINT geo_index_pkey PRIMARY KEY (geo_index_id);


--
-- Name: geo_miamidade_census_tracts_2018_record_id_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY geo_miamidade_census_tract_2018
    ADD CONSTRAINT geo_miamidade_census_tracts_2018_record_id_pkey PRIMARY KEY (geo_record_id);


--
-- Name: hazard_point_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY hazard_point
    ADD CONSTRAINT hazard_point_pkey PRIMARY KEY (id);


--
-- Name: hazard_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY hz_type
    ADD CONSTRAINT hazard_type_pkey PRIMARY KEY (id);


--
-- Name: hz_att_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY hz_att_category
    ADD CONSTRAINT hz_att_cat_pkey PRIMARY KEY (id);


--
-- Name: hz_att_name_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY hz_att_name
    ADD CONSTRAINT hz_att_name_pkey PRIMARY KEY (id);


--
-- Name: hz_att_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY hz_att_unit
    ADD CONSTRAINT hz_att_unit_pkey PRIMARY KEY (id);


--
-- Name: hz_attribute_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY hz_attribute
    ADD CONSTRAINT hz_attribute_pkey PRIMARY KEY (id);


--
-- Name: hz_type_name_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY hz_type
    ADD CONSTRAINT hz_type_name_uniq UNIQUE (name);


--
-- Name: loc_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY location_history
    ADD CONSTRAINT loc_hist_pkey PRIMARY KEY (location_id, entity_id);


--
-- Name: locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);


--
-- Name: person_id_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY persons
    ADD CONSTRAINT person_id_pkey PRIMARY KEY (person_id);


--
-- Name: site_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY site_history
    ADD CONSTRAINT site_hist_pkey PRIMARY KEY (site_id, entity_id);


--
-- Name: sites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (site_id);


--
-- Name: utm_grid_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY utm_grid
    ADD CONSTRAINT utm_grid_pkey PRIMARY KEY (id);


--
-- Name: fki_attr_concept_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_attr_concept_id_fkey ON attr_florida_tri_2018 USING btree (attr_concept_id);


--
-- Name: fki_attr_source_concept_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_attr_source_concept_id_fkey ON attr_florida_tri_2018 USING btree (attr_source_concept_id);


--
-- Name: fki_attribute_of_geo_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_attribute_of_geo_id_fkey ON attr_index USING btree (attr_of_geo_id);


--
-- Name: fki_care_site_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_care_site_fkey ON site_history USING btree (entity_id);


--
-- Name: fki_data_source_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_data_source_id_fkey ON geo_index USING btree (data_source_id);


--
-- Name: fki_dd_att_category_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_dd_att_category_fkey ON dd_attribute USING btree (dd_category_id);


--
-- Name: fki_dd_att_name_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_dd_att_name_fkey ON dd_attribute USING btree (dd_name_id);


--
-- Name: fki_dd_att_source_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_dd_att_source_id ON dd_attribute USING btree (dd_source_id);


--
-- Name: fki_dd_source_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_dd_source_fkey ON demographic_division USING btree (dd_source_id);


--
-- Name: fki_dd_unit_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_dd_unit_fkey ON dd_attribute USING btree (dd_unit_id);


--
-- Name: fki_demographic_division_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_demographic_division_id_fkey ON dd_attribute USING btree (demographic_division_id);


--
-- Name: fki_geo_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_geo_id_fkey ON attr_florida_tri_2018 USING btree (geo_record_id);


--
-- Name: fki_geom_source_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_geom_source_id_fkey ON locations USING btree (geom_source_id);


--
-- Name: fki_hazard_type_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_hazard_type_fkey ON hazard_point USING btree (hz_type_id);


--
-- Name: fki_hz_att_source_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_hz_att_source_id_fkey ON hz_attribute USING btree (hz_att_source_id);


--
-- Name: fki_hz_category_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_hz_category_fkey ON hz_attribute USING btree (hz_category_id);


--
-- Name: fki_hz_name_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_hz_name_fkey ON hz_attribute USING btree (hz_name_id);


--
-- Name: fki_hz_point_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_hz_point_fkey ON hz_attribute USING btree (hz_point_id);


--
-- Name: fki_hz_source_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_hz_source_fkey ON hazard_point USING btree (hz_source_id);


--
-- Name: fki_hz_unity_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_hz_unity_fkey ON hz_attribute USING btree (hz_unit_id);


--
-- Name: fki_location_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_location_fkey ON location_history USING btree (location_id);


--
-- Name: fki_person_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_person_fkey ON location_history USING btree (entity_id);


--
-- Name: fki_qualifier_concept_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_qualifier_concept_id_fkey ON attr_florida_tri_2018 USING btree (qualifier_concept_id);


--
-- Name: fki_site_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_site_fkey ON site_history USING btree (site_id);


--
-- Name: fki_sites_geom_source_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_sites_geom_source_id_fkey ON sites USING btree (geom_source_id);


--
-- Name: fki_unit_concept_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_unit_concept_id_fkey ON attr_florida_tri_2018 USING btree (unit_concept_id);


--
-- Name: fki_value_as_concept_id_fkey; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_value_as_concept_id_fkey ON attr_florida_tri_2018 USING btree (value_as_concept_id);


--
-- Name: attr_concept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attr_florida_tri_2018
    ADD CONSTRAINT attr_concept_id_fkey FOREIGN KEY (attr_concept_id) REFERENCES hz_att_name(id);


--
-- Name: attr_of_geo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attr_index
    ADD CONSTRAINT attr_of_geo_id_fkey FOREIGN KEY (attr_of_geo_id) REFERENCES geo_index(geo_index_id);


--
-- Name: attr_source_concept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attr_florida_tri_2018
    ADD CONSTRAINT attr_source_concept_id_fkey FOREIGN KEY (attr_source_concept_id) REFERENCES data_source(data_source_id);


--
-- Name: care_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY site_history
    ADD CONSTRAINT care_site_fkey FOREIGN KEY (entity_id) REFERENCES care_site(care_site_id);


--
-- Name: data_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY geo_index
    ADD CONSTRAINT data_source_id_fkey FOREIGN KEY (data_source_id) REFERENCES data_source(data_source_id);


--
-- Name: dd_att_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY dd_attribute
    ADD CONSTRAINT dd_att_category_fkey FOREIGN KEY (dd_category_id) REFERENCES dd_att_category(id);


--
-- Name: dd_att_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY dd_attribute
    ADD CONSTRAINT dd_att_name_fkey FOREIGN KEY (dd_name_id) REFERENCES dd_att_name(id);


--
-- Name: dd_att_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY dd_attribute
    ADD CONSTRAINT dd_att_source_id_fkey FOREIGN KEY (dd_source_id) REFERENCES data_source(data_source_id);


--
-- Name: dd_att_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY dd_attribute
    ADD CONSTRAINT dd_att_unit_fkey FOREIGN KEY (dd_unit_id) REFERENCES dd_att_unit(id);


--
-- Name: dd_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY demographic_division
    ADD CONSTRAINT dd_source_fkey FOREIGN KEY (dd_source_id) REFERENCES data_source(data_source_id);


--
-- Name: dd_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY demographic_division
    ADD CONSTRAINT dd_type_fkey FOREIGN KEY (dd_type_id) REFERENCES dd_type(id);


--
-- Name: demographic_division_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY dd_attribute
    ADD CONSTRAINT demographic_division_id_fkey FOREIGN KEY (demographic_division_id) REFERENCES demographic_division(id);


--
-- Name: geo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attr_florida_tri_2018
    ADD CONSTRAINT geo_id_fkey FOREIGN KEY (geo_record_id) REFERENCES geo_florida_tri_2018(geo_record_id);


--
-- Name: geom_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT geom_source_id_fkey FOREIGN KEY (geom_source_id) REFERENCES data_source(data_source_id);


--
-- Name: hz_att_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hz_attribute
    ADD CONSTRAINT hz_att_category_fkey FOREIGN KEY (hz_category_id) REFERENCES hz_att_category(id);


--
-- Name: hz_att_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hz_attribute
    ADD CONSTRAINT hz_att_name_fkey FOREIGN KEY (hz_name_id) REFERENCES hz_att_name(id);


--
-- Name: hz_att_point_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hz_attribute
    ADD CONSTRAINT hz_att_point_fkey FOREIGN KEY (hz_point_id) REFERENCES hazard_point(id);


--
-- Name: hz_att_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hz_attribute
    ADD CONSTRAINT hz_att_source_id_fkey FOREIGN KEY (hz_att_source_id) REFERENCES data_source(data_source_id);


--
-- Name: hz_att_unit_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hz_attribute
    ADD CONSTRAINT hz_att_unit_fkey FOREIGN KEY (hz_unit_id) REFERENCES hz_att_unit(id);


--
-- Name: hz_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hazard_point
    ADD CONSTRAINT hz_source_fkey FOREIGN KEY (hz_source_id) REFERENCES data_source(data_source_id);


--
-- Name: hz_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hazard_point
    ADD CONSTRAINT hz_type_fkey FOREIGN KEY (hz_type_id) REFERENCES hz_type(id);


--
-- Name: location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY location_history
    ADD CONSTRAINT location_fkey FOREIGN KEY (location_id) REFERENCES locations(location_id);


--
-- Name: locations_geom_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_geom_source_id_fkey FOREIGN KEY (geom_source_id) REFERENCES data_source(data_source_id);


--
-- Name: person_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY location_history
    ADD CONSTRAINT person_fkey FOREIGN KEY (entity_id) REFERENCES persons(person_id);


--
-- Name: qualifier_concept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attr_florida_tri_2018
    ADD CONSTRAINT qualifier_concept_id_fkey FOREIGN KEY (qualifier_concept_id) REFERENCES hz_att_category(id);


--
-- Name: site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY site_history
    ADD CONSTRAINT site_fkey FOREIGN KEY (site_id) REFERENCES sites(site_id);


--
-- Name: sites_geom_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT sites_geom_source_id_fkey FOREIGN KEY (geom_source_id) REFERENCES data_source(data_source_id);


--
-- Name: unit_concept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attr_florida_tri_2018
    ADD CONSTRAINT unit_concept_id_fkey FOREIGN KEY (unit_concept_id) REFERENCES hz_att_unit(id);


--
-- Name: value_as_concept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attr_florida_tri_2018
    ADD CONSTRAINT value_as_concept_id_fkey FOREIGN KEY (value_as_concept_id) REFERENCES hz_type(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

