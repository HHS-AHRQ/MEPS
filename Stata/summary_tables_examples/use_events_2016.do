* -----------------------------------------------------------------------------
* Use, expenditures, and population
*
* Utilization and expenditures by event type and source of payment (SOP)
*  based on event files
*
* Example Stata code to replicate the following estimates in the MEPS-HC summary
*  tables for selected event types:
*  - total number of events
*  - mean expenditure per event, by source of payment
*  - mean events per person, for office-based visits

* Selected event types:
*  - Office-based medical visits (OBV)
*  - Office-based physician visits (OBD)
*  - Outpatient visits (OPT)
*  - Outpatient physician visits (OPV)
*
* Sources of payment (SOPs):
*  - Out-of-pocket (SF)
*  - Medicare (MR)
*  - Medicaid (MD)
*  - Private insurance, including TRICARE (PR)
*  - Other (OZ)
*
* Input files:
*  - C:\MEPS\h192.ssp (2016 full-year consolidated)
*  - C:\MEPS\h188f (2016 OP event file)
*  - C:\MEPS\h188g (2016 OB event file)
* -----------------------------------------------------------------------------

clear
set more off

cd "C:\MEPS"

* Load FYC file and keep only needed variables --------------------------------
import sasxport "h192.ssp", clear
keep dupersid perwt16f varstr varpsu
save "FYC2016_temp.dta", replace


* Office-based visits ---------------------------------------------------------
import sasxport "h188g.ssp", clear

* aggregate payment sources
gen pr = obpv16x + obtr16x
gen oz = obof16x + obsl16x + obva16x + obot16x + obor16x + obou16x + obwc16x

keep if obxp16x >= 0 // remove inapplicable events

gen count = 1 // add counter for total events

* merge with FYC to retain all PSUs
merge m:1 dupersid using FYC2016_temp


* Define survey design and calculate estimates ----------------------
svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Total number of events
svy: total count, subpop(if obxp16x != .)                // office visits
svy: total count, subpop(if obxp16x != . & seedoc == 1)  // office phys. visits

* Mean expenditure per event, by source of payment
svy: mean obsf16x pr obmr16 obmd16x oz, subpop(if obxp16x != .)
svy: mean obsf16x pr obmr16 obmd16x oz, subpop(if obxp16x != . & seedoc == 1)


* Mean events per person --------------------------------------------

* Aggregate to person-level

gen phys_count = count*(seedoc == 1)

collapse ///
	(sum)  n_events = count            ///
	(sum)  n_phys_events = phys_count  ///
	(mean) perwt16f = perwt16f,        ///
	by(dupersid varstr varpsu)

svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy: mean n_events n_phys_events



* Outpatient events -----------------------------------------------------------
import sasxport "h188f.ssp", clear

* aggregate payment sources
gen pr_fac = opfpv16x + opftr16x
gen pr_sbd = opdpv16x + opdtr16x

gen oz_fac = opfof16x + opfsl16x + opfor16x + opfou16x + opfva16x + opfot16x + opfwc16x
gen oz_sbd = opdof16x + opdsl16x + opdor16x + opdou16x + opdva16x + opdot16x + opdwc16x

* combine facility and SBD expenses for hospital-type events
gen sf = opfsf16x + opdsf16x // out-of-pocket payments
gen mr = opfmr16x + opdmr16x // medicare
gen md = opfmd16x + opdmd16x // medicaid
gen pr = pr_fac + pr_sbd     // private insurance (including tricare)
gen oz = oz_fac + oz_sbd     // other sources of payment

keep if opxp16x >= 0 // remove inapplicable events

gen count = 1 // add counter for total events

* merge with FYC to retain all PSUs
merge m:1 dupersid using FYC2016_temp


* Define survey design and calculate estimates ----------------------
svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Total number of events
svy: total count, subpop(if opxp16x != .)               // OP visits
svy: total count, subpop(if opxp16x != . & seedoc == 1) // OP phys. visits

* Mean expenditure per event, by source of payment
svy: mean sf pr mr md oz, subpop(if opxp16x != .)
svy: mean sf pr mr md oz, subpop(if opxp16x != . & seedoc == 1)

capture erase FYC2016_temp.dta // Remove temporary file
