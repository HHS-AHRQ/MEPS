**********************************************************************************
*
*PROGRAM:      C:\MEPS\STATA\PROG\EXERCISE8.do
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS LONGITUDINAL DATA FILES FROM DIFFERENT PANELS
*              THE EXAMPLE USED IS PANEL 16, 17, AND 18 POPULATION AGE 26-30 WHO ARE UNINSURED BUT HAVE HIGH INCOME
*              IN THE FIRST YEAR
*
*	         		 DATA FROM PANEL 15, 16, AND 17 ARE POOLED.
*
*INPUT FILE:   (1) C:\MEPS\STATA\DATA\H172.dta (PANEL 18 LONGITUDINAL FILE)
*	             (2) C:\MEPS\STATA\DATA\H164.dta (PANEL 17 LONGITUDINAL FILE)
*              (3) C:\MEPS\STATA\DATA\H156.dta (PANEL 16 LONGITUDINAL FILE)
*********************************************************************************

clear
set more off
capture log close
log using c:\meps\stata\prog\exercise8.log, replace
cd c:\meps\stata\data

// pool three panels of data to get sufficient sample size. Use h172_IC, h164_IC, h156_IC if using Stata/IC
use dupersid inscovy1 inscovy2 longwt varstr varpsu povcaty1 agey1x panel using h172
tempfile panel18
save "`panel18'"

use dupersid inscovy1 inscovy2 longwt varstr varpsu povcaty1 agey1x panel using h164
tempfile panel17
save "`panel17'"

use dupersid inscovy1 inscovy2 longwt varstr varpsu povcaty1 agey1x panel using h156

append using "`panel18'" "`panel17'"

gen poolwt=longwt/3
gen subpop=(agey1x>=26 & agey1x<=30 & inscovy1==3 & povcaty1==5)
label define insf -1 "NA" 1 "1 Any private" 2 "2 Public only" 3 "3 Uninsured"
label define povcat 1 "1 Poor/negative" 2 "2 Near poor" 3 "3 Low income" 4 "4 Midlle income" 5 "5 High income"
label value inscovy1 inscovy2 insf
label value povcaty1 povcat

tab1 agey1x inscovy1 inscovy2 povcaty1 panel if subpop==1
tab subpop
summarize  if subpop==1
tabmiss // user-written command that tabulates missing values

svyset [pweight=poolwt], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

// weighted estimate on totslf for combined data w/age=26-30, uninsured whole year, and high income
// in the first year
svy, subpop(subpop): tabulate inscovy2, cell se obs

log close
exit, clear
