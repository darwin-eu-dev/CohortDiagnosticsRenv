library(ROhdsiWebApi)
baseUrl <- "https://test-atlas.ehden.eu/WebAPI"

authorizeWebApi(
  baseUrl,
  authMethod = "db",
  webApiUsername = Sys.getenv('EHDEN_WEBAPI_USERNAME'),
  webApiPassword = Sys.getenv('EHDEN_WEBAPI_PASSWORD')
)

getCdmSources(baseUrl)

cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  baseUrl,
  c(92:97, 100, setdiff(101:127, 118))
)
write.csv(cohortDefinitionSet, 'inst/cohortDefinitionSet.csv')

# Insert cohort definitions from ATLAS into package -----------------------
for (cohortId in c(92:97, 100)) {
  ROhdsiWebApi::insertCohortDefinitionInPackage(
    cohortId,
    name = cohortId,
    jsonFolder = "inst/cohorts",
    sqlFolder = "inst/sql/sql_server",
    baseUrl,
    generateStats = FALSE
  )
}

# Get treatment cohort definitions from Atlas ------------------------------
for (cohortId in setdiff(101:127, 118)) {
  print(cohortId)
  object <- getCohortDefinition(cohortId = cohortId, baseUrl = baseUrl)
  json <- ROhdsiWebApi:::.toJSON(object$expression, pretty = TRUE)
  writeLines(json, file.path("inst", "treatment_cohorts", paste0(cohortId, ".json")))
}
