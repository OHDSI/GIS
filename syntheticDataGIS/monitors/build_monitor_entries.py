#!/usr/bin/env python3
"""Writes the gaiaCatalog entries of the simulated monitor networks.

  monitors/build_monitor_entries.py --catalog ../gaiaCatalog/datastore/data [--url-base URL]

For each network (20, 60 and 200 monitors) two entries:
  synthetic_monitors_<n>           the monitors as a point source with an annual jsonb series (published CSV, like the tower sensors)
  synthetic_monitors_<n>_voronoi   the Voronoi (Thiessen) cells of the monitors as a polygon source, built from the point source
                                   in the postgis step (it has to be ingested first); each cell carries its monitor's series
"""
import argparse, json, os, textwrap

NETWORKS = [20, 60, 200]
START, END = "2014-01-01", "2019-12-31"
PM25_CONCEPT, UG_M3 = "2052499839", "32964"
ORG = "OHDSI GIS Working Group"
URL_BASE = "https://raw.githubusercontent.com/OHDSI/GIS/main/syntheticDataGIS/monitors/data"
CENTER, HALF_WINDOW = (-118.25, 34.05), 5000
SERIES_DESC = "Annual mean PM2.5 reading of the monitor, stored as a jsonb object keyed by startDate/endDate"


def osgeo_points_sh(tid, url):
    return textwrap.dedent(f'''\
    #!/bin/bash

    # {tid}_osgeo.sh
    # Download the monitors (WKT point and annual jsonb series) and load them into a raw table with ogr2ogr
    #
    # Data source: {url}

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


def postgis_points_sh(tid):
    return textwrap.dedent(f'''\
    #!/bin/bash

    # {tid}_postgis.sh
    # Build the typed table of the monitors: point geometry, annual series as jsonb

    psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -v ON_ERROR_STOP=1 -c "
    DROP TABLE IF EXISTS {tid};
    CREATE TABLE {tid} (
      ogc_fid serial PRIMARY KEY,
      geom geometry(Point, 4269),
      monitor_id integer,
      pm25_monitor jsonb,
      geom_local geometry(Point, 4269));
    INSERT INTO {tid} (geom, monitor_id, pm25_monitor, geom_local)
    SELECT geom, monitor_id::integer, pm25_monitor::jsonb, geom
    FROM {tid}_raw ORDER BY monitor_id::integer;
    CREATE INDEX {tid}_geom_geom_idx ON {tid} USING gist (geom);
    DROP TABLE {tid}_raw;
    "
    ''')


def osgeo_voronoi_sh(tid, src):
    return textwrap.dedent(f'''\
    #!/bin/bash

    # {tid}_osgeo.sh
    # Nothing to download: the cells are derived from {src}, which has to be ingested first

    exists=$(psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -tAc "SELECT to_regclass('public.{src}') IS NOT NULL")
    if [[ "$exists" != "t" ]]; then
      echo "{tid} is derived from {src}: run backbone.ingest_datasource('{src}') first" >&2
      exit 1
    fi
    echo success: {src} found
    ''')


def postgis_voronoi_sh(tid, src):
    cx, cy = CENTER
    return textwrap.dedent(f'''\
    #!/bin/bash

    # {tid}_postgis.sh
    # Voronoi (Thiessen) cells of the monitors in {src}: every location of the window belongs to the cell of its nearest monitor.
    # backbone.create_voronoi_source computes the cells in EPSG:5070 (metres), clips them to the 10 km study window and keeps the
    # monitor's attributes (the series).

    PGOPTIONS='-c client_min_messages=warning' psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -v ON_ERROR_STOP=1 -c "
    SELECT backbone.create_voronoi_source('{src}', '{tid}',
      ST_Expand(ST_Transform(ST_SetSRID(ST_MakePoint({cx}, {cy}), 4326), 5070), {HALF_WINDOW}), 5070);
    "
    ''')


def meta_etl(tid, geometry, url, src=None):
    attrs = ["monitor_id;Monitor identifier;OHDSI GIS tutorial data generator (simulated);integer;;;;",
             f"pm25_monitor;{SERIES_DESC};OHDSI GIS tutorial data generator (simulated);jsonb;micrograms/cubic meter;;;;{START};{END};{PM25_CONCEPT}"]
    out = {"rights": "CC0-1.0", "temporal_extent": [START, END], "structure": "vector", "geometry": geometry, "temporal_dimension": "1 year",
           "epsg": "EPSG:4269", "fields": ["monitor_id", "pm25_monitor"], "attributes": attrs, "local_epsg": "EPSG:4269",
           "derive": [], "service": ["file"], "source": url, "file": [tid], "extension": "csv", "download": "wget", "table": tid, "format": "csv",
           "dependency": [], "etl_parameters": "", "custom_etl": "", "custom_parameters": "", "up": "true", "podID": "gaia-db",
           "update_frequency": "Never", "checksum": "TBD"}
    if src:
        # proposed: how a derived source is built (a tessellation of the monitors of the dependency, clipped to the window)
        out.update({"source": "derived", "extension": "", "download": "", "format": "derived", "dependency": [src],
                    "derive": [{"method": "voronoi", "from": src, "clip": f"window of {2 * HALF_WINDOW} m around {CENTER[0]}, {CENTER[1]} (EPSG:5070)"}]})
    return out


def meta_jsonld(tid, n, derived, url, src=None):
    geom = "multipolygon" if derived else "point"
    name = (f"Voronoi cells of {n} simulated PM2.5 monitors, annual PM2.5 per cell" if derived else f"{n} simulated PM2.5 monitors, annual PM2.5 per monitor")
    desc = (f"SIMULATED network of {n} PM2.5 monitors placed at random (at least 150 m apart) in a 10 km window around downtown Los Angeles, the first {n} of a nested "
            "series of networks of 20, 60 and 200. A monitor reads the simulated exposure field of the OHDSI GIS raster example at its site plus noise (SD 0.3 ug/m3), "
            "one annual mean per year 2014-2019. It is not a measurement of any real exposure.")
    if derived:
        desc = (f"SIMULATED. The Voronoi (Thiessen) tessellation of the {n} monitors of {src}, clipped to the 10 km window: each cell is the set of locations whose nearest "
                f"monitor is that monitor, and carries the monitor's annual PM2.5 series. Built from {src} in the postgis step.")
    var = {"@type": "PropertyValue", "name": "pm25_monitor",
           "description": f"{SERIES_DESC} (YYYY-MM-DD/YYYY-MM-DD) with the PM2.5 value for each year.",
           "propertyID": PM25_CONCEPT, "qudt:dataType": "jsonb", "unitCode": UG_M3, "unitText": "micrograms/cubic meter", "startDate": START, "endDate": END}
    mid = {"@type": "PropertyValue", "name": "monitor_id", "description": "Monitor identifier", "qudt:dataType": "integer"}
    d = {
        "@context": {"@vocab": "https://schema.org/", "dct": "http://purl.org/dc/terms/", "qudt": "http://qudt.org/schema/qudt/"},
        "@type": "Dataset", "@id": f"https://github.com/OHDSI/gaiaCatalog/tree/main/datastore/data/{tid}", "name": name,
        "creator": [{"@type": "Organization", "name": ORG}], "url": "https://github.com/OHDSI/GIS/tree/main/syntheticDataGIS/monitors",
        "provider": [{"@type": "Organization", "name": ORG}], "license": "cc0-1.0",
        "spatialCoverage": [{"@type": "Place", "name": "Los Angeles, California, United States (10 km window)"}],
        "temporalCoverage": f"{START}/{END}", "type": "Vector Dataset", "datePublished": "2026-11-13", "dateModified": "2026-11-13",
        "description": desc, "keywords": ["simulated", "synthetic", "monitors", "Voronoi", "tessellation", "OHDSI benchmark"], "@language": "en",
        "measurementTechnique": [
            {"@type": "DefinedTerm", "description": "GIS Data Structure for Representation", "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "dataRepresentation"}, "termCode": "vector"},
            {"@type": "DefinedTerm", "description": "GIS Vector Geometery", "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "vectorGeometry"}, "termCode": geom}],
        "additionalProperty": [{"@type": "PropertyValue", "propertyID": "http://dbpedia.org/resource/Spatial_reference_system", "value": "https://epsg.io/4269"}],
        "about": [{"@type": "Event", "name": f"ETL process for the simulated monitor {'cells' if derived else 'network'}",
                   "description": ("The cells are the Voronoi tessellation (ST_VoronoiPolygons, in EPSG:5070) of the monitors of the dependency, clipped to the window; each cell keeps the series of its monitor."
                                   if derived else "The CSV (WKT point plus an annual jsonb series) is published by the monitors generator and loaded into a raw table with ogr2ogr; the postgis step builds the typed table.")}],
        "variableMeasured": [mid, var], "version": "1", "distribution": [f"/data/{tid}/"] if derived else [url]}
    if derived:
        d["isBasedOn"] = [{"@id": f"https://github.com/OHDSI/gaiaCatalog/tree/main/datastore/data/{src}", "@type": "Dataset", "name": src}]
    return d


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--catalog", required=True); ap.add_argument("--url-base", default=URL_BASE)
    a = ap.parse_args()
    for n in NETWORKS:
        pts = f"synthetic_monitors_{n}"; vor = f"{pts}_voronoi"; url = f"{a.url_base}/monitors_{n}.csv"
        for tid, etl, jl, osg, pg in (
                (pts, meta_etl(pts, "point", url), meta_jsonld(pts, n, False, url), osgeo_points_sh(pts, url), postgis_points_sh(pts)),
                (vor, meta_etl(vor, "multipolygon", url, pts), meta_jsonld(vor, n, True, f"{a.url_base}/monitors_{n}.csv", pts), osgeo_voronoi_sh(vor, pts), postgis_voronoi_sh(vor, pts))):
            d = os.path.join(a.catalog, tid); os.makedirs(os.path.join(d, "etl"), exist_ok=True)
            json.dump(etl, open(os.path.join(d, f"meta_etl_{tid}.json"), "w"), indent=2)
            json.dump(jl, open(os.path.join(d, f"meta_json-ld_{tid}.json"), "w"), indent=2)
            for nm, txt in ((f"{tid}_osgeo.sh", osg), (f"{tid}_postgis.sh", pg)):
                p = os.path.join(d, "etl", nm); open(p, "w").write(txt); os.chmod(p, 0o755)
            print("wrote", tid)
