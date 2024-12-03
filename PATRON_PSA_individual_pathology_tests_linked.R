
# This is a cleaning/filtering script to get individual blood tests from the PATRON pathology dataset.
# Only change the metrics in the first part and then run the rest of the code.
# Linkage to PATRON encounter reason is optional. 
# It will say "Only individual pathology file was saved." if you choose not to include encounters which will stop the script.

# Includes results for linkable patients only.

# The pathology test result is not always a clean numeric value.
# A new variable "Result_Value_Combined" is created to get the most complete result values possible:
# a flagging variable is created when those result values contain special characters (<3, >5, 4?, etc)
# and/or character values (under 5, etc.). These non-numeric ones may contain "written in the wrong column"
# kind of results and should therefore be evaluated or excluded, depending on the variable outcome of interest.

# Test results without a result are removed. 
# Impossible test results from e.g. <1900 with no age are removed.
# OBS! There will be some "weird" dates (from 2024 for example) and should be removed.
# These were left in here to allow for individual assessment and different project needs.


#################
### LIBRARIES ###
#################

library(tidyverse)
library(data.table)
library(arrow)
library(stringr)
library(readr)
library(lubridate)


####################################################################
### INDIVIDUAL ADAPTION TO TEST OF INTEREST: Define individually ###
####################################################################

# CONFIGURE THIS PART TO MATCH YOUR NEEDS!

###
### What test do you use?
### 

# Define test by test names: account for variations
# create regex for pathology test: "(^|[^A-Za-z0-9])AST|asperas|^ASP$"
# or simple matches: "PLT|hba|xxx"
# don't need to account for letter cases


test_regex <- "PSA|Prostate Spec" 


# Do you want a file with the linked encounters?
link_encounter_too <- "yes" # either "yes" or "no" (spelling is important)


### PATHOLOGY RESULT ONLY: path to where file should be saved + file name

path_file <- "E:/projects/Prostate_102023/data/Patron_PSA_pathology.csv" # keep .csv


### IF LINKED WITH ENCOUNTER: path to where file should be saved + file name (different to above)
# leave this empty if you don't need a linked file with encounter reasons

enc_file <- "E:/projects/Prostate_102023/data/Patron_PSA_encounters.csv" # keep .csv



### OBS: If interested in more than 1 pathology test, repeat everything after "Define specific pathology tests of interest" with different regex


#######################################
### GENERIC CODE PART: Don't change ###
#######################################

### Load data

# pathology patron out of memory
pathology <- open_csv_dataset("Z:/ID200/id200_patron_ivx_idvl_tst_release.csv")

# lookup table to join for linkedID
lookup <- fread("Z:/ID200/id200_cohort_lookup_table_release.csv") # cohort_lookup_table_release


# patron patient information 
patron <- fread("Z:/ID200/id200_patron_pat_dtl_release.csv")


### add linked_id to patron from lookup table
patron <- left_join(patron,
                    
                    lookup %>% 
                      dplyr::select(Patient_UUID, e_linkedpersonid, Incorrect_Link_Flag),
                    
                    join_by(masterID == Patient_UUID))


# patron has multiple IDs with multiple YOBs: delete as these are unreliable
check_id <- patron %>% 
  dplyr::select(e_linkedpersonid, YearOfBirth) %>% 
  dplyr::distinct() %>% 
  dplyr::group_by(e_linkedpersonid) %>% 
  dplyr::summarise(n = n()) %>% 
  dplyr::ungroup() %>% 
  dplyr::filter(n > 1)

patron <- patron %>% 
  dplyr::filter(!e_linkedpersonid %in% check_id$e_linkedpersonid)



###
### Define specific pathology tests of interest
###

pathology_test <- pathology %>% 
  
  # select essential variables
  dplyr::select(newMasterId, Site_PPN, Patient_PPN, 
                Age_at_Event, e_result_date,
                Result_Name, Result_Value, Result_Numeric,
                Result_Units, Result_Range, Results_ID,
                Report_ID, Result_Abnormal_flag) %>% 
  
  # filter linkable patron patients
  dplyr::filter(newMasterId %in% patron$masterID) %>% 
  
  # filter regex 
  dplyr::filter(grepl(test_regex, Result_Name, ignore.case = T)) %>% 
  
  # load into memory (will take a while depending on size)
  collect()


