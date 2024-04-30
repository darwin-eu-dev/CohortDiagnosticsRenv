# Run CohortDiagnostics using CDMConnector

library(Eunomia)
library(CohortDiagnostics)
library(CohortGenerator)
library(CDMConnector)

cdmDatabaseSchema <- "main"
cohortDatabaseSchema <- "main"
tablePrefix <- "pre_"
cohortTable <- "mycohort"
conceptCountsTable <- "concept_counts"
outputFolder <- "export"
databaseId <- "Eunomia"
minCellCount <- 5

if (!dir.exists(outputFolder)) {
  dir.create(outputFolder)
}

cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
  settingsFileName = "Cohorts.csv",
  jsonFolder = "cohorts",
  sqlFolder = "sql/sql_server",
  packageName = "CohortDiagnostics"
)

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = CDMConnector::eunomia_dir())

cdm <- CDMConnector::cdmFromCon(con,
                                cdmSchema = cdmDatabaseSchema,
                                writeSchema = c(schema = cohortDatabaseSchema, prefix = tablePrefix),
                                cdmName = databaseId)

cdm <- CDMConnector::generateCohortSet(cdm, cohortDefinitionSet, name = cohortTable)

# only CDMConnector functions use prefix directly, for other functions, we need to add it
cohortTable <- paste0(tablePrefix, "mycohort")
conceptCountsTable <- paste0(tablePrefix, "concept_counts")

CohortDiagnostics::createConceptCountsTable(connection = attr(cdm, "dbcon"),
                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                            conceptCountsDatabaseSchema = cdmDatabaseSchema,
                                            conceptCountsTable = conceptCountsTable)

CohortDiagnostics::executeDiagnosticsCdm(cdm = cdm,
                                         cohortDefinitionSet = cohortDefinitionSet,
                                         cohortTable = cohortTable,
                                         conceptCountsTable = conceptCountsTable,
                                         exportFolder = outputFolder,
                                         minCellCount = minCellCount,
                                         runInclusionStatistics = T,
                                         runIncludedSourceConcepts = T,
                                         runOrphanConcepts = T,
                                         runTimeSeries = T,
                                         runVisitContext = T,
                                         runBreakdownIndexEvents = T,
                                         runIncidenceRate = T,
                                         runCohortRelationship = T,
                                         runTemporalCohortCharacterization = T,
                                         useExternalConceptCountsTable = T)

# package results ----
CohortDiagnostics::createMergedResultsFile(dataFolder = outputFolder,sqliteDbPath = "DB.sqlite", overwrite = TRUE)
# Launch diagnostics explorer shiny app ----
CohortDiagnostics::launchDiagnosticsExplorer(sqliteDbPath = "DB.sqlite")
