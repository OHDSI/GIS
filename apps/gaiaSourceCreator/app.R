library(shiny)
library(shinyBS)
library(shinyalert)
library(shinyvalidate)
library(shinyjs)

# TODO how to make blank fields end up as NULL values in Postgres

inputLabelInfo <- function(linkId, labelText, iconText) {
  tags$span(
    paste0(labelText, " "),
    actionLink(linkId, label =  tags$i(
      class = "glyphicon glyphicon-info-sign",
      style = "color:gray;",
      title = iconText
    )),
   )
}

outputLabelInfo <- function(inp, title, infoText) {
  observeEvent(inp, {
    shinyalert(title, infoText, type = 'info')
  })
}

ui <- fluidPage(
  useShinyjs(),
  titlePanel("Gaia Source Creator"),
  tabsetPanel(
    tabPanel(
      # GEOM UI -------
      "Data Source",
      sidebarLayout(
        # Panel -----
        sidebarPanel(
          style = "height: 90vh; overflow-y: auto;",
          tabPanelBody("dataSourceType",
             radioButtons("downloadMethod", label = inputLabelInfo(
               linkId = "downloadMethodInfo",
               labelText = "Download Method",
               iconText = "Is the dataset obtained via a direct download URL or an API call?"),
               choiceNames = c("Direct Download", "API"),
               choiceValues = c("file", "api")),
             textInput("sourceUrl", label = inputLabelInfo(
               linkId = "sourceUrlInfo",
               labelText = "Enter the source URL for the dataset",
               iconText = "A URL for a direct download of geospatial data (click for more info)"),
               placeholder = "e.g. https://aqs.epa.gov/aqsweb/airdata/daily_aqi_by_county_2020.zip"),
             actionButton("startDownload", "Start Download"),
             textInput("documentationUrl", label = inputLabelInfo(
               linkId = "documentationUrlInfo",
               labelText = "Enter the documentation URL for the dataset",
               iconText = "A URL that links to the documentation webpage for the dataset"),
               placeholder = "e.g. https://www.epa.gov/aqs"),
             checkboxInput("isGeom", label = inputLabelInfo(
               linkId = "isGeomInfo",
               labelText = "This dataset contains geometry information",
               iconText = "Does this dataset contain geometry information? (click for more info)"),
               # value = TRUE # TODO delete me after dev!!! only for dev!!!
               ),
             checkboxInput("hasAttributes", label = inputLabelInfo(
               linkId = "hasAttributesInfo",
               labelText = "This dataset contains attribute information",
               iconText = "Does this dataset contain attribute information? (click for more info)"))),
          tabPanelBody("mainDataSourceFields",
             textInput("orgId", label = inputLabelInfo(
               linkId = "orgIdInfo",
               labelText = "Enter the organization that hosts this dataset",
               iconText = "The name, short name, or acronym of the organization that created the dataset (click for more info) "),
               value = "",
               placeholder = "e.g. EPA"),
             textInput("orgSetId", label = inputLabelInfo(
               linkId = "orgSetIdInfo",
               labelText = "Enter the organization's subset/dataset ID",
               iconText = "The subset of the organization that created this dataset (click for more info)"),
               placeholder = "e.g. AQS"),
             textInput("datasetName", label = inputLabelInfo(
               linkId = "datasetNameInfo",
               labelText = "Enter a dataset name",
               iconText = "The name of the dataset (click for more info)"),
               placeholder = "e.g. daily_aqi_by_county_2020"),
             textInput("datasetVersion", label = inputLabelInfo(
               linkId = "datasetVersionInfo",
               labelText = "Enter a dataset version",
               iconText = "The version or year of the dataset (click for more info)"),
               placeholder = "e.g. 2020"),
             textInput("downloadSubtype", label = inputLabelInfo( # This could be dropdown of supported types
               linkId = "downloadSubtypeInfo",
               labelText = "Enter a download subtype",
               iconText = "The download subtype that the URL links to, such as zip or gzip (click for more info)"),
               placeholder = "e.g. zip"),
             textInput("downloadDataStandard", label = inputLabelInfo( # This could be dropdown of supported types
               linkId = "downloadDataStandardInfo",
               labelText = "Enter a download data standard",
               iconText = "The standard that the downloaded data is in, such as CSV or SHP (click for more info)"),
               placeholder = "e.g. csv"),
             textInput("boundaryType", label = inputLabelInfo(
               linkId = "boundaryTypeInfo",
               labelText = "Enter a boundary type",
               iconText = "Boundary type is the space that the geometry or attribute pertains to, such as county or ZCTA (click for more info)"),
               placeholder = "e.g. county"),
           conditionalPanel(
             condition = "input.downloadMethod != 'file'",
             textInput("downloadAuth", label = inputLabelInfo(
               linkId = "downloadAuthInfo",
               labelText = "Enter authentication details for this dataset",
               iconText = "Authentication details for dataset's that require authentication for download (click for more info)"))),
           conditionalPanel(
             condition = "input.downloadMethod == 'file'",
             textInput("downloadFilename", label = inputLabelInfo(
               linkId = "downloadFilenameInfo",
               labelText = "Enter the name of the dataset file",
               iconText = "The name of the file downloaded from the source URL"),
               placeholder = "e.g. daily_aqi_by_county_2020.csv")),
          conditionalPanel(
            condition = "input.isGeom == true",
            radioButtons("geomType", label = inputLabelInfo(
              linkId = "geomTypeInfo",
              labelText = "What type of geometry?",
              iconText = "The geometry type of the dataset (click for more info)"),
              choices = c("point", "line", "polygon")),
            # TODO link to detailed page describing geom_spec
            textAreaInput("geomSpec", label = inputLabelInfo( # TODO geom_spec creator should be it's own tab
              linkId = "geomSpecInfo",
              labelText = "Create a geom_spec",
              iconText = "A geom_spec is used to parse the dataset into a geom_X table (click for more info)"),
              height = '18em',
              placeholder = "Manually create a JSON geom_spec: e.g. \n\n{\n\t\"stage_transform\":\n\t\t[\n\t\t\t\"dplyr::filter(staged, ...)\",\n\t\t\t\"dplyr::mutate(staged, ...)\",\n\t\t\t\"...\"\n\t\t]\n}\n\nor use the specWriter tool"),
            checkboxInput("showSpecWriter", label = inputLabelInfo(
              linkId = "showSpecWriterInfo",
              labelText = "Show the specWriter tool",
              iconText = "The specWriter tool provides an interface for creating a JSON-formatted geom_spec"),
              value = TRUE # TODO delete me after dev!!! Only for dev!!
              )),
            conditionalPanel(
              condition = "input.hasAttributes == true",
              textInput("geomDependency", label = inputLabelInfo( # TODO this option should pick from a list that comes from existing geometry data source UUID
                linkId = "geomDependencyInfo",
                labelText = "Enter a geometry dependency UUID",
                iconText = "Attributes must be associated with a geometry. What is the associated geometries UUID? (click for more info)"),
                placeholder = "e.g. 1234")
            )
          )
        ),
        # Main -------
        mainPanel(
          style = "height: 90vh; overflow-y: auto;",
          tableOutput("dataSourceGeom"),
          # actionButton("addDataSourceGeom", "Create"),
          actionButton("createInsertSqlGeom", "Create INSERT SQL")
          # TODO add a box with summary info for data source that populates after download
        )
      ),
      # SpecWriter --------
      fluidRow(
        column(12,
               conditionalPanel(
                 condition = "input.showSpecWriter == true && input.isGeom == true",
                 titlePanel("Gaia specWriter"),
                 sidebarLayout(
                   sidebarPanel(
                     fluidRow(
                       htmltools::h4("Add Transformations"),
                       htmltools::span(
                         div(style="display:inline-block",textInput("mutateStatement", "Mutate:")),
                         div(style="display:inline-block",actionButton("addMutate", "", icon = icon("plus")),width=6)),
                       div(id="mutates"),
                       htmltools::br(),
                       htmltools::span(
                         div(style="display:inline-block",textInput("filterStatement", "Filter:")),
                         div(style="display:inline-block",actionButton("addFilter", "", icon = icon("plus")),width=6)),
                       div(id="filters"),
                       htmltools::br(),
                       htmltools::span(
                         div(style="display:inline-block",textInput("selectStatement", "Select:")),
                         div(style="display:inline-block",actionButton("addSelect", "", icon = icon("plus")),width=6)),
                       div(id="selects")
                     ),
                     fluidRow(
                       htmltools::h4("geom_spec Output"),
                       htmlOutput("specWriterOutput")
                       # textAreaInput("specWriterOutput", "",
                       #               value = '{"stage_transform": []}')
                     )
                   ),
                   mainPanel(
                     htmltools::h4("Transformed Table Output"),
                     style = "height: 90vh; overflow-y: auto;",
                     tableOutput("transformedSourceTable")
                   )
                 )
               ))
      )
      
      ),
    tabPanel("Variable Source", 
  #( . . . . . . . . . . ) --------    
  # VARIABLE UI -------
      sidebarLayout(
        sidebarPanel(
          # Panel --------
          style = "height: 70vh; overflow-y: auto;",
          tabPanelBody("mainVariableSourceFields",
            textInput("variableName", label = inputLabelInfo(
              linkId = "variableNameInfo",
              labelText = "Enter a variable name",
              iconText = "The name of the variable (click for more info)"),
              placeholder = "e.g. PM2.5"),
            textInput("variableDescription", label = inputLabelInfo(
              linkId = "variableDescriptionInfo",
              labelText = "Enter a variable description",
              iconText = "A written description of the variable (click for more info)"),
              placeholder = "e.g. The Air Quality Index for the day for PM2.5"),
            textInput("dataSourceUuid", label = inputLabelInfo( # This could be dropdown of supported types
              linkId = "dataSourceUuidInfo",
              labelText = "Enter the UUID of this variable's Data Source",
              iconText = "The unique identifier of the data source record with which this variable is associated (click for more info)"),
              placeholder = "e.g. 7870"),
            textAreaInput("attrSpec", label = inputLabelInfo( # TODO geom_spec creator should be it's own tab
              linkId = "attrSpecInfo",
              labelText = "Create an attr_spec",
              iconText = "An attr_spec is used to parse the dataset into an attr_X table (click for more info)"),
              height = '18em',
              placeholder = "Manually create a JSON attr_spec: e.g. \n\n{\n\t\"stage_transform\":\n\t\t[\n\t\t\t\"dplyr::filter(staged, ...)\",\n\t\t\t\"dplyr::mutate(staged, ...)\",\n\t\t\t\"...\"\n\t\t]\n}\n\nor use the specWriter tool")
          )
        ),
        mainPanel(
          # Main -------
          style = "height: 70vh; overflow-y: auto;",
          tableOutput("dataSourceVar"),
          # actionButton("addDataSourceVar", "Create"),
          actionButton("createInsertSqlVar", "Create INSERT SQL")
          # TODO add a box with summary info for data source that populates after download
        ),
     ),
   # SpecWriter -----------
     fluidRow(
       column(12,
        titlePanel("Gaia specWriter"),
        sidebarLayout(
          sidebarPanel(
            fluidRow(
              htmltools::h4("Add Transformations"),
              htmltools::span(
                div(style="display:inline-block",textInput("mutateStatementAttr", "Mutate:")),
                div(style="display:inline-block",actionButton("addMutateAttr", "", icon = icon("plus")),width=6)),
              div(id="mutatesAttr"),
              htmltools::br(),
              htmltools::span(
                div(style="display:inline-block",textInput("filterStatementAttr", "Filter:")),
                div(style="display:inline-block",actionButton("addFilterAttr", "", icon = icon("plus")),width=6)),
              div(id="filtersAttr"),
              htmltools::br(),
              htmltools::span(
                div(style="display:inline-block",textInput("selectStatementAttr", "Select:")),
                div(style="display:inline-block",actionButton("addSelectAttr", "", icon = icon("plus")),width=6)),
              div(id="selectsAttr")
            ),
            fluidRow(
              htmltools::h4("attr_spec Output"),
              htmlOutput("specWriterOutputAttr")
            )
          ),
          mainPanel(
            htmltools::h4("Transformed Table Output"),
            style = "height: 90vh; overflow-y: auto;",
            tableOutput("transformedSourceTableAttr")
          )
        )
      )
     )
    )
  )
)

