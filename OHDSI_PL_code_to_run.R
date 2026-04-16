library (jsonlite)
library (tibble)
library (Alathea)
library (PhenotypeLibrary)
library(dplyr)
library (openxlsx)


###########################
#set parameters for the run
###########################
#set name which will be used for the output
projName <- 'PhenLibraryALATHEAWorkshop196'

excludedVisitNodes <- "9202, 2514435,9203,2514436,2514437,2514434,2514433,9201"
includedSourceVocabs <- "'ICD10', 'ICD10CM', 'CPT4', 'HCPCS', 'NDC', 'ICD9CM', 'ICD9Proc', 'ICD10PCS', 'ICDO3', 'JMDC'"

resultSchema <-'vocabulary.jnj_network' #schema containing Achilles results

cdmSchema <-'healthverity_cc.cdm_healthverity_cc_v3616' # to get the stats tab - as it runs on the real data

#specify schemas with vocabulary versions you want to compare
#specify schemas with vocabulary versions you want to compare
oldVocabSchema<-'vocabulary.v20230116'
newVocabSchema <-'vocabulary.v20260227'
scratchSchema <-'scratch.scratch_ddymshyt'


#############################
#work with OHDSI PL
#############################

#get all concept sets
phenotypeLog <- getPhenotypeLog()
phenotypeLog <- phenotypeLog %>% filter(cohortId == 196) # phenotyping workshop cohort ID - RA
allConceptSets <- getPlConceptDefinitionSet(cohortIds = phenotypeLog$cohortId)

#not needed for this run
#A tibble with the cohort ID, name, sql, and JSON for the provided cohort IDs. 
#Can be used by the CohortGenerator package.
cohortDefinition<-getPlCohortDefinitionSet(196)

#initial table
Concepts_in_cohort <- tibble(
  conceptId = numeric(),
  isExcluded = logical(),
  includeDescendants =logical(),
  conceptsetId = numeric (),
  conceptsetName = character(),
  cohortId = numeric()
)

# single concept set version (educational) - uses the first concept set in allConceptSets
i <- 1
parsed <- fromJSON(allConceptSets[i, ]$conceptSetExpression, flatten = TRUE)
result_df <- parsed[[1]] %>% select(concept.CONCEPT_ID, isExcluded, includeDescendants)
result_df$conceptsetId <- allConceptSets[i, ]$conceptSetId
result_df$conceptsetName <- allConceptSets[i, ]$conceptSetName
result_df$cohortId <- allConceptSets[i, ]$cohortId
Concepts_in_cohort <- rbind(Concepts_in_cohort, result_df)

# loop through all the concept sets (commented out for educational purposes)
# for (i in 1:nrow(allConceptSets)) {
#   # Apply the function to each row of the data frame
#   parsed <- fromJSON(allConceptSets[i, ]$conceptSetExpression, flatten = TRUE)
#   # skip empty concept sets
#   if (is.null(parsed[[1]]) || nrow(parsed[[1]]) == 0) next
#   result_df <- parsed[[1]] %>% select(concept.CONCEPT_ID, isExcluded, includeDescendants)
#   result_df$conceptsetId <- allConceptSets[i, ]$conceptSetId
#   result_df$conceptsetName <- allConceptSets[i, ]$conceptSetName
#   result_df$cohortId <- allConceptSets[i, ]$cohortId
#   # Append the result to the dataframe
#   Concepts_in_cohort  <- rbind (Concepts_in_cohort,result_df )
# }

Concepts_in_cohort <- Concepts_in_cohort %>% rename(conceptId = concept.CONCEPT_ID)

# run the actual comparison through different vocabulary versions

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "spark",
  connectionString = keyring::key_get("databricks", "connection_string"),
  user = "token",
  password = keyring::key_get("databricks", "token")
)


Concepts_in_cohortSet <- Concepts_in_cohort %>%
  left_join(phenotypeLog %>% select(cohortId, cohortName), by = "cohortId")

resultToExcel(connectionDetailsVocab = connectionDetails,
              Concepts_in_cohortSet = Concepts_in_cohortSet,
              newVocabSchema = newVocabSchema,
              oldVocabSchema = oldVocabSchema,
              excludedNodes = excludedVisitNodes,
              resultSchema = resultSchema,
              scratchSchema= scratchSchema,
              includedSourceVocabs = includedSourceVocabs,
              projName = projName,
              cdmSchema = cdmSchema,
              outputFolder = "results"
)

#open the excel file
#Windows
shell.exec(normalizePath(file.path("results", paste0(projName, "PhenChange.xlsx"))))

#MacOS
#system(paste("open", file.path("results", paste0(projName, "PhenChange.xlsx"))))

