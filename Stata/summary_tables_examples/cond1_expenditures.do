* -----------------------------------------------------------------------------
* Medical Conditions, 2015
*
* Note: Starting in 2016, conditions were coded to ICD-10 codes (ICD-9 codes
*  were used from 1996-2015). CCS codes are not on the medical conditions PUFs
*  for 2016 or 2017
*
* Example Stata code to replicate the following estimates in the MEPS-HC summary
*  tables by medical condition:
*  - Number of people with care
*  - Number of events
*  - Total expenditures
*  - Mean expenditure per person
* -----------------------------------------------------------------------------

clear
set more off

cd "C:\MEPS"

* Load and stack event files --------------------------------------------------

global keep_vars evntidx dupersid xpx varstr varpsu perwt15f

* RX - count number of fills per event
import sasxport "h178a.ssp", clear
collapse  (sum) xpx = rxxp15x 	(count) n_fills = rxxp15x, ///
	by(dupersid linkidx varstr varpsu perwt15f)
rename linkidx evntidx
gen data = "RX"
save "h178a.dta", replace

* IP
import sasxport "h178d.ssp", clear
rename ipxp15x xpx
keep $keep_vars
gen data = "IP"
save "h178d.dta", replace

* ER
import sasxport "h178e.ssp", clear
rename erxp15x xpx
keep $keep_vars
gen data = "ER"
save "h178e.dta", replace

* OP
import sasxport "h178f.ssp", clear
rename opxp15x xpx
keep $keep_vars
gen data = "OP"
save "h178f.dta", replace

* OB
import sasxport "h178g.ssp", clear
rename obxp15x xpx
keep $keep_vars
gen data = "OB"
save "h178g.dta", replace

* HH
import sasxport "h178h.ssp", clear
rename hhxp15x xpx
keep $keep_vars
gen data = "HH"
save "h178h.dta", replace


* Stack event files and save as .dta
use h178a, clear
append using h178d h178e h178f h178g h178h

gen n_events = max(n_fills, 1)
save "stacked_events.dta", replace


* Load and merge conditions and CLNK file -------------------------------------

* Event-condition linking (CLNK) file
import sasxport "h178if1.ssp", clear
keep dupersid condidx evntidx
save "CLNK2015.dta", replace

* Conditions file -- load and merge with CLNK file
import sasxport "h180.ssp", clear
keep dupersid condidx cccodex
merge 1:m condidx dupersid using "CLNK2015.dta"


* Create collapsed condition code variable
destring cccodex, generate(ccnum) // string -> numeric

gen cond = ""
replace cond = "Infectious diseases" 			if inrange(ccnum, 1, 9)
replace cond = "Cancer" 				    	if inrange(ccnum, 11, 45)
replace cond = "Non-malignant neoplasm" 		if inrange(ccnum, 46, 47)
replace cond = "Thyroid disease"    			if ccnum == 48
replace cond = "Diabetes mellitus" 				if inrange(ccnum, 49, 50)
replace cond = "Other endocrine, nutritional & immune disorder" ///
												if inlist(ccnum, 51, 52) | inrange(ccnum, 54, 58)
replace cond = "Hyperlipidemia" 				if ccnum == 53
replace cond = "Anemia and other deficiencies" 	if ccnum == 59
replace cond = "Hemorrhagic, coagulation, and disorders of White Blood cells" ///
												if inrange(ccnum, 60, 64)
replace cond = "Mental disorders" 				if inrange(ccnum, 65, 75) | inrange(ccnum, 650, 750)
replace cond = "CNS infection" 					if inrange(ccnum, 76, 78)
replace cond = "Hereditary, degenerative and other nervous system disorders" ///
												if inrange(ccnum, 79, 81)
replace cond = "Paralysis" 						if ccnum == 82
replace cond = "Headache" 						if ccnum == 84
replace cond = "Epilepsy and convulsions" 		if ccnum == 83
replace cond = "Coma, brain damage" 			if ccnum == 85
replace cond = "Cataract" 						if ccnum == 86
replace cond = "Glaucoma" 						if ccnum == 88
replace cond = "Other eye disorders" 			if ccnum == 87 | inrange(ccnum, 89, 91)
replace cond = "Otitis media" 					if ccnum == 92
replace cond = "Other CNS disorders" 			if inrange(ccnum, 93, 95)
replace cond = "Hypertension" 					if inrange(ccnum, 98, 99)
replace cond = "Heart disease" 					if inrange(ccnum , 96, 97) | inrange(ccnum, 100, 108)
replace cond = "Cerebrovascular disease" 		if inrange(ccnum, 109, 113)
replace cond = "Other circulatory conditions arteries, veins, and lymphatics" ///
												if inrange(ccnum, 114, 121)
