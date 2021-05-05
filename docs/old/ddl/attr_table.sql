-- SEQUENCE: public.attr_<name>_record_id_seq

-- DROP SEQUENCE public.attr_<name>_record_id_seq;

CREATE SEQUENCE public.attr_<name>_record_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE public.attr_<name>_record_id_seq
    OWNER TO postgres;

-- Table: public.attr_<name>

-- DROP TABLE public.attr_<name>;

CREATE TABLE public.attr_<name>
(
    attr_record_id integer NOT NULL DEFAULT nextval('attr_<name>_record_id_seq'::regclass),
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
    CONSTRAINT attr_<name>_pkey PRIMARY KEY (attr_record_id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.attr_<name>
    OWNER to postgres;

-- Index: attr_<name>_attr_concept_id_idx

-- DROP INDEX public.attr_<name>_attr_concept_id_idx;

CREATE INDEX attr_<name>_attr_concept_id_idx
    ON public.attr_<name> USING btree
    (attr_concept_id ASC NULLS LAST)
    TABLESPACE pg_default;


-- Index: attr_<name>_attr_source_concept_id_idx

-- DROP INDEX public.attr_<name>_attr_source_concept_id_idx;

CREATE INDEX attr_<name>_attr_source_concept_id_idx
    ON public.attr_<name> USING btree
    (attr_source_concept_id ASC NULLS LAST)
    TABLESPACE pg_default;


-- Index: attr_<name>_geo_record_id_idx

-- DROP INDEX public.attr_<name>_geo_record_id_idx;

CREATE INDEX attr_<name>_geo_record_id_idx
    ON public.attr_<name> USING btree
    (geo_record_id ASC NULLS LAST)
    TABLESPACE pg_default;


-- Index: attr_<name>_qualifier_concept_id_idx

-- DROP INDEX public.attr_<name>_qualifier_concept_id_idx;

CREATE INDEX attr_<name>_qualifier_concept_id_idx
    ON public.attr_<name> USING btree
    (qualifier_concept_id ASC NULLS LAST)
    TABLESPACE pg_default;


-- Index: attr_<name>_unit_concept_id_idx

-- DROP INDEX public.attr_<name>_unit_concept_id_idx;

CREATE INDEX attr_<name>_unit_concept_id_idx
    ON public.attr_<name> USING btree
    (unit_concept_id ASC NULLS LAST)
    TABLESPACE pg_default;


-- Index: attr_<name>_value_as_concept_id_idx

-- DROP INDEX public.attr_<name>_value_as_concept_id_idx;

CREATE INDEX attr_<name>_value_as_concept_id_idx
    ON public.attr_<name> USING btree
    (value_as_concept_id ASC NULLS LAST)
    TABLESPACE pg_default;