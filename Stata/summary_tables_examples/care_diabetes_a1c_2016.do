* -----------------------------------------------------------------------------
* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
*
* Accessibility and quality of care: Diabetes Care, 2016
*
* Diabetes care survey (DCS): 
*  - Number/percent of adults with diabetes receiving hemoglobin A1c blood test 
*  - By race/ethnicity
*
* Input file: C:/MEPS/h192.ssp (2016 full-year consolidated)
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

import sasxport5 "C:\MEPS\h192.ssp", clear


* Define variables ------------------------------------------------------------

* Diabetes care: Hemoglobin A1c measurement
*  - dsa1c53 = 'Times tested for A1c in 2016' (96 = did not have test)

recode dsa1c53 ///
	(-9/-7 = -9 "Don't know/Non-response" )  ///
	(-1    = -1 "Inapplicable"            )  ///
	(0     =  0 "Did not have measurement")  ///
	(96    =  0 "Did not have measurement")  ///
	(1/95  =  1 "Had measurement"         ), ///
	generate(diab_a1c)

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


* Define survey design and calculate estimates --------------------------------
*  - use DIABW16F weight variable, since outcome variable comes from DCS
svyset [pweight = diabw16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Adults with diabetes with hemoglobin A1C measurement in 2016, by race
svy: tab race diab_a1c, count se format(%12.0fc) // number
svy: proportion diab_a1c, over(race) // percent