###
### Add linked ID
###

# Join with patron to get e_linkedpersonid/YOB/gender
pathology_test <- left_join(pathology_test, 
                            patron %>% 
                              dplyr::select(e_linkedpersonid, masterID, 
                                            YearOfBirth, PATRON_Gender_Lkp),
                            
                            join_by(newMasterId == masterID),
                            
                            relationship = "many-to-many")

# remove unlinkable patients
pathology_test <- pathology_test %>% 
  dplyr::filter(!is.na(e_linkedpersonid))


###
### Clean Result values
###

# remove unnecessary whitespace
pathology_test <- pathology_test %>% 
  dplyr::mutate(Result_Value = str_squish(Result_Value),
                Result_Range = str_squish(Result_Range),
                Result_Units = str_squish(Result_Units))


# remove those that have no result and flag non-numeric results
pathology_test <- pathology_test %>% 
  dplyr::mutate(Result_Value_Combined = coalesce(as.character(round(Result_Numeric, digits = 2)),
                                                 Result_Value)) %>%
  
  # remove empty values
  dplyr::filter(!Result_Value_Combined == "") %>% 
  
  # flag those where the result value isn't an exact number
  dplyr::mutate(Result_Value_Combined_Flag_Not_Exact_Numeric = ifelse(grepl("[^A-Za-z0-9]", Result_Value_Combined) | # with special characters
                  grepl("(\\D)", Result_Value_Combined), 1, 0)) # with letters
 

# keep unique
pathology_test <- pathology_test %>% 
  dplyr::distinct()



# remove the obviously impossible ones
pathology_test <- pathology_test %>% 
  dplyr::mutate(e_result_year = as.numeric(year(mdy_hms(e_result_date))),
                Age_at_Event_YOB = e_result_year - YearOfBirth) %>% 
  dplyr::filter(!(e_result_year < 1900 &
                    Age_at_Event == 999 &
                    Age_at_Event_YOB < 0)) %>% 
  dplyr::filter(!(Age_at_Event < 0 &
                    Age_at_Event_YOB < 0)) 


# write the pathology file only
fwrite(pathology_test, file = path_file,
       quote = T)

########################################################
### CONDITIONAL: IF ENCOUNTER REASON SHOULD BE ADDED ###
########################################################

### Condition:

if(link_encounter_too == "no") {
  
  # end running the script
  stop("\r Only individual pathology file was saved.")
  
}
  
# otherwise script continues with encounters
pathology_ids <- pathology_test %>% 
  dplyr::select(newMasterId, e_linkedpersonid) %>% 
  dplyr::distinct()


# remove unnecessary files to save memory
rm(pathology_test, patron, lookup, check_id)

gc()

### Encounter files
# encounter patron out of memory

encounter1 <- open_csv_dataset("Z:/ID200/id200_patron_enc_enc_release.csv") 

encounter2 <- open_csv_dataset("E:/processed_data/id200_patron_enc_enc_rsn_release.csv") 


### load filtered files into memory
# encounter only
encounter1 <- encounter1 %>% 
  
  # select variables of interest only
  dplyr::select(masterID, Age_at_Event,
                e_visit_date, Consult_Visit_Type_Description) %>% 
  
  # filter IDs in the pathology file
  dplyr::filter(masterID %in% pathology_ids$newMasterId) %>% 
  
  # load into memory
  collect()

# encounter reasons
encounter2 <- encounter2 %>% 
  
  # select variables of interest only
  dplyr::select(masterID, Age_at_Event,
                e_visit_reason_date, Source_Visit_Reason_Description,
                Source_Visit_Reason_Code, Source_Mapped_SNOMED_Code,
                Source_Mapped_Docle_Code) %>% 
  
  # filter IDs in the pathology file
  dplyr::filter(masterID %in% pathology_ids$newMasterId) %>% 
  
  # load into memory
  collect()

  
### combine into one file
encounter <- full_join(encounter1,
                       encounter2 %>% 
                         dplyr::rename(e_visit_date = e_visit_reason_date),
                       
                       relationship = "many-to-many")  


# remove to save space
rm(encounter1, encounter2)
gc()

### write the encounter file
fwrite(encounter, file = enc_file,
       quote = T)
