******		PSA Project Phase 2 		******
*1. Median PSA before diagnosis, using last available PSA only 
*2. Association between PSA and Gleason at diagnosis 
*3. Association between diagnostic delay and Gleason at diagnosis 
*4. Association between PSA and survival 
*5. Association between diagnostic delay and survival 


cd "Z:\Prostate_102023\data"
************************** Last PSA test before diagnosis 

/*
use final_cohort_psa, clear
// 4,417 ID

gen gleason2 = . 
recode gleason2 .=1 if gleason <=6
recode gleason2 .=2 if gleason == 7 
recode gleason2 .=3 if gleason >=8 & gleason !=. 
replace gleason2 =. if gleason == 11
label define gleason2 1"Low grade <=6" 2"Intermediate = 7" 3"High grade >=8" 
label values gleason2 gleason2 

table1, by(remoteness) vars(gleason2 cat \ stage cat) missing

drop if prostate_yr >= 2020 | prostate_yr <=2010
table1, by(remoteness) vars(prostate_yr cat \ gleason2 cat \ stage cat) missing

**Results more than 6 months before diagnosis - drop
drop if e_result_date<(prostate_date-182.5)
*/

///////////////////////////////////////////////////////////

**** Association between psa and stage 
use psa_2year, clear

**merge back info from VCR: stage, date of death, cause of death 
preserve 
use final_cohort_psa, clear
keep e_linkedpersonid deathcause stagederived nodespositive tnmm tnmn tnmt e_birthdate e_deathdate totalgleason stage gleason prostate_yr prostate_date
duplicates drop
save cohort_temp, replace
restore 

mmerge e_linkedpersonid using cohort_temp 
keep if _m == 3 


*PSA categories 
gen psa_cat = . 
recode psa_cat (.=1) if result_value_cleaned < 10 
recode psa_cat (.=2) if result_value_cleaned >= 10 &  result_value_cleaned <20
recode psa_cat (.=3) if result_value_cleaned >= 20 &  result_value_cleaned !=.
label define cat 1"<10" 2"10-20" 3">20"
label values psa_cat cat

keep e_linkedpersonid result_value_cleaned remoteness result_date diagnosis_date result_timing psa_cat totalgleason gleason stagederived stage deathcause e_deathdate prostate_yr prostate_date

duplicates drop 
duplicates tag e_linkedpersonid result_date, gen(dup)

*More than 1 result on the same day -- which do we keep? an average? for now keep highest  
gsort e_linkedpersonid result_date -result_value_cleaned
duplicates drop e_linkedpersonid result_date, force

drop dup

*Flag the PSA test which occurred last (before diagnosis)
bysort e_linkedpersonid: egen min_count = min(result_timing)

gen last_psa = 1 if min_count == result_timing

duplicates tag e_linkedpersonid last_psa, gen(dup)
drop dup 


**Stage at diagnosis 


*Keep last PSA before diagnosis 
keep if last_psa == 1 
duplicates drop


**Last PSA test before diagnosis for patients 
table1, by(remoteness) vars(psa_cat cat \ result_value_cleaned conts \ result_timing conts) missing
tabstat result_timing, s(min max mean median)


** Association between PSA and stage 
table1_mc, by(remoteness) vars(stage cat) missing
gen exclude = 1  if prostate_yr >= 2020 | prostate_yr <=2010

table1_mc if exclude !=1, by(remoteness) vars(stage cat) missing
table1 if exclude !=1, by(remoteness) vars(stage cat)

*combined
table1_mc if exclude !=1 , by(psa_cat) vars(stage cat) missing
*metro
table1 if exclude !=1 & remoteness == 1, by(psa_cat) vars(stage cat)
*regional
table1 if exclude !=1 & remoteness == 0, by(psa_cat) vars(stage cat)

*combined
preserve 
table1, by(stage) vars(result_value_cleaned conts) 
graph box result_value_cleaned if stage !=., over(stage)
restore 

//outliers?
tabstat result_value_cleaned, s(min max)
br if result_value_cleaned >400

table1, by(psa_cat) vars(stage cat) 
xi: regress  result_value_cleaned i.stage
test _Istage_2 _Istage_3 _Istage_4

**** Last PSA before diagnosis for patients with PSA result in the year before diagnosis ****
preserve 
keep if result_timing <=365 
table1, by(remoteness) vars(psa_cat cat \ result_value_cleaned conts \ result_timing conts) missing
tabstat result_timing, s(min max mean median)
restore 



*** Association between PSA and gleason 
//use final_cohort, clear
//keep e_linkedpersonid gleason stage age_diagnosis_group ageatdiagnosis
//duplicates drop
//mmerge e_linkedpersonid using final_cohort
//keep if _m ==3
//codebook e_linkedpersonid

