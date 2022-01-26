* -----------------------------------------------------------------------------
* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
*
* Accessibility and quality of care: Access to Care, 2019
*
* Did not receive treatment because couldn't afford it
*  - Number/percent of people
*  - By poverty status
*
* Input file: C:/MEPS/h216.dta (2019 full-year consolidated)
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

use "C:\MEPS\h216.dta", clear


* Define variables ------------------------------------------------------------

* Didn't receive care because couldn't afford it 
gen afford_MD = (AFRDCA42 == 1)*1 /* medical care */
gen afford_DN = (AFRDDN42 == 1)*1 /* dental care  */
gen afford_PM = (AFRDPM42 == 1)*1 /* prescription medicines */
gen afford_ANY = (afford_MD | afford_DN | afford_PM)*1 /* any care */


* Poverty status
label define poverty ///
	1 "Negative or poor" ///
    2 "Near-poor" ///
    3 "Low income" ///
    4 "Middle income" ///
    5 "High income" ///

label values POVCAT19 poverty
	

* Define survey design and calculate estimates --------------------------------
* - subset to persons eligible to receive the 'access to care' supplement 

gen domain = (ACCELI42==1)

svyset [pweight = PERWT19F], strata(VARSTR) psu(VARPSU) vce(linearized) singleunit(missing)


* Did not receive treatment because couldn't afford it, by poverty status
svy, subpop(domain): total afford_ANY afford_MD afford_DN afford_PM, over(POVCAT19) // number
svy, subpop(domain): mean  afford_ANY afford_MD afford_DN afford_PM, over(POVCAT19) // percent
