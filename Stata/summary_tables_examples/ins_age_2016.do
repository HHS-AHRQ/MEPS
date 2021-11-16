* -----------------------------------------------------------------------------
* Health insurance
*
* Example Stata code to replicate number and percentage of people by insurance
*  coverage and age groups
*
* Input file: C:\MEPS\h192.ssp (2016 full-year consolidated)
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

import sasxport "C:\MEPS\h192.ssp", clear


* Define variables ------------------------------------------------------------

* Age groups
*  - For 1996-2007, AGELAST must be created from AGEyyX, AGE42X, AGE31X

recode agelast ///
	(0/4    = 1 "Under_5")  ///
	(5/17   = 2 "5-17"   )  ///
	(18/44  = 3 "18-44"  )  ///
	(45/64  = 4 "45-64"  )  ///
	(65/max = 5 "65+"    ), ///
	generate(agegrps)

* Insurance coverage
*  - For 1996-2011, create 'insurc' from 'inscov' and 'ev' variables
*     (for 1996, use 'ever' vars):
*
*     gen public   = (mcdev16 == 1 | opaev16 == 1 | opbev16 == 1)
*     gen medicare = (mcrev16 == 1)
*     gen private  = (inscov16 == 1)
*
*     gen mcr_priv = (medicare &  private)
*     gen mcr_pub  = (medicare & !private & public)
*     gen mcr_only = (medicare & !private & !public)
*     gen no_mcr   = (!medicare)
*
*     gen ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr
*     gen insurc16 = cond(agelast < 65, inscov16, ins_gt65)

recode insurc16 7/8 = 7, generate(insurance)

label define insurance ///
	1 "<65, Any private"  ///
	2 "<65, Public only" ///
	3 "<65, Uninsured" ///
	4 "65+, Medicare only"  ///
	5 "65+, Medicare and private"  ///
	6 "65+, Medicare and other public" ///
	7 "65+, No medicare"

label values insurance insurance

* QC new variables
tabstat agelast, by(agegrps) statistics(min, max, n)
tab insurance insurc16, missing

* Define survey design and calculate estimates --------------------------------

svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy: tab agegrps insurance, count se format(%12.0fc) // number
svy: proportion insurance, over(agegrps) // percent
