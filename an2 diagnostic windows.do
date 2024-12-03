**************************************************************************
*
*	File to restrict PSA tests to study period (5 years before cancer diagnosis)
*	in CASES ONLY look at timing of test and flag by 1 month blocks
*	TO DO: CONSIDER APPROPRIATE COMPARISON GROUP AND IF NEEDED
*
*	created by Meena Rafiq 01/02/2022
*	updated by Meena Rafiq on 06/03/2022
*********************************************
*files: psa_5year: contains all psa tests in patron for prostate cancer patients in VCR with a GP encounter in the year before diagnosis and a PSA test in the 5 years before cancer diagnosis n=2588
*********************************************
****
*********NB can use edit> find > replace to alter this code for different blood tests
****

cd "E:\projects\Prostate_102023\data"

use psa_2year, clear
keep e_linkedpersonid remoteness psa_over3 psa result_date diagnosis_date
duplicates drop
*this file contains all the psa tests for individuals in the cohort
*8432 observations
*********************************************************************************
*restricting event dates to study follow up time
*********************************************************************************
*drop any events after the end dates
keep if result_date<=diagnosis_date
*8432 events left

*********************************************************************************
*keep only events that happened up to 2 years before diagnosis diagnosis 
*can adjust this later
*********************************************************************************
drop if result_date<(diagnosis_date-1827)
*8432 values left
sort e_linkedpersonid

save psa_2year_dw, replace

***********ALL prostate cancer PATIENTS WITH a psa TEST USE from 5 years before the diagnosis date are saved**********

*********************************************************************************
* OBJECTIVE 1: A.)	Examine the proportion of patients who have had a 
*primary care blood test (in cases and controls) in the 1 year before HL diagnosis
*********************************************************************************
*NB NEED TO DROP ANY TWO EVENT DATES ON THE SAME DAY AND ONLY KEEP 1
******************REMOVE DUPLICATES

use psa_2year_dw, clear
drop psa_over3
duplicates drop
duplicates report e_linkedpersonid result_date
*0 duplicate records on the same day


save psa_dw, replace

*******
**8428 observations
*******

******************
*case only analysis
*******************
*initially in CASE ONLY ANALYSIS we are interested in psa tests before diagnosis diagnosis

rename result_date eventdate

***Need to flag psa TEST (0/1) by 1m block and number of TESTS by 1m blocks for descriptive
*overall and by 1 month block for the 2 years before diagnosis
*can extend this later

*tag for -1m before diagnosis or not
*30.44d per month
gen psa_1m=1 if eventdate>=(diagnosis_date-30)
*tag for -2m before diagnosis or not
*only record patients who were followed up in that period
*30.44d per month (x2=61)
gen psa_2m=1 if eventdate<(diagnosis_date-30)
recode psa_2m (1=0) if eventdate<(diagnosis_date-61)
*tag for -3m before diagnosis or not
*30.44d per month (x3=91)
gen psa_3m=1 if eventdate<(diagnosis_date-61)
recode psa_3m (1=0) if eventdate<(diagnosis_date-91)
*tag for -4m before diagnosis or not
*30.44d per month (x4=122)
gen psa_4m=1 if eventdate<(diagnosis_date-91)
recode psa_4m (1=0) if eventdate<(diagnosis_date-122)
*tag for -5m before diagnosis or not
*30.44d per month (x5=152)
gen psa_5m=1 if eventdate<(diagnosis_date-122)
recode psa_5m (1=0) if eventdate<(diagnosis_date-152)
*tag for -6m before diagnosis or not
*30.44d per month (x6=183)
gen psa_6m=1 if eventdate<(diagnosis_date-152)
recode psa_6m (1=0) if eventdate<(diagnosis_date-183)
*tag for -7m before diagnosis or not
*30.44d per month (x7=213)
gen psa_7m=1 if eventdate<(diagnosis_date-183)
recode psa_7m (1=0) if eventdate<(diagnosis_date-213)
*tag for -8m before diagnosis or not
*30.44d per month (x8=244)
gen psa_8m=1 if eventdate<(diagnosis_date-213)
recode psa_8m (1=0) if eventdate<(diagnosis_date-244)
*tag for -9m before diagnosis or not
*30.44d per month (x9=274)
gen psa_9m=1 if eventdate<(diagnosis_date-244)
recode psa_9m (1=0) if eventdate<(diagnosis_date-274)
*tag for -10m before diagnosis or not
*30.44d per month (x10=304)
gen psa_10m=1 if eventdate<(diagnosis_date-274)
recode psa_10m (1=0) if eventdate<(diagnosis_date-304)
*tag for -11m before diagnosis or not
*30.44d per month (x11=335)
gen psa_11m=1 if eventdate<(diagnosis_date-304)
recode psa_11m (1=0) if eventdate<(diagnosis_date-335)
*tag for -12m before diagnosis or not
*30.44d per month (x12=365)
gen psa_12m=1 if eventdate<(diagnosis_date-335)
recode psa_12m (1=0) if eventdate<(diagnosis_date-365)
*tag for -13m before diagnosis or not
*30.44d per month (x13=396)
gen psa_13m=1 if eventdate<(diagnosis_date-365)
recode psa_13m (1=0) if eventdate<(diagnosis_date-396)
*tag for -14m before diagnosis or not
*30.44d per month (x14=426)
gen psa_14m=1 if eventdate<(diagnosis_date-396)
recode psa_14m (1=0) if eventdate<(diagnosis_date-426)

