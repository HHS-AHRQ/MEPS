*****************************************************************************************************
*  This program includes a regression example for persons receiving a flu shot
*  in the last 12 months for the U.S. civilian non-institutionalized population, including:
*   - Percentage of people with a flu shot
*   - Logistic regression: to identify demographic factors associated with
*     receiving a flu shot
* 
*  Input file: 
*   - C:/MEPS/h209.dta (2018 Full-year file)
* 
*****************************************************************************************************
clear
set more off
capture log close
cd c:\MEPS
log using Ex6.log, replace

// Data was already downloaded and saved in Stata format in previous programs; just reading it here
use C:\MEPS\h209, clear

// create and assign value labels 
label define race 1 "Hispanic" 2 "NH_white" 3 "NH_Black" 4 "NH_Asian" 5 "NH_other"
label values racethx race

label define ins 1 "Priv" 2 "Public" 3 "Unins"
label values inscov18 ins

label define povcat 1 "<100%" 2 "100%-125%" 3 "126%-199%" 4 "200%-400%" 5 ">400%"
label values povcat18 povcat

// create variable identifying individuals who received flu shot in last year
gen flushot=(adflst42==1)
replace flushot=. if adflst42<0
tab adflst42 flushot, m

// create variable to identify subpopulation
gen sub1=~missing(flushot, povcat18, inscov18, sex, racethx)


// set survey variables 
svyset varpsu [pw = saqwt18f], strata(varstr) vce(linearized) singleunit(missing)

// bivariate descriptive statistics: proportion with flushot by other variables  
svy, sub(sub1): mean flushot, over(povcat18)
svy, sub(sub1): mean flushot, over(inscov18)
svy, sub(sub1): mean flushot, over(racethx)
svy, sub(sub1): mean flushot, over(sex)

// regression analysis
svy, sub(sub1): reg flushot agelast i.sex i.racethx i.inscov18 i.povcat18
svy, sub(sub1): logit flushot agelast i.sex i.racethx i.inscov18 i.povcat18
margins i.racethx, sub(sub1) nose
margins i.povcat18, sub(sub1) nose
margins i.inscov18, sub(sub1) nose

