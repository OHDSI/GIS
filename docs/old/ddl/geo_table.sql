-- SEQUENCE: public.geo_<name>_id_seq

-- DROP SEQUENCE public.geo_<name>_id_seq;

CREATE SEQUENCE public.geo_<name>_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE public.geo_<name>_id_seq
    OWNER TO postgres;

-- Table: public.geo_<name>

-- DROP TABLE public.geo_<name>;

CREATE TABLE public.geo_<name>
(
    geo_record_id integer NOT NULL DEFAULT nextval('geo_<name>_id_seq'::regclass),
    name character varying COLLATE pg_catalog."default",
    source_id_coding character varying COLLATE pg_catalog."default",
    source_id_value character varying(11) COLLATE pg_catalog."default",
    -- geom_wgs84 geometry(Point,4326),
    geom_wgs84 geometry(MultiPolygon,4326),
    geom_local geometry,
    CONSTRAINT geo_<name>_pkey PRIMARY KEY (geo_record_id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.geo_<name>
    OWNER to postgres;