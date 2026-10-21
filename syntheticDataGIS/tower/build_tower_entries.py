#!/usr/bin/env python3
"""Writes the gaiaCatalog entries of the tower. Usage: build_tower_entries.py [--catalog DIR] [--url-base URL]"""
import argparse, json, os, textwrap

START, END = "2019-01-01", "2019-12-31"
PM25_CONCEPT, UG_M3 = "2052499839", "32964"
ENTRIES = {
    "synthetic_tower_floors": dict(
        csv="tower_floors.csv", geometry="multipolygon", n="100 floor polygons", label="floor",
        name="Simulated 100-floor tower flattened to a row of floors, daily PM2.5 per floor",
        series="pm25_floor_mean", series_desc="Daily mean PM2.5 of the four sensors on the floor",
        fields=["floor_id", "floor_number", "pm25_floor_mean"],
        extra=["floor_id;Floor identifier;OHDSI GIS tutorial data generator (simulated);integer;;;;",
               "floor_number;Floor number, 1 (lowest) to 100;OHDSI GIS tutorial data generator (simulated);integer;;;;"]),
    "synthetic_tower_sensors": dict(
        csv="tower_sensors.csv", geometry="point", n="400 sensor points", label="sensor",
        name="Simulated particle sensors of a 100-floor tower, daily PM2.5 per sensor",
        series="pm25_sensor", series_desc="Daily PM2.5 reading of the sensor",
        fields=["sensor_id", "floor_number", "sensor_type", "pm25_sensor"],
        extra=["sensor_id;Sensor identifier;OHDSI GIS tutorial data generator (simulated);integer;;;;",
               "floor_number;Floor the sensor is on;OHDSI GIS tutorial data generator (simulated);integer;;;;",
               "sensor_type;window (near an outer wall) or core;OHDSI GIS tutorial data generator (simulated);varchar;;;;"]),
}
GEOM_TYPE = {"multipolygon": "MultiPolygon", "point": "Point"}

def osgeo_sh(tid, e, url):
    return textwrap.dedent(f'''\
    #!/bin/bash

    export POSTGRES_PASSWORD=$(cat $PG_PASSWORD_FILE)

    mkdir -p /data/{tid}/download -p /data/{tid}/etl
    chmod -R 777 /data/{tid}
    cd /data/{tid}

    do_update=0
    [[ -e datestamp ]] || do_update=1

    if [[ $do_update = 1 ]]; then
      attempts=0
      until (
        wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 10 -O download/{tid}.csv '{url}' 2>&1
      ); do
        ((attempts++))
        if (( attempts > 3 )); then echo $?; break; fi
      done
      echo $(date '+%F %T') > datestamp
    fi

    ogr2ogr -f PostgreSQL PG:"dbname=$POSTGRES_DB port=$POSTGRES_PORT user=$POSTGRES_USER password=$POSTGRES_PASSWORD host='gaia-db'" download/{tid}.csv -oo GEOM_POSSIBLE_NAMES=wkt -oo KEEP_GEOM_COLUMNS=NO -a_srs EPSG:4269 -nln {tid}_raw -lco GEOMETRY_NAME=geom -overwrite
    echo success: {tid}.csv loaded with ogr2ogr
    ''')

def sql_type(c, e):
    return "jsonb" if c == e["series"] else "integer" if c.endswith("id") or c == "floor_number" else "varchar"

def postgis_sh(tid, e):
    gt = GEOM_TYPE[e["geometry"]]
    geom = "ST_Multi(geom)" if gt == "MultiPolygon" else "geom"
    columns = ",\n      ".join(f"{c} {sql_type(c, e)}" for c in e["fields"])
    casts = ", ".join(f"{c}::{sql_type(c, e)}" for c in e["fields"])
    return textwrap.dedent(f'''\
    #!/bin/bash

    psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -v ON_ERROR_STOP=1 -c "
    DROP TABLE IF EXISTS {tid};
    CREATE TABLE {tid} (
      ogc_fid serial PRIMARY KEY,
      geom geometry({gt}, 4269),
      {columns},
      geom_local geometry({gt}, 4269));
    INSERT INTO {tid} (geom, {', '.join(e['fields'])}, geom_local)
    SELECT {geom}, {casts}, {geom}
    FROM {tid}_raw ORDER BY {e['fields'][0]}::integer;
    CREATE INDEX {tid}_geom_geom_idx ON {tid} USING gist (geom);
    DROP TABLE {tid}_raw;
    "
    ''')

