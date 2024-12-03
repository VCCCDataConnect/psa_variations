******** Prostate cancer project initial cohort check ********


***Patients diagnosed with prostate cancer on the VCR, linked to patron with data prior to diagnosis ***

***VCR 

*Import and run basic cleaning script for VCR data 
clear
do "E:\cleaning_scripts\VCR\VCR_basic_cleaning.do"
cd "E:\projects\Prostate_102023\data"


codebook e_linkedpersonid
// 534,068 patients on the VCR


**How many prostate cancer notifications?
gen flg = 1 if site_icd0 == "C619"
//73,902 prostate cancers 

*Prostate cancer ever recorded for each patient, and first date
bysort e_linkedpersonid (flg): gen prostate = flg[1]
label var prostate "Prostate cancer record on VCR"

bysort e_linkedpersonid (flg e_diagnosisdate): gen prostate_date = e_diagnosisdate[1]
replace prostate_date = . if prostate == . 
format prostate_date %td
label var prostate_date "Date of first prostate VCR diagnosis"

*how many prostate cancer notifications per patient?
bysort e_linkedpersonid: egen total_prostate = total(flg)

egen tag = tag(e_linkedpersonid)
tab prostate if tag == 1  
//73,486 patients with prostate cancer 

*Keep only prostate cancer patients 
keep if prostate == 1 

**Keep record of first prostate cancer diagnosis (or do we want to use most recent prostate cancer diagnosis?)
keep if site_icd0 == "C619"
keep if e_diagnosisdate == prostate_date



**Keep variables of interest for now 
keep e_linkedpersonid prostate prostate_date ageatdiagnosis e_deathdate deathcause diagnosis_seifa_quintle diagnosis_seifa_yr diagnosis_postcode
duplicates drop
gen prostate_yr = year(prostate_date)
codebook e_linkedpersonid

save vcr_prostate, replace
************



*******
*** Link VCR prostate cancer patients to Patron encounter to see if they had at least 1 encounter in the year before diagnosis 

		**Run R script which will save all Encounter dates and e_linkedpersonids only, so dataset is small enough to be loaded into stata 
		* E:\projects\Prostate_102023\scripts\Patron_Encounter_Dates
import delimited "E:\projects\Prostate_102023\data\Patron_EncounterDates.csv", clear 

duplicates drop

*3,185,929 masterids 







keep if _m == 3 
rename patient_uuid masterid 

keep e_linkedpersonid prostate prostate_date prostate_yr masterid
duplicates drop

codebook e_linkedpersonid

*duplicate linkedpersonid due to some having more than one masterid in patron

**Link to patron 
mmerge masterid using "Z:\Project-042\OW\Data\patron_patient.dta"


//how many link to patron?
codebook e_linkedpersonid if _m == 3
*14,295 prostate cancer patients linked to patron 

keep if _m == 3 

**Save patron ids
keep e_linkedpersonid prostate prostate_date prostate_yr masterid
duplicates drop

save "Z:\Project-042\OW\Data\prostate_patronIDs.dta", replace




*******************************************
*** Pathology : PSA tests 
import delimited "E:\projects\Prostate_102023\data\Patron_PSA_pathology.csv", clear


//95,990 PSA tests which can be linked


mmerge e_linkedpersonid using "Z:\Project-042\OW\Data\prostate_patronIDs.dta"