*tag for -15m before diagnosis or not
*30.44d per month (x15=457)
gen psa_15m=1 if eventdate<(diagnosis_date-426)
recode psa_15m (1=0) if eventdate<(diagnosis_date-457)
*tag for -16m before diagnosis or not
*30.44d per month (x16=487)
gen psa_16m=1 if eventdate<(diagnosis_date-457)
recode psa_16m (1=0) if eventdate<(diagnosis_date-487)
*tag for -17m before diagnosis or not
*30.44d per month (x17=517)
gen psa_17m=1 if eventdate<(diagnosis_date-487)
recode psa_17m (1=0) if eventdate<(diagnosis_date-517)
*tag for -18m before diagnosis or not
*30.44d per month (x18=548)
gen psa_18m=1 if eventdate<(diagnosis_date-517)
recode psa_18m (1=0) if eventdate<(diagnosis_date-548)
*tag for -19m before diagnosis or not
*30.44d per month (x19=578)
gen psa_19m=1 if eventdate<(diagnosis_date-548)
recode psa_19m (1=0) if eventdate<(diagnosis_date-578)
*tag for -20m before diagnosis or not
*30.44d per month (x20=609)
gen psa_20m=1 if eventdate<(diagnosis_date-578)
recode psa_20m (1=0) if eventdate<(diagnosis_date-609)
*tag for -21m before diagnosis or not
*30.44d per month (x21=639)
gen psa_21m=1 if eventdate<(diagnosis_date-609)
recode psa_21m (1=0) if eventdate<(diagnosis_date-639)
*tag for -22m before diagnosis or not
*30.44d per month (x22=670)
gen psa_22m=1 if eventdate<(diagnosis_date-639)
recode psa_22m (1=0) if eventdate<(diagnosis_date-670)
*tag for -23m before diagnosis or not
*30.44d per month (x23=700)
gen psa_23m=1 if eventdate<(diagnosis_date-670)
recode psa_23m (1=0) if eventdate<(diagnosis_date-700)
*tag for -24m before diagnosis or not
*30.44d per month (x24=731)
gen psa_24m=1 if eventdate<(diagnosis_date-700)
recode psa_24m (1=0) if eventdate<(diagnosis_date-731)

rename eventdate testdate

save psa24mdiagnosis, replace

*need to add in var for total number of crp tests per patient
gen startfu = (diagnosis_date-731)
format startfu %td
gen fu = (diagnosis_date-startfu)
summ fu, detail
*check range,
*range is 1-15

save psa24mdiagnosis, replace
*****this is a record of all the psa blood tests done in the 24m before diagnosis diagnosis date in diagnosis patients 

*******************************************************************************
*TIME CLEANING / DATA MANAGEMENT DONE
********************************************************************************

