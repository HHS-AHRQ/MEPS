* -----------------------------------------------------------------------------
* Use, expenditures, and population
*
* Expenditures by event type and source of payment (SOP)
*
* Example Stata code to replicate the following estimates in the MEPS-HC summary
*  tables, by source of payment (SOP), for selected event types:
*  - total expenditures
*  - mean expenditure per person
*  - mean out-of-pocket (SLF) payment per person with a SLF payment
*
* Selected event types:
*  - Office-based medical visits (OBV)
*  - Office-based physician visits (OBD)
*  - Outpatient visits (OPT)
*  - Outpatient physician visits (OPV)
*
* Sources of payment (SOPs):
*  - Out-of-pocket (SLF)
*  - Medicare (MCR)
*  - Medicaid (MCD)
*  - Private insurance, including TRICARE (PTR)
*  - Other (OTH)
* -----------------------------------------------------------------------------

clear
set more off

* Load FYC file ---------------------------------------------------------------

import sasxport "C:\MEPS\h192.ssp", clear


* Aggregate payment sources ---------------------------------------------------
*  For 1996-1999: TRICARE label is CHM (changed to TRI in 2000)
*
*  PTR = Private (PRV) + TRICARE (TRI)
*  OTZ = other federal (OFD)  + State/local (STL) + other private (OPR) +
*         other public (OPU)  + other unclassified sources (OSR) +
*         worker's comp (WCP) + Veteran's (VA)

* office-based visits
gen obvptr = obvprv16 + obvtri16
gen obvotz = obvofd16 + obvstl16 + obvopr16 + obvopu16 + obvosr16 + obvwcp16 + obvva16

* office-based physician visits
gen obdptr = obdprv16 + obdtri16
gen obdotz = obdofd16 + obdstl16 + obdopr16 + obdopu16 + obdosr16 + obdwcp16 + obdva16

* outpatient visits (facility + sbd expenses)
*  - for 1996-2006: combined facility + sbd variables are not on puf
gen optptr = optprv16 + opttri16
gen optotz = optofd16 + optstl16 + optopr16 + optopu16 + optosr16 + optwcp16 + optva16

* outpatient physician visits (facility expense)
gen opvptr = opvprv16 + opvtri16,
gen opvotz = opvofd16 + opvstl16 + opvopr16 + opvopu16 + opvosr16 + opvwcp16 + opvva16

* outpatient physician visits (sbd expense)
gen opsptr = opsprv16 + opstri16
gen opsotz = opsofd16 + opsstl16 + opsopr16 + opsopu16 + opsosr16 + opswcp16 + opsva16


* Combine facility and SBD expenses for hospital-type events ------------------
*  Note: for 1996-2006, also need to create OPT*** = OPF*** + OPD***

gen optslf_p = opvslf16 + opsslf16 // out-of-pocket payments
gen optmcr_p = opvmcr16 + opsmcr16 // Medicare
gen optmcd_p = opvmcd16 + opsmcd16 // Medicaid
gen optptr_p = opvptr   + opsptr   // private insurance (including TRICARE)
gen optotz_p = opvotz   + opsotz   // other sources of payment


* Define survey design and calculate estimates --------------------------------

svyset [pweight = perwt16f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)

* Total expenditures
svy: total ///
	obvslf16 obvptr   obvmcr16 obvmcd16 obvotz   /* office-based visits       */ ///
	obdslf16 obdptr   obdmcr16 obdmcd16 obdotz   /* office-based phys. visits */ ///
	optslf16 optptr   optmcr16 optmcd16 optotz   /* OP visits                 */ ///
	optslf_p optptr_p optmcr_p optmcd_p optotz_p /* OP phys. visits          */

* Mean expenditure per person
svy: mean ///
	obvslf16 obvptr   obvmcr16 obvmcd16 obvotz   /* office-based visits       */ ///
	obdslf16 obdptr   obdmcr16 obdmcd16 obdotz   /* office-based phys. visits */ ///
	optslf16 optptr   optmcr16 optmcd16 optotz   /* OP visits                 */ ///
	optslf_p optptr_p optmcr_p optmcd_p optotz_p /* OP phys. visits           */

* Mean out-of-pocket expense per person with an out-of-pocket expense
svy, subpop(if obvslf16 > 0): mean obvslf16 // office-based visits
svy, subpop(if obdslf16 > 0): mean obdslf16 // office-based phys. visits
svy, subpop(if optslf16 > 0): mean optslf16 // OP visits
svy, subpop(if optslf_p > 0): mean optslf_p // OP phys. visits
