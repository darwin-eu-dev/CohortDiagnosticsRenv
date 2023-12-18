# Install the environment --------------------

# 1. In RStudio, create a new project: File -> New Project... -> New Directory -> New Project.
# If asked if you want to use `renv` with the project, answer ‘no’.

# 2. Inside the project, install the latest version of renv
install.packages("renv")

# 3. Download the lock file:
download.file("https://raw.githubusercontent.com/darwin-eu-dev/CohortDiagnosticsRenv/main/renv.lock", "renv.lock")

# 4. Build the local library
renv::restore()

# Running the package ------------------------

# 1. Load the CohortDiagnosticsRenv package
library(CohortDiagnosticsRenv)

# 2. Edit the variables below to create a connection and run CohortDiagnostics

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

# 3. This statement instatiates the cohorts, performs the diagnostics, and writes the results to
# a zip file containing CSV files
CohortDiagnosticsRenv::runDiagnostics(connectionDetails = connectionDetails,
                                      cdmDatabaseSchema = cdmDatabaseSchema,
                                      vocabularyDatabaseSchema = cdmDatabaseSchema,
                                      cohortDatabaseSchema = cohortDatabaseSchema,
                                      cohortTable = cohortTable,
                                      cohortsFolder = cohortsFolder,
                                      outputDir = outputDir,
                                      databaseId = databaseId)

# 4. (Optionally) to view the results locally:
CohortDiagnostics::createMergedResultsFile(dataFolder = file.path(outputDir),
                                           sqliteDbPath = file.path(outputDir, "MergedCohortDiagnosticsData.sqlite"))

CohortDiagnostics::launchDiagnosticsExplorer(sqliteDbPath = file.path(outputDir, "MergedCohortDiagnosticsData.sqlite"))
