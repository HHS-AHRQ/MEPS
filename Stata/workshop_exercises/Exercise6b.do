*************************************************************************************************************************
*  This program includes a regression example for persons reporting COVID-related delays in Medical, Dental and Rx Care 
*  in the last 12 months for the U.S. civilian non-institutionalized population, including:
*   - Percentage reporting COVID-related delays in care
*   - Logistic regression: to identify demographic factors associated with COVID-related delays in care
* 
*  Input file: 
*   - C:/MEPS/h224.dta (2020 Full-year file)
* 
*  This program is available at:
*  https://github.com/HHS-AHRQ/MEPS-workshop/tree/master/stata_exercises
****************************************************************************************************************************
clear
set more off
capture log close
cd c:\MEPS

log using Ex6.log, replace

/* Get data from web */
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h224/h224dta.zip" "h224dta.zip", replace
unzipfile "h224dta.zip", replace 

/* Read in 2020 Full-year consolidated file */ 
use h224, clear
rename *, lower

// create variables identifying individuals who report delays in care
gen cvdlay_medical=cvdlayca53
recode cvdlay_medical (1=1) (2=0) (*=.)
gen cvdlay_dental=cvdlaydn53
recode cvdlay_dental (1=1) (2=0) (*=.)
gen cvdlay_rx=cvdlaypm53
recode cvdlay_rx (1=1) (2=0) (*=.)

recode sex 1=1 2=0 *=.
// treat missing values in RHS variables 
foreach var of varlist agelast sex racethx inscov20 region53 {
	replace `var'=. if `var'<0
}

// set survey variables 
svyset varpsu [pw = perwt20f], strata(varstr) vce(linearized) singleunit(missing)

// bivariate descriptive statistics: proportion with flushot by other variables
svy: mean cvdlay_medical
svy: mean cvdlay_dental
svy: mean cvdlay_rx
svy: mean cvdlay_medical cvdlay_dental cvdlay_rx
 
// regression analysis
svy: logit cvdlay_medical agelast i.sex i.racethx i.inscov20 i.region53

svy: logit cvdlay_dental agelast i.sex i.racethx i.inscov20 i.region53

svy: logit cvdlay_rx agelast i.sex i.racethx i.inscov20 i.region53
