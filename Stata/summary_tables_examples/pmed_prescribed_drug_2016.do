* -----------------------------------------------------------------------------
* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
*
* Prescribed drugs, 2016
*
* Purchases and expenditures by generic drug name (RXDRGNAM)
*  - Number of people with purchase
*  - Total purchases
*  - Total expenditures
*
* Input file: C:/MEPS/h188a.ssp (2016 RX event file)
* -----------------------------------------------------------------------------

clear
set more off

* Load datasets ---------------------------------------------------------------
* For 1996-2013, need to merge with RX Multum Lexicon Addendum files to get
*  therapeutic class categories and generic drug names

* Load RX file
import sasxport5 "C:\MEPS\h188a.ssp", clear


* Aggregate to person-level ---------------------------------------------------

encode rxdrgnam, generate(rx_factor) // convert rxdrgnam to factor

collapse ///
	(mean) perwt16f = perwt16f ///
	(sum) pers_RXXP = rxxp16x ///
	(count) n_purchases = perwt16f, ///
	by(dupersid varstr varpsu rx_factor)

gen persons = 1


* Define survey design and calculate estimates --------------------------------


* Define domain to limit to groups with at least 60 people (makes svy faster)
egen n_people = count(persons), by(rx_factor)
gen domain = (n_people >= 60)
tabstat n_people, by(domain) statistics(min, max, n) // QC


svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Number of people with purchase
quietly svy, subpop(domain): total persons, over(rx_factor)
estimates table,  b(%20.0fc) se(%20.0fc) varwidth(30)

* Total purchases
quietly svy, subpop(domain): total n_purchases, over(rx_factor)
estimates table,  b(%20.0fc) se(%20.0fc) varwidth(30)

* Total expenditures
quietly svy, subpop(domain): total pers_RXXP, over(rx_factor)
estimates table,  b(%20.0fc) se(%20.0fc) varwidth(30)
