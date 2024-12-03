*********************************************************************************
********* descriptive analysises of prostate cancer cohort****************************
*********************************************************************************

* created by Meena Rafiq on 15/01/2024
* last modified by Meena Rafiq on 06/03/2024

*********************************************************************************
*** STEPS

* 1.) Identify all patients with a prostate cancer diagnosis in VCR (malignant) who are linked to patron (at any point) and have >=1 non-admin GP encounter in the year before cancer diagnosis (OW completed)
* 2.) Extract and clean all PSA and free-to-total PSA ratio blood tests from patron (AL done) 
* 3.) Only keep PSA tests for the VCR active cohort (but also keep patients without any tests) (AL done)
* 4.) Descriptives of final cohort: number, age, SEIFA, ARIA, tumour stage, year of diagnosis, gleason, other. (done)
* 5.) cohort descriptives by aria status ?rural vs regional ? other categories (done)
* 6.) blood test descriptives (RURAL vs REGIONAL) (%) with any PSA (and number of tests), abnormal psa, psa ratio, abn ratio, abn psa + abn ratio, 
* 7.) descriptives of fu diagnostic activity (RURAL Vs REGIONAL) : ratio done after abnormal psa, rept psa test after abn psa, timing of repeat test after 1st abnormal
* 8.) average blood test results (PSA and ratio) (RURAL vs REGIONAL)


*********************************************************************************
*files:

* VCR_Patron_Cohort = all patients with a prostate ca diagnosis in VCR with at least 1 GP encounter (non-admin) in the year before cancer diagnosis *n=4423
* psa_cleaned_07022024 = all psa tests in patron (cleaned)
* VCR_Patron_Cohort_with_RA_PSA = all patients with a prostate ca diagnosis in VCR with at least 1 GP encounter (non-admin) in the year before cancer diagnosis + RA + PSA values
*sa2_best_ra = the bestmatch RA for each SA2 (using highest % of patients in each RA if >1 RA for SA2)
*final_cohort= one row per patient of all patients with a prostate ca diagnosis in VCR with at least 1 GP encounter (non-admin) in the year before cancer diagnosis *n=4417 + best RA code
*final_cohort_psa= all psa results for all patients with a prostate ca diagnosis in VCR with at least 1 GP encounter (non-admin) in the year before cancer diagnosis *n=4417 + best RA code
*final_cohort_psa_concise= all psa tests for the final cohort with remoteness and prostate ca dx date only n=4417

*psa_5year = all psa results in the 5 years before cancer diagnosis (n=2,588)
*psa_2year = all psa results in the 2 years before cancer diagnosis (n=2,470)
*psa_1year = all psa results in the 1 years before cancer diagnosis (n=2,328)

*psa_2year_register = e_linkedpersonids for 2470 patients with a psa in the 2 years before prostate cancer diagnosis

*********************************************************************************
 
cd "E:\projects\Prostate_102023\data"
cd "Z:\Prostate_102023\data"
*********************************************************************************
* 1.) Identify all patients with a prostate cancer diagnosis in VCR (malignant) who are linked to patron (at any point) and have >=1 non-admin GP encounter in the year before cancer diagnosis (OW completed)
*********************************************************************************
save VCR_Patron_Cohort, replace
codebook e_linkedpersonid
*n=4423
clear all
save psa_cleaned_07022024, replace
codebook 

save vca_patron_cohort_with_ra_psa, replace
codebook e_linkedpersonid
rename sa2_main16 diagnosis_sa2_2016
sort diagnosis_sa2_2016
save sa2_best_ra, replace
*apply best RA code as currently multiple RA codes per e_linkedpersonid
use vca_patron_cohort_with_ra_psa, clear
drop ra_code ra_name
merge m:1 diagnosis_sa2_2016 using sa2_best_ra
drop if _m==2
*6 patients do not have a diagnosis sa2 -> drop them
drop if _m==1
drop _m
codebook e_linkedpersonid
*n=4417
save final_cohort_psa, replace

keep e_linkedpersonid diagnosis_sa2_2016 ageatdeath ageatdiagnosis deathcause diagnosis_seifa_quintle diagnosis_seifa_yr morphology stagederived tnmm tnmn tnmt e_birthdate e_deathdate prostate_date totalgleason prostate_yr diag_age visits ra_best

duplicates drop
save final_cohort, replace

