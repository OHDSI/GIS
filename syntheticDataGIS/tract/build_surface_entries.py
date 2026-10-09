#!/usr/bin/env python3
"""Writes the catalog entries and features of the synthetic exposure surfaces (Gaussian random fields rendered as grids) used by the geocoding stress test.

  tract/build_surface_entries.py --catalog ../gaiaCatalog/datastore/data [--features-dir tract/data] [--url-base URL]
"""
import argparse, json, math, os, random, textwrap

SCALES = {"100m": (100.0, 25.0), "1km": (1000.0, 250.0), "10km": (10000.0, 2500.0)}
N_FEATURES, MEAN, SD, SEED = 1000, 9.0, 1.9, 20261020
CENTER = (-118.25, 34.05); HALF_WINDOW = 5000.0


def features(length, seed):
    rng = random.Random(seed)
    rows = []
    for _ in range(N_FEATURES):
        z0 = rng.gauss(0, 1)
        rows.append((rng.gauss(0, 1) / (length * abs(z0)), rng.gauss(0, 1) / (length * abs(z0)), rng.uniform(0, 2 * math.pi)))
    return rows


def osgeo_sh(tid, url):
    return textwrap.dedent(f'''\
    #!/bin/bash

    # {tid}_osgeo.sh
    # Download the random Fourier features of the surface and load them into postGIS (the grid is built in the postgis step)
    #
    # Data source: {url}
    # Destination postGIS table: {tid}_features (temporary)

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

    ogr2ogr -f PostgreSQL PG:"dbname=$POSTGRES_DB port=$POSTGRES_PORT user=$POSTGRES_USER password=$POSTGRES_PASSWORD host='gaia-db'" download/{tid}.csv -dialect sqlite -sql "SELECT w1, w2, phase FROM {tid}" -lco COLUMN_TYPES="w1=varchar,w2=varchar,phase=varchar" -nlt NONE -nln {tid}_features
    echo success: {tid}.csv loaded with ogr2ogr
    ''')


def postgis_sh(tid, cell):
    return textwrap.dedent(f'''\
    #!/bin/bash

    # {tid}_postgis.sh
    # Build the grid of the synthetic surface in postGIS from the random Fourier features

    psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -v ON_ERROR_STOP=1 -c "
    DROP TABLE IF EXISTS {tid};
    CREATE TEMP TABLE cells AS
    SELECT row_number() OVER () AS cell_id, g.geom AS geom5070, ST_X(ST_Centroid(g.geom)) AS cx, ST_Y(ST_Centroid(g.geom)) AS cy
    FROM ST_SquareGrid({cell:g}, ST_Expand(ST_Transform(ST_SetSRID(ST_MakePoint({CENTER[0]}, {CENTER[1]}), 4326), 5070), {HALF_WINDOW:g})) g;
    CREATE TEMP TABLE feat AS
      SELECT w1::double precision AS w1, w2::double precision AS w2, phase::double precision AS ph FROM {tid}_features;
    CREATE TEMP TABLE cell_value AS
      SELECT c.cell_id, {MEAN:g} + {SD:g} * sqrt(2.0 / (SELECT count(*) FROM feat)) * sum(cos(f.w1 * c.cx + f.w2 * c.cy + f.ph)) AS v
      FROM cells c CROSS JOIN feat f GROUP BY c.cell_id;
    CREATE TABLE {tid} (
      ogc_fid serial PRIMARY KEY,
      geom geometry(MultiPolygon, 4269),
      cell_id integer,
      pm25_surface numeric,
      geom_local geometry(MultiPolygon, 4269));
    INSERT INTO {tid} (geom, cell_id, pm25_surface)
    SELECT ST_Multi(ST_Transform(c.geom5070, 4269)), c.cell_id, v.v
    FROM cells c JOIN cell_value v USING (cell_id);
    CREATE INDEX {tid}_geom_geom_idx ON {tid} USING gist (geom);
    DROP TABLE {tid}_features;
    "
    ''')


def meta_etl(tid, url):
    return {
        "rights": "CC0-1.0", "temporal_extent": ["2014-01-01", "2019-12-31"], "structure": "vector", "geometry": "multipolygon",
        "temporal_dimension": "static", "epsg": "EPSG:4269", "fields": ["cell_id", "pm25_surface"],
        "attributes": [
            "cell_id;Grid cell identifier;OHDSI GIS tutorial data generator (simulated);integer;;;;",
            "pm25_surface;Simulated exposure surface, Gaussian random field with exponential covariance;OHDSI GIS tutorial data generator (simulated);numeric;micrograms/cubic meter;;;;2014-01-01;2019-12-31;2052499839"],
        "local_epsg": "EPSG:4269", "derive": [], "service": ["file"], "source": url, "file": [tid], "extension": "csv", "download": "wget",
        "table": tid, "format": "csv", "dependency": [], "etl_parameters": "", "custom_etl": "", "custom_parameters": "", "up": "true",
        "podID": "gaia-db", "update_frequency": "Never", "checksum": "TBD"}


