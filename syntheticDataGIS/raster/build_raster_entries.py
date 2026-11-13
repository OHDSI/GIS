#!/usr/bin/env python3
"""Writes the gaiaCatalog entries (JSON-LD, ETL metadata, osgeo and postgis scripts) of the synthetic rasters.

  raster/build_raster_entries.py --catalog ../gaiaCatalog/datastore/data [--url-base URL]

One entry per raster source: synthetic_raster_surface_{100m,1km,10km}, synthetic_raster_annual (one table, one file per
year, told apart by the `filename` column) and synthetic_raster_landcover. The files come from build_synthetic_rasters.py.
"""
import argparse, json, os, textwrap

YEARS = range(2014, 2020)
PM25_CONCEPT = "2052499839"
ORG = "OHDSI GIS Working Group"
URL_BASE = "https://raw.githubusercontent.com/OHDSI/GIS/main/syntheticDataGIS/raster/data"
LC_CLASSES = {11: "Open Water", 21: "Developed, Open Space", 41: "Deciduous Forest", 81: "Pasture/Hay"}

ENTRIES = [
    {"tid": f"synthetic_raster_surface_{k}", "files": [f"synthetic_raster_surface_{k}.tif"], "cell": c, "var": "pm25_surface", "dtype": "float", "unit": "micrograms/cubic meter",
     "concept": PM25_CONCEPT, "start": "2014-01-01", "end": "2019-12-31", "nodata": "-9999", "temporal": "static",
     "name": f"Simulated exposure surface as a raster, correlation length {L:g} m",
     "desc": (f"SIMULATED exposure surface, the raster counterpart of synthetic_surface_{k}: the same Gaussian random field with exponential covariance and correlation length {L:g} m "
              f"(mean 9, SD 1.9 ug/m3), one value per {c:g} m cell, over a 10 km window around downtown Los Angeles. Static over 2014-2019. Not a measurement of any real exposure."),
     "var_desc": "Simulated exposure at the cell centre. Static over 2014-2019."}
    for k, L, c in (("100m", 100, 25.0), ("1km", 1000, 250.0), ("10km", 10000, 2500.0))
] + [
    {"tid": "synthetic_raster_annual", "files": [f"synthetic_raster_annual_{y}.tif" for y in YEARS], "cell": 250.0, "var": "pm25_annual", "dtype": "float", "unit": "micrograms/cubic meter",
     "concept": PM25_CONCEPT, "start": "2014-01-01", "end": "2019-12-31", "nodata": "-9999", "temporal": "1 year",
     "name": "Simulated annual exposure rasters",
     "desc": ("SIMULATED annual exposure layers, one 250 m raster per calendar year 2014-2019 over a 10 km window around downtown Los Angeles: the 1 km Gaussian random field plus a trend of 0.30 ug/m3 "
              "per year in the west rising to 0.50 in the east. A 3 x 3 cell nodata hole (-9999) lies 1 km east and 1 km south of the centre. The year of each layer is the calendar year of its file; "
              "the files are loaded into one table with a filename column. Not a measurement of any real exposure."),
     "var_desc": "Simulated annual exposure at the cell centre. One layer per calendar year; the layer's period is in raster_layers of the ETL metadata."},
    {"tid": "synthetic_raster_landcover", "files": ["synthetic_raster_landcover.tif"], "cell": 100.0, "var": "land_cover", "dtype": "integer", "unit": "",
     "concept": "", "start": "2019-01-01", "end": "2019-12-31", "nodata": "255", "temporal": "static",
     "name": "Simulated land cover raster",
     "desc": ("SIMULATED land cover classes with NLCD codes (" + "; ".join(f"{k} {v}" for k, v in LC_CLASSES.items()) + ") on a 100 m grid over a 10 km window around downtown Los Angeles, "
              "for testing categorical raster values and class fractions in a buffer. Nodata is 255. Not a map of any real land cover."),
     "var_desc": "Simulated land cover class (NLCD code) at the cell centre, 2019."},
]


def osgeo_sh(e, base):
    tid = e["tid"]
    gets = "\n".join(f"  wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 10 -O download/{f} '{base}/{f}' 2>&1" for f in e["files"])
    return textwrap.dedent('''\
    #!/bin/bash

    # {tid}_osgeo.sh
    # Download the synthetic raster file(s); they are loaded into postGIS in the postgis step
    #
    # Data source: {base}
    # Destination postGIS table: {tid}

    mkdir -p /data/{tid}/download -p /data/{tid}/etl
    chmod -R 777 /data/{tid}
    cd /data/{tid}

    do_update=0
    [[ -e datestamp ]] || do_update=1

    if [[ $do_update = 1 ]]; then
      attempts=0
      until (
    {gets}
      ); do
        ((attempts++))
        if (( attempts > 3 )); then echo $?; exit 1; fi
      done
      echo $(date '+%F %T') > datestamp
    fi
    ''').format(tid=tid, base=base, gets=gets)


