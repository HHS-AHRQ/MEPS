* -----------------------------------------------------------------------------
* Use, expenditures, and population
*
* Expenditures by race and sex
*
* Example Stata code to replicate the following estimates in the MEPS-HC summary
*  tables, by race and sex:
*  - number of people
*  - percent of population with an expense
*  - total expenditures
*  - mean expenditure per person
*  - mean expenditure per person with expense
*  - median expenditure per person with expense
*
* Input file: C:\MEPS\h192.ssp (2016 full-year consolidated)
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

import sasxport "C:\MEPS\h192.ssp"


* Define variables ------------------------------------------------------------

* Race/ethnicity
* 1996-2002: race/ethnicity variable based on racethnx (see documentation for details)
* 2002-2011: race/ethnicity variable based on racethnx and racex:
*   gen hisp   = (racethnx == 1)
*   gen white  = (racethnx == 4 & racex == 1)
*   gen black  = (racethnx == 2)
*   gen native = (racethnx >= 3 & inlist(racex, 3,6))
*   gen asian  = (racethnx >= 3 & inlist(racex, 4,5))

* For 2012 and later, use RACETHX and RACEV1X:

gen hisp   = (racethx == 1)
gen white  = (racethx == 2)
gen black  = (racethx == 3)
gen native = (racethx > 3 & inlist(racev1x, 3,6))
gen asian  = (racethx > 3 & inlist(racev1x, 4,5))

gen race = 1*hisp + 2*white + 3*black + 4*native + 5*asian

label define race ///
	1 "Hispanic" ///
	2 "White" ///
	3 "Black" ///
	4 "Amer. Indian, AK Native, or mult. races" ///
	5 "Asian, Hawaiian, or Pacific Islander"

label values race race

* Sex
label define sex  1 "Male"  2 "Female"
label values sex sex

* Subgroup variables
gen persons = 1              // counter for population totals
gen has_exp = (totexp16 > 0) // 1 if person has an expense

* QC new variables
tabstat totexp16, by(has_exp) statistics(min, mean, max, n)

* Define survey design and calculate estimates --------------------------------

svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Number of people
quietly svy: total persons, over(sex race)
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)

* Total expenditures
quietly svy: total totexp16, over(sex race)
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)

* Percent of population with expense
svy: mean has_exp,  over(sex race)

* Mean expenditure per person
svy: mean totexp16, over(sex race)

* Mean expenditure per person with expense
svy, subpop(has_exp): mean totexp16, over(sex race)

* Median expenditure per person with expense -- using the 'epctile' package
*  Note: Estimates may vary in R, SAS, and Stata, due to different methods
*        of estimating survey quantiles
epctile totexp16, p(50) over(sex race) subpop(has_exp) svy
