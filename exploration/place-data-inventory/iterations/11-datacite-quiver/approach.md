# Iteration 11: the DataCite quiver (2026-10-29)

## Approach

An ad hoc test, run from the Claude desktop browser pane. There was no prompt file: the work ran directly in the chat session. JavaScript `fetch` calls went to DataCite's public REST API (`api.datacite.org/dois`), with no key. The results were saved to `quiver/`.

1. **Unfiltered test.** Free-text queries for 3 anchors (care sites, deprivation indices, heat), datasets from 2015 on.
2. **Refined pilot.** The 5 priority-1 anchors from `landscape/anchors.csv`. Each query:
   - searches **titles only** (`titles.title:(...)`);
   - requires a **place term in the title** (county, tract, ZIP, district, gridded, 1 km, LSOA, NUTS, province, sub-national, geocoded and others);
   - keeps datasets only, published 2015-2026;
   - fetches up to 500 results per anchor.

   Results are de-duplicated by title, with spam removed.
3. **Australia.** All 12 anchors, with Australian terms (state names, cities, SA1-SA3, LGA, Mesh Block, postcode) required anywhere in the record. A flag records whether Australia appears in the title.

## Results

| Run | Rows | Notes |
|---|---|---|
| Unfiltered test | not saved | Care sites: 9,093 hits, top results were Zenodo spam. Every record appeared twice (concept and version DOIs) |
| Refined pilot (`quiver/datacite-pilot-2026-10-29.csv`) | 1,006 | Care sites 112, deprivation 84, census socioeconomic 287, heat 232, water hazards and fire 291. 813 have a place unit in the title; 1 already in the inventory |
| Australia (`quiver/datacite-australia-2026-10-29.csv`) | 1,903 | 626 with Australia in the title. None already in the inventory, which had 7 Australian rows |

Strong examples:
- geocoded primary-care clinics in Brazil;
- 1 km hospital travel-time maps for China;
- access to dementia-related facilities in the US;
- SVI by block group;
- county-level daily maximum temperature for the continental US;
- cancer surgery waiting times by Australian hospital;
- South Australia's bushfire history;
- Victoria's EPA air-quality stations.

## Review

- **Worked:**
  - cost was near zero (a few API calls, no Claude Code, no agents);
  - nearly all results were new to the inventory;
  - title-only queries with a required place term removed the spam.
- **Didn't:**
  - unfiltered free text is unusable;
  - broad words create false matches: census (species, plants), heatwave (marine), noise (quantum), emission (greenhouse-gas factors);
  - Australian rows without Australia in the title are mostly unrelated;
  - most hits are single-study research outputs.
- **Learned:**
  - DataCite works as a discovery index only with filters: titles, place terms, and preferably curated repositories (ICPSR, Dataverse, Pangaea, the JRC);
  - for Australia, the best hits were Zenodo copies of government portal data, so data.gov.au and the state portals are the primary source;
  - precision has not been measured yet; Prompt 2 phase B does that.
- **Process note:** large browser results were saved to files by the tool instead of being read into the conversation, which kept the session's token use small.