def postgis_sh(e):
    tid, files = e["tid"], " ".join(e["files"])
    return textwrap.dedent('''\
    #!/bin/bash

    # {tid}_postgis.sh
    # Load the raster file(s) into public.{tid} (column rast, one row per tile, filename of the source file)

    cd /data/{tid}/download
    raster2pgsql -s 5070 -d -C -I -M -F -t 64x64 {files} public.{tid} \\
      | psql -d $POSTGRES_DB -U $POSTGRES_USER -p $POSTGRES_PORT -h gaia-db -v ON_ERROR_STOP=1 -q
    echo success: {files} loaded with raster2pgsql
    ''').format(tid=tid, files=files)


def meta_etl(e, base):
    out = {
        "rights": "CC0-1.0", "temporal_extent": [e["start"], e["end"]], "structure": "raster", "temporal_dimension": e["temporal"],
        "bands": [e["var"]], "pixel_size": e["cell"], "pixel_dimension": "meters", "epsg": "EPSG:5070",
        "attributes": [f"{e['var']};{e['var_desc']};OHDSI GIS tutorial data generator (simulated);{e['dtype']};{e['unit']};;;{e['start']};{e['end']};{e['concept']}"],
        "nodata": [e["dtype"] if e["dtype"] == "integer" else "float", e["nodata"]], "local_epsg": "EPSG:5070",
        "service": ["file"], "source": base, "file": [f[:-4] for f in e["files"]], "extension": "tif", "download": "wget",
        "table": e["tid"], "format": "tif", "dependency": [], "etl_parameters": "-t 64x64", "custom_etl": "", "custom_parameters": "",
        "up": "true", "podID": "gaia-db", "update_frequency": "Never", "checksum": "TBD"}
    if e["tid"].endswith("annual"):
        # proposed field: the period each layer of a multi-file raster table stands for
        out["raster_layers"] = [{"filename": f, "start_date": f"{y}-01-01", "end_date": f"{y}-12-31"} for f, y in zip(e["files"], YEARS)]
    if e["var"] == "land_cover":
        out["classes"] = {str(k): v for k, v in LC_CLASSES.items()}
    return out


def meta_jsonld(e, base):
    var = {"@type": "PropertyValue", "name": e["var"], "description": e["var_desc"], "qudt:dataType": e["dtype"],
           "startDate": e["start"], "endDate": e["end"]}
    if e["unit"]:
        var["unitText"] = e["unit"]
    if e["concept"]:
        var["propertyID"] = e["concept"]
    return {
        "@context": {"@vocab": "https://schema.org/", "dct": "http://purl.org/dc/terms/", "qudt": "http://qudt.org/schema/qudt/"},
        "@type": "Dataset", "@id": f"https://github.com/OHDSI/gaiaCatalog/tree/main/datastore/data/{e['tid']}",
        "name": e["name"], "creator": [{"@type": "Organization", "name": ORG}], "url": "https://github.com/OHDSI/GIS/tree/main/syntheticDataGIS/raster",
        "provider": [{"@type": "Organization", "name": ORG}], "license": "cc0-1.0",
        "spatialCoverage": [{"@type": "Place", "name": "Los Angeles, California, United States (10 km window)"}],
        "temporalCoverage": f"{e['start']}/{e['end']}", "type": "Raster Dataset", "datePublished": "2026-11-13", "dateModified": "2026-11-13",
        "description": e["desc"], "keywords": ["simulated", "synthetic", "raster", "OHDSI benchmark"], "@language": "en",
        "measurementTechnique": [{"@type": "DefinedTerm", "description": "GIS Data Structure for Representation",
                                  "inDefinedTermSet": {"@type": "DefinedTermSet", "name": "dataRepresentation"}, "termCode": "raster"}],
        "additionalProperty": [
            {"@type": "PropertyValue", "name": "https://dbpedia.org/resource/Ground_sample_distance", "value": e["cell"], "unitText": "meters"},
            {"@type": "PropertyValue", "propertyID": "http://dbpedia.org/resource/Spatial_reference_system", "value": "https://epsg.io/5070"}],
        "about": [{"@type": "Event", "name": "ETL process for the simulated raster",
                   "description": "The GeoTIFF file(s) are downloaded and loaded into postGIS with raster2pgsql (EPSG:5070, 64 x 64 cell tiles, filename column)."}],
        "variableMeasured": [var], "version": "1", "distribution": [f"{base}/{f}" for f in e["files"]]}


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--catalog", required=True); ap.add_argument("--url-base", default=URL_BASE)
    a = ap.parse_args()
    for e in ENTRIES:
        tid = e["tid"]; d = os.path.join(a.catalog, tid); os.makedirs(os.path.join(d, "etl"), exist_ok=True)
        json.dump(meta_etl(e, a.url_base), open(os.path.join(d, f"meta_etl_{tid}.json"), "w"), indent=2)
        json.dump(meta_jsonld(e, a.url_base), open(os.path.join(d, f"meta_json-ld_{tid}.json"), "w"), indent=2)
        for nm, txt in ((f"{tid}_osgeo.sh", osgeo_sh(e, a.url_base)), (f"{tid}_postgis.sh", postgis_sh(e))):
            p = os.path.join(d, "etl", nm); open(p, "w").write(txt); os.chmod(p, 0o755)
        print("wrote", tid)
