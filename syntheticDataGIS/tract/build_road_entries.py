#!/usr/bin/env python3
"""Writes the catalog entries of the road-proximity scenario: TIGER primary and secondary roads (us_2019_prisecroads_tl) and simulated distance bands (synthetic_road_proximity).

  tract/build_road_entries.py --catalog ../gaiaCatalog/datastore/data
"""
import argparse, json, os, textwrap

ROADS, BANDS = "us_2019_prisecroads_tl", "synthetic_road_proximity"
BAND_LIMITS = [0, 50, 100, 200, 400]
INCREMENT = lambda mid: round(2.0 * __import__("math").exp(-mid / 150.0), 3)


def write(path, text, exe=False):
    open(path, "w").write(text)
    if exe: os.chmod(path, 0o755)


def roads_osgeo():
    return textwrap.dedent('''\
    #!/bin/bash

    # us_2019_prisecroads_tl_osgeo.sh
    # Download and ETL into postGIS from osgeo_postgis container
    #
    # Data source: https://www2.census.gov/geo/tiger/TIGER2019/PRISECROADS/tl_2019_<state fips>_prisecroads.zip
    # Destination postGIS table: us_2019_prisecroads_tl

    export POSTGRES_PASSWORD=$(cat $PG_PASSWORD_FILE)

    STATES="${TRACT_STATES:-01}"

    mkdir -p /data/us_2019_prisecroads_tl/download -p /data/us_2019_prisecroads_tl/etl
    chmod -R 777 /data/us_2019_prisecroads_tl
    cd /data/us_2019_prisecroads_tl

    do_update=0
    [[ -e datestamp ]] || do_update=1

    if [[ $do_update = 1 ]]; then
      for st in $STATES; do
        attempts=0
        until (
          wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 10 -O download/tl_2019_${st}_prisecroads.zip "https://www2.census.gov/geo/tiger/TIGER2019/PRISECROADS/tl_2019_${st}_prisecroads.zip" 2>&1
        ); do
          ((attempts++))
          if (( attempts > 3 )); then echo $?; break; fi
        done
        unzip -o download/tl_2019_${st}_prisecroads.zip -d download && rm download/tl_2019_${st}_prisecroads.zip 2>&1
      done
      echo $(date '+%F %T') > datestamp
    fi

    first=1
    for st in $STATES; do
      if [[ $first = 1 ]]; then
        ogr2ogr -lco GEOMETRY_NAME=geom -f PostgreSQL PG:"dbname=$POSTGRES_DB port=$POSTGRES_PORT user=$POSTGRES_USER password=$POSTGRES_PASSWORD host='gaia-db'" download/tl_2019_${st}_prisecroads.shp -nlt multilinestring -nln us_2019_prisecroads_tl
        first=0
      else
        ogr2ogr -append -f PostgreSQL PG:"dbname=$POSTGRES_DB port=$POSTGRES_PORT user=$POSTGRES_USER password=$POSTGRES_PASSWORD host='gaia-db'" download/tl_2019_${st}_prisecroads.shp -nlt multilinestring -nln us_2019_prisecroads_tl
      fi
      echo success: tl_2019_${st}_prisecroads.shp loaded with ogr2ogr
    done
    ''')


def roads_postgis():
    return textwrap.dedent('''\
    #!/bin/bash

    # us_2019_prisecroads_tl_postgis.sh
    # Finish ETL into postGIS from postgis_postgis container
    #
    # Data source: https://www2.census.gov/geo/tiger/TIGER2019/PRISECROADS/tl_2019_<state fips>_prisecroads.zip
    # Destination postGIS table: us_2019_prisecroads_tl

    psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -c "
    UPDATE us_2019_prisecroads_tl
      SET geom=ST_MakeValid(ST_RemoveRepeatedPoints(geom));
    ALTER TABLE us_2019_prisecroads_tl DROP COLUMN IF EXISTS geom_local CASCADE;
    SELECT AddGeometryColumn ('us_2019_prisecroads_tl', 'geom_local', 4269, 'multilinestring', 2);
    UPDATE us_2019_prisecroads_tl
      SET geom_local=ST_Multi(ST_Transform(geom,4269));
    CREATE INDEX us_2019_prisecroads_tl_geom_local_idx ON us_2019_prisecroads_tl USING GIST (geom_local);
    NOTIFY pgrst, 'reload schema';
    " 2>&1
    ''')


def bands_osgeo():
    return textwrap.dedent('''\
    #!/bin/bash

    # synthetic_road_proximity_osgeo.sh
    # Nothing is downloaded: the bands are derived from us_2019_prisecroads_tl in the postgis step.
    mkdir -p /data/synthetic_road_proximity/download -p /data/synthetic_road_proximity/etl
    chmod -R 777 /data/synthetic_road_proximity
    echo success: synthetic_road_proximity is derived from us_2019_prisecroads_tl
    ''')


