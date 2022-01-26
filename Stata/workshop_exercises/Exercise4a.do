**********************************************************************************
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS DATA FILES FROM DIFFERENT YEARS
*              THE EXAMPLE USED IS POPULATION AGE 26-30 WHO ARE UNINSURED BUT HAVE HIGH INCOME
*
*	         		 DATA FROM 2015 AND 2016 ARE POOLED.
*
*              VARIABLES WITH YEAR-SPECIFIC NAMES MUST BE RENAMED BEFORE COMBINING FILES.
*              IN THIS PROGRAM THE INSURANCE COVERAGE VARIABLES 'INSCOV15' AND 'INSCOV16' ARE RENAMED TO 'INSCOV'.
*
*	         		 SEE HC-036 (1996-2015 POOLED ESTIMATION FILE) FOR
*              INSTRUCTIONS ON POOOLING AND CONSIDERATIONS FOR VARIANCE
*	         		 ESTIMATION FOR PRE-2002 DATA.
*
*INPUT FILE:   (1) C:\MEPS\STATA\DATA\H192.dta (2016 FULL-YEAR FILE)
*	           (2) C:\MEPS\STATA\DATA\H181.dta (2015 FULL-YEAR FILE)
*
*********************************************************************************

clear
set more off
capture log close
/*log using c:\meps\stata\prog\exercise6.log, replace
cd c:\meps\stata\data

log using \\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\STATA\PROG\exercise6.log, replace
cd \\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\STATA\DATA
*/

// rename year specific variables prior to combining files
import sasxport5 "C:\MEPS\h181.ssp"
keep dupersid inscov15 perwt15f varstr varpsu povcat15 agelast totslf15

rename inscov15 inscov
rename perwt15f perwt
rename povcat15 povcat
rename totslf15 totslf
tempfile yr1
save "`yr1'"

import sasxport5 "C:\MEPS\h192.ssp"
keep dupersid inscov16 perwt16f varstr varpsu povcat16 agelast totslf16

rename inscov16 inscov
rename perwt16f perwt
rename povcat16 povcat
rename totslf16 totslf

append using "`yr1'", generate(yearnum)

gen poolwt=perwt/2
gen subpop=(agelast>=26 & agelast<=30 & inscov==3 & povcat==5)

tab1 agelast inscov povcat if subpop==1
tab subpop yearnum
summarize
*tabmiss

svyset [pweight=poolwt], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

// weighted estimate on totslf for combined data w/age=26-30, uninsured whole year, and high income
svy, subpop(subpop): mean totslf


*log close
exit, clear