#( . . . . . . . . . . ) --------






server <- function(input, output, session) {


  # GEOM ----------
  
  # Main Panel tables -------------------------------------------------------
  
  dataSourceTableGeom <- reactive(dplyr::tibble("org_id" = input$orgId,
                                                "org_set_id" = input$orgSetId,
                                                "dataset_name" = input$datasetName,
                                                "dataset_version" = input$datasetVersion,
                                                "geom_type" = input$geomType,
                                                "geom_spec" = input$geomSpec,
                                                "boundary_type" = input$boundaryType,
                                                "has_attributes" = as.integer(input$hasAttributes),
                                                "geom_dependency_uuid" = as.integer(input$geomDependency),
                                                "download_method" = input$downloadMethod,
                                                "download_subtype" = input$downloadSubtype,
                                                "download_data_standard" = input$downloadDataStandard,
                                                "download_filename" = input$downloadFilename,
                                                "download_url" = input$sourceUrl,
                                                "download_auth" = input$downloadAuth,
                                                "documentation_url" = input$documentationUrl))
  
  
  observeEvent(input$sourceUrl, {
    updateTextInput(inputId = "downloadSubtype",
                    value = stringr::str_extract(input$sourceUrl, "(?<=\\.)\\w+$"))
  })
  
  observeEvent(input$isGeom, {
    updateRadioButtons(inputId = "geomType", selected = character(0))
    updateTextInput(inputId = "geomSpec", value = NA_character_)
  })
  
  output$dataSourceGeom <- renderTable(dataSourceTableGeom())
  
  output$transformedSourceTableGeom <- renderTable(transformedSourceTableGeom())
  
  
  # Info popups -------------------------------------------------------------
  observeEvent(input$sourceUrlInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$isGeomInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$hasAttributesInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$orgIdInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$orgSetIdInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$datasetNameInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$datasetVersionInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$downloadSubtypeInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$downloadDataStandardInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$boundaryTypeInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$geomTypeInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$geomSpecInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$geomDependencyInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})


  
  
  # specWriter --------------------------------------------------------------
  
  specReactive <- reactiveValues()
  
  observeEvent(input$addMutate, {
    specReactive$mutateList <- c(isolate(specReactive$mutateList), isolate(input$mutateStatement))
    updateTextInput(inputId = "mutateStatement", value = "")
    nr <- input$mutateStatement
    insertUI(
      selector = "#mutates",
      ui = div(
        id = paste0("newInput", nr),
        htmltools::span(nr),
        actionButton(paste0("removeBtn", nr), label = "", icon = icon("minus")),
        htmltools::br()
      )
    )
    observeEvent(input[[paste0("removeBtn", nr)]], {
      shiny::removeUI(selector = paste0("#newInput", nr))
      specReactive$mutateList <- specReactive$mutateList[specReactive$mutateList != nr]
    })
  })
  
  observeEvent(input$addFilter, {
    specReactive$filterList <- c(isolate(specReactive$filterList), isolate(input$filterStatement))
    updateTextInput(inputId = "filterStatement", value = "")
    nr <- input$filterStatement
    insertUI(
      selector = "#filters",
      ui = div(
        id = paste0("newInput", nr),
        htmltools::span(nr),
        actionButton(paste0("removeBtn", nr), label = "", icon = icon("minus")),
        htmltools::br()
      )
    )
    observeEvent(input[[paste0("removeBtn", nr)]], {
      shiny::removeUI(selector = paste0("#newInput", nr))
      specReactive$filterList <- specReactive$filterList[specReactive$filterList != nr]
    })
  })
  
  observeEvent(input$addSelect, {
    specReactive$selectList <- c(isolate(specReactive$selectList), isolate(input$selectStatement))
    updateTextInput(inputId = "selectStatement", value = "")
    nr <- input$selectStatement
    insertUI(
      selector = "#selects",
      ui = div(
        id = paste0("newInput", nr),
        htmltools::span(nr),
        actionButton(paste0("removeBtn", nr), label = "", icon = icon("minus")),
        htmltools::br()
      )
    )
    observeEvent(input[[paste0("removeBtn", nr)]], {
      shiny::removeUI(selector = paste0("#newInput", nr))
      specReactive$selectList <- specReactive$selectList[specReactive$selectList != nr]
    })
  })
  
  output$specWriterOutput <- renderText({
    paste0(
      '<pre>{\n\t"stage_transform": [\n',
      ifelse(length(specReactive$mutateList) > 0, paste0('\t\t"dplyr::mutate(staged,\n\t\t\t\t', paste(specReactive$mutateList, collapse = ",\n\t\t\t\t"), ')",\n'), paste0("")),
      ifelse(length(specReactive$filterList) > 0, paste0('\t\t"dplyr::filter(staged,\n\t\t\t\t', paste(specReactive$filterList, collapse = ",\n\t\t\t\t"), ')",\n'), paste0("")),
      ifelse(length(specReactive$selectList) > 0, paste0('\t\t"dplyr::select(staged,\n\t\t\t\t', paste(specReactive$selectList, collapse = ",\n\t\t\t\t"), ')"\n'), paste0("")),
      '\t]\n}</pre>'
    )
  })
  
  