def meta_etl(tid, e, url):
    attrs = e["extra"] + [f"{e['series']};{e['series_desc']}, stored as a jsonb object keyed by startDate/endDate;OHDSI GIS tutorial data generator (simulated);jsonb;micrograms/cubic meter;;;;{START};{END};{PM25_CONCEPT}"]
    return {"rights": "CC0-1.0", "temporal_extent": [START, END], "structure": "vector", "geometry": e["geometry"], "temporal_dimension": "1 day",
            "epsg": "EPSG:4269", "fields": e["fields"], "attributes": attrs, "local_epsg": "EPSG:4269", "derive": [], "service": ["file"],
            "source": url, "file": [tid], "extension": "csv", "download": "wget", "table": tid, "format": "csv", "dependency": [],
            "etl_parameters": "", "custom_etl": "", "custom_parameters": "", "up": "true", "podID": "gaia-db", "update_frequency": "Never", "checksum": "TBD"}

def meta_jsonld(tid, e, url):
    series = {"@type": "PropertyValue", "name": e["series"],
              "description": f"{e['series_desc']}, stored as a jsonb object with date ranges as keys (startDate/endDate formatted as YYYY-MM-DD/YYYY-MM-DD) and PM2.5 values for each date key.",
              "propertyID": PM25_CONCEPT, "qudt:dataType": "jsonb", "unitCode": UG_M3, "unitText": "micrograms/cubic meter", "startDate": START, "endDate": END}
    plain = [{"@type": "PropertyValue", "name": f.split(";")[0], "description": f.split(";")[1], "qudt:dataType": f.split(";")[3]} for f in e["extra"]]
    return {
        "@context": {"@vocab": "https://schema.org/", "dct": "http://purl.org/dc/terms/", "qudt": "http://qudt.org/schema/qudt/"},
        "@type": "Dataset", "@id": f"https://github.com/OHDSI/gaiaCatalog/tree/main/datastore/data/{tid}", "name": e["name"],
        "creator": [{"@type": "Organization", "name": "OHDSI GIS Working Group"}], "url": "https://github.com/OHDSI/GIS/tree/main/syntheticDataGIS/tower",
        "provider": [{"@type": "Organization", "name": "OHDSI GIS Working Group"}], "license": "cc0-1.0",
        "spatialCoverage": [{"@type": "Place", "name": "Synthetic (open ocean at longitude 0, latitude 0; no real place)"}],
        "temporalCoverage": f"{START}/{END}", "type": "Vector Dataset", "datePublished": "2026-10-21", "dateModified": "2026-10-21",
        "description": (f"SIMULATED data for a 100-floor tower flattened to a row of adjacent {e['label']} geometries ({e['n']}; floor k is the 30 m by 30 m rectangle starting "
                        f"at x = 30(k-1) m, so height is the x axis). {e['series_desc']}, one value per day of 2019. Particle levels rise with height by design and are illustrative, "
                        "not physical. It is not a measurement of any real exposure."),
        "keywords": ["simulated", "synthetic", "tower", "floors", "particulate matter", "OHDSI benchmark"], "@language": "en",
        "measurementTechnique": [
            {"@type": "DefinedTerm", "description": "GIS Data Structure for Representation", "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "dataRepresentation"}, "termCode": "vector"},
            {"@type": "DefinedTerm", "description": "GIS Vector Geometery", "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "vectorGeometry"}, "termCode": e["geometry"]}],
        "additionalProperty": [{"@type": "PropertyValue", "propertyID": "http://dbpedia.org/resource/Spatial_reference_system", "value": "https://epsg.io/4269"}],
        "about": [{"@type": "Event", "name": f"ETL process for the simulated tower {e['label']}s",
                   "description": f"The CSV (WKT geometry plus a daily jsonb series) is published by the tower generator and loaded into a raw table with ogr2ogr; the postgis step builds the typed table, converts the series to jsonb, adds geom_local and the spatial index."}],
        "variableMeasured": plain + [series], "version": "1", "distribution": [url]}

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--catalog", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "catalog"))
    ap.add_argument("--url-base", default="https://raw.githubusercontent.com/OHDSI/GIS/main/syntheticDataGIS/tower/data")
    a = ap.parse_args()
    for tid, e in ENTRIES.items():
        url = f"{a.url_base}/{e['csv']}"
        d = os.path.join(a.catalog, tid); os.makedirs(os.path.join(d, "etl"), exist_ok=True)
        json.dump(meta_etl(tid, e, url), open(os.path.join(d, f"meta_etl_{tid}.json"), "w"), indent=2)
        json.dump(meta_jsonld(tid, e, url), open(os.path.join(d, f"meta_json-ld_{tid}.json"), "w"), indent=2)
        for nm, txt in ((f"{tid}_osgeo.sh", osgeo_sh(tid, e, url)), (f"{tid}_postgis.sh", postgis_sh(tid, e))):
            p = os.path.join(d, "etl", nm); open(p, "w").write(txt); os.chmod(p, 0o755)
        print("wrote", tid)
