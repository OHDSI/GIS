library(shiny)
library(shinydashboard)
library(reactable)
library(shinyjs)
library(waiter)
library(config)
library(DT)

# setwd("C:/Users/kzollovenecek/Documents/gaiaShiny/")
#
# initiateSummaryTable <- function(connectionDetails) {
#   rawSummaryTable <- getVariableSourceSummaryTable(connectionDetails)
#   rawSummaryTable <- rawSummaryTable %>%
#     dplyr::mutate(
#       SOURCE_DATASET = paste0(
#         substr(DATASET_NAME, 1, nchar(DATASET_NAME)-5),
#         " (", ORG_ID,"; ", ORG_SET_ID, ")"),
#       year = substr(DATASET_NAME, nchar(DATASET_NAME)-3, nchar(DATASET_NAME))
#     )
# }
# rawSummaryTable <- initiateSummaryTable(connectionDetails)
# datasetFormattedNames <- unique(rawSummaryTable$SOURCE_DATASET)
# datasetNames <- setNames(stringr::str_extract_all(datasetFormattedNames, ".+(?= \\()"), datasetFormattedNames)

# TODO uncomment the line below to enable reading of config file (this was a good thing!)
# You may need to specify where this file is in the get function
# It may be in your Documents folder
dbConnectionDetails <- NULL#suppressWarnings(get("connectionDetails")) 

databaseConnectionForm <- function(dbName, dbStem) {
  column(6,
    h3(paste0("Connect to ", dbName)),
    textInput(paste0("dbms", dbStem), "DBMS", value = dbConnectionDetails[[dbStem]]$dbms, placeholder = "e.g. postgresql"),
    textInput(paste0("user", dbStem), "Username", value = dbConnectionDetails[[dbStem]]$user, placeholder = "e.g. postgres"),
    passwordInput(paste0("password", dbStem), "Password", value = dbConnectionDetails[[dbStem]]$password),
    textInput(paste0("server", dbStem), "Server", value = dbConnectionDetails[[dbStem]]$server, placeholder = "e.g. localhost"),
    textInput(paste0("port", dbStem), "Port", value = dbConnectionDetails[[dbStem]]$port, placeholder = "e.g. 5432"),
    textInput(paste0("path", dbStem), "Path to Driver", value = dbConnectionDetails[[dbStem]]$pathToDriver, placeholder = "e.g. C:\\R\\"),
    actionButton(paste0("connect", dbStem), paste0("Connect to ", dbName), icon = icon("database"))
  )
}

ui <- dashboardPage(
  dashboardHeader(title = "OHDSI GAIA"),
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Database Connections", tabName = "dbs", icon = icon("database")),
      menuItem("Variables", tabName = "variables", icon = icon("dashboard")),
      menuItem("Layer Builder", tabName = "layers", icon = icon("table")),
      menuItem("Map", tabName = "map", icon = icon("map"))
    )
  ),
  dashboardBody(
    useShinyjs(),
    waiter::use_waiter(),
    tabItems(
      tabItem(tabName = "dbs",
              h2("Create Database Connections"),
                  # TODO a little success/alert looking thing that says connectionDetails found in config file -- if no config, mention that it is an option
                  # TODO what does the connect button do? Maybe test connection (for OMOP)? or test connection and do first retrieval of database (for gaiaDB)?
              # TODO validation for inputs (on button click) --- do required exist? shinyvalidate
              fluidRow(
                column(12,
                  if(!is.null(dbConnectionDetails)) {
                    h5("Connection details sourced from configuration file")
                  } else {
                    h5("Manually enter connection details or create configuration file in working directory")
                  }
                )
              ),
              fluidRow(
                databaseConnectionForm("gaiaDB", "gaia"),
                databaseConnectionForm("OMOP database", "omop")
              )
      ),
      tabItem(tabName = "variables",
              h2("Variable Summary Table"),
              fluidRow(
                column(10, reactableOutput("summaryTable"),
                       uiOutput("connectAlert")),
                column(2, title = "Filter",
                       uiOutput("yearFilter"),
                       uiOutput("datasetFilter")
                )
              )
      ),
      tabItem(tabName = "layers",
              h2("Layer Builder"),
              # fluidRow(column(10, reactableOutput("layerBuilderTable")),
              #          column(2, title = "Filter",
              #                 # TODO eventually change value to min and max source dataset year
              #                 sliderInput("yearFilterLB", "Date Range (Year)", value = c(2011, 2020),
              #                             min = 2009, max = as.integer(format(Sys.Date(), "%Y")),
              #                             step = 1, sep = "", ticks = FALSE),
              #                 checkboxGroupInput("datasetFilterLB", "Datasets",
              #                                    choices = datasetNames),
              #                 textOutput("yearsLB")))
      ),
      tabItem(tabName = "map",
              h2("Map")
      )
    )
  )
)