use psa24mdiagnosis, clear

sort e_linkedpersonid

rename psa event
*this contains all diagnosis patients in the cohort with flags for all those with a psa test in last 2 years
keep e_linkedpersonid remoteness testdate event diagnosis_date
duplicates drop
*keeps one e_linkedpersonid per patientid for merged patients
*******allocate startdate as latest of first recorded encounter in nps or diagnosis date -731 days

gen startdate = diagnosis_date-730
format startdate %td
sort e_linkedpersonid testdate
by e_linkedpersonid: gen start=testdate[_n-1]
replace start=startdate if start==.
format start %td
by e_linkedpersonid: gen stop=start[_n+1]
replace stop=diagnosis_date if stop==.
format stop %td
by e_linkedpersonid: gen error=1 if stop[_n-1]==stop
*no duplicates or errors
drop error
gsort e_linkedpersonid testdate
*MANUALLY check start and stop dates are correct by looking at one
*YES IT WORKS :)

gen diagnosis=1
tab event diagnosis
* 879 events (psa tests) in total 1389 obs
gen error=1 if start>=stop
gsort -error
drop if error==1
*drop tests on the day of study start
drop error
* 873 events (psa tests) in total 1383 obs
save psa24mdiagnosis_PR, replace

*now stset
use psa24mdiagnosis_PR, clear
keep e_linkedpersonid remoteness diagnosis_date testdate event startdate start stop 

stset stop, fail(event==1) origin(time (diagnosis_date-730)) time0(start) enter(time start) id(e_linkedpersonid) exit(time diagnosis_date) scale(30.4375)
*nb origin = diagnosis_date-731 to count back from diagnosis_date
*check 873 events in 855 diagnosis cases

strate

sort e_linkedpersonid testdate start
*now need to split time by 1 month periods from startdate to diagnosis_date.
stsplit period, every(1)
replace event=0 if event==.

*need to reallocate events to correct period

rename event event_old
gen event =1 if (testdate>=start)
recode event (1=0) if (testdate>stop)
recode event (.=0)
tab event
*check same number of events (873)
*there are 0 extra events where event occurs on the split and is counted twice
*gen error=1 if testdate==stop
*recode error (1=0) if _d==1
*gsort -error
*these are the 2 events


*manually reallocate these 3 events to the earliest time period
*sort epatid testdate start
*drop error
*tab event sex
*505 events
stset stop, fail(event==1) origin(time startdate) time0(start) enter(time start) id(e_linkedpersonid) exit(time diagnosis_date) scale(30.4375)
************************************re-stset with origin as startdate*************************************************
gen error=1 if _d!=event
gsort -error
*100% correlation, no errors
drop error


*nb each event may contribute different amounts of days to diff time periods but each patid will only contribute max 365.25x2 days in total.

*relabel period counting backwards from diagnosis diagnosis

sort e_linkedpersonid 

lab define period 0 "23-24 months" 1 "22-23 months" 2 "21-22 months" 3 "20-21 months" 4 "19-20 months" 5 "18-19 months" 6 "17-18 months" 7 "16-17 months" 8 "15-16 months" 9 "14-15 months" 10 "13-14 months" 11 "12-13 months" 12 "11-12 months" 13 "10-11 months" 14 "9-10 months" 15 "8-9 months" 16 "7-8 months" 17 "6-7 months" 18 "5-6 months" 19 "4-5 months" 20 "3-4 months" 21 "2-3 months" 22 "1-2 months" 23 "0-1 months"
lab val period period

save psa_incident_stset, replace



*********************************************************************************
*DESCRIPTIVES/ INCIDENCE RATES
*******************************************************************
tab event period, col
stset stop, fail(event==1) origin(time startdate) time0(start) enter(time start) id(e_linkedpersonid) exit(time diagnosis_date) scale(30.4375)
strate, per(1000)
strate period
strate period, per(1000)
log off

sort period

strate period, per(1000) output (psa_IR, replace)

preserve 
keep if remoteness==0
strate period, per(1000) graph 
restore

preserve 
keep if remoteness==1
strate period, per(1000) graph 
restore