def bands_postgis():
    values = ", ".join(f"({i + 1}, '{lo}-{hi} m', {lo}, {hi}, {INCREMENT((lo + hi) / 2)})" for i, (lo, hi) in enumerate(zip(BAND_LIMITS[:-1], BAND_LIMITS[1:])))
    return textwrap.dedent(f'''\
    #!/bin/bash

    # synthetic_road_proximity_postgis.sh
    # Distance bands around the primary and secondary roads of us_2019_prisecroads_tl, as non-overlapping polygons (in 100 km tiles of EPSG:5070,
    # subdivided into small pieces), with the SIMULATED near-road increment  2 * exp(-d_mid / 150 m)  ug/m3 of each band (illustrative values).

    psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -v ON_ERROR_STOP=1 -c "
    DROP TABLE IF EXISTS synthetic_road_proximity;
    CREATE TEMP TABLE roads5070 AS SELECT ST_Transform(geom, 5070) AS geom FROM us_2019_prisecroads_tl;
    CREATE INDEX ON roads5070 USING gist (geom);
    CREATE TEMP TABLE bands (k int, band text, lo int, hi int, road_increment numeric);
    INSERT INTO bands VALUES {values};
    CREATE TEMP TABLE tiles AS
      SELECT row_number() OVER () AS tid, g.geom FROM ST_SquareGrid(100000, (SELECT ST_SetSRID(ST_Extent(geom), 5070) FROM roads5070)) g
      WHERE EXISTS (SELECT 1 FROM roads5070 r WHERE r.geom && ST_Expand(g.geom, 400));
    CREATE TEMP TABLE tile_buf AS
      SELECT t.tid, t.geom AS tile,
             ST_Buffer(c.g, 50, 'quad_segs=2') AS b1, ST_Buffer(c.g, 100, 'quad_segs=2') AS b2,
             ST_Buffer(c.g, 200, 'quad_segs=2') AS b3, ST_Buffer(c.g, 400, 'quad_segs=2') AS b4
      FROM tiles t
      JOIN LATERAL (SELECT ST_Collect(r.geom) AS g FROM roads5070 r WHERE r.geom && ST_Expand(t.geom, 400)) c ON true;
    CREATE TABLE synthetic_road_proximity (
      ogc_fid serial PRIMARY KEY,
      geom geometry(MultiPolygon, 4269),
      band varchar,
      road_increment numeric,
      geom_local geometry(MultiPolygon, 4269));
    INSERT INTO synthetic_road_proximity (geom, band, road_increment)
    SELECT ST_Multi(ST_Transform(piece, 4269)), band, road_increment
    FROM (
      SELECT bd.band, bd.road_increment,
             ST_Subdivide(ST_CollectionExtract(ST_MakeValid(ST_Intersection(
               CASE bd.k WHEN 1 THEN tb.b1 WHEN 2 THEN ST_Difference(tb.b2, tb.b1) WHEN 3 THEN ST_Difference(tb.b3, tb.b2) ELSE ST_Difference(tb.b4, tb.b3) END,
               tb.tile)), 3), 256) AS piece
      FROM tile_buf tb CROSS JOIN bands bd) x
    WHERE NOT ST_IsEmpty(piece);
    CREATE INDEX synthetic_road_proximity_geom_geom_idx ON synthetic_road_proximity USING gist (geom);
    CREATE INDEX synthetic_road_proximity_geom_local_idx ON synthetic_road_proximity USING gist (geom_local);
    NOTIFY pgrst, 'reload schema';
    " 2>&1
    ''')


def meta_etl_roads():
    return {"rights": "Public Domain", "structure": "vector", "geometry": "multilinestring", "epsg": "EPSG:4269",
            "attributes": ["linearid;Linear feature identifier;U.S. Census Bureau;varchar;;;;", "fullname;Road name;U.S. Census Bureau;varchar;;;;",
                           "rttyp;Route type code;U.S. Census Bureau;varchar;;;;", "mtfcc;MAF/TIGER feature class code (S1100 primary, S1200 secondary road);U.S. Census Bureau;varchar;;;;"],
            "local_epsg": "EPSG:4269", "source": "https://www2.census.gov/geo/tiger/TIGER2019/PRISECROADS/tl_2019_<state fips>_prisecroads.zip",
            "file": [ROADS], "extension": "zip", "download": "wget", "table": ROADS, "format": "shp", "up": "true", "podID": "gaia-db",
            "last_updated": "2026-10-09T00:00:00Z", "update_frequency": "Never", "checksum": "TBD", "fields": ["linearid", "fullname", "rttyp", "mtfcc"]}


def meta_etl_bands():
    return {"rights": "CC0-1.0", "temporal_extent": ["2014-01-01", "2019-12-31"], "structure": "vector", "geometry": "multipolygon",
            "temporal_dimension": "static", "epsg": "EPSG:4269", "fields": ["band", "road_increment"],
            "attributes": ["band;Distance band from the nearest primary or secondary road;OHDSI GIS tutorial data generator (simulated);varchar;;;;",
                           "road_increment;Simulated near-road increment in PM2.5, 2 * exp(-d_mid / 150 m) for the distance band;OHDSI GIS tutorial data generator (simulated);numeric;micrograms/cubic meter;;;;2014-01-01;2019-12-31;2052499839"],
            "local_epsg": "EPSG:4269", "derive": [], "service": ["file"], "source": "derived from us_2019_prisecroads_tl", "file": [BANDS], "extension": "none",
            "download": "none", "table": BANDS, "format": "derived", "dependency": [ROADS], "etl_parameters": "", "custom_etl": "", "custom_parameters": "", "up": "true",
            "podID": "gaia-db", "update_frequency": "Never", "checksum": "TBD"}