replace cond = "Pneumonia" 						if ccnum == 122
replace cond = "Influenza" 						if ccnum == 123
replace cond = "Tonsillitis" 					if ccnum == 124
replace cond = "Acute Bronchitis and URI" 		if inrange(ccnum, 125, 126)
replace cond = "COPD, asthma" 					if inrange(ccnum, 127, 134)
replace cond = "Intestinal infection" 			if ccnum == 135
replace cond = "Disorders of teeth and jaws" 	if ccnum == 136
replace cond = "Disorders of mouth and esophagus" if ccnum == 137
replace cond = "Disorders of the upper GI" 		if inrange(ccnum, 138, 141)
replace cond = "Appendicitis" 					if ccnum == 142
replace cond = "Hernias" 						if ccnum == 143
replace cond = "Other stomach and intestinal disorders" ///
												if inrange(ccnum, 144, 148)
replace cond = "Other GI" 						if inrange(ccnum, 153, 155)
replace cond = "Gallbladder, pancreatic, and liver disease" ///
												if inrange(ccnum, 149, 152)
replace cond = "Kidney Disease" 				if inrange(ccnum, 156, 158) | inlist(ccnum, 160, 161)
replace cond = "Urinary tract infections" 		if ccnum == 159
replace cond = "Other urinary" 					if inrange(ccnum, 162, 163)
replace cond = "Male genital disorders" 		if inrange(ccnum, 164, 166)
replace cond = "Non-malignant breast disease" 	if ccnum == 167
replace cond = "Complications of pregnancy and birth" ///
												if inrange(ccnum, 177, 195)
replace cond = "Female genital disorders, and contraception" ///
												if inrange(ccnum, 168, 176)
replace cond = "Normal birth/live born" 		if inrange(ccnum, 196, 218)
replace cond = "Skin disorders" 				if inrange(ccnum, 197, 200)
replace cond = "Osteoarthritis and other non-traumatic joint disorders" ///
												if inrange(ccnum, 201, 204)
replace cond = "Back problems" 					if ccnum == 205
replace cond = "Other bone and musculoskeletal disease" ///
												if inrange(ccnum, 206, 209) | ccnum == 212
replace cond = "Systemic lupus and connective tissues disorders" ///
												if inrange(ccnum, 210, 211)
replace cond = "Congenital anomalies" 			if inrange(ccnum, 213, 217)
replace cond = "Perinatal Conditions" 			if inrange(ccnum, 219, 224)
replace cond = "Trauma-related disorders" 		if inrange(ccnum, 225, 236) | inlist(ccnum, 239, 240, 244)
replace cond = "Complications of surgery or device" ///
												if inrange(ccnum, 237, 238)
replace cond = "Poisoning by medical and non-medical substances" ///
												if inrange(ccnum, 241, 243)
replace cond = "Residual Codes" 				if ccnum == 259
replace cond = "Other care and screening" 		if ccnum == 10 | inrange(ccnum, 254, 258)
replace cond = "Symptoms" 						if inrange(ccnum, 245, 252)
replace cond = "Allergic reactions" 			if ccnum == 253

* Convert to factor
encode cond, generate(condition)

* De-duplicate by event ID ('evntidx') and collapsed code ('condition')
duplicates drop dupersid evntidx condition, force


* Merge conditions and event files --------------------------------------------
merge m:1 dupersid evntidx using stacked_events, nogenerate

* Remove observations with missing 'condition' or negative/missing expenditures
keep if xpx >= 0
drop if condition == . | xpx == .


* Aggregate to person-level, by condition -------------------------------------

collapse ///
	(sum)  pers_XP = xpx        ///
	(sum)  n_events = n_events  ///
	(mean) perwt15f = perwt15f, ///
	by(dupersid varstr varpsu condition)

gen persons = 1

* Define survey design and calculate estimates --------------------------------

svyset [pweight = perwt15f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)


svy: total persons,  over(condition)  // Number of people with care
svy: total n_events, over(condition)  // Number of events
svy: total pers_XP,  over(condition)  // Total expenditures

svy: mean pers_XP, over(condition)  // Mean expenditure per person with care
