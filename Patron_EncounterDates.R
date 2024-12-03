#################
### LIBRARIES ###
#################

library(tidyverse)
library(data.table)
library(arrow)
library(stringr)
library(readr)
library(lubridate)


#Load PSA patient IDs 
psa_ID <- fread("E:/projects/Prostate_102023/data/PSA_IDs.csv")


#Load Encounter (without reason) out of memory

# Encounters  out of memory
encounter1 <- open_csv_dataset("Z:/ID200/id200_patron_enc_enc_release.csv") 

### load filtered files into memory
# encounter only
encounter1 <- encounter1 %>% 
  
  # select variables of interest only
  dplyr::select(masterID, e_visit_date, PATRON_Non_Visit_flag) %>% 
  dplyr::distinct() %>%
  dplyr::filter(masterID %in% psa_ID$masterID) 

encounter1 <- encounter1 %>% 

  
  # load into memory
  collect()


# encounter reasons only out of memory
encounter2 <- open_csv_dataset("E:/processed_data/id200_patron_enc_enc_rsn_release.csv") 

encounter2 <- encounter2 %>% 
  
  # select variables of interest only
  dplyr::select(masterID, e_visit_reason_date) %>%
  dplyr::filter(masterID %in% psa_ID$masterID) %>% 
  dplyr::distinct() %>%
  
  # load into memory
  collect()


### combine into one file
encounter <- full_join(encounter1,
                       encounter2 %>% 
                         dplyr::rename(e_visit_date = e_visit_reason_date),
                       
                       relationship = "many-to-many")  


### write the encounter file
fwrite(encounter, "E:/projects/Prostate_102023/data/Patron_EncounterDates.csv",
       quote = T)

# remove to save space
rm(encounter1, encounter2)
gc()