def jsonld(tid, name, description, geometry, variables, based_on=None, url="https://github.com/OHDSI/GIS/tree/main/syntheticDataGIS"):
    d = {"@context": {"@vocab": "https://schema.org/", "dct": "http://purl.org/dc/terms/", "qudt": "http://qudt.org/schema/qudt/"}, "@type": "Dataset",
         "@id": f"https://github.com/OHDSI/gaiaCatalog/tree/main/datastore/data/{tid}", "name": name,
         "creator": [{"@type": "Organization", "name": "OHDSI GIS Working Group"}], "url": url,
         "provider": [{"@type": "Organization", "name": "OHDSI GIS Working Group"}], "license": "cc0-1.0",
         "spatialCoverage": [{"@type": "Place", "name": "United States"}], "temporalCoverage": "2014-01-01/2019-12-31", "type": "Vector Dataset",
         "datePublished": "2026-10-09", "dateModified": "2026-10-09", "description": description, "keywords": ["roads", "TIGER", "OHDSI benchmark"], "@language": "en",
         "measurementTechnique": [
             {"@type": "DefinedTerm", "description": "GIS Data Structure for Representation", "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "dataRepresentation"}, "termCode": "vector"},
             {"@type": "DefinedTerm", "description": "GIS Vector Geometery", "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "vectorGeometry"}, "termCode": geometry}],
         "additionalProperty": [{"@type": "PropertyValue", "propertyID": "http://dbpedia.org/resource/Spatial_reference_system", "value": "https://epsg.io/4269"}],
         "variableMeasured": variables, "version": "1", "distribution": ["TBD"]}
    if based_on: d["isBasedOn"] = based_on
    return d


if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("--catalog", required=True); a = ap.parse_args()
    road_vars = [{"@type": "PropertyValue", "name": n, "description": dsc, "qudt:dataType": "varchar"}
                 for n, dsc in (("linearid", "Linear feature identifier"), ("fullname", "Road name"), ("rttyp", "Route type code"), ("mtfcc", "MAF/TIGER feature class code"))]
    band_vars = [{"@type": "PropertyValue", "name": "band", "description": "Distance band from the nearest primary or secondary road", "qudt:dataType": "varchar"},
                 {"@type": "PropertyValue", "name": "road_increment", "description": "Simulated near-road PM2.5 increment of the band. Static over 2014-2019.", "propertyID": "2052499839",
                  "qudt:dataType": "numeric", "unitText": "micrograms/cubic meter", "startDate": "2014-01-01", "endDate": "2019-12-31"}]
    roads_ld = jsonld(ROADS, "TIGER/Line Shapefile, 2019, State(s), Primary and Secondary Roads",
                      "Census TIGER/Line 2019 primary (S1100) and secondary (S1200) roads. The states loaded are set by the TRACT_STATES environment variable of the gaia-db container (default Alabama).",
                      "multilinestring", road_vars, url="https://www2.census.gov/geo/tiger/TIGER2019/PRISECROADS/")
    bands_ld = jsonld(BANDS, "Simulated near-road exposure increment (distance bands)",
                      "SIMULATED near-road PM2.5 increment used by the road-proximity scenario of the OHDSI GIS geocoding stress test: non-overlapping distance bands (0-50, 50-100, 100-200, 200-400 m) "
                      "around the TIGER primary and secondary roads, each with the increment 2 * exp(-d_mid / 150 m) ug/m3. The values are illustrative, not measurements.",
                      "multipolygon", band_vars,
                      based_on=[{"@id": f"https://gdsc.idsc.miami.edu/details/{ROADS}", "@type": "Dataset", "name": ROADS, "url": f"https://gdsc.idsc.miami.edu/details/{ROADS}"}])
    for tid, osg, pg, me, jl in ((ROADS, roads_osgeo(), roads_postgis(), meta_etl_roads(), roads_ld), (BANDS, bands_osgeo(), bands_postgis(), meta_etl_bands(), bands_ld)):
        d = os.path.join(a.catalog, tid); os.makedirs(os.path.join(d, "etl"), exist_ok=True)
        json.dump(me, open(os.path.join(d, f"meta_etl_{tid}.json"), "w"), indent=2); json.dump(jl, open(os.path.join(d, f"meta_json-ld_{tid}.json"), "w"), indent=2)
        write(os.path.join(d, "etl", f"{tid}_osgeo.sh"), osg, True); write(os.path.join(d, "etl", f"{tid}_postgis.sh"), pg, True); print("wrote", tid)
