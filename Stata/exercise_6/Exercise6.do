**********************************************************************************
*
*PROGRAM:      C:\MEPS\STATA\PROG\EXERCISE6.do
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS DATA FILES FROM DIFFERENT YEARS
*              THE EXAMPLE USED IS POPULATION AGE 26-30 WHO ARE UNINSURED BUT HAVE HIGH INCOME
*
*	         		 DATA FROM 2013 AND 2014 ARE POOLED.
*
*              VARIABLES WITH YEAR-SPECIFIC NAMES MUST BE RENAMED BEFORE COMBINING FILES.
*              IN THIS PROGRAM THE INSURANCE COVERAGE VARIABLES 'INSCOV13' AND 'INSCOV14' ARE RENAMED TO 'INSCOV'.
*
*	         		 SEE HC-036 (1996-2014 POOLED ESTIMATION FILE) FOR
*              INSTRUCTIONS ON POOOLING AND CONSIDERATIONS FOR VARIANCE
*	         		 ESTIMATION FOR PRE-2002 DATA.
*
*INPUT FILE:   (1) C:\MEPS\STATA\DATA\H171.dta (2014 FULL-YEAR FILE)
*	           (2) C:\MEPS\STATA\DATA\H163.dta (2013 FULL-YEAR FILE)
*
*********************************************************************************

clear
set more off
capture log close
log using c:\meps\stata\prog\exercise6.log, replace
cd c:\meps\stata\data

// rename year specific variables prior to combining files
use dupersid inscov13 perwt13f varstr varpsu povcat13 agelast totslf13 using h163
rename inscov13 inscov
rename perwt13f perwt
rename povcat13 povcat
rename totslf13 totslf
tempfile yr1
save "`yr1'"

use dupersid inscov14 perwt14f varstr varpsu povcat14 agelast totslf14 using h171
rename inscov14 inscov
rename perwt14f perwt
rename povcat14 povcat
rename totslf14 totslf

append using "`yr1'", generate(yearnum)

gen poolwt=perwt/2
gen subpop=(agelast>=26 & agelast<=30 & inscov==3 & povcat==5)

tab1 agelast inscov povcat if subpop==1
tab subpop yearnum
summarize
tabmiss // user-written command to tabulate missing values

svyset [pweight=poolwt], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

// weighted estimate on totslf for combined data w/age=26-30, uninsured whole year, and high income
svy, subpop(subpop): mean totslf


log close
exit, clear
