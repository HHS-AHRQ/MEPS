*****************************************************************************************************************************************
* This program generates the following estimates on national health care for the U.S. civilian non-institutionalized population, 2018:
*  - Overall expenses (National totals)
*  - Percentage of persons with an expense
*  - Mean expense per person
*  - Mean expense per person with an expense:
*    - Mean expense per person with an expense
*    - Mean expense per person with an expense, by age group
*
* Input file:
*  - C:/MEPS/h209.dta (2018 Full-year file)
*
*****************************************************************************************************************************************


clear
set more off
capture log close
cd C:\MEPS
log using Ex1.log, replace 

/* Get data and read into Stata */
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h209dta.zip" "h209dta.zip"
unzipfile "h209dta.zip", replace 
use h209, clear
rename *, lower
save h209, replace

/* define expenditure variables  */
gen total=totexp18

/* create flag (1/0) variables for persons with an expense  */
gen any_expenditure=(total>0)

/* create age categorical variable */
gen agecat=1 if age18x>=0 & age18x<=64
replace agecat=2 if age18x>64
label define agecat 1 "<65" 2 "65+"
label values agecat agecat

/* qc check on new variables*/
list total any_expenditure agecat age18x in 1/20, table

tab1 any_expenditure agecat, m
 
summarize total, d
summarize total if any_expenditure==1, d

/* identify the survey design characteristics */
svyset varpsu [pw = perwt18f], strata(varstr) vce(linearized) singleunit(missing)
// overall expenses
svy: mean total
svy: total total

di %15.0f r(table)[1,1]
          
// percentage of persons with an expense
svy: mean any_expenditure		   
		   
// mean expense per person with an expense
svy, subpop(if any_expenditure==1): mean total

// mean expense per person with an expense, by age category
svy, subpop(if any_expenditure==1): mean total, over(agecat)