*Now calculate incidence rate ratios for each time period e_linkedpersonidng poisson regression

log on
**********************************************************************************
*POISSON REGRESSION FOR IRR
***************************
*******************************************************************
stset stop, fail(event==1) origin(time startdate) time0(start) enter(time start) id(e_linkedpersonid) exit(time diagnosis_date) scale(30.4375)

streg, dist(exp) base
est store a
streg i.period, dist(exp) base
est store b
**********************************************************************************
*                  alternative models
******************NEGATIVE BINOMIAL REGRESSION**********
**********************************************************************************
streg i.period, dist(exp) base
*poisson
mepoisson event i.period||e_linkedpersonid:, irr base
*mixed effects poisson

************ inflection point

use psa_incident_stset, clear
keep if remoteness==1

*set up data
stset stop, fail(event==1) origin(time startdate) time0(start) enter(time start) id(e_linkedpersonid) exit(time .) scale(30.4375)

*graph of rates to visually estimate inflection point
strate period, per(1000) graph

*rename variables
gen months_before = (24-period)
label var months_before "Months before prostate cancer diagnosis"
gen month = 1+(24-months_before)
label var month "1 + 24-months_before (so we count forwards in time)"
gen pm = ((stop-start)/30.4375)
label var pm "Person-months"
gen py = pm/12
label var py "Person-years"

*modelling - look for an inflection point
tempvar inflection_month

*convenience values*
local biggest_ll = 0
local inf_month = 0

*loop over each of the 'possible' inflection point months */

/*nb these are all comparable alternatives
	gen inf_m_2 = cond(month >= 2, month-2, 0)
	poisson event c.month c.inf_m_2, exposure(py) vce(robust) irr
	streg c.month c.inf_m_2, dist(exp) base
	mepoisson event c.month c.inf_m_2, ||usi:, base irr
*/

 forval m = 2/23 {
qui	gen `inflection_month' = cond(month >= `m', month-`m', 0)
	poisson event c.month c.`inflection_month', exposure(pm) vce(cluster e_linkedpersonid)
	estimates store m`m'
	
	*pull out the log-likelihood
	local ll = e(ll)
	di `ll'
	
	*does this month have a bigger ll than any other (we want the inflection point with the best fit i.e. biggest log-likelihood value)
	if `ll' > `biggest_ll'|`biggest_ll' == 0 {
		local biggest_ll = `ll'
		local inf_month = `m'
		}
	*close loop 2
	drop `inflection_month'
	}
*close loop 1


*which inflection point was the best fit?
di "inflection month with best fit: `inf_month', LL `biggest_ll'"

****************************************************************
* now manually get the estimates for that inflection month = 
gen inf_m_`inf_month' = cond(month >=`inf_month', month-`inf_month', 0)
*fit model at patient level
poisson event c.month c.inf_m_`inf_month', exposure(pm) vce(cluster e_linkedpersonid) 

*predict at patient level including CIs
predictnl pred_event = predict(n), ci(pred_event_lb pred_event_ub)

*collapse and sum to get counts at month-level
collapse (sum) event pred_* pm, by(month)

gen rev_month = 24-month+1

*calculate rates
gen rate = (event/pm)*1000
gen pred_rate = (pred_event/pm) *1000
gen pred_rate_lb = (pred_event_lb/pm)*1000
gen pred_rate_ub = (pred_event_ub/pm) *1000

* plot the modelled vs the observed rates 
twoway 	(rarea pred_rate_lb pred_rate_ub 	rev_month, col(red%30) lw(0)  ) ///
		(line pred_rate 					rev_month, lc(red)  ) ///
		(line rate							rev_month, lc(gs0)  ) ///
		,	legend(order(3 "Observed" 2 "Modelled") cols(1) ring(0) pos(10) ) ///
			ylabel(, angle(h) format(%02.1fc)) ///
			ytitle("Tests per 1000 patients per month") ///
			yscale(nolog) ///
			xsc(reverse) ///
			xlabel(24(1) 1) /// 
			xtitle("Months before prostate cancer diagnosis") ///
			title( "Metro" )