*********************************************************************************
* 4.) Descriptives of final cohort: number, age, SEIFA, ARIA, tumour stage, year of diagnosis, gleason, other. (done)
* 5.) cohort descriptives by aria status ?rural vs regional ? other categories (done)
********************************************************************************

tab ra_best
gen remoteness =.
recode remoteness (.=1) if ra_best=="Major Cities of Australia"
recode remoteness (.=0) if ra_best =="Outer Regional Australia"
recode remoteness (.=0) if ra_best =="Inner Regional Australia"
lab define remoteness 1"major city" 0"regional"
lab val remoteness remoteness
gen age_diagnosis_group=.
recode age_diagnosis_group (.=0) if ageatdiagnosis=="35-39"
recode age_diagnosis_group (.=0) if ageatdiagnosis=="40-44"
recode age_diagnosis_group (.=0) if ageatdiagnosis=="45-49"
recode age_diagnosis_group (.=1) if ageatdiagnosis=="50-54"
recode age_diagnosis_group (.=1) if ageatdiagnosis=="55-59"
recode age_diagnosis_group (.=2) if ageatdiagnosis=="60-64"
recode age_diagnosis_group (.=2) if ageatdiagnosis=="65-69"
recode age_diagnosis_group (.=3) if ageatdiagnosis=="70-74"
recode age_diagnosis_group (.=3) if ageatdiagnosis=="75-79"
recode age_diagnosis_group (.=4) if ageatdiagnosis=="80-84"
recode age_diagnosis_group (.=4) if ageatdiagnosis=="85+"
lab define age_diagnosis_group 0"35-49" 1"50-59" 2"60-69" 3"70-79" 4">=80"
lab val age_diagnosis_group age_diagnosis_group

lab define diagnosis_seifa_quintle 1 "1 - most deprived" 2"2" 3"3" 4"4" 5"5- least deprived"
lab val diagnosis_seifa_quintle diagnosis_seifa_quintle

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

gen gleason=totalgleason
recode gleason (0/6=6)
recode gleason (.=11)
lab define gleason 6"1-6" 7"7" 8"8" 9"9" 10"10" 11"missing"
lab val gleason gleason

gen gp_visits=visits
recode gp_visits (2/5=2)(6/10=3)(10/15=4)(16/2000=5)
lab define gp_visits 1"1" 2"2-5" 3"6-10" 4"10-15" 5">=16"
lab val gp_visits gp_visits

save final_cohort, replace

use final_cohort, clear

log on
tab ra_best
tab remoteness 
tab sa2_name16, sort

*demographics
tab remoteness ageatdiagnosis, row chi
tab remoteness age_diagnosis_group, row chi
bysort remoteness: summ diag_age, detail
tab remoteness diagnosis_seifa_quintle, row chi
*1=low SES 5=high SES IRSD

*tumour characteristics
tab remoteness stagederived, row chi
tab remoteness stage, row chi
tab remoteness totalgleason, row chi missing
tab remoteness gleason, row chi
tab remoteness morphology, row chi

*GP encounters
tab remoteness visits, row chi
tab remoteness gp_visits, row chi

*outcomes
tab remoteness ageatdeath, row chi
log off

*graphs
 twoway histo diagnosis_seifa_quintle, percent by(remoteness) xlabel(1 2 3 4 5, valuelabel)
  twoway histo diagnosis_seifa_quintle, percent 
  twoway histo age_diagnosis_group, frequ by(remoteness) xlabel(0 1 2 3 4 , valuelabel)
twoway histo stage, percent by(remoteness)
twoway histo gleason, percent by(remoteness) xlabe(6 7 8 9 10 11, valuelabel)
twoway histo visits, percent by(remoteness)
twoway histo gp_visits, percent by(remoteness) xlab(1 2 3 4 5, valuelabel)

**********************************************************************************
** 6.) blood test descriptives (RURAL vs REGIONAL) (%) with any PSA (and number of tests), abnormal psa, psa ratio, abn ratio, abn psa + abn ratio,
*********************************************************************************
*identify how many patients have a PSA test in the year before diagnosis

