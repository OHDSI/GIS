# OMOP GIS Vocabularies Package
The OMOP GIS Vocabularies Package advances data-driven healthcare research by seamlessly integrating spatial, environmental, and societal determinants into unified data structures, catering to the evolving demands of the field.
It includes vocabularies, scripts, and documentation, all curated by the [GIS Working Group](https://www.ohdsi.org/web/wiki/doku.php?id=projects:workgroups:gis), to facilitate the integration of new terms into an existing OMOP Vocabulary instance.

* **Objective**: To facilitate a robust understanding of health determinants by providing a systematic framework for incorporating geographical, toxicological, and societal data.
* **Features**:
    * **OMOP GIS Vocabulary**: Offers terminologies covering geographic details, boundaries, and spatial elements essential for geographical epidemiology and health accessibility studies.
    * **OMOP Toxin Vocabulary**: Provides an  integrated into the OMOP Vocabulary taxonomy of toxins, catering to environmental pollutants and specific chemical agents, thereby supporting toxicological research and interventions.
    * **SDOH (Social Determinants of Health) Vocabulary**: Captures environmental and societal factors crucial for health disparity and community health research.
* **Application**: Ideal for healthcare researchers, epidemiologists, and data analysts focused on a holistic approach to health data exploration.
* **Integration**:
    * Designed for seamless integration with standard health data structures.
    * Compliant with existing OMOP standards, ensuring compatibility with prevalent health databases and platforms.
      
## Contents 
## OMOP GIS Vocabulary
The OMOP GIS vocabulary is a compilation of terminologies related to geography, boundaries, and spatial elements. Developed at the intersection of healthcare and geospatial studies, this vocabulary facilitates precise geospatial analyses within observational health research.

The vocabulary encompasses 159 concepts of the Observation OMOP domain. They are categorized by **concept_class_id as**:
* **Geometry Item**: e.g. 'LineString', 'Polygon', '2D (Two-Dimensional) Geometry'
* **Location**: e.g. 'Administrative Boundary', 'County'
* **Geom Relationship**: e.g. 'Within', 'Adjacent to'

The concepts within the vocabulary are interlinked through the following associations: 
- **Hierarchical relationships**: *'Is a'* - *'Subsumes'*: 'Polygon' - 'Is a' - '2D (Two-Dimensional) Geometry' / '2D (Two-Dimensional) Geometry' - 'Subsumes' - 'Polygon'
- **Supplemental GIS-specific relationships**: e.g. *'Is geometry of'* - *'Has geometry'*: 'LineString'	-	 'Is geometry of' -	'International Border' / 'International Border'	-	'Has geometry' - 'LineString'

**Target OMOP Vocabularies used in mappings**: OSM, SNOMED (+SDOH)

 ### Future work:
* Build additional hierarchical relationships within the "Location" concept_class_id in OMOP.
* Enhance and refine the vocabulary.
* Test the vocabulary with more use cases
    
## OMOP Toxin Vocabulary
Offers a comprehensive taxonomy and classification system centered on environmental substances (exposomes). Designed to facilitate structured data capture, analysis, and interpretation, this vocabulary forms the foundation for toxicological studies within the observational health data paradigm.

The concepts within the OMOP Toxin Vocabulary belong to the 'Observation' domain and the 'Substance' concept class in OMOP.
There are 170,593 associations between concepts. These connections are defined by relationships:
| relationship_id     | reverse relationship_id | meaning |
|---------------------|-------|-------|
| Cellular agent     | Locates in cell | Indicates that a certain agent or substance is found within or targets a cellular entity. |
| Tissue agent  | Locates in tissue | Suggests that a certain agent or substance is present within or targets a specific tissue type. |
| Impacts on process         | Impacted by  | Signifies that an agent or substance exerts an influence on a specific process. |
| Is a                | Subsumes | Hierarchical relationship where a concept is a subset or instance of another more general concept. |
| Affects biostructure |  Affected by | Suggests that an agent or substance has an impact on a certain biological structure. |
| Maps to             | Mapped from | This signifies a relationship where a concept can be equated to or represented as a standard OMOP concept. |

**Target OMOP Vocabularies used in mappings**: SNOMED, RxNorm, RxNorm Extension, OMOP Genomic. 

### Future work:
* Test the vocabulary with more use cases
* Build additional hierarchical relationships.
* Enhance and refine the vocabulary.

## SDOH Vocabulary
The "Social Determinants of Health" (SDOH) vocabulary encapsulates a refined set of terminologies delineating the multifaceted environmental and societal factors that significantly influence individual and community health outcomes. The vocabulary boasts a comprehensive structure, organized hierarchically to facilitate precise categorization and effective data navigation. Within this structure, the SDOH vocabulary seamlessly integrates key components from recognized standards such as the Social Vulnerability Index (SVI), the Agency for Healthcare Research and Quality (AHRQ) frameworks, and the Social Determinants of Health Ontology (SDOHO) nodes. This integration ensures a rich, multi-dimensional perspective, capturing a wide spectrum of determinants from socioeconomic status to healthcare access, and from educational opportunities to neighborhood and built environment. 

The concepts in the SDOH Vocabulary are part of the newly introduced 'Phenotypic Feature' domain to expand the scope of OMOP.

### Selection of the 'Phenotypic Feature' Domain for Observational Studies
In the realm of observational health studies, capturing comprehensive and nuanced patient data is of paramount importance. This ensures the validity and applicability of the findings. Utilizing the [Social Determinants of Health Ontology (SDoHO)](https://academic.oup.com/jamia/article-abstract/30/9/1465/7193859?redirectedFrom=fulltext&login=false) as the foundational structure for the vocabulary allowed us to capture an extensive range of environmental, social, and personal determinants of health. Given the intricacies and nuances of these determinants, the conventional OMOP domains, such as Observation, Measurement, Condition, and Procedure, might not entirely suffice. Here's why:
* **Nature of SDOH data**: The determinants often represent intrinsic and extrinsic attributes that mold an individual's health status. These aren't merely observations or specific conditions but can be viewed as characteristic traits or phenotypic features. They encompass more than just medical conditions or procedures; they capture the broader spectrum of factors affecting health.
* **Holistic understanding**: Phenotypes, by definition, are observable characteristics resulting from the interaction of an organism's genetic makeup with the environment. When studying social determinants, it's vital to capture the whole picture – the result of genetics and environment. The 'Phenotypic Feature' domain aligns with this philosophy, offering a more holistic view of patients in observational studies.
* **Granularity and complexity**: The depth of data in the realm of SDOH transcends mere observations or conditions. It's about the intricate interplay of genetics, environment, and personal choices, which are best depicted as phenotypic features. This provides researchers a more granular insight into the factors affecting health outcomes.
* **Flexibility and expansion**: Using a 'Phenotypic Feature' domain allows for greater adaptability. As our understanding of social determinants evolves, the phenotypic feature domain can more easily accommodate new insights, traits, or determinants that might not fit neatly into more rigid categories like Procedure or Condition.
* **Interdisciplinary Integration**: Observational studies often pull data from various sources, not just medical records. By using the 'Phenotypic Feature' domain, there's an easier path for integrating data from fields like sociology, psychology, and economics, which often play a role in SDOH data.

### SDOH Concept Classes
The SDOH-specific Concept Classes enable researchers to discern both the origin and purpose of each term as follows:
| concept_class_id      | meaning |
|--------------------|-------|
| AHRQ Construct     | Construct derived from Agency for Healthcare Research and Quality (AHRQ)    |
| AHRQ Determinant   | Determinant derived from AHRQ    |
| AHRQ Geo Item      | Geography-related semantic item derived from AHRQ    |
| AHRQ Item          | Semantic item derived from AHRQ  |
| SDOH Construct     | Construct created by GIS WG    |
| SDOH Determinant   | Determinant created by GIS WG   |
| SDOH Geo Item      | Geography-related semantic item created by GIS WG    |
| SDOH Item          | Semantic item  created by GIS WG   |
| SDOH Value         | Item value created by GIS WG    |
| SDOHO Construct    | Construct derived from SDOHO   |
| SDOHO Determinant  | Determinant derived from SDOHO    |
| SDOHO Geo Item     | Geography-related semantic item derived from  SDOHO   |
| SDOHO Item         | Semantic item derived from SDOHO   |
| SDOHO Value        | Item value derived from SDOHO    |
| SVI Construct      | Construct derived from Social Vulnerability Index (SVI)    |
| SVI Determinant    | Determinant derived from SVI     |
| SVI Geo Item       | Geography-related semantic item derived from SVI    |
| SVI Item           | Semantic item derived from SVI   |

### Additional Glossary for Concept Classes Understanding:
* **Construct**:
    * A construct is a more abstract idea or concept developed to understand and evaluate determinants. It provides a framework or model to explain complex relationships and behaviors.
    * Constructs are often operationalized into measurable variables in research. For example, while "socioeconomic status" might be a construct, its measurement could include tangible variables like income, education level, or occupation.
    * Constructs help conceptualize and organize determinants for better understanding and analysis.
* **Determinant**: 
    * A determinant refers to a factor or condition that can directly shape or influence health outcomes. It is a broader term that encompasses various factors contributing to an individual's or population's health.
    * Determinants can be positive or negative, and they can include aspects like socioeconomic status, education, physical environment, employment, and social support networks, among others.
    * They are actionable factors, meaning interventions can target determinants to improve health outcomes.
      
In essence, while **determinants** are the *actual factors influencing health*, **constructs** are the *conceptual frameworks* used to understand, measure, and analyze these determinants. When discussing SDOH, it's crucial to recognize the role of both constructs (the theoretical understanding) and determinants (the practical factors) in shaping health outcomes.

* **Item**:
    * Refers to a specific element or factor within a broader determinant category. Think of determinants as overarching categories or themes, and determinant items as the individual aspects or components of those themes.
    * Each determinant item provides a more granulated perspective, allowing for detailed examination and understanding of the broader determinant.
* **Item Value**:
    * For some determinant items, there are specific measurable values or states that the item can take.
    * Using the example of the determinant item "employment status," the item values might include "employed," "unemployed," "self-employed," "retired," etc.

### SDOH Relationships

Within the SDOH Vocabulary, there are precisely 8,194 concept associations, systematically structured. This framework defines an intrinsic hierarchy specific to SDOH, while simultaneously interfacing with external OMOP vocabularies. This dual-layered architectural design enhances the robustness and granularity of the representation of the social determinants of health across ODHSI.

| relationship_id     | reverse relationship_id | meaning |
|---------------------|-------|-------|
| Has component  | Component of | Represents mapping to a SNOMED/LOINC attribute where relevant |
| Is a                | Subsumes | Hierarchical relationship where a concept is a subset or instance of another more general concept. |
| Maps to             | Mapped from | This signifies a relationship where a concept can be equated to or represented as a standard OMOP concept. |

### Primary Components of the SDOH Hierarchical Structure
* Element Relevant To Demographics
* Element Relevant To Education
* Element Relevant To Geographic Location
* Element Relevant To Health
* Element Relevant To Physical Environment
* Element Relevant To Population
* Element Relevant To Social And Community Context

**Target OMOP Vocabularies used in mappings**: SNOMED, ATC, CPT4, HCPCS, LOINC, Nebraska Lexicon, OMOP Extension, PPI, Race, UK Biobank (+OMOP GIS).

### Future work:
* Test the vocabulary with more use cases
* Incorporate SOHO ontology, esp. terms for health equity research (there is a new OHDSI WG for this!)
* Build additional hierarchical relationships.
* Enrich and refine the vocabulary.
