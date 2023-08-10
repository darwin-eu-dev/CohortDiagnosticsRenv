# Connection Eunomia
renv::activate()
renv::restore()

connectionDetails <- Eunomia::getEunomiaConnectionDetails()

# connection <- DatabaseConnector::connect(connectionDetails)

# Vars

cdmDatabaseSchema <- "main"
cohortDatabaseSchema <- "main"
cohortTable <- "darwinTestEnv"

# CohortDefinitionSet

cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(settingsFileName = "Cohorts.csv",
                                                               jsonFolder = "cohorts",
                                                               sqlFolder = "sql/sql_server",
                                                               packageName = "CohortDiagnostics")

cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTable)

CohortGenerator::createCohortTables(
  connectionDetails = connectionDetails,
  cohortTableNames = cohortTableNames,
  cohortDatabaseSchema = cohortDatabaseSchema,
  incremental = FALSE
)

# Generate the cohort set

CohortGenerator::generateCohortSet(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTableNames = cohortTableNames,
  cohortDefinitionSet = cohortDefinitionSet,
  incremental = FALSE
)

# Create useExternalConceptCountsTable

exportFolder <- here::here("results")

CohortDiagnostics::createConceptCountsTable(connectionDetails = connectionDetails,
                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                            conceptCountsDatabaseSchema = cohortDatabaseSchema,
                                            conceptCountsTable = "concept_counts",
                                            removeCurrentTable = TRUE)

# executeDiagnostics with useExternalConceptCountsTable

CohortDiagnostics::executeDiagnostics(cohortDefinitionSet =  cohortDefinitionSet,
                                      connectionDetails = connectionDetails,
                                      cohortTable = cohortTable,
                                      cohortDatabaseSchema = cohortDatabaseSchema,
                                      cdmDatabaseSchema = cdmDatabaseSchema,
                                      conceptCountsTable = "concept_counts",
                                      exportFolder = exportFolder,
                                      databaseId = "Eunomia",
                                      minCellCount = 5,
                                      useExternalConceptCountsTable = TRUE)
