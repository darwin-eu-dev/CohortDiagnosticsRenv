% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/runDiagnostics.R
\name{runDiagnostics}
\alias{runDiagnostics}
\title{\code{runDiagnostics()} Execute the CohortDiagnostics section of the study.}
\usage{
runDiagnostics(
  connectionDetails = NULL,
  connection = NULL,
  cdmDatabaseSchema,
  cohortDatabaseSchema = cdmDatabaseSchema,
  vocabularyDatabaseSchema = cdmDatabaseSchema,
  verifyDependencies = FALSE,
  cohortTable = "cohort",
  tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
  cohortsFolder = NULL,
  outputDir = NULL,
  databaseId = "Unknown",
  useExternalConceptCountsTable = FALSE,
  conceptCountsTable = "#concept_counts"
)
}
\arguments{
\item{connectionDetails}{An object of type \code{connectionDetails} as created
using the
\code{\link[DatabaseConnector]{createConnectionDetails}}
function in the DatabaseConnector package.}

\item{connection}{An object of type \code{connection} as created
using the
\code{\link[DatabaseConnector]{connect}}
function in the DatabaseConnector package.}

\item{cdmDatabaseSchema}{Schema name where your patient-level data in OMOP CDM
format resides. Note that for SQL Server, this should
include both the database and schema name, for example
'cdm_data.dbo'.}

\item{cohortDatabaseSchema}{Schema name where intermediate data can be stored. You
will need to have write privileges in this schema. Note
that for SQL Server, this should include both the
database and schema name, for example 'cdm_data.dbo'.}

\item{vocabularyDatabaseSchema}{Schema name where your OMOP vocabulary data resides. This
is commonly the same as cdmDatabaseSchema. Note that for
SQL Server, this should include both the database and
schema name, for example 'vocabulary.dbo'.}

\item{verifyDependencies}{Check whether correct package versions are installed?}

\item{cohortTable}{The name of the table that will be created in the work
database schema. This table will hold the exposure and
outcome cohorts used in this study.}

\item{tempEmulationSchema}{Some database platforms like Oracle and Impala do not
truly support temp tables. To emulate temp tables,
provide a schema with write privileges where temp tables
can be created.}

\item{cohortsFolder}{Name of local folder to find the cohorts; make sure to use
forward slashes (/). Do not use a folder on a network
drive since this greatly impacts performance.}

\item{outputDir}{Name of local folder to place results; make sure to use
forward slashes (/). Do not use a folder on a network
drive since this greatly impacts performance.}

\item{databaseId}{A short string for identifying the database (e.g.
'Synpuf').}

\item{useExternalConceptCountsTable}{If TRUE, CohortDiagnostics will look for this table
in the cohortDatabaseSchema, provided the name in
conceptCountsTable.}

\item{conceptCountsTable}{The name of the ExternalConceptCountsTable.}
}
\description{
\code{runDiagnostics()} Execute the CohortDiagnostics section of the study.
}
\details{
This function executes the cohort diagnostics.
}
