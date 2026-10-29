# Place-based data inventory (exploratory)

A working inventory of public, place-based datasets that could be linked to where patients live, built by the OHDSI GIS working group's discovery effort. **Explore it on the site: [Data Inventory](https://ohdsi.github.io/GIS/inventory.html).** Nothing here is a gaiaCatalog entry yet.

**As of 2026-10-30:** 691 datasets assessed. **494 verified** (Gold 105, Silver 389): licence, years, spatial unit and access read from the publisher's pages, with the page kept as evidence. **15 file-verified**: a real file opened and its columns, place key, geometry and years read. Bronze 127, Browser needed 23, Failed 47. About 1,087 more unvalidated candidates (rule-triaged, precision about 0.59) are in `candidates-unvalidated.csv`.

## Files

| File | What it is |
|---|---|
| `inventory-verified.csv` | The Gold and Silver datasets |
| `inventory-all.csv` | Every assessed dataset with every check, its detail and evidence URL, geometry classification and file-check findings |
| `place-data-inventory.xlsx` | The same, as a workbook with a summary and a colour-coded check grid |
| `candidates-unvalidated.csv` | DataCite references found by title search, triaged by rules; to be checked later |
| `iterations/` | How it was built: 17 iterations, each with its approach (prompt or brief) and results |
| `TODO.md` | What's next, from ready-to-run to needs-the-working-group |
| `method/` | The anchors (what we measure against), the unit and place-key vocabulary, the place-identifiers backlog and the scripts |

## How to read a row

- **Tier.** Gold: link, page, licence, unit, years and access all pass. Silver: link passes and no check fails. Bronze: live, but content not read or incomplete. Browser needed: the site blocks scripts; a person should open it. Failed: dead, withdrawn, or data before 2000.
- **Verification level.** `page-verified` (read from the publisher's pages) or `file-verified` (a file was opened). Column `verification_level`.
- **Checks.** Each check is pass / warn / fail / n.a. / not checked, with `_detail` and `_evidence` columns.
- **Geometry.** `geometry_source`: the dataset ships its own geometry (`embedded`), joins to a standard geography such as Census tracts or NUTS (`reference_standard`), or needs one specific geometry dataset (`reference_specific`, with `geometry_dependency`).

## Caveats

- **Licence by rule.** US federal works are treated as public domain unless a page says otherwise (`license_class = public_domain_us_federal`); for those rows Gold rests on that rule, not on a statement read on the page.
- **Inferred geometry.** About 60% of geometry classifications are inferred from the unit and name (`geo_class_basis`).
- **No workarounds.** Sites that block scripts were not worked around, and no logins or registrations were used. Gated sources say so.
- **Exploratory.** Counts move as checks are added; see `iterations/` for what each number comes from.
