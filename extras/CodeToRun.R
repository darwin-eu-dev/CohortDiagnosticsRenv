# 1. Install the environment --------------------

# Install the latest version of renv:
install.packages("renv")

# Build the local library. This may take a while:
renv::init()

# Restore the library
renv::restore()

# 2. Running the package ------------------------

library(CohortDiagnosticsRenv)

# Edit the variables below to the correct values for your environment:
dbms <- Sys.getenv("dbms")
host <- Sys.getenv("host")
dbname <- Sys.getenv("dbname")
user <- Sys.getenv("user")
password <- Sys.getenv("password")
port <- Sys.getenv("port")

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = paste0(host, "/", dbname),
                                                                user = user,
                                                                password = password,
                                                                port = port)

connection <- DatabaseConnector::connect(connectionDetails)


# The database schema where the observational data in CDM is located
cdmDatabaseSchema <- "..."

# The database schema where the cohorts can be instantiated
cohortDatabaseSchema <- "..."

# The name of the table that will be created in the cohortDatabaseSchema
cohortTable <- "..."

# A folder with cohorts
cohortsFolder <- "..."

# A folder on the local file system to store results
outputDir <- "..."

# The databaseId is a short (<= 20 characters)
databaseId <- "..."

# This statement instatiates the cohorts, performs the diagnostics, and writes the results to
# a zip file containing CSV files
CohortDiagnosticsRenv::runDiagnostics(connectionDetails = connectionDetails,
                                      cdmDatabaseSchema = cdmDatabaseSchema,
                                      vocabularyDatabaseSchema = cdmDatabaseSchema,
                                      cohortDatabaseSchema = cohortDatabaseSchema,
                                      cohortTable = cohortTable,
                                      cohortsFolder = cohortsFolder,
                                      outputDir = outputDir,
                                      databaseId = databaseId)

# (Optionally) to view the results locally:
CohortDiagnostics::createMergedResultsFile(dataFolder = file.path(outputDir),
                                           sqliteDbPath = file.path(outputDir, "MergedCohortDiagnosticsData.sqlite"))

CohortDiagnostics::launchDiagnosticsExplorer(sqliteDbPath = file.path(outputDir, "MergedCohortDiagnosticsData.sqlite"))