def meta_jsonld(tid, length, cell, url):
    return {
        "@context": {"@vocab": "https://schema.org/", "dct": "http://purl.org/dc/terms/", "qudt": "http://qudt.org/schema/qudt/"},
        "@type": "Dataset", "@id": f"https://github.com/OHDSI/gaiaCatalog/tree/main/datastore/data/{tid}",
        "name": f"Simulated exposure surface, correlation length {length:g} m",
        "creator": [{"@type": "Organization", "name": "OHDSI GIS Working Group"}],
        "url": "https://github.com/OHDSI/GIS/tree/main/syntheticDataGIS",
        "provider": [{"@type": "Organization", "name": "OHDSI GIS Working Group"}], "license": "cc0-1.0",
        "spatialCoverage": [{"@type": "Place", "name": "Los Angeles, California, United States (10 km window)"}],
        "temporalCoverage": "2014-01-01/2019-12-31", "type": "Vector Dataset", "datePublished": "2026-10-09", "dateModified": "2026-10-09",
        "description": (f"SIMULATED exposure surface used to check the geocoding stress test of the OHDSI GIS benchmark through Gaia: a Gaussian random field with exponential "
                        f"covariance and correlation length {length:g} m (mean {MEAN:g}, SD {SD:g} ug/m3), rendered as a {cell:g} m square grid over a {2 * HALF_WINDOW / 1000:g} km window "
                        "around downtown Los Angeles. It is not a measurement of any real exposure. The field is built from random Fourier features in the postGIS step."),
        "keywords": ["simulated", "synthetic", "exposure surface", "grid", "OHDSI benchmark"], "@language": "en",
        "measurementTechnique": [
            {"@type": "DefinedTerm", "description": "GIS Data Structure for Representation", "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "dataRepresentation"}, "termCode": "vector"},
            {"@type": "DefinedTerm", "description": "GIS Vector Geometery", "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "vectorGeometry"}, "termCode": "multipolygon"}],
        "additionalProperty": [{"@type": "PropertyValue", "propertyID": "http://dbpedia.org/resource/Spatial_reference_system", "value": "https://epsg.io/4269"}],
        "about": [{"@type": "Event", "name": "ETL process for the simulated exposure surface",
                   "description": "The random Fourier features (w1, w2, phase) are published as a CSV and loaded into a temporary table; the square grid is created in EPSG:5070 with ST_SquareGrid and the value of every cell is computed at its centre."}],
        "variableMeasured": [
            {"@type": "PropertyValue", "name": "cell_id", "description": "Grid cell identifier", "qudt:dataType": "integer"},
            {"@type": "PropertyValue", "name": "pm25_surface", "description": "Simulated exposure at the cell centre. Static over 2014-2019.", "propertyID": "2052499839",
             "qudt:dataType": "numeric", "unitText": "micrograms/cubic meter", "startDate": "2014-01-01", "endDate": "2019-12-31"}],
        "version": "1", "distribution": [url]}


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--catalog", required=True); ap.add_argument("--features-dir", default="syntheticDataGIS/tract/data")
    ap.add_argument("--url-base", default="https://raw.githubusercontent.com/OHDSI/GIS/main/syntheticDataGIS/tract/data")
    a = ap.parse_args()
    for key, (length, cell) in SCALES.items():
        tid = f"synthetic_surface_{key}"; fname = f"surface_{key}_features.csv"; url = f"{a.url_base}/{fname}"
        with open(os.path.join(a.features_dir, fname), "w") as fh:
            fh.write("w1,w2,phase\n")
            for w1, w2, ph in features(length, SEED + int(length)): fh.write(f"{w1:.12g},{w2:.12g},{ph:.12g}\n")
        d = os.path.join(a.catalog, tid); os.makedirs(os.path.join(d, "etl"), exist_ok=True)
        json.dump(meta_etl(tid, url), open(os.path.join(d, f"meta_etl_{tid}.json"), "w"), indent=2)
        json.dump(meta_jsonld(tid, length, cell, url), open(os.path.join(d, f"meta_json-ld_{tid}.json"), "w"), indent=2)
        for nm, txt in ((f"{tid}_osgeo.sh", osgeo_sh(tid, url)), (f"{tid}_postgis.sh", postgis_sh(tid, cell))):
            p = os.path.join(d, "etl", nm); open(p, "w").write(txt); os.chmod(p, 0o755)
        print("wrote", tid)
