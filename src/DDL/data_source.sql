CREATE TABLE data_source
(
    data_source_id integer primary key,
    data_source_name varchar,
    data_source_description varchar,
    document_url varchar,
    source_version varchar,
    collection_start_date date,
    collection_end_date date,
    last_updated_date date
);
