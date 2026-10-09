# Empirical geocoding errors

Distance in metres between the geocoded point and the Miami-Dade County property point, for 5,000 randomly drawn addresses geocoded with four tools
(ArcGIS Pro, Nominatim, DeGAUSS, PostGIS TIGER). Derived from the [geocode-benchmark-2023](https://github.com/tibbben/geocode-benchmark-2023)
data by Timothy Norris (University of Miami Libraries; CC BY 4.0): the distances are the `*_distance` columns of
`mdc_5000_addresses_geocode_join` in `geocode.sql` (EPSG:2236, feet), converted to metres. Addresses and coordinates are not included.

| File | Geocoded | Median (m) | Mean (m) | > 100 ft | > 500 ft | > 1 mile |
|---|---|---|---|---|---|---|
| `errors_arcgis.csv` | 4,868 | 26.1 | 86.6 | 1,883 | 94 | 7 |
| `errors_nominatim.csv` | 4,918 | 5.6 | 92.2 | 1,200 | 301 | 71 |
| `errors_degauss.csv` | 4,960 | 50.2 | 249.2 | 3,540 | 957 | 191 |
| `errors_postgis.csv` | 4,999 | 47.4 | 1,199.1 | 3,325 | 924 | 213 |

The summaries reproduce the statistics in the benchmark's `NOTES.md`. Columns: `stratum` (`all`: the benchmark is a single urban county, so there is no urban/rural split) and `error_m`.
These files are the input of `tract/geocoding_error_mc.sh --errors`.

## Full summary (feet)

| Geocoder | Geocoded (of 5,000) | Hit rate | 0–100 ft | 100–500 ft | 500 ft–1 mi | > 1 mile | Min (ft) | Max (ft) | Mean (ft) | Median (ft) | SD (ft) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| PostGIS TIGER | 4,999 | 99.98% | 1,675 | 2,400 | 711 | 213 | 5 | 2,700,504 | 3,934 | 155 | 66,546 |
| DeGAUSS | 4,960 | 99.20% | 1,420 | 2,583 | 766 | 191 | 13 | 57,698 | 818 | 165 | 2,420 |
| ArcGIS Pro | 4,868 | 97.36% | 2,985 | 1,789 | 87 | 7 | 0.1 | 212,687 | 284 | 85 | 4,724 |
| Nominatim | 4,918 | 98.36% | 3,718 | 899 | 230 | 71 | 0.0 | 57,096 | 303 | 18 | 1,906 |

Distance from the geocoded point to the county's property point, in feet (EPSG:2236), for the 5,000 randomly drawn Miami-Dade addresses; the distance bins are mutually exclusive and sum to the number geocoded. Min, max, mean, median and SD reproduce the geocode-benchmark-2023 summary exactly. The distance-bin counts differ from the table in that repository's README, whose four bins do not partition the addresses (the "100 to 499 ft" and later columns match the cumulative counts of addresses over 100 ft, over 500 ft and over a mile), and ArcGIS has 4,868 geocoded rows in the benchmark's database dump (97.4%), not the 100% shown there (Norris's notes record 4,865 matched, 3 tied, 132 unmatched).
