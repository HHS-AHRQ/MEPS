* -----------------------------------------------------------------------------
* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
*
* Prescribed drugs, 2016
*
* Purchases and expenditures by Multum therapeutic class name (TC1)
*  - Number of people with purchase
*  - Total purchases
*  - Total expenditures
*
* Input file: C:/MEPS/h188a.ssp (2016 RX event file)
* -----------------------------------------------------------------------------

clear
set more off

* Load RX file ----------------------------------------------------------------
* For 1996-2013, need to merge with RX Multum Lexicon Addendum files to get
*  therapeutic class categories and generic drug names

import sasxport5 "C:\MEPS\h188a.ssp", clear


* Define labels for therapeutic classes ---------------------------------------

* Recode negative values (not allowed for factors in svy statement)
recode tc1 -9=999 -1=991 

 label define TC1name ///
	999 "Not_ascertained" ///
	991 "Inapplicable" ///
	  1 "Anti-infectives" ///
	 19 "Antihyperlipidemic_agents" ///
	 20 "Antineoplastics" ///
	 28 "Biologicals" ///
	 40 "Cardiovascular_agents" ///
	 57 "Central_nervous_system_agents" ///
	 81 "Coagulation_modifiers" ///
	 87 "Gastrointestinal_agents" ///
	 97 "Hormones/hormone_modifiers" ///
	105 "Miscellaneous_agents" ///
	113 "Genitourinary_tract_agents" ///
	115 "Nutritional_products" ///
	122 "Respiratory_agents" ///
	133 "Topical_agents" ///
	218 "Alternative_medicines" ///
	242 "Psychotherapeutic_agents" ///
	254 "Immunologic_agents" ///
	358 "Metabolic_agents"


label values tc1 TC1name // Apply labels to therapeutic classes


* Aggregate to person-level ---------------------------------------------------

collapse ///
	(mean) perwt16f = perwt16f ///
	(sum) pers_RXXP = rxxp16x ///
	(count) n_purchases = perwt16f, ///
	by(dupersid varstr varpsu tc1)

gen persons = 1


* Define survey design and calculate estimates --------------------------------

svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Number of people with purchase
quietly svy, over(tc1): total persons
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)

* Total purchases
quietly svy, over(tc1): total n_purchases
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)

* Total expenditures
quietly svy, over(tc1): total pers_RXXP
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)
