# Backlog: place identifiers and boundary standards (exploration 3)

**Status:** backlog, high priority. Raised by Robert on 2026-10-28 while drafting the anchors for the landscape assessment. It is a separate exploration, not part of round 1 or of the landscape census, except for the one cheap step below.

## The problem

Place-based data joins to patients through a place identifier: the foreign key that says "this row is about this tract, district or region". Every country, and often every publisher, has its own.

Without a deliberate choice, Gaia inherits thousands of representations of the same places. That means:
- mismatched names and codes;
- different vintages of the same boundaries;
- no reliable way to join a dataset from one source to a location from another.

This is a semantics and interoperability problem, not a geometry problem. The question is which identifier systems Gaia should treat as first-class, and which crosswalks it needs between them.

## Questions to answer

1. **Which identifier does place-related data use, by country and region?** What foreign key does a typical dataset carry?
2. **How prevalent is each system outside the US?** US data is dominated by Census GEOIDs and FIPS codes. What is the equivalent elsewhere, and how consistently is it used?
3. **Is there a consensus standard per region?** A top-down standard (for example, one shared by all EU countries) avoids building per-country handling.
4. **Which crosswalks exist?** Between systems (for example NUTS to national codes, P-codes to GADM), and between vintages of the same system (2010 vs 2020 tracts).
5. **What does Gaia need to store?** Identifier system, code, vintage and level, plus the vocabulary to express them (ties to the working group's vocabulary work and to OMOP's location tables).

## Starting map (from memory; to be verified in the exploration)

| Scope | Identifier system | Notes |
|---|---|---|
| United States | Census GEOID; FIPS state and county codes | GEOIDs nest from state to block. Vintages change every decennial census, so crosswalks are needed |
| European Union | Eurostat NUTS regions (levels 0-3) and LAU local units | A consensus statistical standard across member states; official boundaries from Eurostat GISCO; revised every few years |
| United Kingdom | ONS area codes (e.g. E01... for LSOAs) | Its own system; still mapped to NUTS-equivalent levels (ITL) after Brexit |
| Canada | Statistics Canada's Standard Geographical Classification and DGUIDs | Census-based, like the US |
| Australia | The Australian Statistical Geography Standard (ASGS) | Census-based statistical areas |
| Humanitarian settings, much of Africa and Asia (including Kenya) | OCHA P-codes on the Common Operational Datasets for boundaries | The de facto standard for admin levels in HDX data; relevant to the APHRC climate and HIV use case |
| Countries and first-level subdivisions, worldwide | ISO 3166-1 and ISO 3166-2 | Stable and universal, but stops at admin level 1 |
| Global boundary sets | GADM IDs, geoBoundaries IDs, HASC codes | Widely used in research; not official; versions differ |
| Statistical regions | UN M49 | For country groupings, not sub-national work |

## Suggested approach

1. **Measure before choosing (cheap, already scheduled).** The landscape assessment (`PROMPT-2-landscape-census.md`) records, for every candidate it pulls, the join key and identifier type when the metadata states one. That gives real counts of identifier use by region at no extra cost.
2. **Read the standards top-down.** For each region, find the official or consensus standard, its maintenance body, its revision cycle and its published crosswalks.
3. **Profile the inventory.** For the Gold and Silver rows, record the identifier system and vintage from part B's join-key check (`chk_join_key`).
4. **Recommend a short list.** Name the systems Gaia supports first-class, with the crosswalks it needs, and how a location in OMOP maps to each. Bring it to the working group.

## Out of scope here

Building crosswalks; changing gaiaCore or gaiaDB; geometry processing.

## Links

- `landscape/anchors.csv`: administrative boundaries were removed as an anchor and moved here.
- The working group's use cases: https://ohdsi.github.io/GIS/status.html (the global-geometry requests: gaiaCatalog#31 DIVA-GIS; GIS#289 INSPIRE).
