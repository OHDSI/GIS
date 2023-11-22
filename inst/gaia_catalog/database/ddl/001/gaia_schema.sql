CREATE SCHEMA IF NOT EXISTS backbone AUTHORIZATION postgres;

ALTER USER postgres SET search_path TO backbone, public;