* -----------------------------------------------------------------------------
* Prescribed drugs, 2016
*
* Purchases and expenditures by generic drug name
*
* Example Stata code to replicate the following estimates in the MEPS-HC summary
*  tables by generic drug name:
*  - Number of people with purchase
*  - Total purchases
*  - Total expenditures
*
* Input file: C:\MEPS\h188a.ssp (2016 RX event file)
* -----------------------------------------------------------------------------

clear
set more off

* Load datasets ---------------------------------------------------------------
* For 1996-2013, need to merge RX event file with Multum Lexicon Addendum
*  file to get therapeutic class categories and generic drug names

* Load RX file
import sasxport "C:\MEPS\h188a.ssp", clear


* Aggregate to person-level ---------------------------------------------------

keep if rxndc != "-9" & rxdrgnam != "-9" // Remove missing drug names

encode rxdrgnam, generate(rx_factor) // convert rxdrgnam to factor

collapse ///
	(mean) perwt16f = perwt16f ///
	(sum) pers_RXXP = rxxp16x ///
	(count) n_purchases = perwt16f, ///
	by(dupersid varstr varpsu rx_factor)

gen persons = 1

* Define domain to limit to groups with at least 60 people (makes svy faster)
egen n_people = count(persons), by(rx_factor)
gen domain = (n_people >= 60)
tabstat n_people, by(domain) statistics(min, max, n) // QC


* Define survey design and calculate estimates --------------------------------

svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Number of people with purchase
quietly svy, subpop(domain): total persons, over(rx_factor)
estimates table,  b(%20.0fc) se(%20.0fc) varwidth(30)

* Number of purchases
quietly svy, subpop(domain): total n_purchases, over(rx_factor)
estimates table,  b(%20.0fc) se(%20.0fc) varwidth(30)

* Total expenditures
quietly svy, subpop(domain): total pers_RXXP, over(rx_factor)
estimates table,  b(%20.0fc) se(%20.0fc) varwidth(30)
