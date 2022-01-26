* -----------------------------------------------------------------------------
* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
*
* Accessibility and quality of care: Access to Care, 2017
*
* Reasons for difficulty receiving needed care
*  - Number/percent of people
*  - By poverty status
*
* Input file: C:/MEPS/h201.dta (2017 full-year consolidated)
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

use "C:\MEPS\h201.dta", clear


* Define variables ------------------------------------------------------------

* Reasons for difficulty receiving needed care

* any delay / unable to receive needed care
gen delay_MD  = (MDUNAB42 == 1 | MDDLAY42==1)*1
gen delay_DN  = (DNUNAB42 == 1 | DNDLAY42==1)*1
gen delay_PM  = (PMUNAB42 == 1 | PMDLAY42==1)*1


* Among people unable or delayed, how many...
* ...couldn't afford
gen afford_MD = (MDDLRS42 == 1 | MDUNRS42 == 1)*1
gen afford_DN = (DNDLRS42 == 1 | DNUNRS42 == 1)*1
gen afford_PM = (PMDLRS42 == 1 | PMUNRS42 == 1)*1

* ...had insurance problems
gen insure_MD = (inlist(MDDLRS42, 2,3) | inlist(MDUNRS42, 2,3))*1
gen insure_DN = (inlist(DNDLRS42, 2,3) | inlist(DNUNRS42, 2,3))*1
gen insure_PM = (inlist(PMDLRS42, 2,3) | inlist(PMUNRS42, 2,3))*1

* ...other
gen other_MD  = (MDDLRS42 > 3 | MDUNRS42 > 3)*1
gen other_DN  = (DNDLRS42 > 3 | DNUNRS42 > 3)*1
gen other_PM  = (PMDLRS42 > 3 | PMUNRS42 > 3)*1

gen delay_ANY  = (delay_MD  | delay_DN  | delay_PM)*1
gen afford_ANY = (afford_MD | afford_DN | afford_PM)*1
gen insure_ANY = (insure_MD | insure_DN | insure_PM)*1
gen other_ANY  = (other_MD  | other_DN  | other_PM)*1


* Poverty status
label define poverty ///
	1 "Negative or poor" ///
    2 "Near-poor" ///
    3 "Low income" ///
    4 "Middle income" ///
    5 "High income" ///

label values POVCAT17 poverty
	

* Define survey design and calculate estimates --------------------------------
* - subset to persons eligible to receive the 'access to care' supplement 
*   and who experienced difficulty receiving needed care

gen domain = (ACCELI42==1 & delay_ANY==1)

svyset [pweight = PERWT17F], strata(VARSTR) psu(VARPSU) vce(linearized) singleunit(missing)


* Reasons for difficulty receiving any needed care, by poverty status
svy, subpop(domain): total afford_ANY insure_ANY other_ANY, over(POVCAT17) // number
svy, subpop(domain): mean  afford_ANY insure_ANY other_ANY, over(POVCAT17) // percent
