**********************************************************************************
*
*DESCRIPTION: THIS PROGRAM GENERATES THE FOLLOWING ESTIMATES ON NATIONAL HEALTH CARE, 2016:
*
*	           (1) OVERALL EXPENSES
*	           (2) PERCENTAGE OF PERSONS WITH AN EXPENSE
*	           (3) MEAN EXPENSE PER PERSON WITH AN EXPENSE
*
*
*INPUT FILE:  C:\MEPS\STATA\DATA\H192.dta (2016 FULL-YEAR FILE)
*
*********************************************************************************

clear
set more off
capture log close
/*log using c:\meps\stata\prog\exercise1.log, replace
cd c:\meps\stata\data

log using \\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\STATA\PROG\exercise1.log, replace
cd \\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\STATA\DATA
*/

/* read in data from 2016 consolidated data file (hc-192) */
import sasxport5 "C:\MEPS\h192.ssp"
keep totexp16 age16x age42x age31x varstr varpsu perwt16f

/* define expenditure variables  */
gen total=totexp16

/* create flag (1/0) variables for persons with an expense  */
foreach var in total {
gen x_`var'=(`var'>0)
}

/* create a summary variable from end of year, 42, and 31 variables*/
gen age=age16x if age16x>=0
replace age=age42x if age42x>=0 & missing(age)
replace age=age31x if age31x>=0 & missing(age)

gen agecat=1 if age>=0 & age<=64
replace agecat=2 if age>64

/* qc check on new variables*/
tab1  x_total
sum total if total>0

list age age16x age42x age31x in 1/20, table

tab agecat
sum age if age>64

/* identify the survey design characteristics */
svyset [pweight= perwt16f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

// overall expenses
svy: mean total
svy: total total

// percentage of persons with an expense
svy: mean x_total

// mean expense per person with an expense
svy, subpop(x_total): mean total

// mean expense per person with an expense, by age category
svy, subpop(x_total): mean total, over(agecat)

exit, clear
