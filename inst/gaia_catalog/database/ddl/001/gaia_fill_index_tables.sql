truncate backbone.geom_index;
truncate backbone.attr_index;

insert into backbone.geom_index
select row_number() over() as geom_index_id
		, null as data_type_id
		, geom_type as data_type_name
		, null as geom_type_concept_id 
		, boundary_type as geom_type_source_value
		, regexp_replace(regexp_replace(lower(concat(org_id, '_', org_set_id)), '\W','_', 'g'), '^_+|_+$|_(?=_)', '', 'g') as database_schema
		, regexp_replace(regexp_replace(lower(concat(dataset_name)), '\W','_', 'g'), '^_+|_+$|_(?=_)', '', 'g') as table_name
		, concat_ws(' ', org_id, org_set_id, dataset_name) as table_desc
		, data_source_uuid as data_source_id
from backbone.data_source
where geom_type <> ''
and geom_type is not null
and data_source_uuid not in (
	select data_source_uuid
	from backbone.geom_index
);

insert into backbone.attr_index 
select row_number() over() as attr_index_id
		, vs.variable_source_id as variable_source_id
		, gi.geom_index_id as attr_of_geom_index_id
		, regexp_replace(regexp_replace(lower(concat(ds.org_id, '_', ds.org_set_id)), '\W','_', 'g'), '^_+|_+$|_(?=_)', '', 'g') as database_schema
		, regexp_replace(regexp_replace(lower(concat(ds.dataset_name)), '\W','_', 'g'), '^_+|_+$|_(?=_)', '', 'g') as table_name
		, ds.data_source_uuid as data_source_id
from backbone.data_source ds
inner join backbone.variable_source vs
on ds.data_source_uuid = vs.data_source_uuid 
and ds.has_attributes=1
inner join backbone.geom_index gi
on gi.data_source_id = vs.geom_dependency_uuid;
