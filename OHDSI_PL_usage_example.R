install.packages("PhenotypeLibrary")

library(PhenotypeLibrary)

PhenotypeLog<-getPhenotypeLog()

#see all cohort metadata
cohortMetadata <-
PhenotypeLog %>%
  filter(cohortId == 123) %>%
  mutate(across(everything(), as.character)) %>%
  tidyr::pivot_longer(cols = everything(), names_to = "columnName", values_to = "value") %>%
  as.data.frame()

CohortDefinitionSet<-getPlCohortDefinitionSet(123)

CohortDefinitionPivot <- CohortDefinitionSet %>%
  mutate(across(everything(), as.character)) %>%
  tidyr::pivot_longer(cols = everything(), names_to = "columnName", values_to = "value") %>%
  as.data.frame()

ConceptDefinitionSet<-getPlConceptDefinitionSet(123)

ConceptDefinitionPivot <- ConceptDefinitionSet %>%
  mutate(across(everything(), as.character)) %>%
  tidyr::pivot_longer(cols = everything(), names_to = "columnName", values_to = "value") %>%
  as.data.frame()
