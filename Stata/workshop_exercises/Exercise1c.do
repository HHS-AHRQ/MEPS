*****************************************************************************************************************************************
* Exercise 1: 
* This program generates the following estimates on national health care for the U.S. civilian non-institutionalized population, 2018:
*  - Overall expenses (National totals)
*  - Percentage of persons with an expense
*  - Mean expense per person
*  - Mean/median expense per person with an expense:
*    - Mean expense per person with an expense
*    - Mean expense per person with an expense, by age group
*    - Median expense per person with an expense, by age group
*
* Input file:
*  - C:/MEPS/h209.dat (2018 Full-year file)
*
* This program is available at:
* https://github.com/HHS-AHRQ/MEPS-workshop/tree/master/stata_exercises
*****************************************************************************************************************************************


clear
set more off
capture log close
cd C:\MEPS
log using Ex1.log, replace 

use C:\MEPS\DATA\h209, clear
/* define expenditure variables  */
gen total=totexp18

/* create flag (1/0) variables for persons with an expense  */
gen any_expenditure=(total>0)

/* create a summary variable from end of year, 42, and 31 variables*/
gen age=age18x if age18x>=0
replace age=age53x if age53x>=0 & missing(age)
replace age=age42x if age42x>=0 & missing(age)
replace age=age31x if age31x>=0 & missing(age)

gen agecat=1 if age>=0 & age<=64
replace agecat=2 if age>64
label define agecat 1 "<65" 2 "65+"
label values agecat agecat

/* qc check on new variables*/
list total any_expenditure age agecat age18x age42x age31x in 1/20, table

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
svy, subpop(if any_expenditure==1): mean total, over(racethx)


