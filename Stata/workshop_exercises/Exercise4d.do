**********************************************************************************************
* Exercise 4
*  This program illustrates how to pool MEPS data files from different years. It
*  highlights one example of a discontinuity that may be encountered when 
*  working with data from before and after the 2018 CAPI re-design.
*  
*  The program pools 2017, 2018 and 2019 data and calculates:
*   - Percentage of people with Joint Pain / Arthritis (JTPAIN**, ARTHDX)
*   - Average expenditures per person, by Joint Pain status (TOTEXP, TOTSLF)
* 
*  Notes:
*   - Variables with year-specific names must be renamed before combining files
*     (e.g. 'TOTEXP17' and 'TOTEXP18' renamed to 'totexp')
* 
*   - HC-36 must be merged to get strata and psu variables when pooling years
* 
*  Input files: 
*   - C:/MEPS/h216.dta (2019 Full-year file)
*   - C:/MEPS/h209.dta (2018 Full-year file)
*   - C:/MEPS/h201.dta (2017 Full-year file)
*	- C:/MEPS/h36u19.dta (pooled linkage file)
* 
*  This program is available at:
*  https://github.com/HHS-AHRQ/MEPS-workshop/tree/master/stata_exercises
**********************************************************************************************
clear
set more off
capture log close
cd C:\MEPS
log using Ex4.log, replace

/* 2017 */
// rename 2017 variables, create joint pain indicator
use C:\MEPS\h201, clear
keep dupersid panel varpsu varstr perwt17f inscov17 povcat17 totexp17 totslf17 jtpain31 arthdx agelast
rename (perwt17f inscov17 povcat17 totexp17 totslf17) (perwtf inscov povcat totexp totslf) 
gen year=2017
gen any_jtpain=(jtpain31==1 | arthdx==1)
replace any_jtpain=. if jtpain31<0 & arthdx<0
// merge pooled linkage file
merge m:m panel dupersid using h36u19, keepusing(psu9619 stra9619)
drop if _merge~=3
drop _merge
save h201_temp, replace

/* 2018 */
// rename 2018 variables, create joint pain indicator 
use C:\MEPS\h209, clear
keep dupersid panel varpsu varstr perwt18f inscov18 povcat18 totexp18 totslf18 jtpain31_m18 arthdx agelast
rename (perwt18f inscov18 povcat18 totexp18 totslf18) (perwtf inscov povcat totexp totslf) 
gen year=2018
gen any_jtpain=(jtpain31_m18==1 | arthdx==1)
replace any_jtpain=. if jtpain31_m18<0 & arthdx<0
// merge pooled linkage file
merge m:m dupersid using h36u19, keepusing(psu9619 stra9619)
drop if _merge~=3
drop _merge
save h209_temp, replace

/* 2019 */
// rename 2019 variables, create joint pain indicator 
use C:\MEPS\h216, clear
keep dupersid panel varpsu varstr perwt19f inscov19 povcat19 totexp19 totslf19 jtpain31_m18 arthdx agelast
rename (perwt19f inscov19 povcat19 totexp19 totslf19) (perwtf inscov povcat totexp totslf) 
gen year=2019
gen any_jtpain=(jtpain31_m18==1 | arthdx==1)
replace any_jtpain=. if jtpain31_m18<0 & arthdx<0
// merge pooled linkage file 
merge m:m dupersid using h36u19, keepusing(psu9619 stra9619)
drop if _merge~=3
drop _merge
save h216_temp, replace

/* append 2018 to 2017, erase temp file */
append using h201_temp h209_temp, gen(source_file) 

/* create pooled person-level weight and subpop */
gen poolwt=perwt/3
gen sub18=(agelast>17)

/* set up survey parameters */
svyset psu9619 [pw=poolwt], str(stra9619) vce(linearized) singleunit(centered) 

/* estimate percent with any joint pain (any_jtpain) */
svy, sub(sub18): mean any_jtpain

/* estimate mean expenditures per person by whether they have joint pain*/
svy, sub(sub18): mean totexp, over(any_jtpain)
svy, sub(sub18): mean totslf, over(any_jtpain)

log close
