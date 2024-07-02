library(ROhdsiWebApi)
library(here)
library(readxl)
library(dplyr)

library(ROhdsiWebApi)
baseUrl <- "https://atlas-dev.darwin-eu.org/WebAPI"

token <- Sys.getenv("ATLAS_TOKEN")
ROhdsiWebApi::setAuthHeader(baseUrl, authHeader = token)
ROhdsiWebApi::getCdmSources(baseUrl)

cohortsToCreate <- ROhdsiWebApi::exportCohortDefinitionSet(
  baseUrl,
  c(598, 615, 596, 617, 618, 616, 713, 714)
) %>% select(atlasId, cohortId, cohortName)

write.csv(cohortsToCreate, file = "inst/CohortsToCreate.csv", row.names = FALSE)

ROhdsiWebApi::insertCohortDefinitionSetInPackage(
  fileName = "inst/CohortsToCreate.csv",
  baseUrl,
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql",
  rFileName = "R/CreateCohorts.R",
  insertTableSql = TRUE,
  insertCohortCreationR = TRUE,
  generateStats = FALSE,
  packageName
)
