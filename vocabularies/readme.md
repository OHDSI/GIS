# OMOP GIS Vocabulary Package
The OMOP GIS Vocabulary Package is designed to elevate data-driven healthcare research by enabling the integration of spatial, environmental, behavioral, socioeconomic, phenotypic, and toxin-related determinants of health into standardized data structures. This comprehensive framework facilitates a multi-dimensional understanding of health outcomes, accounting for both external environmental exposures and intrinsic patient characteristics.

This package is a vital extension of the OMOP CDM, addressing the growing need to contextualize healthcare data with external environmental and societal factors. Developed and maintained by the [GIS Working Group](https://www.ohdsi.org/web/wiki/doku.php?id=projects:workgroups:gis), this package provides vocabularies, scripts, and documentation for seamless term integration into existing OHDSI vocabularies.

* **Objective**: To provide a comprehensive, standardized framework that enables the incorporation of geographic, toxicological, healthcare, behavioral, and socioeconomic terminology into the OMOP Common Data Model (CDM).
* **Application**: Ideal for terminologists, researchers, epidemiologists, and data analysts.
* **Integration**:
    * The package is compatible with existing OMOP CDM, allowing for the extension and integration of geographic and societal data into standard health databases.
    * All vocabularies, scripts, and mappings conform to OMOP standards, ensuring interoperability with commonly used health data platforms and tools.
    * Designed to scale with evolving data needs, including new terms, environmental datasets, and expanding global health contexts.
* **Features**:
    * **OMOP GIS Vocabulary**: Standardizes geographical terminologies and spatial data, supporting geospatial epidemiology, healthcare accessibility studies, and population health research. The OMOP GIS vocabulary is a compilation of terminologies related to geography, boundaries, and spatial elements. 
The vocabulary encompasses 159 concepts of the Observation OMOP domain. They are categorized by **concept_class_id as**.* **Target OMOP Vocabularies used in mappings**: OSM, SNOMED (+SDOH)
    * **OMOP Exposome Vocabulary**: Integrates environmental and toxicological factors (exposomes) into the OMOP CDM, providing a taxonomy of environmental pollutants, toxins, and chemical agents. Offers a comprehensive taxonomy and classification system centered on environmental substances (exposomes). Designed to facilitate structured data capture, analysis, and interpretation, this vocabulary forms the foundation for toxicological studies within the observational health data paradigm. The concepts within the OMOP Exposome Vocabulary belong to the 'Observation' domain and the 'Substance' concept class in OMOP. **Target OMOP Vocabularies used in mappings**: SNOMED, RxNorm, RxNorm Extension, OMOP Genomic. 
    * **OMOP SDOH (Social Determinants of Health) Vocabulary**: Captures and standardizes social and environmental factors critical to understanding health disparities and community health. The SDOH vocabulary encapsulates a refined set of terminologies delineating the multifaceted environmental and societal factors that significantly influence individual and community health outcomes. The vocabulary boasts a comprehensive structure, organized hierarchically to facilitate precise categorization and effective data navigation. Within this structure, the SDOH vocabulary seamlessly integrates key components from recognized standards such as the Social Vulnerability Index (SVI), the Agency for Healthcare Research and Quality (AHRQ) frameworks, and the Social Determinants of Health Ontology (SDOHO) nodes. This integration ensures a rich, multi-dimensional perspective, capturing a wide spectrum of determinants from socioeconomic status to healthcare access, and from educational opportunities to neighborhood and built environment. The concepts in the SDOH Vocabulary are part of the newly introduced domains to expand the scope of OMOP. Within the SDOH Vocabulary, there are precisely 8,194 concept associations, systematically structured. This framework defines an intrinsic hierarchy specific to SDOH, while simultaneously interfacing with external OMOP vocabularies. This dual-layered architectural design enhances the robustness and granularity of the representation of the social determinants of health across ODHSI. **Target OMOP Vocabularies used in mappings**: SNOMED, ATC, CPT4, HCPCS, LOINC, Nebraska Lexicon, OMOP Extension, PPI, Race, UK Biobank (+OMOP GIS).
#### Examples of Main Nodes of the SDOH Hierarchy
* Element Relevant To Demographics
* Element Relevant To Education
* Element Relevant To Geographic Location
* Element Relevant To Health
* Element Relevant To Physical Environment
* Element Relevant To Population
* Element Relevant To Social And Community Context

-----------------------------------
## Sources
The following data sources have been processed to enrich and integrate spatial, environmental, behavioral, socioeconomic, phenotypic, and toxin-related determinants into the OMOP GIS Vocabulary Package. 

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
## Concept Names
All concept names are uniquely generated, adhering to source data specifications and informed by the relevant literature to ensure precision and alignment with established terminologies.

## Concept Codes
Concept codes were either adopted directly from source data or autogenerated for newly developed terms (start with 'GIS' prefix).

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
* **Construct**:
* A construct is an abstract concept used to understand and evaluate various determinants of health. It serves as a framework or model that explains complex relationships and behaviors.
* Constructs are often broken down into measurable variables for research. For example, "socioeconomic status" is a construct, but it can be measured using concrete variables like income, education level, or occupation.
* Constructs organize and conceptualize determinants, making it easier to analyze and understand their impact on health outcomes.

* **Determinant**: 
* A determinant is a specific factor or condition that directly affects health outcomes. It refers to real-world factors that influence the health of individuals or populations.
* Determinants can be either positive or negative, including factors like socioeconomic status, education, physical environment, employment, and social support.
* They are actionable, meaning interventions can target these determinants to improve health outcomes.

* **Item**:
    * Refers to a specific element or factor within a broader determinant category. Think of determinants as overarching categories or themes, and determinant items as the individual aspects or components of those themes.
    * Each determinant item provides a more granulated perspective, allowing for detailed examination and understanding of the broader determinant.
* **Item Value**:
    * For some determinant items, there are specific measurable values or states that the item can take.
    * Using the example of the determinant item "employment status," the item values might include "employed," "unemployed," "self-employed," "retired," etc.
      
## Concept Status (Standardness)
By default, all GIS codes are designated as standard concepts. However, if a full semantic match is identified, they are mapped to the corresponding standard concepts in their respective domains and reclassified as non-standard.

## Relationships

| relationship_id     | reverse relationship_id | meaning |
|---------------------|-------|-------|
| Cellular agent     | Locates in cell | Indicates that a certain agent or substance is found within or targets a cellular entity. |
| Tissue agent  | Locates in tissue | Suggests that a certain agent or substance is present within or targets a specific tissue type. |
| Impacts on process         | Impacted by  | Signifies that an agent or substance exerts an influence on a specific process. |
| Affects biostructure |  Affected by | Suggests that an agent or substance has an impact on a certain biological structure. |
| Maps to             | Mapped from | This signifies a relationship where a concept can be equated to or represented as a standard OMOP concept. |
| Is a                | Subsumes | Hierarchical relationship where a concept is a subset or instance of another more general concept. |
| Has component  | Component of | Represents mapping to a SNOMED/LOINC attribute where relevant |

- **Hierarchical relationships**: *'Is a'* - *'Subsumes'*: 'Polygon' - 'Is a' - '2D (Two-Dimensional) Geometry' / '2D (Two-Dimensional) Geometry' - 'Subsumes' - 'Polygon'
- **Supplemental GIS-specific relationships**: e.g. *'Is geometry of'* - *'Has geometry'*: 'LineString'	-	 'Is geometry of' -	'International Border' / 'International Border'	-	'Has geometry' - 'LineString'
    
### Future work:
* Test the vocabulary with more use cases
* Fix hidden errors.
* Build additional hierarchical relationships.
* Enrich and refine the vocabulary.
