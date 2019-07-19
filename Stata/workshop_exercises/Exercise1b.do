**********************************************************************************
* DESCRIPTION:  THIS PROGRAM GENERATES UPDATED ESTIMATES FROM
*               1. MEPS STATISTICAL BRIEF # 456:
*           		   "NATIONAL HEALTH CARE EXPENSES IN THE U.S. CIVILIAN NONINSTITUTIONALIZED POPULATION,
*                      DISTRIBUTIONS BY TYPE OF SERVICE AND SOURCE OF PAYMENT, 2012"
*               2. MEPS STATISTICAL BRIEF # 457:
*           		   "NATIONAL HEALTH CARE EXPENSES IN THE U.S. CIVILIAN NONINSTITUTIONALIZED POPULATION, 2012"
*
* 	            ESTIMATES GENERATED INCLUDE:
*
*       	    (1) Figure 1(#456): PERCENTAGE DISTRIBUTION OF EXPENSES BY TYPE OF SERVICE
* 	            (2) Figure 1(#457): PERCENTAGE OF PERSONS WITH AN EXPENSE, BY TYPE OF SERVIC
* 	            (3) Figure 2(#457): MEAN EXPENSE PER PERSON WITH AN EXPENSE, BY TYPE OF SERVICE
*
*               DEFINED SERVICE CATEGORIES ARE:
*                 HOSPITAL INPATIENT
*                 AMBULATORY SERVICE: OFFICE-BASED & HOSPITAL OUTPATIENT VISITS
*                 PRESCRIBED MEDICINES
*                 DENTAL VISITS
*                 EMERGENCY ROOM
*                 HOME HEALTH CARE (AGENCY & NON-AGENCY) AND OTHER (TOTAL EXPENDITURES - ABOVE EXPENDITURE CATEGORIES)
*
*               NOTE: EXPENSES INCLUDE BOTH FACILITY AND PHYSICIAN EXPENSES.
*
* INPUT FILE:   C:\MEPS\STATA\DATA\H181.dta (2015 FULL-YEAR FILE)
*********************************************************************************

clear
set more off
capture log close
log using C:\MEPS\stata\prog\Exercise1.log, replace
cd C:\MEPS\stata\data


/* READ IN DATA FROM 2015 CONSOLIDATED DATA FILE (HC-171) */
use totexp15 ipdexp15 ipfexp15 obvexp15 rxexp15 opdexp15 opfexp15 dvtexp15 erdexp15 erfexp15 hhaexp15 hhnexp15 ///
othexp15 visexp15 age15x age42x age31x varstr varpsu perwt15f using h181

/* Define expenditure variables by type of service  */
gen totalexp=totexp15
gen hospital_inpatient   = ipdexp15 + ipfexp15
gen ambulatory           = obvexp15 + opdexp15 + opfexp15 + erdexp15 + erfexp15
gen prescribed_medicines = rxexp15
gen dental               = dvtexp15
gen home_health_other    = hhaexp15 + hhnexp15 + othexp15 + visexp15
gen diff                 = totalexp-hospital_inpatient - ambulatory   - prescribed_medicines - dental - home_health_other

/* CREATE FLAG (1/0) VARIABLES FOR PERSONS WITH AN EXPENSE, BY TYPE OF SERVICE  */
foreach var in totalexp hospital_inpatient ambulatory prescribed_medicines dental home_health_other {
gen x_`var'=(`var'>0)
}

/* CREATE A SUMMARY VARIABLE FROM END OF YEAR, 42, AND 31 VARIABLES*/
gen age=age15x if age15x>=0
replace age=age42x if age42x>=0 & missing(age)
replace age=age31x if age31x>=0 & missing(age)

gen agecat=1 if age>=0 & age<=64
replace agecat=2 if age>64

/* qc check on new variables*/
tab1  x_totalexp x_hospital_inpatient  x_ambulatory  x_prescribed_medicines  x_dental  x_home_health_other
foreach var in totalexp hospital_inpatient ambulatory prescribed_medicines dental home_health_other {
sum `var' if `var'>0
}
list age age15x age42x age31x in 1/20, table

tab agecat
sum age if age>64

/* identify the survey design characteristics */
svyset [pweight= perwt15f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

// Update HEALTHCARE SPENDING, 2012 (MEPS STAT BRIEF #456)
// FIGURE 1: PERCENTAGE DISTRIBUTION OF EXPENSES BY TYPE OF SERVICE
svy: ratio ( hospital_inpatient: hospital_inpatient/totalexp) ///
           ( ambulatory: ambulatory/ totalexp) ///
           ( prescribed_medicines: prescribed_medicines/totalexp) ///
           ( dental: dental/totalexp) ///
           ( home_health_other: home_health_other/totalexp)

// Update HEALTHCARE SPENDING, 2012 (MEPS STAT BRIEF #457)
// FIGURE 1: PERCENTAGE OF PERSONS WITH AN EXPENSE, BY TYPE OF SERVICE
svy: mean  x_totalexp x_hospital_inpatient x_ambulatory x_prescribed_medicines x_dental x_home_health_other

// FIGURES 2: MEAN EXPENSE PER PERSON WITH AN EXPENSE, BY TYPE OF SERVICE
foreach var in totalexp hospital_inpatient ambulatory prescribed_medicines dental home_health_other {
svy, subpop(x_`var'): mean `var'
}
// FIGURES 2: MEAN EXPENSE PER PERSON WITH AN EXPENSE, BY TYPE OF SERVICE AND AGE CATEGORY
foreach var in totalexp hospital_inpatient ambulatory prescribed_medicines dental home_health_other {
svy, subpop(x_`var'): mean `var', over(agecat)
}

log close
exit, clear
