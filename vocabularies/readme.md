# OMOP GIS Vocabulary Package
The OMOP GIS (Geographic Information System) Vocabulary Package is designed to elevate data-driven healthcare research by enabling the integration of spatial, environmental, behavioral, socioeconomic, phenotypic, and toxin-related determinants of health into standardized data structures. This comprehensive framework facilitates a multi-dimensional understanding of health outcomes, accounting for both external environmental exposures and intrinsic patient characteristics.

This package is a vital extension of the OMOP CDM, addressing the growing need to contextualize healthcare data with external environmental and societal factors. Developed and maintained by the [GIS Working Group](https://www.ohdsi.org/web/wiki/doku.php?id=projects:workgroups:gis), this package provides vocabularies, scripts, and documentation for seamless term integration into existing OHDSI vocabularies.

* **Objective**: To provide a comprehensive, standardized framework that enables the incorporation of geographic, toxicological, healthcare, behavioral, and socioeconomic terminology into the OMOP Common Data Model (CDM).
* **Application**: Ideal for terminologists, ontologists, researchers, epidemiologists, and data analysts.
* **Integration**:
    * The package is compatible with existing OMOP CDM.
    * All vocabularies, scripts, and mappings conform to OMOP standards.
    * Designed to scale with evolving data needs and expanding global health contexts.
----------------------------------------------      
* **Features**:
    * **OMOP GIS Vocabulary**: Standardizes geographical terminologies and spatial data, supporting geospatial epidemiology, healthcare accessibility studies, and population health research. The OMOP GIS vocabulary is a compilation of terminologies related to geography, boundaries, and spatial elements. 
The vocabulary encompasses 159 concepts of the Observation OMOP domain. 
    * **OMOP Exposome Vocabulary**: Integrates environmental and toxicological factors (exposomes) into the OMOP CDM, providing a taxonomy of environmental pollutants, toxins, and chemical agents. Offers a comprehensive taxonomy and classification system centered on environmental substances (exposomes). Designed to facilitate structured data capture, analysis, and interpretation, this vocabulary forms the foundation for toxicological studies within the observational health data paradigm. The concepts within the OMOP Exposome Vocabulary belong to the 'Observation' domain and the 'Substance' concept class in OMOP.
    * **OMOP SDOH (Social Determinants of Health) Vocabulary**: encapsulates a refined set of terminologies delineating the multifaceted environmental and societal factors that significantly influence individual and community health outcomes. The vocabulary boasts a comprehensive structure, organized hierarchically to facilitate precise categorization and effective data navigation. Within this structure, the SDOH vocabulary seamlessly integrates key components from recognized standards such as the Social Vulnerability Index (SVI), the Agency for Healthcare Research and Quality (AHRQ) frameworks, and the Social Determinants of Health Ontology (SDOHO) nodes. This integration ensures a rich, multi-dimensional perspective, capturing a wide spectrum of determinants from socioeconomic status to healthcare access, and from educational opportunities to neighborhood and built environment. Examples of Main Nodes of the SDOH Hierarchy:
     * Element Relevant To Demographics
     * Element Relevant To Education
     * Element Relevant To Geographic Location
     * Element Relevant To Health
     * Element Relevant To Physical Environment
     * Element Relevant To Population
     * Element Relevant To Social And Community Context

-----------------------------------
## Sources
The following data sources have been processed to enrich and integrate spatial, environmental, behavioral, socioeconomic, phenotypic, and toxin-related entities into the OMOP GIS Vocabulary Package. 

1. **Area Deprivation Index (ADI)**
* Link: [ADI Story Map](https://storymaps.arcgis.com/stories/a5511f076857458188737a6c9c18a744)
* Use Case: [Issue #290](https://github.com/OHDSI/GIS/issues/290)
* Description: The ADI measures socioeconomic deprivation at the neighborhood level, which is a critical factor in understanding disparities in health outcomes. The dataset helps identify areas with high social and economic challenges that impact population health.

3. **AHRQ Social Determinants of Health (SDOH) Database**
* Link: [AHRQ SDOH Data Sources Documentation](https://www.ahrq.gov/sites/default/files/wysiwyg/sdoh/SDOH-Data-Sources-Documentation-v1-Final.pdf)
* Use Case: [Issue #175](https://github.com/OHDSI/GIS/issues/175)
* Description: This database, provided by the Agency for Healthcare Research and Quality (AHRQ), offers a collection of data sources on social determinants of health (SDOH). It includes key indicators such as income, education, employment, and healthcare access, which influence health outcomes across populations.

4. **Child Opportunity Index (COI)**
* Link: [COI Database](https://data.diversitydatakids.org/dataset/coi20-child-opportunity-index-2-0-database/resource/080cfe52-90aa-4925-beaa-90efb04ab7fb)
* Use Case: [Issue #288](https://github.com/OHDSI/GIS/issues/288)
* Description: The COI provides insights into the quality of resources and opportunities available to children across different neighborhoods. The index covers multiple dimensions, including education, health, and social environment, critical for analyzing the impact of socioeconomic factors on child development.

5. **Environmental Justice Index (EJI)**
* Link: [EJI Data Dictionary](https://eji.cdc.gov/Documents/Data/2022/EJI_2022_Data_Dictionary_508.pdf)
* Use Case: [Issue #307](https://github.com/OHDSI/GIS/issues/307)
* Description: The EJI measures the cumulative impacts of environmental injustice on health, particularly in vulnerable communities. It integrates environmental, social, and health data to highlight areas where health outcomes are disproportionately affected by environmental hazards.

6. **Sustainable Development Goals (SDG)**
* Link: [SDG Overview](https://globalcompact.org.ua/en/17-sustainable-development-goals/)
* Use Case: [Issue #288](https://github.com/OHDSI/GIS/issues/288)
* Description: The United Nations' 17 Sustainable Development Goals (SDGs) and their indicators aim to address global challenges, including poverty, inequality, climate change, environmental degradation, and health.

7. **Social Determinants of Health Ontology (SDOHO)**
* Link 1: [SDOHO PubMed Article](https://pubmed.ncbi.nlm.nih.gov/37301740/)
* Link 2: [SDOHO OWL](https://ww2.uth.edu/dA/e1e921b288/SDoHO_1005.owl?language_id=1)
* Use Case: [Issue #198](https://github.com/OHDSI/GIS/issues/198)
* Description: SDOHO is an ontology that models the social determinants of health, providing a structured framework to represent the complex relationships between social, economic, and environmental factors that influence individual and population health outcomes.

8. **Social and Environmental Determinants of Health (SEDH)**
* Link: [SEDH Report](https://info.ornl.gov/sites/publications/Files/Pub200164.pdf)
* Use Case: [Issue #307](https://github.com/OHDSI/GIS/issues/307)
* Description: This dataset focuses on the social and environmental determinants of health, providing a rich source of data on the external factors influencing public health, including physical environment, socioeconomic status, and behavioral factors.

9. **Social Vulnerability Index (SVI)**
* Link: [SVI Documentation](https://www.atsdr.cdc.gov/placeandhealth/svi/documentation/pdf/SVI-2022-Documentation-H.pdf)
* Use Case: [Issue #9](https://github.com/OHDSI/GIS/issues/9)
* Description: The Social Vulnerability Index (SVI) identifies communities that may need support before, during, or after disasters. It uses census data to evaluate the vulnerability of different areas based on factors like poverty, housing, and access to transportation.

10. **Toxin and Toxin Target Database (T3DB)**
* Link: [T3DB Downloads](http://www.t3db.ca/downloads)
* Use Case: [Issue #194](https://github.com/OHDSI/GIS/issues/194)
* Description: The Toxin and Toxin Target Database (T3DB) is a comprehensive resource that catalogs toxins and their biological targets.

The list of the collected source terms and their mappings are maintained in an editable [Google Spreadsheet](https://docs.google.com/spreadsheets/d/1hMLjKokFCpoDqC_WsAd7ZXyBKDmnPif2rR9DlQ9X7cs/edit?usp=sharing), allowing for real-time collaboration and ongoing validation by the community.

## Concept Names
Concept names adhere to source data specifications or are guided by relevant literature.

## Concept Codes
Concept codes were either adopted directly from source data or autogenerated for newly developed terms (start with 'GIS' prefix).

## Domains

| **domain_id**           | **Definition**                                                                                               | **Example**                                             | **Exists in OMOP** |
|-------------------------|-------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|--------------------|
| **Behavioral Feature**   | Refers to actions or behaviors by individuals that influence health outcomes, often related to lifestyle choices. | `Element Relevant To Physical Activity`                                                    | **NO**             |
| **Demographic Feature**  | Describes the characteristics of a population, such as age, gender, race, or ethnicity.                      | `Race In Population`                                                                  | **NO**             |
| **Environmental Feature**| Involves natural or man-made environmental factors that affect health and well-being.                        | `Air Quality Index (AQI)`                                                 | **NO**             |
| **Geographic Feature**   | Describes physical locations, spatial relationships, and geographical characteristics relevant to health studies. | `State-County FIPS Code (5-Digit)`                                                     | **NO**             |
| **Healthcare Feature**   | Involves elements directly related to healthcare services, access, and utilization.                          | `Element Relevant To Health Care`                                       | **NO**             |
| **Observation**          | Captures clinical or non-clinical observations relevant to the contextual data.                              | `Total Number Of Households`                                                                       | **YES**            |
| **Phenotypic Feature**   | Refers to observable traits or characteristics of an individual, influenced by genetic and environmental factors. | `Element Relevant To Depression`                             | **NO**             |
| **Socioeconomic Feature**| Involves social and economic factors that impact health, such as income, education, or employment status.     | `Employment In Population`                                                     | **NO**             |
| **Type Concept**         | A categorization used to define where the record comes from.                                                 | `Air Quality Database`                                                                                             | **YES**            |
## Concept Classes
| **concept_class_id**    | **Definition**                                                                                                     | **Example**                                                                                                     |
|-------------------------|---------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| **ADI Construct**        | Represents a high-level conceptual framework within the Area Deprivation Index (ADI) for analyzing socioeconomic factors. | `Area Deprivation Index (ADI)`   |
| **ADI Item**            | Refers to specific elements or data points that make up the ADI framework.  | `% Families Below Federal Poverty Level`  |
| **AHRQ Construct**      | A conceptual framework from the Agency for Healthcare Research and Quality (AHRQ) related to social determinants of health. | `Food Access`               |
| **AHRQ Determinant**    | A measurable factor derived from AHRQ's data, influencing health outcomes.     | `Crime And Violence`    |
| **AHRQ Item**           | Specific data points or elements within the AHRQ framework.     | `Total Number Of Households`         |
| **COI Construct**       | A framework within the Child Opportunity Index (COI) for assessing child well-being and opportunity.      | `Economic Resource Index` |
| **COI Determinant**     | A measurable factor in the COI influencing child development and health.    | `Access To Green Spaces`                                                |
| **COI Item**            | Specific data points or factors that make up the COI.                                                               | `Mean Estimated 8-Hour Average Ozone Concentration`                                                |
| **EJI EBM Item**        | Refers to an Environmental Burden Measure (EBM) within the Environmental Justice Index (EJI).                        | `Ambient Concentrations Of Diesel PM/M3`                                   |
| **EJI HVM Item**        | Refers to a Health Vulnerability Measure (HVM) within the EJI.                                                       | `Percentage Of Individuals With Cancer`                                  |
| **EJI Item**            | A general item from the EJI, integrating environmental and health vulnerability data.                               | `Census Tract Code`       |
| **Exposome Target**     | Represents specific biological targets within the exposome (a measure of all environmental exposures across a lifetime). | `Tissue-type plasminogen activator`
| **Exposome Transporter**| Refers to biological transporters related to the exposome, responsible for moving substances within an organism.      | `SLCO2B1 (OATP2B1, OATP-B)`                                                  |
| **Exposure Type Concept**| A category defining types of exposures relevant to toxicology and environmental health studies.                     | `Census Data`                                                       |
| **Geometry Relationship**| Refers to spatial relationships within geographic data, such as spatial proximity or overlap.                       | `Near/Proximity to`                                                       |
| **Geometry Type**       | Defines the type of geometry used in spatial data.                                                                  | `Polygon`                                                           |                                                  |
| **GIS Measure**         | A specific metric or quantitative value derived from GIS data.                                                      | `Estimate`                                                     |
| **Location**            | Refers to the specific geographic location or spatial point in GIS data.                                             | `Administrative Boundary`                                                    |
| **SDG Goal**            | Represents one of the United Nations' Sustainable Development Goals (SDGs) related to health, environment, and equity. | `Significantly reduce all forms of violence and related death rates everywhere`                                         |
| **SDG Indicator**       | A measurable indicator for tracking progress toward SDG goals.                                                      | `Proportion of bodies of water with good ambient water quality`                   |
| **SDOH Construct**      | A high-level framework for understanding social determinants of health (SDOH) and their impact on population health. | `Neighborhood Quality`                                                    |
| **SDOH Determinant**    | A specific social or economic factor that directly influences health outcomes.                                       | `Air Quality Index (AQI)`                                                        |
| **SDOH Item**           | A specific data element within the SDOH framework.                                                                  | `The Air Quality Index For The Day For PM2.5`                                                       |
| **SDOHO Construct**     | A conceptual framework from the Social Determinants of Health Ontology (SDOHO) focused on categorizing health determinants. | `Smoking`                                                                     |
| **SDOHO Determinant**   | A measurable factor in the SDOHO framework affecting health.                                                         | `Alcohol Use`                                           |
| **SDOHO Item**          | A specific measurable element in the SDOHO framework.                                                            | `Occupational Prestige Score`                                                |                                               |
| **SDOHO Value**         | A specific value or outcome within the SDOHO framework that reflects health disparities or social conditions.        | `Intersex`                                                 |
| **SEDH Construct**      | A conceptual framework for Social and Environmental Determinants of Health (SEDH).                                   | `Social Capital Index`                                            |                           |
| **SEDH Item**           | A data element within the SEDH framework.                                                                           | `Veteran Segments By Census Block Group`                                                              |                                            |
| **Substance**           | A chemical or biological substance relevant to environmental exposure or toxicology.                                | `Nicotine`                                                      |
| **SVI Construct**       | A conceptual framework for the Social Vulnerability Index (SVI), representing factors that make communities vulnerable. | `Household Characteristics`                                 |
| **SVI Determinant**     | A specific factor in the SVI that directly impacts a community's resilience to health risks or environmental hazards. | `Housing Type & Transportation`                                    |
| **SVI Item**            | A specific data point within the SVI framework.                                                                     | `Persons Below 150% Poverty Estimate MOE`      |

### Additional Glossary for Concept Classes Understanding:
* **Construct**: represents conceptual or behavioral elements that are often measured through subjective or indirect means. Constructs are used to characterize complex or abstract social, psychological, or environmental phenomena that contribute to understanding health outcomes but are not necessarily directly measurable or causal by themselves. Examples:
    * Social Norms And Attitude (SDOHO Construct)
    * Sexual Orientation (SDOHO Construct)
    * Occupational Hazards (SDOH Construct)
    * Neighborhood Safety (SDOH Construct)
These examples reflect behaviors, relationships, and environmental factors that influence health outcomes, but they are abstract and typically involve interpretation, surveys, or proxies for measurement.

* **Determinant**: is a specific, measurable factor that has a more direct influence on health outcomes. Determinants are often quantifiable and can be linked more concretely to causes or risk factors affecting a person’s health, such as economic status, education, or access to healthcare. Examples:
    * Veteran Status (SDOHO Determinant)
    * Healthcare Provider Availability (SDOH Determinant)
    * Income (AHRQ Determinant)
    * Tobacco Use (SDOHO Determinant)
    * Vaccination Status (SDOH Determinant)

* **Item**: is a specific, measurable data point or element that is used to evaluate a larger construct or determinant.
    * % Households Without A Motor Vehicle (ADI Item)
    * All Cause Readmissions Per 100 Male Admissions (AHRQ Item)
    * Ambient Concentrations Of Diesel PM/M3 (EJI EBM Item)
    * Civilian (Age 16+) Unemployed Estimate (SVI Item)

* **Item Value**: is a specific measurable value or state that the item can take. The item values might include "employed," "unemployed," "self-employed," "retired," etc.
      
## Concept Status (Standardness)
If a full semantic match is identified in OMOP, GIS codes are mapped to the corresponding standard concepts and reclassified as non-standard. If no match is found, GIS codes are retained as standard concepts.

## Valid Start Date
| **vocabulary_id**       | **valid_start_date**                  |
|-------------------------|---------------------------------------|
| OMOP Exposome            | source field `updated_at` in 'MM-DD-YYYY' format   |
| OMOP Exposome (cas is null) | 09-14-2024  |
| OMOP SDOH (concept_class_id_1 ~ 'SDOHO') | 01-01-2022           |
| OMOP SDOH (concept_class_id_1 ~ 'ADI')     | 01-01-2018           |
| OMOP SDOH (concept_class_id_1 ~ 'AHRQ')   | 01-01-2022           |
| OMOP SDOH (concept_class_id_1 ~ 'COI')     | 01-01-2020           |
| OMOP SDOH (concept_class_id_1 ~ 'EJI')     | 01-01-2022           |
| OMOP SDOH (concept_class_id_1 ~ 'SEDH')   | 01-01-2021           |
| OMOP SDOH (concept_class_id_1 ~ 'SVI')     | 01-01-2018           |
| OMOP SDOH (concept_class_id_1 ~ 'SDG')     | 03-01-2017             |
| All other cases          | 09-14-2024       |

## Relationships
| **relationship_id**         | **reverse_relationship_id** | **Meaning**                                                                                             |
|-----------------------------|-----------------------------|---------------------------------------------------------------------------------------------------------|
| **Locates in cell**          | **Cell contains**            | Indicates that a certain agent or substance is found within or targets a cellular entity.                |
| **Locates in tissue**        | **Tissue contains**          | Suggests that a certain agent or substance is present within or targets a specific tissue type.          |
| **Impacts on process**       | **Impacted by**              | Signifies that an agent or substance exerts an influence on a specific process.                          |
| **Affects biostructure**     | **Affected by**              | Suggests that an agent or substance has an impact on a certain biological structure.                     |
| **Maps to**                  | **Mapped from**              | Indicates a relationship where a concept is equated to or represented as a standard OMOP concept.        |
| **Is a**                     | **Subsumes**                 | Hierarchical relationship where a concept is a subset or instance of a more general concept.             |
| **Has associated finding**   | **Asso finding of**          | Indicates a relationship between a concept and an associated finding related to it.                      |
| **Has relat context**        | **Relat context of**         | Describes the contextual relationship between two related concepts.                                      |
| **Has geometry**             | **Is geometry of**           | Represents the spatial or geometric relationship between an entity and its geographic or spatial structure. |

Examples:
    * **Hierarchical relationships**: *'Is a'* - *'Subsumes'*: 'Polygon' - 'Is a' - '2D (Two-Dimensional) Geometry' / '2D (Two-Dimensional) Geometry' - 'Subsumes' - 'Polygon'
    * **Supplemental GIS-specific relationships**: e.g. *'Is geometry of'* - *'Has geometry'*: 'LineString'	-	 'Is geometry of' -	'International Border' / 'International Border'	-	'Has geometry' - 'LineString'

## Mapping and Hierarchy

| **target_vocabulary_id** | **number of associations** |
|----------------------------|-----------|
| OMOP Exposome               | 82,150    |
| OMOP SDOH                   | 6,738     |
| RxNorm                      | 4,418     |
| RxNorm Extension            | 2,221     |
| SNOMED                      | 1,769     |
| LOINC                       | 776       |
| OMOP GIS                    | 423       |
| ICD10CM                     | 122       |
| PPI                         | 56        |
| OMOP Genomic                | 49        |
| OMOP Extension              | 32        |
| OSM                         | 25        |
| UK Biobank                  | 24        |
| Type Concept                | 24        |
| CPT4                        | 10        |
| HCPCS                       | 9         |
| Nebraska Lexicon            | 3         |
| Race                        | 2         |
| ATC                         | 2         |
    
### Future work:
* Test the vocabulary with more use cases.
* Fix hidden errors.
* Build additional hierarchical relationships.
* Enrich and refine the vocabulary.
