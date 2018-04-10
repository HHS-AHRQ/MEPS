**********************************************************************************
*
*PROGRAM:      C:\MEPS\STATA\PROG\EXERCISE6.do
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS DATA FILES FROM DIFFERENT YEARS
*              THE EXAMPLE USED IS POPULATION AGE 26-30 WHO ARE UNINSURED BUT HAVE HIGH INCOME
*
*	             DATA FROM 2014 AND 2015 ARE POOLED.
*
*              VARIABLES WITH YEAR-SPECIFIC NAMES MUST BE RENAMED BEFORE COMBINING FILES.  
*              IN THIS PROGRAM THE INSURANCE COVERAGE VARIABLES 'INSCOV14' AND 'INSCOV15' ARE RENAMED TO 'INSCOVyy'.
*
*	             SEE HC-036 (1996-2015 POOLED ESTIMATION FILE) FOR
*              INSTRUCTIONS ON POOOLING AND CONSIDERATIONS FOR VARIANCE ESTIMATION FOR PRE-2002 DATA.
*	             
*INPUT FILE:   (1) C:\MEPS\STATA\DATA\H171.dta (2014 FULL-YEAR FILE)
*	             (2) C:\MEPS\STATA\DATA\H181.dta (2015 FULL-YEAR FILE)
*
*********************************************************************************

clear
set more off
capture log close
log using C:\MEPS\stata\prog\Exercise6.log, replace
cd C:\MEPS\stata\data

/* RENAME YEAR SPECIFIC VARIABLES PRIOR TO COMBINING FILES */
use dupersid inscov14 perwt14f varstr varpsu povcat14 agelast totslf14 using h171
rename *14* **
tempfile YR1
save "`YR1'"

use dupersid inscov15 perwt15f varstr varpsu povcat15 agelast totslf15 using h181
rename *15* **
append using "`YR1'", generate(yearnum)

gen subpop=(agelast>=26 & agelast<=30 & inscov==3 & povcat==5)

tab1 agelast inscov povcat if subpop==1
tab subpop yearnum
summarize
tabmiss

/* WEIGHTED ESTIMATES ON TOTSLF FOR COMBINED DATA W/AGE=26-30, UNINSURED WHOLE YEAR, AND HIGH INCOME */

/* A common question is when is it necesarry to divide weights when pooling years of data. 
It is typically only necesarry when aggregating, or summing estimates using the sample weights in order to 
make an estimate that in an AVERAGE across multiple years. Dividing the weights will typically not matter for
estimating means or other non-aggregated statistics. */

* Mean out-of pocket spending for persons age=26-30, uninsured whole year, and high income from 2014-2015
svyset [pweight=perwt], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy, subpop(subpop): mean totslf

gen poolwt=perwt/2
svyset [pweight=poolwt], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy, subpop(subpop): mean totslf

* total out-of pocket spending for persons age=26-30, uninsured whole year, and high income from 2014-2015

svyset [pweight=poolwt], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy, subpop(subpop): total totslf // Correct: Average total out-of-pocket spending across the two years

svyset [pweight=perwt], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy, subpop(subpop): total totslf // In-correct: This is the sum of all out-of-pocket spending in 2014, and in 2015.

log close  
exit, clear
