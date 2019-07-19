**********************************************************************************
*
*DESCRIPTION:  DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS LONGITUDINAL DATA FILES FROM DIFFERENT PANELS
*              THE EXAMPLE USED IS PANELS 17-19 POPULATION AGE 26-30 WHO ARE UNINSURED BUT HAVE HIGH INCOME IN THE FIRST YEAR
*
*	         		 DATA FROM PANELS 17, 18, AND 19 ARE POOLED.
*
*INPUT FILE:   (1) C:\MEPS\SAS\DATA\H183.SAS7BDAT (PANEL 19 LONGITUDINAL FILE)
*	            (2) C:\MEPS\SAS\DATA\H172.SAS7BDAT (PANEL 18 LONGITUDINAL FILE)
*	            (3) C:\MEPS\SAS\DATA\H164.SAS7BDAT (PANEL 17 LONGITUDINAL FILE)
*********************************************************************************

clear
set more off
capture log close
/*log using c:\meps\stata\prog\exercise8.log, replace
cd c:\meps\stata\data

log using \\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\STATA\PROG\exercise8.log, replace
cd \\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\STATA\DATA
*/

// pool three panels of data to get sufficient sample size

/* Stata-IC can't load longitudinal files (too many variables) */
/* Using premade file instead (see below) */
/*
import sasxport "C:\MEPS\h183.ssp"
keep dupersid inscovy1 inscovy2 longwt varstr varpsu povcaty1 agey1x panel
tempfile panel19
save "`panel19'"

import sasxport "C:\MEPS\h172.ssp"
keep dupersid inscovy1 inscovy2 longwt varstr varpsu povcaty1 agey1x panel
tempfile panel18
save "`panel18'"

import sasxport "C:\MEPS\h164.ssp"
keep dupersid inscovy1 inscovy2 longwt varstr varpsu povcaty1 agey1x panel

append using "`panel19'" "`panel18'"
*/

import sasxport "Ex4_Long.ssp"

gen poolwt=longwt/3
gen subpop=(agey1x>=26 & agey1x<=30 & inscovy1==3 & povcaty1==5)
label define insf -1 "NA" 1 "1 Any private" 2 "2 Public only" 3 "3 Uninsured"
label define povcat 1 "1 Poor/negative" 2 "2 Near poor" 3 "3 Low income" 4 "4 Midlle income" 5 "5 High income"
label value inscovy1 inscovy2 insf
label value povcaty1 povcat

tab1 agey1x inscovy1 inscovy2 povcaty1 panel if subpop==1
tab subpop
summarize  if subpop==1
*tabmiss

svyset [pweight=poolwt], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

// weighted estimate on totslf for combined data w/age=26-30, uninsured whole year, and high income
// in the first year
svy, subpop(subpop): tabulate inscovy2, cell se obs

*log close
exit, clear
