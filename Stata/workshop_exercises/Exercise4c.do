**********************************************************************************************
* Exercise 3
*  This program illustrates how to pool MEPS data files from different years. It
*  highlights one example of a discontinuity that may be encountered when 
*  working with data from before and after the 2018 CAPI re-design.
*  
*  The program pools 2017 and 2018 data and calculates:
*   - Percentage of people with Joint Pain / Arthritis (JTPAIN**, ARTHDX)
*   - Average expenditures per person, by Joint Pain status (TOTEXP, TOTSLF)
* 
*  Notes:
*   - Variables with year-specific names must be renamed before combining files
*     (e.g. 'TOTEXP17' and 'TOTEXP18' renamed to 'totexp')
* 
*   - For pre-2002 data, see HC-036 (1996-2017 pooled estimation file) for 
*     instructions on pooling and considerations for variance estimation.
* 
*  Input files: 
*   - C:/MEPS/h209.dat (2018 Full-year file)
*   - C:/MEPS/h201.dat (2017 Full-year file)
* 
*  This program is available at:
*  https://github.com/HHS-AHRQ/MEPS-workshop/tree/master/stata_exercises
**********************************************************************************************
clear
set more off
capture log close
cd C:\MEPS
log using Ex3.log, replace

/* rename 2017 variables, create joint pain indicator */
use C:\MEPS\DATA\h201, clear
keep dupersid varpsu varstr perwt17f inscov17 povcat17 totexp17 totslf17 jtpain31 arthdx agelast
rename (perwt17f inscov17 povcat17 totexp17 totslf17) (perwtf inscov povcat totexp totslf) 
gen year=2017
gen any_jtpain=(jtpain31==1 | arthdx==1)
replace any_jtpain=. if jtpain31<0 & arthdx<0 
save h201_temp, replace

/* rename 2018 variables, create joint pain indicator */
use C:\MEPS\DATA\h209, clear
keep dupersid varpsu varstr perwt18f inscov18 povcat18 totexp18 totslf18 jtpain31 arthdx agelast
rename (perwt18f inscov18 povcat18 totexp18 totslf18) (perwtf inscov povcat totexp totslf) 
gen year=2018
gen any_jtpain=(jtpain31_m18==1 | arthdx==1)
replace any_jtpain=. if jtpain31_m18<0 & arthdx<0 

/* append 2018 to 2017, erase temp file */
append using h201_temp
erase h201_temp.dta

/* create pooled person-level weight and subpop */
gen poolwt=perwt/2
gen sub1=(agelast>=18 & ~missing(any_jtpain))

/* set up survey parameters */
svyset varpsu [pw=poolwt], str(varstr) vce(linearized) singleunit(centered) 

/* estimate percent with any joint pain (any_jtpain) */
svy, sub(sub1): mean any_jtpain

/* estimate mean expenditures per person by whether they have joint pain*/
svy, sub(sub1): mean totexp, over(any_jtpain)
svy, sub(sub1): mean totslf, over(any_jtpain)
