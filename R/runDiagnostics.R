# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute the CohortDiagnostics section of the study
#'
#' @details
#' This function executes the cohort diagnostics.
#'
#' @param connectionDetails                   An object of type \code{connectionDetails} as created
#'                                            using the
#'                                            \code{\link[DatabaseConnector]{createConnectionDetails}}
#'                                            function in the DatabaseConnector package.
#' @param connection                          An object of type \code{connection} as created
#'                                            using the
#'                                            \code{\link[DatabaseConnector]{connect}}
#'                                            function in the DatabaseConnector package.
#' @param cdmDatabaseSchema                   Schema name where your patient-level data in OMOP CDM
#'                                            format resides. Note that for SQL Server, this should
#'                                            include both the database and schema name, for example
#'                                            'cdm_data.dbo'.
#' @param cohortDatabaseSchema                Schema name where intermediate data can be stored. You
#'                                            will need to have write privileges in this schema. Note
#'                                            that for SQL Server, this should include both the
#'                                            database and schema name, for example 'cdm_data.dbo'.
#' @param vocabularyDatabaseSchema            Schema name where your OMOP vocabulary data resides. This
#'                                            is commonly the same as cdmDatabaseSchema. Note that for
#'                                            SQL Server, this should include both the database and
#'                                            schema name, for example 'vocabulary.dbo'.
#' @param cohortTable                         The name of the table that will be created in the work
#'                                            database schema. This table will hold the exposure and
#'                                            outcome cohorts used in this study.
#' @param tempEmulationSchema                 Some database platforms like Oracle and Impala do not
#'                                            truly support temp tables. To emulate temp tables,
#'                                            provide a schema with write privileges where temp tables
#'                                            can be created.
#' @param settingsFileName                    Name of the settings file, by convention the default is "CohortsToCreate.csv".
#' @param jsonFolder                          Location of the cohort json files, by convention the default is "cohorts".
#' @param sqlFolder                           Location of the cohort sql files, by convention the default is "sql.
#' @param packageName                         Name of the package in character.
#' @param outputDir                           Name of local folder to place results; make sure to use
#'                                            forward slashes (/). Do not use a folder on a network
#'                                            drive since this greatly impacts performance.
#' @param databaseId                          A short string for identifying the database (e.g.
#'                                            'Synpuf').
#'
#' @importFrom ParallelLogger addDefaultFileLogger addDefaultErrorReportLogger unregisterLogger unregisterLogger logInfo
#' @importFrom CohortGenerator getCohortTableNames createCohortTables createEmptyCohortDefinitionSet generateCohortSet exportCohortStatsTables
#' @importFrom tools file_path_sans_ext
#' @importFrom CirceR cohortExpressionFromJson buildCohortQuery createGenerateOptions
#' @importFrom FeatureExtraction createCohortBasedTemporalCovariateSettings createTemporalCovariateSettings
#' @importFrom CohortDiagnostics executeDiagnostics
#' @importFrom readr read_csv
#' @import dplyr
#' @export
runDiagnostics <- function(connectionDetails = NULL,
                           connection = NULL,
                           cdmDatabaseSchema,
                           cohortDatabaseSchema = cdmDatabaseSchema,
                           vocabularyDatabaseSchema = cdmDatabaseSchema,
                           cohortTable = "cohort",
                           tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
                           settingsFileName = "CohortsToCreate.csv",
                           jsonFolder = "cohorts",
                           sqlFolder = "sql",
                           packageName,
                           outputDir,
                           databaseId = "Unknown") {

  if (!file.exists(outputDir)) {
    dir.create(outputDir, recursive = TRUE)
  }

  ParallelLogger::addDefaultFileLogger(file.path(outputDir, "log.txt"))
  ParallelLogger::addDefaultErrorReportLogger(file.path(outputDir, "errorReportR.txt"))
  on.exit(ParallelLogger::unregisterLogger("DEFAULT_FILE_LOGGER", silent = TRUE))
  on.exit(
    ParallelLogger::unregisterLogger("DEFAULT_ERRORREPORT_LOGGER", silent = TRUE),
    add = TRUE
  )

  ParallelLogger::logInfo("Creating cohorts")
  cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTable)

  # Next create the tables on the database
  CohortGenerator::createCohortTables(
    connectionDetails = connectionDetails,
    connection = connection,
    cohortTableNames = cohortTableNames,
    cohortDatabaseSchema = cohortDatabaseSchema,
    incremental = FALSE
  )

  cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
    settingsFileName = settingsFileName,
    jsonFolder = jsonFolder,
    sqlFolder = sqlFolder,
    packageName = packageName
  )

  # Generate the cohort set
  CohortGenerator::generateCohortSet(
    connectionDetails = connectionDetails,
    connection = connection,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortTableNames = cohortTableNames,
    cohortDefinitionSet = cohortDefinitionSet,
    # incrementalFolder = incrementalFolder,
    incremental = FALSE
  )

  # export stats table to local
  CohortGenerator::exportCohortStatsTables(
    connectionDetails = connectionDetails,
    connection = connection,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortTableNames = cohortTableNames,
    cohortStatisticsFolder = outputDir,
    incremental = FALSE
  )

  temporalStartDays <- c(
    # components displayed in cohort characterization
    -9999, # anytime prior
    -365, # long term prior
    -180, # medium term prior
    -30, # short term prior

    # components displayed in temporal characterization
    -365, # one year prior to -31
    -30, # 30 day prior not including day 0
    0, # index date only
    1, # 1 day after to day 30
    31,
    -9999 # Any time prior to any time future
  )

  temporalEndDays <- c(
    0, # anytime prior
    0, # long term prior
    0, # medium term prior
    0, # short term prior

    # components displayed in temporal characterization
    -31, # one year prior to -31
    -1, # 30 day prior not including day 0
    0, # index date only
    30, # 1 day after to day 30
    365,
    9999 # Any time prior to any time future
  )

  cohortBasedCovariateSettings <-
    FeatureExtraction::createCohortBasedTemporalCovariateSettings(
      analysisId = 150,
      covariateCohortDatabaseSchema = cohortDatabaseSchema,
      covariateCohortTable = cohortTableNames$cohortTable,
      covariateCohorts = cohortDefinitionSet |>
        dplyr::select(
          .data$cohortId,
          .data$cohortName
        ),
      valueType = "binary",
      temporalStartDays = temporalStartDays,
      temporalEndDays = temporalEndDays
    )

  featureBasedCovariateSettings <-
    FeatureExtraction::createTemporalCovariateSettings(
      useDemographicsGender = TRUE,
      useDemographicsAge = TRUE,
      useDemographicsAgeGroup = TRUE,
      useDemographicsRace = FALSE,
      useDemographicsEthnicity = FALSE,
      useDemographicsIndexYear = TRUE,
      useDemographicsIndexMonth = TRUE,
      useDemographicsIndexYearMonth = TRUE,
      useDemographicsPriorObservationTime = TRUE,
      useDemographicsPostObservationTime = TRUE,
      useDemographicsTimeInCohort = TRUE,
      useConditionOccurrence = TRUE,
      useProcedureOccurrence = FALSE,
      useDrugEraStart = TRUE,
      useMeasurement = TRUE,
      useConditionEraStart = FALSE,
      useConditionEraOverlap = FALSE,
      useConditionEraGroupStart = FALSE,
      # do not use because https://github.com/OHDSI/FeatureExtraction/issues/144
      useConditionEraGroupOverlap = FALSE,
      useDrugExposure = TRUE,
      # leads to too many concept id
      useDrugEraOverlap = FALSE,
      useDrugEraGroupStart = FALSE,
      # do not use because https://github.com/OHDSI/FeatureExtraction/issues/144
      useDrugEraGroupOverlap = FALSE,
      useObservation = FALSE,
      useVisitCount = FALSE,
      useVisitConceptCount = FALSE,
      useDeviceExposure = FALSE,
      useCharlsonIndex = FALSE,
      useDcsi = FALSE,
      useChads2 = FALSE,
      useChads2Vasc = FALSE,
      useHfrs = FALSE,
      temporalStartDays = temporalStartDays,
      temporalEndDays = temporalEndDays
    )

  # run cohort diagnostics
  CohortDiagnostics::executeDiagnostics(
    cohortDefinitionSet = cohortDefinitionSet,
    exportFolder = outputDir,
    databaseId = databaseId,
    cohortDatabaseSchema = cohortDatabaseSchema,
    connectionDetails = connectionDetails,
    connection = connection,
    cdmDatabaseSchema = cdmDatabaseSchema,
    tempEmulationSchema = tempEmulationSchema,
    cohortTable = cohortTable,
    cohortTableNames = cohortTableNames,
    vocabularyDatabaseSchema = vocabularyDatabaseSchema,
    cdmVersion = 5,
    runInclusionStatistics = TRUE,
    runIncludedSourceConcepts = TRUE,
    runOrphanConcepts = TRUE,
    runTimeSeries = TRUE,
    runVisitContext = FALSE,
    runBreakdownIndexEvents = TRUE,
    runIncidenceRate = TRUE,
    runCohortRelationship = TRUE,
    runTemporalCohortCharacterization = TRUE,
    temporalCovariateSettings = featureBasedCovariateSettings,
    # temporalCovariateSettings = getDefaultCovariateSettings(),
    minCellCount = 5,
    minCharacterizationMean = 0.00001,
    incremental = FALSE
    # incrementalFolder = file.path(exportFolder, "incremental")
  )
}