//psa at last test association with stage 
//can only include patients diagnosed 2011 - 2019
gen gleason2 = . 
recode gleason2 .=1 if gleason <=6
recode gleason2 .=2 if gleason == 7 
recode gleason2 .=3 if gleason >=8 & gleason !=. 
replace gleason2 =. if gleason == 11
label define gleason2 1"Low grade <=6" 2"Intermediate = 7" 3"High grade >=8" 
label values gleason2 gleason2 


table1 if exclude !=1, by(psa_cat) vars(gleason2 cat)
*metro 
table1 if exclude !=1 & remoteness == 1, by(gleason2) vars(result_value_cleaned conts)
table1 if exclude !=1 & remoteness == 1, by(gleason2) vars(psa_cat cat)

*regional 
table1 if exclude !=1 & remoteness == 0, by(gleason2) vars(result_value_cleaned conts)
table1 if exclude !=1 & remoteness == 0, by(gleason2) vars(psa_cat cat)

*correlation between psa and gleason 
drop if exclude ==1
drop if totalgleason == . 
spearman result_value_cleaned totalgleason

*Spearman's rho = 0.3907 --> moderation correlation between PSA and gleason 



spearman result_value_cleaned totalgleason if remoteness == 0 
spearman result_value_cleaned totalgleason if remoteness == 1

*cohort includes patients with non-missing gleason, and only those diagnosed 2010 - 2020 


***********************************************************************
*** Association between diagnostic delay and gleason at diagnosis 
*time from first abnormal PSA to diagnosis 
** First abnormal PSA result 
use psa_2year, clear


*PSA categories 
gen psa_cat = . 
recode psa_cat (.=1) if result_value_cleaned < 10 
recode psa_cat (.=2) if result_value_cleaned >= 10 &  result_value_cleaned <20
recode psa_cat (.=3) if result_value_cleaned >= 20 &  result_value_cleaned !=.
label define cat 1"<10" 2"10-20" 3">20"
label values psa_cat cat

keep e_linkedpersonid result_value_cleaned remoteness result_date diagnosis_date result_timing psa_cat

duplicates drop 
duplicates tag e_linkedpersonid result_date, gen(dup)

*More than 1 result on the same day -- which do we keep? an average? for now keep highest  
gsort e_linkedpersonid result_date -result_value_cleaned
duplicates drop e_linkedpersonid result_date, force

drop dup

*Flag the PSA test which occurred last (before diagnosis)
bysort e_linkedpersonid: egen min_count = min(result_timing)

gen last_psa = 1 if min_count == result_timing

duplicates tag e_linkedpersonid last_psa, gen(dup)
drop dup 


//// first abnormal PSA in the 5 years before diagnosis 









tabstat result_timing, s(min max median p25 p75)
gen time_diagnosis = 1 if result_timing <=30 
recode time_diagnosis .=2 if result_timing >30 & result_timing <=60
recode time_diagnosis .=3 if result_timing >60 & result_timing <=90
recode time_diagnosis .=4 if result_timing >90 & result_timing != . 

label define timing 1"<=30 days" 2"31-60 days" 3"61-90 days" 4">91 days"
label values time_diagnosis timing


table1, by(remoteness) vars(time_diagnosis conts)




****** Kaplan Meier survival analysis ***** 
** Association between PSA at diagnosis and survival 
*keep the last PSA result before diagnosis for each patient 
use psa_2year, clear

**merge back info from VCR: stage, date of death, cause of death 
preserve 
use final_cohort_psa, clear
keep e_linkedpersonid deathcause stagederived nodespositive tnmm tnmn tnmt e_birthdate e_deathdate totalgleason stage gleason prostate_yr prostate_date
duplicates drop
save cohort_temp, replace
restore 

mmerge e_linkedpersonid using cohort_temp 
keep if _m == 3 


*PSA categories 
gen psa_cat = . 
recode psa_cat (.=1) if result_value_cleaned < 10 
recode psa_cat (.=2) if result_value_cleaned >= 10 &  result_value_cleaned <20
recode psa_cat (.=3) if result_value_cleaned >= 20 &  result_value_cleaned !=.
label define cat 1"<10" 2"10-20" 3">20"
label values psa_cat cat

keep e_linkedpersonid result_value_cleaned remoteness result_date diagnosis_date result_timing psa_cat totalgleason gleason stagederived stage deathcause e_deathdate prostate_yr prostate_date

duplicates drop 
duplicates tag e_linkedpersonid result_date, gen(dup)

*More than 1 result on the same day -- which do we keep? an average? for now keep highest  
gsort e_linkedpersonid result_date -result_value_cleaned
duplicates drop e_linkedpersonid result_date, force

drop dup

*Flag the PSA test which occurred last (before diagnosis)
bysort e_linkedpersonid: egen min_count = min(result_timing)

