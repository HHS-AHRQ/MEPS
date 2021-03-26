*****************************************************************************************************
* Exercise 4
*  This program includes a regression example for persons receiving a flu shot
*  in the last 12 months for the U.S. civilian non-institutionalized population, including:
*   - Percentage of people with a flu shot
*   - Logistic regression: to identify demographic factors associated with
*     receiving a flu shot
* 
*  Input file: 
*   - C:/MEPS/h209.dat (2018 Full-year file)
* 
*  This program is available at:
*  https://github.com/HHS-AHRQ/MEPS-workshop/tree/master/stata_exercises
*****************************************************************************************************
clear
set more off
capture log close
cd c:\MEPS

log using Ex4.log, replace

// Data was already downloaded and saved in Stata format in previous programs; just reading it here
use C:\MEPS\DATA\h209, clear

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
svy, sub(sub1): reg flushot agelast i.sex i.racethx i.inscov18
svy, sub(sub1): logit flushot agelast i.sex i.racethx i.inscov18 


