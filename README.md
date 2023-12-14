
# CohortDiagnosticsRenv

<!-- badges: start -->
<!-- badges: end -->

This project includes a renv.lock file to run CohortDiagnostics v3.2.4.

# 1. Instructions

In this project you can also find a extras/CodeToRun.R to executeDiagnostics. In the R folder, there is a script with a helper function with the parameters adjusted for Darwin studies. 

# Install the latest version of renv:

```R
install.packages("renv")
```

# Build the local library. This may take a while:
```R
renv::init()
```

# Restore the library

```R
renv::restore()
```

# 2. Running the package 

Edit the variables below to the correct values for your environment:

```R
library(...)

# Login details
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

# A folder on the local file system to store results:
outputDir <- "..."

# The database schema where the observational data in CDM is located.

cdmDatabaseSchema <- "..."

# The database schema where the cohorts can be instantiated.
cohortDatabaseSchema <- "..."


# The name of the table that will be created in the cohortDatabaseSchema.
cohortTable <- "..."

# The databaseId is a short (<= 20 characters)
databaseId <- "..."

# This statement instatiates the cohorts, performs the diagnostics, and writes the results to
# a zip file containing CSV files. This will probaby take a long time to run:
runDiagnostics(connectionDetails = connectionDetails,
               cdmDatabaseSchema = cdmDatabaseSchema,
               vocabularyDatabaseSchema = cdmDatabaseSchema,
               cohortDatabaseSchema = cohortDatabaseSchema,
               cohortTable = cohortTable,
               outputDir = outputDir,
               databaseId = databaseId)

# (Optionally) to view the results locally:
CohortDiagnostics::createMergedResultsFile(
  dataFolder = file.path(outputDir),
  sqliteDbPath = file.path(outputDir, "MergedCohortDiagnosticsData.sqlite")
)
CohortDiagnostics::launchDiagnosticsExplorer(sqliteDbPath = file.path(outputDir, "MergedCohortDiagnosticsData.sqlite"))
```
