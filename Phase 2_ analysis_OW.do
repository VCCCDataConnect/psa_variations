******		PSA Project Phase 2 		******
*1. Median PSA before diagnosis, using last available PSA only 
*2. Association between PSA and Gleason at diagnosis 
*3. Association between diagnostic delay and Gleason at diagnosis 
*4. Association between PSA and survival 
*5. Association between diagnostic delay and survival 


cd "Z:\Prostate_102023\data"
************************** Last PSA test before diagnosis 
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


///////////////////////////////////////////////////////////

**** Association between psa and stage 
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


*Keep last PSA before diagnosis 
keep if last_psa == 1 

**Last PSA test before diagnosis for patients 
table1, by(remoteness) vars(psa_cat cat \ result_value_cleaned conts \ result_timing conts) missing
tabstat result_timing, s(min max mean median)




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

mmerge e_linkedpersonid using final_cohort

keep if _m ==3

codebook e_linkedpersonid

//psa at last test association with stage 
//can only include patients diagnosed 2011 - 2019
gen gleason2 = . 
recode gleason2 .=1 if gleason <=6
recode gleason2 .=2 if gleason == 7 
recode gleason2 .=3 if gleason >=8 & gleason !=. 
replace gleason2 =. if gleason == 11
label define gleason2 1"Low grade <=6" 2"Intermediate = 7" 3"High grade >=8" 
label values gleason2 gleason2 

gen exclude = 1  if prostate_yr >= 2020 | prostate_yr <=2010


table1 if exclude !=1, by(psa_cat) vars(gleason2 cat)
*metro 
table1 if exclude !=1 & remoteness == 1, by(psa_cat) vars(gleason2 cat)
*regional 
table1 if exclude !=1 & remoteness == 0, by(psa_cat) vars(gleason2 cat)

*correlation between psa and gleason 
drop if exclude ==1
drop if totalgleason == . 
spearman result_value_cleaned totalgleason

*Spearman's rho = 0.3907 --> moderation correlation between PSA and gleason 


*cohort includes patients with non-missing gleason, and only those diagnosed 2010 - 2020 


***********************************************************************
*** Association between diagnostic delay and gleason at diagnosis 
*time from first abnormal PSA to diagnosis 











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





