server <- function(input, output, session) {


# Database Connections ----------------------------------------------------

  observeEvent(input$connectgaia, {

    waiter <- waiter::Waiter$new(id = "connectgaia", html = spin_wave())
    waiter$show()
    on.exit(waiter$hide())

    gaiaConnectionDetails <<- DatabaseConnector::createConnectionDetails(
      dbms = input$dbmsgaia,
      pathToDriver = input$pathgaia,
      server = input$servergaia,
      port = input$portgaia,
      user = input$usergaia,
      password = input$passwordgaia
    )

    rawSummaryTable <- getVariableSourceSummaryTable(gaiaConnectionDetails)
    rawSummaryTable <- rawSummaryTable %>%
      dplyr::mutate(
        SOURCE_DATASET = paste0(
          substr(DATASET_NAME, 1, nchar(DATASET_NAME)-5),
          " (", ORG_ID,"; ", ORG_SET_ID, ")"),
        year = substr(DATASET_NAME, nchar(DATASET_NAME)-3, nchar(DATASET_NAME))
      )

    reactiveSummaryTable$t <- rawSummaryTable

    updateTabItems(session, "tabs", "variables")

  })

  reactiveSummaryTable <- reactiveValues(t = dplyr::tibble(
    "VARIABLE_NAME" = character(),
    "VARIABLE_DESC" = character(),
    "DATASET_NAME" = character(),
    "year" = character(),
    "isLoaded" = character()
    ))

  # Button on variables page that sends unconnected user to database connection
  output$connectAlert <- renderUI({
    if (nrow(reactiveSummaryTable$t) == 0) {
      actionButton("goToConnect", "Connect to gaiaDB", icon = icon("go"))
    }
  })

  observeEvent(input$goToConnect, {
    updateTabItems(session, "tabs", "dbs")
  })


  output$yearFilter <- renderUI({
    if (nrow(reactiveSummaryTable$t) > 0) {
      r <- isolate(range(as.numeric(reactiveSummaryTable$t$year)))
      sliderInput("renderedSlide", "Date Range (Year)", value = r,
                  min = r[1] - 1, max = r[2] + 1,
                  step = 1, sep = "", ticks = FALSE)
    }
  })

  output$datasetFilter <- renderUI({
    if (nrow(reactiveSummaryTable$t) > 0) {
      datasetNames <- isolate(setNames(stringr::str_extract_all(unique(reactiveSummaryTable$t$SOURCE_DATASET),".+(?= \\()"),
                               unique(reactiveSummaryTable$t$SOURCE_DATASET)))
      checkboxGroupInput("renderedCheckbox", "Datasets",
                          choices = datasetNames)
    }
  })

  # Layer builder and summary table mirror each other
  # observeEvent(input$yearFilter, {updateSliderInput(inputId = "yearFilterLB", value = input$yearFilter)})
  # observeEvent(input$yearFilterLB, {updateSliderInput(inputId = "yearFilter", value = input$yearFilterLB)})
  # observeEvent(input$datasetFilter, {updateCheckboxInput(inputId = "datasetFilterLB", value = input$datasetFilter)}, ignoreNULL = FALSE, ignoreInit = FALSE)
  # observeEvent(input$datasetFilterLB, {updateCheckboxInput(inputId = "datasetFilter", value = input$datasetFilterLB)}, ignoreNULL = FALSE, ignoreInit = FALSE)
x <-  reactive({
  if(nrow(reactiveSummaryTable$t) == 0) {
    reactable(reactiveSummaryTable$t)
  } else {
    reactable(isolate(reactiveSummaryTable$t) %>%
                  dplyr::filter( # TODO add "Loaded?" as a filter (Checkbox next to "Hide Loaded Datasets")
                    stringr::str_detect(
                      SOURCE_DATASET,
                      paste(input$renderedCheckbox, collapse="|")),
                    year >= input$renderedSlide[1],
                    year <= input$renderedSlide[2]
                  ), searchable = TRUE, defaultColDef = colDef(show = FALSE),
                columns = list(
                  VARIABLE_NAME = colDef(name = "Name", show = TRUE),
                  VARIABLE_DESC = colDef(name = "Description", show = TRUE),
                  DATASET_NAME = colDef(name = "Source Dataset", show = TRUE,
                                        cell = function(value, index) {
                                          htmltools::div(
                                            htmltools::div(htmltools::tags$a(href = dplyr::pull(reactiveSummaryTable$t, DOCUMENTATION_URL)[index], target="_blank", value)),
                                            htmltools::div(style = "font-size: 0.85rem", paste(dplyr::pull(reactiveSummaryTable$t, ORG_ID)[index], dplyr::pull(reactiveSummaryTable$t, ORG_SET_ID)[index]))
                                          )
                                        }),
                  year = colDef(name = "Year", show = TRUE),
                  isLoaded = colDef(name = "Loaded to gaiaDB", show = TRUE,
                                    cell = JS(sprintf('
                                                      function(cellInfo) {
                                                        if (cellInfo.value == false) {
                                                          let varSourceId = cellInfo.row["VARIABLE_SOURCE_ID"]
                                                          return `<div><button type="button" class="action-button" id=${"loadVarButton" + varSourceId} onclick="Shiny.setInputValue(\'loadVariableButtonClick\', ${varSourceId})">Load Variable</button></div>`
                                                        } else {
                                                          return `<span>Loaded</span>`
                                                        }
                                                      }'
                                    )),
                                    html = TRUE)))}
    })

  output$summaryTable <- renderReactable({
   x()
  })





# Layer Builder -----------------------------------------------------------


  output$layerBuilderTable <- renderReactable({
    reactable(data = dplyr::filter(reactiveSummaryTable$t, isLoaded == "TRUE"),
              searchable = TRUE,
              onClick = "expand",
              defaultColDef = colDef(show = FALSE),
              columns = list(
                VARIABLE_NAME = colDef(name = "Name",
                                       show = TRUE),
                VARIABLE_DESC = colDef(name = "Description", show = TRUE),
                DATASET_NAME = colDef(name = "Source Dataset", show = TRUE,

                                        cell = function(value, index) {
                                          htmltools::div(
                                            htmltools::div(htmltools::tags$a(href = dplyr::pull(reactiveSummaryTable$t, DOCUMENTATION_URL)[index], target="_blank", value)),
                                            htmltools::div(style = "font-size: 0.85rem", paste(dplyr::pull(reactiveSummaryTable$t, ORG_ID)[index], dplyr::pull(reactiveSummaryTable$t, ORG_SET_ID)[index]))
                                          )}
                                        ),
                year = colDef(name = "Year", show = TRUE)),
              details = colDef(
                show = TRUE,
                details = JS("function(rowInfo) {
    return `<div style='border:1px solid black; margin:10px; padding:10px;'><h4>Details for Variable: <b>${rowInfo.values['VARIABLE_NAME']}</b></h4>` +
      `<p>Associated Geometry: <b>${rowInfo.values['GEOM_DEPENDENCY_NAME']} (${rowInfo.values['GEOM_TYPE']})</b></p>` +
      `<p>Boundary Type: <b>${rowInfo.values['BOUNDARY_TYPE']}</b></p><div>`
  }"),
                html = TRUE,
                width = 60
              )
              )
  })

  observeEvent(input$loadVariableButtonClick, {
    buttonId <- paste0("loadVarButton", input$loadVariableButtonClick)
    waiter <- waiter::Waiter$new(id = buttonId, html = spin_wave())
    waiter$show()
    on.exit(waiter$hide())
    loadVariable(gaiaConnectionDetails, variableSourceId = input$loadVariableButtonClick)
    rawSummaryTable <- getVariableSourceSummaryTable(gaiaConnectionDetails)
    rawSummaryTable <- rawSummaryTable %>%
      dplyr::mutate(
        SOURCE_DATASET = paste0(
          substr(DATASET_NAME, 1, nchar(DATASET_NAME)-5),
          " (", ORG_ID,"; ", ORG_SET_ID, ")"),
        year = substr(DATASET_NAME, nchar(DATASET_NAME)-3, nchar(DATASET_NAME))
      )

    reactiveSummaryTable$t <- rawSummaryTable
    # rawSummaryTable <- initiateSummaryTable(connectionDetails)
    # reactiveSummaryTable <- reactive(rawSummaryTable %>%
    #                                    dplyr::filter(
    #                                      stringr::str_detect(
    #                                        SOURCE_DATASET,
    #                                        paste(input$datasetFilter, collapse="|")),
    #                                      year >= input$yearFilter[1],
    #                                      year <= input$ yearFilter[2]
    #                                    ))
    # updateReactable("summaryTable", data = reactiveSummaryTable())
    })

}

shinyApp(ui, server)