# Validate ----------------------------------------------------------------

  main_iv <- InputValidator$new()
  url_iv <- InputValidator$new()
  geom_validator <- InputValidator$new()
  # main_iv$add_validator(url_iv)
  main_iv$add_validator(geom_validator)

  url_iv$add_rule("sourceUrl", sv_required())
  url_iv$add_rule("sourceUrl", sv_url("Not a valid URL"))
  url_iv$add_rule("documentationUrl", sv_optional())
  url_iv$add_rule("documentationUrl", sv_url("Not a valid URL"))

  geom_validator$condition(~ isTRUE(input$isGeom))
  geom_validator$add_rule("geomType", sv_required())
  geom_validator$add_rule("geomSpec", sv_required())



  # TODO this assumes downloadMethod == file and downloadSubtype == zip

# Download Dataset Action -------------------------------------------------

  observeEvent(input$startDownload, {
    url_iv$enable()
    if (!url_iv$is_valid()) {
      showNotification("Valid URL required to download dataset", type = "error", duration = 3)
    } else {
      url <- input$sourceUrl
      gisTempdir <- paste0(tempdir(), "\\", "gaia\\")
      if(!dir.exists(gisTempdir)) {
        dir.create(gisTempdir)
      }
      tempzip <- paste0(gisTempdir, stringr::str_replace_all(basename(url), "[^[:alnum:]]", ""))
      if (!endsWith(tempzip, '.zip')) {
        tempzip <- paste0(tempzip, ".zip")
      }
      tryCatch({
        if (!file.exists(tempzip)) {
          utils::download.file(url, tempzip)
        } else {
          message("Skipping download (zip file located on disk) ...")
        }
        filename <- utils::unzip(tempzip, exdir = gisTempdir)
      }, 
      warning = function(w) {
        if (stringr::str_detect(as.character(w), 'corrupt')) {
          res <- httr::GET(url)
          writeBin(httr::content(res), con = tempzip)
          filename <<- utils::unzip(tempzip, exdir = gisTempdir)
        }
      })
      # if (length(filename) > 1) {
      #   # popup window that asks to select a source
      #   # THIS MAY BE UNNECESSARY
      # } 
      if(any(stringr::str_detect(filename, ".shp$"))) {
        filename <- filename[stringr::str_detect(filename, ".shp$")]
        updateCheckboxInput(inputId = "isGeom", value = TRUE)
      }
      downloadDataStandard <- stringr::str_extract(filename, "(?<=\\.)\\w+$")
      downloadFilename <- basename(filename)
      updateTextInput(inputId = "downloadFilename", value = downloadFilename)
      updateTextInput(inputId = "datasetName", value = tools::file_path_sans_ext(basename(filename)))
      updateTextInput(inputId = "datasetVersion", value = stringr::str_extract(tools::file_path_sans_ext(basename(filename)), "\\d{4}"))
      updateTextInput(inputId = "downloadDataStandard", value = downloadDataStandard)
    }
  })

  transformedSourceTable <- eventReactive(input$startDownload, {
    gisTempdir <- paste0(tempdir(), "\\", "gaia\\")
    if (input$downloadDataStandard == "shp") {
      message("Done it")
      return(head(as.data.frame(sf::st_read(file.path(gisTempdir, input$downloadFilename)) %>%
                      sf::st_drop_geometry())))
    } else {
      return(head(utils::read.csv(file = file.path(gisTempdir, input$downloadFilename),
                                                         check.names = FALSE)))
    }

  })

