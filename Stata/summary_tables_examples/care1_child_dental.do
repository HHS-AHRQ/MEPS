* -----------------------------------------------------------------------------
* Accessibility and quality of care, 2016
*
* Children with dental care
*
* Example Stata code to replicate number and percentage of children with dental
*  care, by poverty status
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

import sasxport "C:\MEPS\h192.ssp"


* Define variables ------------------------------------------------------------

* Children receiving dental care
*  - For 1996-2007, AGELAST must be created from AGEyyX, AGE42X, AGE31X

gen child_2to17 = (1 < agelast & agelast < 18)
gen child_dental = (dvtot16 > 0) & (child_2to17 == 1)
gen person = 1 // Indicator for population counts

label define child_dental             ///
	0 "No dental visits in past year" ///
	1 "One or more dental visits"

label define povcat      ///
	1 "Negative or poor" ///
	2 "Near-poor"        ///
	3 "Low income"       ///
	4 "Middle income"    ///
	5 "High income"

label values child_dental child_dental
label values povcat povcat

describe child_dental povcat


* Define survey design and calculate estimates --------------------------------
svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy, subpop(child_2to17): tab povcat child_dental, count se format(%12.0fc) // number
svy, subpop(child_2to17): proportion child_dental, over(povcat) // percent
