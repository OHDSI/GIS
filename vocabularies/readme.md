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
The Observational Medical Outcomes Partnership (OMOP) GIS vocabulary is a compilation of terminologies related to geography, boundaries, and spatial elements. Developed at the intersection of healthcare and geospatial studies, this vocabulary facilitates precise geospatial analyses within observational health research.

The vocabulary encompasses 159 concepts of the Observation OMOP domain. They are categorized by **concept_class_id as**:
* **Geometry Item**: e.g. 'LineString', 'Polygon', '2D (Two-Dimensional) Geometry'
* **Location**: e.g. 'Administrative Boundary', 'County'
* **Geom Relationship**: e.g. 'Within', 'Adjacent to'

The concepts within the vocabulary are interlinked through the following associations: 
- **Hierarchical relationships**: *'Is a'* - *'Subsumes'*: 'Polygon' - 'Is a' - '2D (Two-Dimensional) Geometry' / '2D (Two-Dimensional) Geometry' - 'Subsumes' - 'Polygon'
- **Supplemental GIS-specific relationships**: e.g. *'Is geometry of'* - *'Has geometry'*: 'LineString'	-	 'Is geometry of' -	'International Border' / 'International Border'	-	'Has geometry' - 'LineString'

 ### Future work:
* Build additional hierarchical relationships within the "Location" concept_class_id in OMOP.
* Enhance and refine the vocabulary.
    
## OMOP Toxin Vocabulary
Offers a comprehensive taxonomy and classification system centered on toxins and their respective implications in healthcare and medical research. Designed to facilitate structured data capture, analysis, and interpretation, this vocabulary forms the foundation for toxicological studies within the observational health data paradigm.

## SDOH Vocabulary
The "Social Determinants of Health" (SDOH) vocabulary encapsulates a refined set of terminologies delineating the multifaceted environmental and societal factors that significantly influence individual and community health outcomes. The vocabulary boasts a comprehensive structure, organized hierarchically to facilitate precise categorization and effective data navigation. Within this structure, the SDOH vocabulary seamlessly integrates key components from recognized standards such as the Social Vulnerability Index (SVI), the Agency for Healthcare Research and Quality (AHRQ) frameworks, and the Social Determinants of Health Ontology (SDOHO) nodes. This integration ensures a rich, multi-dimensional perspective, capturing a wide spectrum of determinants from socioeconomic status to healthcare access, and from educational opportunities to neighborhood and built environment. 
