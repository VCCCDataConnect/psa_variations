******** Prostate cancer project cohort creation ********
**Olivia Wawryk 2/1/2024

***Patients diagnosed with incident prostate cancer on the VCR; keep patient postcode / SA2 information. Patients are then to be linked to Patron encounter dataset ***

***VCR 

*Import and run basic cleaning script for VCR data 
clear
clear frames
do "Z:\cleaning_scripts\VCR\VCR_basic_cleaning_ICD10.do"
cd "Z:\Prostate_102023\data"


codebook e_linkedpersonidx
// 534,067 linkable patients on the VCR
rename e_linkedpersonidx e_linkedpersonid

**How many prostate cancer notifications?
gen flg1 = 1 if icd10_recode == "C61"
//71,787 prostate cancers

gen flg2 = 1 if site_icd0 == "C619"
//73,902 prostate cancers

tab tumourbehaviour if flg1 == . & flg2 == 1

tab morphology if flg1 == . & flg2 == 1 & tumourbehaviour == 3


*Keep only prostate cancers 
keep if flg1 == 1 

*Prostate cancer ever recorded for each patient, and first date
keep if incidenceflag == "21"
bysort e_linkedpersonid (flg1): gen prostate = flg1[1]
label var prostate "Prostate cancer record on VCR"

bysort e_linkedpersonid (flg1 e_diagnosisdate): gen prostate_date = e_diagnosisdate[1]
replace prostate_date = . if prostate == . 
format prostate_date %td
label var prostate_date "Date of first prostate VCR diagnosis"

*how many prostate cancer notifications per patient?
bysort e_linkedpersonid: egen total_prostate = total(flg1)

egen tag = tag(e_linkedpersonid)
tab prostate if tag == 1  
//71,740 patients with prostate cancer 


tab total_prostate if tag ==1 ,m
/*


total_prost |
        ate |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     73,097       99.47       99.47
          2 |        388        0.53      100.00
------------+-----------------------------------
      Total |     73,485      100.00



	  388 patients with 2 diagnosis records of prostate cancer
*/




**import VCR reference files**
frame create vcr_lookup
frame vcr_lookup: import delimited "Z:\ID200\id200_cancerregistry_reference_lookup_Release.csv", clear

	***********************************************************************
	***Gleason score: sourced from VCR notifier dataset
	frame create notifier
	frame change notifier 
	//import delimited "Z:\ID200\id200_cancerregistrynotifier_release.csv", clear
	//tab totalgleason
	*unmatched quote error: 2,047,972 obs, 79,250 total gleason
	
	import delimited "Z:\ID200\id200_cancerregistrynotifier_release.csv", clear bindquote(strict)
	tab totalgleason
	*2,047,968 obs, 79,250 total gleason
	


	
	foreach var of varlist e_admdate e_diagnosisdate {
	split `var', p("")
	drop `var'2
	gen new_`var' = date(`var'1, "MDY")
	format new_`var' %td
	drop `var'
	rename new_`var' `var'
	drop `var'1
}
	duplicates drop
	keep if gleason1 != . | gleason2 != . | totalgleason !=.
	duplicates drop
	rename notificationtyperefid referenceid
frlink m:1 referenceid, frame(vcr_lookup)
frget notificationtyperefid = sourcecode, from(vcr_lookup)
drop referenceid vcr_lookup


	keep e_linkedpersonid gleason1 gleason2 e_diagnosisdate totalgleason e_admdate
	duplicates drop
	*keep gleason scores from the date of diagnosis 
	//keep if e_admdate == e_diagnosisdate
	*keep highest gleason score if duplicate on the same date 
	bysort e_linkedpersonid e_diagnosisdate (totalgleason): keep if totalgleason == totalgleason[_N]
	keep  e_linkedpersonid e_diagnosisdate totalgleason 
	duplicates drop
	duplicates tag e_linkedpersonid e_diagnosisdate, gen(dup)
	drop dup
	frame change default 
	***********************************************************************

*Add Gleason score to vcr data 
frlink m:1  e_linkedpersonid e_diagnosisdate, frame(notifier) 
frget totalgleason, from(notifier)
//19,986 observations unable to be matched from default to notification file based on linkedpersonid and date 


**Keep record of first prostate cancer diagnosis for the 388 patients with more than one recorded prostate cancer diagnosis
keep if e_diagnosisdate == prostate_date

duplicates drop
*duplicate patients
duplicates tag e_linkedpersonid, gen(dup)

foreach var of varlist stagederived tnmm tnmn tnmt {
	replace `var' = "" if `var' == "NA"
}



**Keep variables of interest for now 
keep e_linkedpersonid icd10_recode prostate prostate_date ageatdiagnosis e_deathdate deathcause diagnosis_seifa_quintle diagnosis_seifa_yr diagnosis_postcode stagederived tnmm tnmn tnmt diagnosis_sa2_2011 diagnosis_sa2_2016 morphology nodespositive ageatdeath genderid totalgleason tumourbehaviour e_birthdate diagnosis_seifa_quintle diagnosis_seifa_yr



gen prostate_yr = year(prostate_date)
codebook e_linkedpersonid


*Keep only  malignant tumours 
drop if tumourbehaviour !=3

codebook e_linkedpersonid

