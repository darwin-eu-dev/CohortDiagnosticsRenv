# Run CohortDiagnostics using CDMConnector on a PG db

library(Eunomia)
library(CohortDiagnostics)
library(CohortGenerator)
library(CDMConnector)
library(CirceR)

cdmDatabaseSchema <- Sys.getenv("LOCAL_POSTGRESQL_CDM_SCHEMA")
cohortDatabaseSchema <- Sys.getenv("LOCAL_POSTGRESQL_OHDSI_SCHEMA")
tablePrefix <- "cdd_"
cohortTable <- "mycohort"
conceptCountsTable <- "concept_counts"
outputFolder <- "export_pg"
databaseId <- "Local_PG"
minCellCount <- 5
sqlDBPath <- "DB_pg.sqlite"

if (!dir.exists(outputFolder)) {
  dir.create(outputFolder)
}

# First construct a cohort definition set: an empty
# data frame with the cohorts to generate
cohortDefinitionSet <- CohortGenerator::createEmptyCohortDefinitionSet()
cohortJsonFiles <- list.files(path = system.file("cohorts", package = "CohortDiagnostics"), full.names = TRUE)
for (i in 1:length(cohortJsonFiles)) {
  cohortJsonFileName <- cohortJsonFiles[i]
  cohortName <- tools::file_path_sans_ext(basename(cohortJsonFileName))
  # Here we read in the JSON in order to create the SQL
  cohortJson <- readChar(cohortJsonFileName, file.info(cohortJsonFileName)$size)
  cohortExpression <- CirceR::cohortExpressionFromJson(cohortJson)
  cohortSql <- CirceR::buildCohortQuery(cohortExpression, options = CirceR::createGenerateOptions(generateStats = FALSE))
  cohortDefinitionSet <- rbind(cohortDefinitionSet, data.frame(cohortId = as.numeric(i),
                                                               cohortName = cohortName,
                                                               sql = cohortSql,
                                                               json = cohortJson,
                                                               stringsAsFactors = FALSE))
}

con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "synthea10",
                      host = "localhost",
                      user = Sys.getenv("LOCAL_POSTGRESQL_USER"),
                      password = Sys.getenv("LOCAL_POSTGRESQL_PASSWORD"),
                      bigint = "integer")

cdm <- CDMConnector::cdm_from_con(con,
                                  cdm_schema = cdmDatabaseSchema,
                                  write_schema = c(schema = cohortDatabaseSchema, prefix = tablePrefix),
                                  cdm_name = databaseId)

cdm <- CDMConnector::generateCohortSet(cdm, cohortDefinitionSet, name = cohortTable)

# only CDMConnector functions use prefix directly, for other functions, we need to add it
cohortTable <- paste0(tablePrefix, cohortTable)
conceptCountsTable <- paste0(tablePrefix, conceptCountsTable)

CohortDiagnostics::createConceptCountsTable(connection = attr(cdm, "dbcon"),
                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                            conceptCountsDatabaseSchema = cohortDatabaseSchema,
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
CohortDiagnostics::createMergedResultsFile(dataFolder = outputFolder, sqliteDbPath = sqlDBPath, overwrite = TRUE)
# Launch diagnostics explorer shiny app ----
CohortDiagnostics::launchDiagnosticsExplorer(sqliteDbPath = sqlDBPath)
