# Part B brief: content verification of one batch of dataset landing pages

You are verifying public geospatial datasets for the OHDSI GIS working group's place-based data inventory. You get a small set of rows (a JSON file). For each row, read its landing page (`site_url`) with WebFetch and, if the landing page lacks the facts, follow **at most one** documentation link from it (a "metadata", "documentation", "data dictionary", "about", "license" or "download" page). Then write one JSON result file. Budget: about 2–3 minutes per row. Leave a check `not_checked` rather than digging deeper.

## Hard rules

- **Never download a dataset** (no zip, csv, shp, tif, nc, gdb, parquet). Reading HTML or a PDF/HTML data dictionary is fine.
- **Never bypass bot protection, logins or certificate errors.** If WebFetch returns an error, a challenge page, "enable JavaScript", 403/401/429, or an empty page: set `"blocked": true`, every check `not_checked`, and move on.
- **Never guess.** A field is confirmed only if you read it on a page, and you store that page's URL in `evidence`. Values from your own memory of the dataset are NOT evidence; leave `not_checked` and say in `detail` what you looked for. Do not use web search.
- Do not edit any other file. Write exactly the one result file named in your instructions, under `docs/discovery/partB/results/`.
- Results use the fixed vocabulary `pass` / `warn` / `fail` / `n.a.` / `not_checked`.

## The checks (one object each, with `result`, `detail`, `evidence`)

| key | what to confirm | pass | warn | fail |
|---|---|---|---|---|
| `chk_license` | A licence or terms of use is stated. Put the exact licence in `license_confirmed` (e.g. "CC BY 4.0", "public domain (US Government work)", "Open Government Licence v3", "ODbL", "custom terms: non-commercial") and classify it in `license_class`: `open` (public domain, CC0, CC BY, OGL, ODbL, similar), `attribution` (CC BY when attribution is the only condition can be `open`; use `attribution` for licences whose main condition is attribution and nothing else is said), `non-commercial`, `registration` (free but you must register or accept terms), `restricted` (application, fee, DUA), `unknown` | stated and open or attribution | non-commercial or registration | restricted, or nothing found |
| `chk_temporal` | Years covered. Record `temporal_confirmed` (e.g. "2010–2023 annual", "2019 (single year)", "ongoing since 2015") and `latest_year` (integer; the latest year of data, or the current year if explicitly ongoing/updated continuously) | years stated on the page | years partly stated (e.g. only a release year) | — (use not_checked if nothing) |
| `chk_recency` | From `latest_year`: pass = 2020 or later, or ongoing; warn = 2000–2019; fail = before 2000, or the page says discontinued/no longer updated | | | |
| `chk_cadence` | Update frequency stated (`update_cadence_confirmed`: annual, monthly, daily, irregular, one-time/static, discontinued) | stated | implied only (e.g. a series of yearly releases) | — |
| `chk_version` | Current version/release/vintage named (`version_confirmed`, e.g. "v4.03", "2023 release", "Version 2.3 (Aug 2024)") | named | release date only | — |
| `chk_unit` | Finest spatial unit. Compare with the row's listed `finest_unit`. Record `finest_unit_confirmed` using this vocabulary where it fits: `point`, `line`, `address`, `block`, `block_group`, `tract`, `zcta`, `zip`, `county`, `state`, `country`, `admin1`, `admin2`, `admin3`, `lsoa`, `msoa`, `grid_<res>` (e.g. `grid_1km`, `grid_0.1deg`), `polygon` (custom polygons), `raster` | matches the listed unit | finer or coarser than listed (give the right one) | — (not_checked if not stated) |
| `chk_coverage` | Geographic coverage (`coverage_confirmed`: e.g. "US (50 states, DC, PR)", "global", "EU-27", "England and Wales") | stated | partly | contradicts the listed `coverage` |
| `chk_access` | How you get the data (`access_confirmed`: `open_download`, `api`, `api_key`, `registration`, `request`, `restricted`) | open_download or api with no key | registration, api_key | request or restricted |
| `chk_join_key` | The data dictionary or download description shows a standard geographic key (FIPS/GEOID, ZIP/ZCTA, LSOA code, ISO/NUTS/admin codes, lat/lon) or a geometry (shapefile/GeoJSON). Record `join_key_confirmed` (e.g. "GEOID (11-digit tract FIPS)", "geometry (shapefile)", "lat/lon", "NUTS3 code") | shown | implied (e.g. "by county" with no code named) | the data has no geographic key |
| `chk_format_gaia` | At least one distribution is a format the GDAL-based catalog loader takes: shp, gpkg, geojson, gdb, kml, csv/xlsx with a key or coordinates, geoparquet, geotiff, netcdf. Record `formats_confirmed` (list as a string, e.g. "csv; shp; geojson") | yes | only via an API/viewer, or only pdf/xlsx without a key | no loadable format |

`evidence` is the URL of the page where you read it (the landing page or the one documentation page you followed). Several URLs separated by `;` are fine.

## Result file format

```json
{
  "batch": "<batch id from your instructions>",
  "agent": "<agent id from your instructions>",
  "rows": [
    {
      "id": "<row id exactly as given>",
      "blocked": false,
      "pages_read": ["<url>", "<url>"],
      "license_confirmed": "", "license_class": "",
      "temporal_confirmed": "", "latest_year": null,
      "update_cadence_confirmed": "", "version_confirmed": "",
      "finest_unit_confirmed": "", "coverage_confirmed": "", "access_confirmed": "",
      "join_key_confirmed": "", "formats_confirmed": "",
      "withdrawn_notice": "",
      "notes": "",
      "checks": {
        "chk_license":     {"result": "pass", "detail": "CC BY 4.0 stated in the Licence box", "evidence": "https://..."},
        "chk_temporal":    {"result": "pass", "detail": "2010–2023, annual", "evidence": "https://..."},
        "chk_recency":     {"result": "pass", "detail": "latest year 2023", "evidence": "https://..."},
        "chk_cadence":     {"result": "...", "detail": "...", "evidence": "..."},
        "chk_version":     {"result": "...", "detail": "...", "evidence": "..."},
        "chk_unit":        {"result": "...", "detail": "...", "evidence": "..."},
        "chk_coverage":    {"result": "...", "detail": "...", "evidence": "..."},
        "chk_access":      {"result": "...", "detail": "...", "evidence": "..."},
        "chk_join_key":    {"result": "...", "detail": "...", "evidence": "..."},
        "chk_format_gaia": {"result": "...", "detail": "...", "evidence": "..."}
      }
    }
  ]
}
```

`withdrawn_notice`: if the page says the dataset is retired, discontinued, decommissioned or no longer available, quote the sentence; otherwise leave empty.

When you have written the file, reply with one line per row: `id: n checks pass / n warn / n fail / n not_checked; blocked yes|no`. Nothing else.