gen stage=.
recode stage (.=1) if stagederived=="1"
recode stage (.=2) if stagederived=="2"
recode stage (.=2) if stagederived=="2A"
recode stage (.=2) if stagederived=="2B"
recode stage (.=3) if stagederived=="3"
recode stage (.=3) if stagederived=="3A"
recode stage (.=3) if stagederived=="3B"
recode stage (.=3) if stagederived=="3C"
recode stage (.=4) if stagederived=="4"
recode stage (.=4) if stagederived=="4A"
recode stage (.=4) if stagederived=="4B"


**VCR cohort table 
gen diag_age = (prostate_date - e_birthdate) / 365.25
table1, vars(diag_age conts \ genderid cat \ prostate_yr cat \ totalgleason conts \ diagnosis_seifa_quintle cat)


*Gleason 
table1, vars(diag_age conts \ genderid cat \ prostate_yr cat \ totalgleason cate \ diagnosis_seifa_quintle cat \ stage cat) missing

table1 if prostate_yr == 2019, vars(diag_age conts \ genderid cat \ prostate_yr cat \ totalgleason cate \ diagnosis_seifa_quintle cat \ stage cat) missing

tab totalgleason if prostate_yr == 2020,m
tab totalgleason if prostate_yr == 2021,m
tab totalgleason if prostate_yr == 2022,m

save vcr_prostate, replace
************



******************************************************************************
******** LINK VCR TO COHORT LOOK UP TABLE ************
*Link to look up table in order to add 'masterid' -- needed to link to Patron
******************************************************************************
import delimited "Z:\ID200\id200_cohort_lookup_table_release.csv", clear

rename patient_uuid masterid

drop if  incorrect_link_flag == 1 

keep masterid e_linkedpersonid

mmerge e_linkedpersonid using vcr_prostate
keep if _m == 2 | _m == 3 

egen tag = tag(e_linkedpersonid)
table1 if tag ==1, by(_merge) vars(diag_age conts \ genderid cat \ prostate_yr cat \ totalgleason conts \ diagnosis_seifa_quintle cat)


*** Save CSV of PSA linkedpersonid & masterid for Patron encounter filtering in R 
preserve
keep if _merge == 3 
keep e_linkedpersonid masterid
rename masterid masterID
duplicates drop
export delimited using "E:\projects\Prostate_102023\data\PSA_IDs.csv", replace
restore

drop tag
save temp_lookup, replace

*******
*** Link VCR prostate cancer patients to Patron encounter to see if they had at least 1 encounter in the year before diagnosis 

		**Run R script which will save all Encounter dates and e_linkedpersonids only, so dataset is small enough to be loaded into stata 
		* E:\projects\Prostate_102023\scripts\Patron_Encounter_Dates
//import delimited "E:\projects\Prostate_102023\data\Patron_EncounterDates.csv", clear 
import delimited "Z:\Prostate_102023\data\Patron_EncounterDates.csv", clear 
duplicates drop

*14,863 masterids 

***Merge to cohort lookup table 
mmerge masterid using temp_lookup
keep if _m == 3 

codebook e_linkedpersonid
**12,169 patients in the encounter files 

*Encounter dates 
	foreach var of varlist e_visit_date {
	split `var', p("")
	drop `var'2
	gen new_`var' = date(`var'1, "MDY")
	format new_`var' %td
	drop `var'
	rename new_`var' `var'
	drop `var'1
}


*Drop 'non-visits'
drop if patron_non_visit_flag == 1 

codebook e_linkedpersonid
*11,093 patients 

*Keep visits occuring in the 12 months before diagnosis 
gen start_date = prostate_date - 365
gen flg = 1 if (e_visit_date <= prostate_date) & (e_visit_date >= start_date)

keep if flg == 1 

drop flg start_date

codebook e_linkedpersonid
*4,423 patients 

duplicates drop

*Duplicate visits on the same date 
duplicates tag e_linkedpersonid e_visit_date, gen(dup)
drop masterid dup _merge

duplicates drop
duplicates tag e_linkedpersonid e_visit_date, gen(dup)
drop dup 


**Count total visits in 12 months before diagnosis 
bysort e_linkedpersonid: gen visits = _N
label var visits "Total visits in yr before diagnosis"

keep e_linkedpersonid prostate prostate_date ageatdiagnosis e_deathdate deathcause diagnosis_seifa_quintle diagnosis_seifa_yr diagnosis_postcode stagederived tnmm tnmn tnmt diagnosis_sa2_2011 diagnosis_sa2_2016 morphology nodespositive ageatdeath genderid totalgleason tumourbehaviour e_birthdate diagnosis_seifa_quintle diagnosis_seifa_yr diag_age visits prostate_yr
duplicates drop

table1, vars(diag_age conts \ genderid cat \ prostate_yr cat \ totalgleason conts \ diagnosis_seifa_quintle cat \ visits conts)



** Gleason scores before 2022 
table1 if prostate_yr <2021 & prostate_yr >=2015, vars(diag_age conts \ genderid cat \ prostate_yr cat \ totalgleason cate \ diagnosis_seifa_quintle cat \ visits conts) missing
// 



table1 if prostate_yr ==2019, vars(diag_age conts \ genderid cat \ prostate_yr cat \ totalgleason cate \ diagnosis_seifa_quintle cat \ visits conts) missing

stop

export delimited using "E:\projects\Prostate_102023\data\VCR_Patron_Cohort.csv", replace








erase "E:\projects\Prostate_102023\data\temp_lookup.dta"
erase "E:\projects\Prostate_102023\data\vcr_prostate.dta"


