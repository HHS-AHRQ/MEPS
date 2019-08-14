* -----------------------------------------------------------------------------
* Accessibility and quality of care, 2016
*
* Diabetes care survey (DCS):
*  Adults receiving hemoglobin A1c blood test
*
* Example Stata code to replicate number and percentage of adults with diabetes
*  who had a hemoglobin A1c blood test, by race/ethnicity
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

import sasxport "C:\MEPS\h192.ssp"


* Define variables ------------------------------------------------------------

* Diabetes care: Hemoglobin A1c measurement
*  - dsa1c53 = 'Times tested for A1c in 2016' (96 = did not have test)

recode dsa1c53 ///
 -9/-7 = -9  ///
	96 = 0   ///
  1/95 = 1,  ///
  generate(diab_a1c)

label define diab_a1c ///
	-9  "Don't know/Non-response" ///
	-1  "Inapplicable" ///
	 0  "Did not have measurement" ///
	 1  "Had measurement"

label values diab_a1c diab_a1c

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
*  - use DIABW16F weight variable
svyset [pweight = diabw16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy: tab race diab_a1c, count se format(%12.0fc) // number
svy: proportion diab_a1c, over(race) // percent
