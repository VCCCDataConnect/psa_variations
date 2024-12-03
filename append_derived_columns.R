# append remoteness area to the cohort and the psa values
library(dplyr)
library(arrow)
library(ggplot2)
library(stringr)

folder_path <- "E:/projects/Prostate_102023/data/"

# load up the cohort
cohort <- read_csv_arrow(paste0(folder_path, "VCR_Patron_Cohort.csv"))

# load up the psa data
psa <- read_csv_arrow(paste0(folder_path, "psa_cleaned_140224.csv"))
#psa <- read_csv_arrow(paste0(folder_path, "psa_cleaned_080224.csv"))

# load up the remoteness area mapping data
ra_to_sa2 <- read_csv_arrow(paste0(folder_path, "sa2_to_ra_2016.csv"))

# diagnosis sa2 to ra
# are all the diagnosis sa2 values in Vic?
intersect(cohort$diagnosis_sa2_2016, ra_to_sa2$SA2_MAIN16) %>% length()

# 407 in intersection, 408 in cohort
# which sa2's are in the cohort but are not in the mapping?
setdiff(cohort$diagnosis_sa2_2016, ra_to_sa2$SA2_MAIN16) # none

# merge ra to the cohort on sa2
cohort_with_ra <- merge(x=cohort,
                        y=ra_to_sa2,
                        by.x='diagnosis_sa2_2016',
                        by.y='SA2_MAIN16',
                        all.x=TRUE,
                        all.y=FALSE)

# include the psa test results
cohort_with_ra_psa <- merge(x=cohort_with_ra,
                            y=psa,
                            by.x="e_linkedpersonid",
                            by.y="e_linkedpersonid", 
                            all.x=TRUE)

cohort_with_ra_psa %>% write_csv_arrow(paste0(folder_path, "VCA_Patron_Cohort_with_RA_PSA_140224.csv"))