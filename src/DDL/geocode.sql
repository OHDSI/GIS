create or replace procedure geocode(batch_size int)
language plpgsql
as $$
begin

  drop table if exists addresses_to_geocode;

  create table addresses_to_geocode (
    location_id BIGINT primary key,
    address norm_addy,
    the_geom geometry,
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

end;$$;

create or replace procedure resume_geocode(batch_size int)
language plpgsql
as $$
begin

  loop
    exit when (select count(*) from addresses_to_geocode where rating is null) = 0;

    update addresses_to_geocode
      set (rating, new_address, the_geom)
        = ( coalesce(g.rating,-1), g.addy,
            g.geomout )
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

end;$$;
