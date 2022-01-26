* -----------------------------------------------------------------------------
* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
*
* Accessibility and quality of care: Quality of Care, 2016
*
* Self-administered questionnaire (SAQ): 
*  - Number/percent of adults by ability to schedule a routine appointment
*  - By insurance coverage status
*
* Input file: C:\MEPS\h192.ssp (2016 full-year consolidated)
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

import sasxport5 "C:\MEPS\h192.ssp", clear


* Define variables ------------------------------------------------------------

* Ability to schedule a routine appt. (adults)
recode adrtww42 -9/-7=99 -1=91 1/2=1, generate(adult_routine)

label define frequency ///
	 4 "Always" ///
	 3 "Usually" ///
	 1 "Sometimes/Never" ///
	99 "Don't know/Non-response" ///
	91 "Inapplicable"

label values adult_routine frequency


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



* Define survey design and calculate estimates --------------------------------
*  - use SAQWT16F weight variable, since outcome variable comes from SAQ
*  - subset to adults who made an appointment

gen domain = (adrtcr42 == 1 & agelast >= 18)

svyset [pweight = saqwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)


* Ability to schedule a routine appointment (adults), by insurance coverage
svy, subpop(domain): tab insurance adult_routine, count se     /// number
	stubw(30) format(%12.0fc)
	
svy, subpop(domain): proportion adult_routine, over(insurance) // percent