use final_cohort_psa, clear
*add the derived variables created above
merge m:1 e_linkedpersonid using final_cohort
drop _m
save final_cohort_psa, replace
*n-4417
*variables of interest = e_result_date, result_value_cleaned result_name_cleaned
foreach var of varlist e_result_date {
	split `var', p("")
	drop `var'2
	gen result_date = date(`var'1, "MDY")
	format result_date %td
	drop `var'
	drop `var'1
}

keep e_linkedpersonid prostate_date remoteness result_numeric result_units result_value_cleaned result_name result_name_cleaned result_date

save final_cohort_psa_concise, replace
*************************************************************************
* clean pathology data
***************************************************************************
*clean result name
drop result_name_cleaned
tab result_name
gen PSA=.
recode PSA (.=1) if result_name=="PROSTATESPECIFICAG(PSA)"
recode PSA (.=1) if result_name=="PROSTATESPECIFICANTIGEN"
recode PSA (.=1) if result_name=="PROSTATICSPECIFICANTIGEN"
recode PSA (.=1) if result_name=="PSA"
recode PSA (.=1) if result_name=="PSA(1PER12MONTHS)"
recode PSA (.=1) if result_name=="PSA(4PER12MONTHS)"
recode PSA (.=1) if result_name=="PSA(ARCHITECT)"
recode PSA (.=1) if result_name=="PSA(CENTAUR)"
recode PSA (.=1) if result_name=="PSA(COBAS)"
recode PSA (.=1) if result_name=="PSA(EQUIMOLAR)"
recode PSA (.=1) if result_name=="PSA(IMMULITE)"
recode PSA (.=1) if result_name=="PSA,TOTAL"
recode PSA (.=1) if result_name=="PSA-SUSPECTEDDISEASE"
recode PSA (.=1) if result_name=="PSAALINITY"
recode PSA (.=1) if result_name=="TOTALPSA"
recode PSA (.=1) if result_name=="TOTALPSA(ACCESS)"
rename PSA psa

gen freepsa=.
recode freepsa(.=1) if result_name=="FREEPSA(CALC)"
recode freepsa(.=1) if result_name=="FREEPSA(MEASURED)"
recode freepsa(.=1) if result_name=="SFREEPSA:"
recode freepsa(.=1) if result_name=="FREEPSA"
recode freepsa(.=1) if result_name=="FREEPSA(ACCESS)"
recode freepsa(.=1) if result_name=="FREEPSA(CENTAUR)"
recode freepsa(.=1) if result_name=="FREEPSA(IMMULITE)"

gen psa_ratio=.
recode psa_ratio(.=1) if result_name=="%FREEPSA"
recode psa_ratio(.=1) if result_name=="F/TPSARATIO"
recode psa_ratio(.=1) if result_name=="FREEPSARATIO"
recode psa_ratio(.=1) if result_name=="FREE/TOTALPSARATIO:"
recode psa_ratio(.=1) if result_name=="FREE:TOTALPSA(CENTAUR)"
recode psa_ratio(.=1) if result_name=="FREE:TOTALPSA(IMMULITE)"
recode psa_ratio(.=1) if result_name=="FREEPSA/PSARATIO"

gen complexedpsa=.
recode complexedpsa (.=1) if result_name=="COMPLEXEDPSA"

drop if result_name=="P2PSA(ACCESS)"


save final_cohort_psa_concise, replace

use final_cohort_psa_concise, clear

*only keep blood tests before the diagnosis date
gen diagnosis_date=date(prostate_date, "DMY")
format diagnosis_date %td
drop prostate_date
recode psa(.=0)
recode freepsa (.=0)
recode psa_ratio(.=0)

keep if result_date<=diagnosis_date |result_date==.

collapse (max)remoteness (sum) psa (sum) freepsa (sum) psa_ratio (max) diagnosis_date, by(e_linkedpersonid)
*re-add patients who only had psa after dx 
merge m:1 e_linkedpersonid using final_cohort

keep e_linkedpersonid remoteness psa freepsa psa_ratio
recode psa(.=0)
recode freepsa (.=0)
recode psa_ratio(.=0)
*lab define remoteness 1"major city" 0"regional"
lab val remoteness remoteness
********************************************************************************
* number of patients with a PSA test
********************************************************************************
gen psa_any=psa
recode psa_any (2/100=1)
gen psa_num=psa
recode psa_num (2/100=2)
lab define psa_num 0"0" 1"1" 2"<=2"
lab val psa_num psa_num

gen freepsa_num=freepsa
recode freepsa_num (2/100=2)
lab define freepsa_num 0"0" 1"1" 2"<=2"
lab val freepsa_num freepsa_num

gen psa_ratio_num=psa_ratio
recode psa_ratio_num (2/100=2)
lab define psa_ratio_num 0"0" 1"1" 2"<=2"
lab val psa_ratio_num psa_ratio_num


tab psa_any
*2667 patients
tab psa_num
tab psa
tab freepsa
*1014 patients
tab freepsa_num
tab psa_ratio
tab psa_ratio_num
*1188 patients
gen error=1 if freepsa!=0 & psa_ratio==0
*1 patient has a free psa but no ratio
drop error

tab remoteness psa_num, row chi
tab remoteness psa_any, row chi
tab remoteness psa_ratio_num, row chi

bysort remoteness: sum psa, detail

twoway histo psa, freq
twoway histo psa, freq by(remoteness)

*********************************************************************************
* examining abnormal PSA results. note definition changed in 2016
* 	a.) flag abnormal result >3, >4, >10, >50
*	b.) calculate average PSA result
*	c.) for patients with a PSA after 2016 look at number with a repeat after PSA >3
*	d.) for patients with a PSA after 2016 AND >3 AND a repeat look at interval between repeats
*	e.) average time from first abnormal psa to cancer diagnosis
*	f.) dx window analysis: test requests and abnormal results
********************************************************************************

use final_cohort_psa_concise, clear
*only keep total PSA results
keep if psa==1
codebook e_linkedpersonid
*36,442 results in 3252 patients

*only keep blood tests before the diagnosis date
gen diagnosis_date=date(prostate_date, "DMY")
format diagnosis_date %td
drop prostate_date
drop freepsa psa_ratio complexedpsa

keep if result_date<=diagnosis_date 
codebook e_linkedpersonid
*13,926 results in 2,667 patients

*only keep blood tests in the 5 years before the diagnosis date
gen psa_over3=.
recode psa_over3(.=1) if result_value_cleaned>3
recode psa_over3 (.=0)
gen result_timing=(diagnosis_date-result_date)
gsort-psa_over3 -result_timing
gen result_year =year(result_date)
gen result_timing_year = result_timing
recode result_timing_year (0/365=1)(366/731=2)(732/1096=3)(1097/1461=4)(1462/1826=5)(1827/20000=6)
lab define result_timing_year 1"-1 year" 2"-2 years" 3"-3 years" 4"-4 years" 5"-5 years" 6">-5years"
lab val result_timing_year result_timing_year
twoway histo result_timing_year, by(psa_over3)

drop if result_timing_year==6
codebook e_linkedpersonid
*10,401 results in 2,588 patients

*flag abnormal results using different thresholds >3, >4, >10 >50
gen psa_over4=0
recode psa_over4 (0=1) if result_value_cleaned>4

gen psa_over10=0
recode psa_over10 (0=1) if result_value_cleaned>10

gen psa_over20=0
recode psa_over20 (0=1) if result_value_cleaned>20

gen psa_over50=0
recode psa_over50 (0=1) if result_value_cleaned>50

preserve
keep if psa_over3==1
twoway histo result_timing_year, frequency by(remoteness)
restore

preserve
keep if psa_over4==1
twoway histo result_timing_year, frequency by(remoteness)
restore

preserve
keep if psa_over10==1
twoway histo result_timing_year, frequency by(remoteness)
restore

preserve
keep if psa_over20==1
twoway histo result_timing_year, frequency by(remoteness)
restore

save psa_5year, replace

drop if result_timing_year>=3
save psa_2year, replace

drop if result_timing_year>=2
save psa_1year, replace
codebook e_linkedpersonid


*********************************************************************************
*linear regression to test relationship between psa count and time
*********************************************************************************
use psa_5year, clear
*gen days to diagnosis var
gen psa_days = diagnosis_date-result_date 
gen psa_days2 = result_date-diagnosis_date


*scatterplot
twoway (scatter result_value_cleaned psa_days2, msymbol(p))(lfit result_value_cleaned psa_days2), ytitle(psa level (x10*9/L))xtitle(Days from test to cancer diagnosis) by(remoteness)

*drop outliers
drop if result_value_cleaned>20

*scatterplot without outliers
preserve
keep if remoteness==0
twoway (scatter result_value_cleaned psa_days2, msymbol(p))(lfit result_value_cleaned psa_days2), ytitle(psa level (x10*9/L))xtitle(Days from test to cancer diagnosis) 
restore

preserve
keep if remoteness==1
twoway (scatter result_value_cleaned psa_days2, msymbol(p))(lfit result_value_cleaned psa_days2), ytitle(psa level (x10*9/L))xtitle(Days from test to cancer diagnosis) 
restore
**********************************************************************************
* descriptives of PSA tests in the 6, 12, 18 and 24 months before prostate cancer diagnosis
**********************************************************************************

use psa_2year, clear
codebook e_linkedpersonid
*6,787 psa tests in 2470 patients
sort e_linkedpersonid result_date
gen period=result_timing
recode period (0/182=1)(183/365=2)(366/548=3)(549/731=4)
lab var period "time before cancer diagnosis"
lab define period 1"0-6 months" 2"6-12 months" 3"12-18 months" 4"18-24 months"
lab value period period
save psa_2year, replace

bysort e_linkedpersonid period: gen number_tests=_N

bysort remoteness period: summ number_tests, detail

gen number_tests_gp=number_tests
recode number_tests_gp(1=1)(2=2)(3/100=3)
lab define number_tests_gp 1"1" 2"2" 3">=3"
lab val number_tests_gp number_tests_gp

//log on
bysort remoteness: tab period number_tests_gp, row
//log off

use psa_2year, clear
bysort e_linkedpersonid period: gen number_tests=_N

foreach x of numlist 1 2 3 4 {
	gen period`x'=.
	recode period`x'(.=1) if period==`x'
}
save psa_2year, replace

keep e_linkedpersonid
duplicates drop
save psa_2year_register, replace

********************************************************************************
*cohort descriptives psa 2 year
********************************************************************************
use final_cohort_psa, clear
merge m:1 e_linkedpersonid using psa_2year_register
keep if _m==3
drop _m

keep e_linkedpersonid remoteness diag_age stage gleason age_diagnosis_group diagnosis_seifa_quintle prostate_yr
duplicates drop

//log on
tab remoteness
bysort remoteness: summ diag_age, detail
tab stage remoteness, miss col chi
tab gleason remoteness, miss col chi
tab age_diagnosis_group remoteness, miss col chi
tab diagnosis_seifa_quintle remoteness, miss col chi
//log off


gen gleason2 = . 
recode gleason2 .=1 if gleason <=6
recode gleason2 .=2 if gleason == 7 
recode gleason2 .=3 if gleason >=8 & gleason !=. 
replace gleason2 =. if gleason == 11
label define gleason2 1"Low grade <=6" 2"Intermediate = 7" 3"High grade >=8" 
label values gleason2 gleason2 

table1, by(remoteness) vars(age_diagnosis_group cat \ diag_age contn \ diagnosis_seifa_quintle cat \ gleason cat \ gleason2 cat \ stage cat \ prostate_yr cat) missing

drop if prostate_yr >= 2020 | prostate_yr <=2010
table1, by(remoteness) vars(prostate_yr cat \ gleason2 cat \ stage cat) missing

********************************************************************************
*test use descriptives psa 2 year
********************************************************************************
use psa_2year, clear

*collapse to one row per patient for descriptives
collapse (max)remoteness (max) diagnosis_date (sum)psa (sum)period1 (sum)period2 (sum)period3 (sum)period4 (max)psa_over3 (max)psa_over4 (max)psa_over10  (max)psa_over20 (max)psa_over50    , by(e_linkedpersonid)
*n=2470
*lab define remoteness 1"major city" 0"regional"
lab val remoteness remoteness

gen diagnosis_year = year(diagnosis_date)
gen diagnosis_year_gp=diagnosis_year
recode diagnosis_year_gp(2008/2011=1)(2012/2015=2)(2016/2019=3)(2020/2022=4)
//log on
tab diagnosis_year_gp remoteness, miss col chi
//log off

foreach x of numlist 1 2 3 4 {
gen test_period`x'=period`x'
recode test_period`x'(1/1000=1)
}

gen test_any=psa
recode test_any(1/10000=1)


//log on
foreach x of numlist 1 2 3 4 {
tab test_period`x' remoteness, col chi
}
tab test_any remoteness, col chi

bysort remoteness: summ psa, detail

foreach x of numlist 1 2 3 4 {
bysort remoteness: summ period`x', detail
}

tab psa_over3 remoteness, col chi
tab psa_over4 remoteness, col chi
tab psa_over10 remoteness, col chi
tab psa_over20 remoteness, col chi
tab psa_over50 remoteness, col chi
//log off

*******abnormal PSA descriptives

use psa_2year, clear

foreach x of numlist 1 2 3 4 {
	gen psa_3_`x'= psa_over3 if period==`x'
	gen psa_4_`x'= psa_over4 if period==`x'
	gen psa_10_`x'= psa_over10 if period==`x'
	gen psa_20_`x'= psa_over20 if period==`x'
	gen psa_50_`x'= psa_over50 if period==`x'
}

save psa_2year, replace

collapse (max)remoteness (max) diagnosis_date  (max)psa_3_* (max)psa_4_* (max)psa_10_* (max)psa_20_* (max)psa_50_* , by(e_linkedpersonid)
lab val remoteness remoteness
//log on


foreach x of numlist 1 2 3 4 {
tab psa_3_`x' remoteness, col chi
tab psa_4_`x' remoteness, col chi
tab psa_10_`x' remoteness, col chi
tab psa_20_`x' remoteness, col chi
tab psa_50_`x' remoteness, col chi

}

bysort remoteness: summ result_value_cleaned, detail

//log off


use psa_2year, clear
duplicates drop
*5555 results for 2470 patients

foreach x of numlist 1 2 3 4 5{
	gen result_`x'= result_value_cleaned if period==`x'
}


collapse (max)remoteness (max) diagnosis_date (median)result_value_cleaned  (median)result_1 (median)result_2 (median)result_3 (median)result_4  median(result_5) , by(e_linkedpersonid)
lab val remoteness remoteness
//log on

bysort remoteness: summ result_value_cleaned, detail
bysort remoteness: summ result_1, detail
bysort remoteness: summ result_2, detail
bysort remoteness: summ result_3, detail
bysort remoteness: summ result_4, detail
bysort remoteness: summ result_5, detail

//log off

********************************************************************************
* repeat PSA test after an abnormal PSA result
********************************************************************************

use psa_2year, clear
duplicates drop
save psa_2year, replace

use psa_2year, clear

sort e_linkedpersonid result_date
bysort e_linkedpersonid: gen result_order=_n
bysort e_linkedpersonid: gen result_number=_N

foreach x of numlist 3 4 10 20 50 {
bysort e_linkedpersonid: gen repeat_over`x'=1 if psa_over`x'==1 & (result_order[_n+1]>result_order) & result_order[_n+1]!=.

bysort e_linkedpersonid: gen repeat_interval_over`x'=(result_date[_n+1]-result_date) if repeat_over`x'==1

recode repeat_over`x'(1=.) if repeat_interval_over`x'==0
recode repeat_interval_over`x'(0=.)

gen repeat_3m_over`x'=1 if repeat_interval_over`x'<92
}

collapse (max)remoteness (max) psa_over* (max) repeat_over*  (max) repeat_3m* (median) repeat_int* , by(e_linkedpersonid)
lab val remoteness remoteness
//log on

foreach x of numlist 3 4 10 20 50 {
bysort remoteness: tab psa_over`x' repeat_over`x', miss row
bysort remoteness: tab psa_over`x' repeat_3m_over`x', miss row
bysort remoteness: summ repeat_interval_over`x', detail
}
//log off

*********************************************************************************
* days from 1st abnormal PSA result (using different definitions) to cancer diagnosis - box and whiskers plot
*********************************************************************************

foreach x of numlist 3 4 10 20 50 {
use psa_2year, clear
keep e_linkedpersonid psa_over`x' result_date remoteness diagnosis_date
keep if psa_over`x'==1
duplicates drop
*this is all abnormal results over "`x'"
sort e_linkedpersonid result_date
bysort e_linkedpersonid: gen result_order=_n
keep if result_order==1
gen diagnostic_interval_over`x'=(diagnosis_date-result_date)

keep e_linkedpersonid remoteness diagnostic_interval_over`x'
save diagnostic_interval_over`x', replace
}

use diagnostic_interval_over3, clear
merge m:1 e_linkedpersonid using diagnostic_interval_over4
drop _m
merge m:1 e_linkedpersonid using diagnostic_interval_over10
drop _m
merge m:1 e_linkedpersonid using diagnostic_interval_over20
drop _m
//merge m:1 e_linkedpersonid using diagnostic_interval_over50
//drop _m
save diagnostic_interval, replace

*use this in R to create box plots

*********************************************************************************
* diagnostic windows in PSA test requests and abnormal results (>3)
**********************************************************************************
clear all




