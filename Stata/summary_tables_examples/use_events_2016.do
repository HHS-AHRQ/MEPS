* -----------------------------------------------------------------------------
* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
*
* Use, expenditures, and population, 2016
*
* Utilization and expenditures by event type and source of payment (SOP)
*  - Total number of events
*  - Mean expenditure per event, by source of payment
*  - Mean events per person, for office-based visits
*
* Selected event types:
*  - Office-based medical visits (OBV)
*  - Office-based physician visits (OBD)
*  - Outpatient visits (OPT)
*  - Outpatient physician visits (OPV)
*
* Input files:
*  - C:/MEPS/h192.ssp  (2016 full-year consolidated)
*  - C:/MEPS/h188f.ssp (2016 OP event file)
*  - C:/MEPS/h188g.ssp (2016 OB event file)
* -----------------------------------------------------------------------------

clear
set more off

cd "C:\MEPS"

* Load FYC file and keep only needed variables --------------------------------
import sasxport5 "h192.ssp", clear
keep dupersid perwt16f varstr varpsu
save "FYC2016_temp.dta", replace


* For event files, aggregate payment sources for each dataset -----------------
*
*  Notes:
*   - For 1996-1999: TRICARE label is CHM (changed to TRI in 2000)
*
*   - For 1996-2006: combined facility + SBD variables for hospital-type events
*      are not on PUF
*
*   - Starting in 2019, 'Other public' (OPU) and 'Other private' (OPR) are  
*      dropped from the files  
*
*
*  PR = Private (PV) + TRICARE (TR)
*
*  OZ = other federal (OF)  + State/local (SL) + other private (OR) +
*        other public (OU)  + other unclassified sources (OT) +
*        worker's comp (WC) + Veteran's (VA)


* Office-based visits ---------------------------------------------------------
import sasxport5 "h188g.ssp", clear

* aggregate payment sources
gen pr = obpv16x + obtr16x
gen oz = obof16x + obsl16x + obva16x + obot16x + obor16x + obou16x + obwc16x

keep if obxp16x >= 0 // remove inapplicable events

gen count = 1 // add counter for total events

* merge with FYC to retain all PSUs
merge m:1 dupersid using FYC2016_temp


* Define survey design and calculate estimates ----------------------
svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Total number of events, by event type
svy: total count, subpop(if obxp16x != .)                // office visits
svy: total count, subpop(if obxp16x != . & seedoc == 1)  // office phys. visits

* Mean expenditure per event, by event type and source of payment
svy: mean obsf16x pr obmr16 obmd16x oz, subpop(if obxp16x != .)
svy: mean obsf16x pr obmr16 obmd16x oz, subpop(if obxp16x != . & seedoc == 1)


* Mean events per person (first, aggregate to person-level)

gen phys_count = count*(seedoc == 1)

collapse ///
	(sum)  n_events = count            ///
	(sum)  n_phys_events = phys_count  ///
	(mean) perwt16f = perwt16f,        ///
	by(dupersid varstr varpsu)

svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy: mean n_events n_phys_events



* Outpatient events -----------------------------------------------------------
import sasxport5 "h188f.ssp", clear

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

* Total number of events, by event type
svy: total count, subpop(if opxp16x != .)               // OP visits
svy: total count, subpop(if opxp16x != . & seedoc == 1) // OP phys. visits

* Mean expenditure per event, by event type and source of payment
svy: mean sf pr mr md oz, subpop(if opxp16x != .)
svy: mean sf pr mr md oz, subpop(if opxp16x != . & seedoc == 1)

capture erase FYC2016_temp.dta // Remove temporary file