# Create data source ----
  observeEvent(input$addDataSourceGeom, {
    main_iv$enable()
    if (main_iv$is_valid()) {
      # TODO some transform function to format correctly for insert
      addDataSource(connectionDetails, dataSourceTable())
      showNotification("Data Source Added", duration = 3)
    } else {
      showNotification("Make sure all fields are correctly filled out", type = "error", duration = 3)
    }
  })
  
  # Create data source insert ----
  observeEvent(input$createInsertSqlGeom, {
    sql_insert_text <- paste0(
      "INSERT INTO backbone.data_source VALUES (<INSERT-ID> '",
      input$orgId, "', '", input$orgSetId, "', '", input$datasetName, "', ",
      input$datasetVersion, ", '", input$geomType, "', '", input$geomSpec, "', '", input$boundaryType, "', ",
      as.numeric(input$hasAttributes), ", ", input$geomDependency, ", '", input$downloadMethod, "', '",
      input$downloadSubtype, "', '", input$downloadDataStandard, "', '", input$downloadFilename, "', '",
      input$sourceUrl, "', '", input$downloadAuth, "', '", input$documentationUrl, "')"
    )

    sql_insert_text <- stringr::str_replace_all(sql_insert_text, "''", "NULL")
    # TODO Display as pop-up window with editable text window and a copy button
    print(sql_insert_text)
  })




  #( . . . . . . . . . . ) --------
  # VARIABLE ----------
  # Main Panel tables -------------------------------------------------------
  
  dataSourceTableVar <- reactive(dplyr::tibble("variable_name" = input$variableName,
                                                "variable_description" = input$variableDescription,
                                                "data_source_uuid" = input$dataSourceUuid,
                                                "attr_spec" = input$attrSpec))
  
  output$dataSourceVar <- renderTable(dataSourceTableVar())
  
  output$transformedSourceTableVar <- renderTable(transformedSourceTableVar())
  
  
  # Info popups -------------------------------------------------------------
  observeEvent(input$variableNameInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$variableDescriptionInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$dataSourceUuidInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  observeEvent(input$attrSpecInfo, {shinyalert("This feature not yet ready", "Once this feature is ready, each info icon will connect to an individualized popup with guiding information about the input required. Neat!", type = 'info')})
  
  # specWriter --------------------------------------------------------------
  
  specReactiveAttr <- reactiveValues()
  
  observeEvent(input$addMutateAttr, {
    specReactiveAttr$mutateListAttr <- c(isolate(specReactiveAttr$mutateListAttr), isolate(input$mutateStatementAttr))
    updateTextInput(inputId = "mutateStatementAttr", value = "")
    nr <- input$mutateStatementAttr
    insertUI(
      selector = "#mutatesAttr",
      ui = div(
        id = paste0("newInput", nr),
        htmltools::span(nr),
        actionButton(paste0("removeBtn", nr), label = "", icon = icon("minus")),
        htmltools::br()
      )
    )
    observeEvent(input[[paste0("removeBtn", nr)]], {
      shiny::removeUI(selector = paste0("#newInput", nr))
      specReactiveAttr$mutateListAttr <- specReactiveAttr$mutateListAttr[specReactiveAttr$mutateListAttr != nr]
    })
  })
  
  observeEvent(input$addFilterAttr, {
    specReactiveAttr$filterListAttr <- c(isolate(specReactiveAttr$filterListAttr), isolate(input$filterStatementAttr))
    updateTextInput(inputId = "filterStatementAttr", value = "")
    nr <- input$filterStatementAttr
    insertUI(
      selector = "#filtersAttr",
      ui = div(
        id = paste0("newInput", nr),
        htmltools::span(nr),
        actionButton(paste0("removeBtn", nr), label = "", icon = icon("minus")),
        htmltools::br()
      )
    )
    observeEvent(input[[paste0("removeBtn", nr)]], {
      shiny::removeUI(selector = paste0("#newInput", nr))
      specReactiveAttr$filterListAttr <- specReactiveAttr$filterListAttr[specReactiveAttr$filterListAttr != nr]
    })
  })
  
  observeEvent(input$addSelectAttr, {
    specReactiveAttr$selectListAttr <- c(isolate(specReactiveAttr$selectListAttr), isolate(input$selectStatementAttr))
    updateTextInput(inputId = "selectStatementAttr", value = "")
    nr <- input$selectStatementAttr
    insertUI(
      selector = "#selectsAttr",
      ui = div(
        id = paste0("newInput", nr),
        htmltools::span(nr),
        actionButton(paste0("removeBtn", nr), label = "", icon = icon("minus")),
        htmltools::br()
      )
    )
    observeEvent(input[[paste0("removeBtn", nr)]], {
      shiny::removeUI(selector = paste0("#newInput", nr))
      specReactiveAttr$selectListAttr <- specReactiveAttr$selectListAttr[specReactiveAttr$selectListAttr != nr]
    })
  })
  
  output$specWriterOutputAttr <- renderText({
    paste0(
      '<pre>{\n\t"stage_transform": [\n',
      ifelse(length(specReactiveAttr$mutateListAttr) > 0, paste0('\t\t"dplyr::mutate(staged,\n\t\t\t\t', paste(specReactiveAttr$mutateListAttr, collapse = ",\n\t\t\t\t"), ')",\n'), paste0("")),
      ifelse(length(specReactiveAttr$filterListAttr) > 0, paste0('\t\t"dplyr::filter(staged,\n\t\t\t\t', paste(specReactiveAttr$filterListAttr, collapse = ",\n\t\t\t\t"), ')",\n'), paste0("")),
      ifelse(length(specReactiveAttr$selectListAttr) > 0, paste0('\t\t"dplyr::select(staged,\n\t\t\t\t', paste(specReactiveAttr$selectListAttr, collapse = ",\n\t\t\t\t"), ')"\n'), paste0("")),
      '\t]\n}</pre>'
    )
  })
  
  
  
  
  # Create data source insert ----
  observeEvent(input$createInsertSqlVar, {
    sql_insert_text <- paste0(
      "INSERT INTO backbone.variable_source VALUES (<INSERT-ID> '",
      input$variableName, "', '", input$variableDescription, "', ",
      input$dataSourceUuid, ", '", input$attrSpec, "')"
    )

    sql_insert_text <- stringr::str_replace_all(sql_insert_text, "''", "NULL")
    # TODO Display as pop-up window with editable text window and a copy button
    print(sql_insert_text)
  })
}

shinyApp(ui, server)