gen last_psa = 1 if min_count == result_timing

duplicates tag e_linkedpersonid last_psa, gen(dup)
drop dup 


**Stage at diagnosis 


*Keep last PSA before diagnosis 
keep if last_psa == 1 
duplicates drop
// 1277 regional, 1193 metro 

*Death date
gen deathdate = date(e_deathdate, "DMY" )
format deathdate %td

** 5 year survival 
// years from diagnosis to death 
gen diag_death = (deathdate - diagnosis_date) / 365.25

// 5 year follow up time 
gen enddate = diagnosis_date + 365*5 + 1
format enddate %td

egen end_date = rowmin(deathdate enddate)
format end_date %td

gen survival_time = (end_date - diagnosis_date) / 365.25

replace survival_time = round(survival_time, 0.1)

gen status = 0 if survival_time ==5
replace status = 1 if survival_time <5 & (deathcause == "ZNCD" | deathcause == "ZUNK")
replace status = 2 if survival_time <5 & (deathcause != "ZNCD" & deathcause != "ZUNK" & deathcause != "")

label define status 0"Alive" 1"Deceased - non cancer" 2"Deceased - cancer"
label values status status 


label var status "5-year survival status"


** Association between region and survival 
stset survival_time, failure(status = 1,2)
sts graph, by(remoteness) name(all_cause, replace) subtitle("All cause")

stset survival_time, failure(status == 2)
sts graph, by(remoteness) name(cancer, replace) subtitle("Cancer")

graph combine all_cause cancer

stset survival_time, failure(status == 2)
sts test remoteness


** Association between stage and survival 
// metro 
stset survival_time, failure(status = 1,2)
sts graph if remoteness ==1, by(stage) name(all_cause_metro, replace) subtitle("All cause")

stset survival_time, failure(status == 2)
sts graph if remoteness ==1, by(stage) name(cancer_metro, replace) subtitle("Cancer")

// regional 
stset survival_time, failure(status = 1,2)
sts graph if remoteness ==0, by(stage) name(all_cause_regional, replace) subtitle("All cause")

stset survival_time, failure(status == 2)
sts graph if remoteness ==0, by(stage) name(cancer_regional, replace) subtitle("Cancer")

graph combine all_cause_metro cancer_metro all_cause_regional cancer_regional

sts test stage

graph save "Graph" "Z:\Prostate_102023\output\stage_region_survival.gph", replace



**PSA and survival 
//metro
stset survival_time, failure(status = 1,2)
sts graph if remoteness ==1, by(psa_cat) name(all_cause_metro, replace) subtitle("All cause")

stset survival_time, failure(status == 2)
sts graph if remoteness ==1, by(psa_cat) name(cancer_metro, replace) subtitle("Cancer")

// regional 
stset survival_time, failure(status = 1,2)
sts graph if remoteness ==0, by(psa_cat) name(all_cause_regional, replace) subtitle("All cause")

stset survival_time, failure(status == 2)
sts graph if remoteness ==0, by(psa_cat) name(cancer_regional, replace) subtitle("Cancer")

graph combine all_cause_metro cancer_metro all_cause_regional cancer_regional

sts test psa_cat remoteness

graph save "Graph" "Z:\Prostate_102023\output\psa_region_survival3.gph", replace




// combined regional metro on one graph 
stset survival_time, failure(status = 1,2)
sts graph, by(remoteness psa_cat ) name(all_cause, replace) subtitle("All cause")

stset survival_time, failure(status == 2)
sts graph, by(remoteness psa_cat ) name(cancer, replace) subtitle("Cancer")

graph combine all_cause cancer

sts test remoteness psa_cat

graph save "Graph" "Z:\Prostate_102023\output\psa_survival.gph", replace













/*








use psa_2year, clear
mmerge e_linkedpersonid using final_cohort

keep if _m ==3

gsort e_linkedpersonid result_date -result_value_cleaned
duplicates drop e_linkedpersonid result_date, force

drop dup

*Flag the PSA test which occurred last (before diagnosis)
bysort e_linkedpersonid: egen min_count = min(result_timing)

gen last_psa = 1 if min_count == result_timing

duplicates tag e_linkedpersonid last_psa, gen(dup)
drop dup 


*Keep last PSA before diagnosis 
keep if last_psa == 1 


gen gleason2 = . 
recode gleason2 .=1 if gleason <=6
recode gleason2 .=2 if gleason == 7 
recode gleason2 .=3 if gleason >=8 & gleason !=. 
replace gleason2 =. if gleason == 11
label define gleason2 1"Low grade <=6" 2"Intermediate = 7" 3"High grade >=8" 
label values gleason2 gleason2 


gen exclude = 1  if prostate_yr >= 2020 | prostate_yr <=2010
drop if exclude ==1
drop if totalgleason == . 





























