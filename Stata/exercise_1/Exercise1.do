**********************************************************************************
*
*PROGRAM:     C:\MEPS\STATA\PROG\EXERCISE1.do
*
*DESCRIPTION: THIS PROGRAM GENERATES THE FOLLOWING ESTIMATES ON NATIONAL HEALTH CARE EXPENSES BY TYPE OF SERVICE, 2014:
*
*	           	(1) PERCENTAGE DISTRIBUTION OF EXPENSES BY TYPE OF SERVICE
*	           	(2) PERCENTAGE OF PERSONS WITH AN EXPENSE, BY TYPE OF SERVIC
*	           	(3) MEAN EXPENSE PER PERSON WITH AN EXPENSE, BY TYPE OF SERVICE
*
*             DEFINED SERVICE CATEGORIES ARE:
*                HOSPITAL INPATIENT
*                AMBULATORY SERVICE: OFFICE-BASED & HOSPITAL OUTPATIENT VISITS
*                PRESCRIBED MEDICINES
*                DENTAL VISITS
*                EMERGENCY ROOM
*                HOME HEALTH CARE (AGENCY & NON-AGENCY) AND OTHER (TOTAL EXPENDITURES - ABOVE EXPENDITURE CATEGORIES)
*
*            	NOTE: EXPENSES INCLUDE BOTH FACILITY AND PHYSICIAN EXPENSES.
*
*INPUT FILE:  C:\MEPS\STATA\DATA\H171.dta (2014 FULL-YEAR FILE)
*
*********************************************************************************

clear
set more off
capture log close
log using c:\meps\stata\prog\exercise1.log, replace
cd c:\meps\stata\data

/* read in data from 2014 consolidated data file (hc-171) */
use totexp14 ipdexp14 ipfexp14 obvexp14 rxexp14 opdexp14 opfexp14 dvtexp14 erdexp14 erfexp14 hhaexp14 hhnexp14 othexp14 visexp14 age14x age42x age31x varstr varpsu perwt14f using h171.dta
    
/* define expenditure variables by type of service  */
gen total=totexp14
gen hospital_inpatient   = ipdexp14 + ipfexp14
gen ambulatory           = obvexp14 + opdexp14 + opfexp14 + erdexp14 + erfexp14
gen prescribed_medicines = rxexp14
gen dental               = dvtexp14
gen home_health_other    = hhaexp14 + hhnexp14 + othexp14 + visexp14
gen diff                 = total-hospital_inpatient - ambulatory   - prescribed_medicines - dental - home_health_other

/* create flag (1/0) variables for persons with an expense, by type of service  */
foreach var in total hospital_inpatient ambulatory prescribed_medicines dental home_health_other {
gen x_`var'=(`var'>0)
}

/* create a summary variable from end of year, 42, and 31 variables*/
gen age=age14x if age14x>=0
replace age=age42x if age42x>=0 & missing(age)
replace age=age31x if age31x>=0 & missing(age)

gen agecat=1 if age>=0 & age<=64
replace agecat=2 if age>64

/* qc check on new variables*/
tab1  x_total x_hospital_inpatient  x_ambulatory  x_prescribed_medicines  x_dental  x_home_health_other
sum total if total>0
sum hospital_inpatient if hospital_inpatient>0
sum ambulatory if ambulatory>0
sum prescribed_medicines if prescribed_medicines>0
sum dental if dental>0
sum home_health_other if home_health_other>0

list age age14x age42x age31x in 1/20, table

tab agecat
sum age if age>64

/* identify the survey design characteristics */
svyset [pweight= perwt14f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

// percentage distribution of expenses by type of service (stat brief #491 figure 1)
svy: ratio ( hospital_inpatient: hospital_inpatient/total) ///
           ( ambulatory: ambulatory/ total) ///
           ( prescribed_medicines: prescribed_medicines/total) ///
           ( dental: dental/total) ///
           ( home_health_other: home_health_other/total)
           
// percentage of persons with an expense, by type of service
svy: mean  x_total x_hospital_inpatient x_ambulatory x_prescribed_medicines x_dental x_home_health_other
           
// mean expense per person with an expense, by type of service     
svy, subpop(x_total): mean total
svy, subpop(x_hospital_inpatient): mean hospital_inpatient
svy, subpop(x_ambulatory): mean ambulatory
svy, subpop(x_prescribed_medicines): mean prescribed_medicines
svy, subpop(x_dental): mean dental
svy, subpop(x_home_health_other): mean home_health_other

// mean expense per person with an expense, by type of service and age category
svy, subpop(x_total): mean total, over(agecat)
svy, subpop(x_hospital_inpatient): mean hospital_inpatient, over(agecat)
svy, subpop(x_ambulatory): mean ambulatory, over(agecat)
svy, subpop(x_prescribed_medicines): mean prescribed_medicines, over(agecat)
svy, subpop(x_dental): mean dental, over(agecat)
svy, subpop(x_home_health_other): mean home_health_other, over(agecat)

log close
exit, clear
