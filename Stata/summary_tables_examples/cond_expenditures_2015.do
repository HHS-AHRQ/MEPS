* -----------------------------------------------------------------------------
* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
*
* Medical Conditions, 2015:
*  - Number of people with care
*  - Number of events
*  - Total expenditures
*  - Mean expenditure per person
*
* Note: Starting in 2016, conditions were converted from ICD-9 and CCS codes
*  to ICD-10 and CCSR codes 
*
* Input files:
* 	- C:/MEPS/h178a.ssp (2015 RX event file)
* 	- C:/MEPS/h178d.ssp (2015 IP event file)
* 	- C:/MEPS/h178e.ssp (2015 ER event file)
* 	- C:/MEPS/h178f.ssp (2015 OP event file)
* 	- C:/MEPS/h178g.ssp (2015 OB event file)
* 	- C:/MEPS/h178h.ssp (2015 HH event file)
* 	- C:/MEPS/h178if1.ssp (2015 CLNK: Condition-event link file)
* 	- C:/MEPS/h180.ssp    (2015 Conditions file)
* -----------------------------------------------------------------------------

clear
set more off

cd "C:\MEPS"

* Load and stack event files --------------------------------------------------

global keep_vars evntidx dupersid xpx varstr varpsu perwt15f

* RX - count number of fills per event
import sasxport5 "h178a.ssp", clear
collapse  (sum) xpx = rxxp15x 	(count) n_fills = rxxp15x, ///
	by(dupersid linkidx varstr varpsu perwt15f)
rename linkidx evntidx
gen data = "RX"
save "RX2015_tmp.dta", replace

* IP
import sasxport5 "h178d.ssp", clear
rename ipxp15x xpx
keep $keep_vars
gen data = "IP"
save "IP2015_tmp.dta", replace

* ER
import sasxport5 "h178e.ssp", clear
rename erxp15x xpx
keep $keep_vars
gen data = "ER"
save "ER2015_tmp.dta", replace

* OP
import sasxport5 "h178f.ssp", clear
rename opxp15x xpx
keep $keep_vars
gen data = "OP"
save "OP2015_tmp.dta", replace

* OB
import sasxport5 "h178g.ssp", clear
rename obxp15x xpx
keep $keep_vars
gen data = "OB"
save "OB2015_tmp.dta", replace

* HH
import sasxport5 "h178h.ssp", clear
rename hhxp15x xpx
keep $keep_vars
gen data = "HH"
save "HH2015_tmp.dta", replace


* Stack event files and save as .dta
use RX2015_tmp, clear
append using IP2015_tmp ER2015_tmp OP2015_tmp OB2015_tmp HH2015_tmp

gen n_events = max(n_fills, 1)
save "stacked_events.dta", replace


* Load and merge conditions and CLNK file -------------------------------------

* Event-condition linking (CLNK) file
import sasxport5 "h178if1.ssp", clear
keep dupersid condidx evntidx
save "CLNK2015_tmp.dta", replace

* Conditions file -- load and merge with CLNK file
import sasxport5 "h180.ssp", clear
keep dupersid condidx cccodex
merge 1:m condidx dupersid using CLNK2015_tmp

* Create collapsed condition code variable
destring cccodex, generate(ccnum) // string -> numeric

gen cond = ""
replace cond = "Infectious_diseases"             if inrange(ccnum, 1, 9)
replace cond = "Cancer"                          if inrange(ccnum, 11, 45)
replace cond = "Non-malignant neoplasm"          if inrange(ccnum, 46, 47)
replace cond = "Thyroid_disease"                 if ccnum == 48
replace cond = "Diabetes_mellitus"               if inrange(ccnum, 49, 50)
replace cond = "Other endocrine, nutritional & immune disorder" ///
                                                 if inlist(ccnum, 51, 52) | inrange(ccnum, 54, 58)
replace cond = "Hyperlipidemia"                  if ccnum == 53
replace cond = "Anemia_and_other_deficiencies"   if ccnum == 59
replace cond = "Hemorrhagic, coagulation, and disorders of White Blood cells" ///
                                                 if inrange(ccnum, 60, 64)
replace cond = "Mental_disorders"                if inrange(ccnum, 65, 75) | inrange(ccnum, 650, 750)
replace cond = "CNS_infection"                   if inrange(ccnum, 76, 78)
replace cond = "Hereditary, degenerative and other nervous system disorders" ///
                                                 if inrange(ccnum, 79, 81)
replace cond = "Paralysis"                       if ccnum == 82
replace cond = "Headache"                        if ccnum == 84
replace cond = "Epilepsy_and_convulsions"        if ccnum == 83
replace cond = "Coma,_brain_damage"              if ccnum == 85
replace cond = "Cataract"                        if ccnum == 86
replace cond = "Glaucoma"                        if ccnum == 88
replace cond = "Other_eye_disorders"             if ccnum == 87 | inrange(ccnum, 89, 91)
replace cond = "Otitis_media"                    if ccnum == 92
replace cond = "Other_CNS_disorders"             if inrange(ccnum, 93, 95)
replace cond = "Hypertension"                    if inrange(ccnum, 98, 99)
replace cond = "Heart_disease"                   if inrange(ccnum , 96, 97) | inrange(ccnum, 100, 108)
replace cond = "Cerebrovascular_disease"         if inrange(ccnum, 109, 113)
replace cond = "Other circulatory conditions arteries, veins, and lymphatics" ///
                                                 if inrange(ccnum, 114, 121)
replace cond = "Pneumonia"                       if ccnum == 122
replace cond = "Influenza"                       if ccnum == 123
replace cond = "Tonsillitis"                     if ccnum == 124
replace cond = "Acute_Bronchitis_and_URI"        if inrange(ccnum, 125, 126)
replace cond = "COPD, asthma"                    if inrange(ccnum, 127, 134)
replace cond = "Intestinal_infection"            if ccnum == 135
replace cond = "Disorders_of_teeth_and_jaws"     if ccnum == 136
replace cond = "Disorders_of_mouth_and_esophagus" if ccnum == 137
replace cond = "Disorders_of_the_upper_GI"       if inrange(ccnum, 138, 141)
replace cond = "Appendicitis"                    if ccnum == 142
replace cond = "Hernias"                         if ccnum == 143
replace cond = "Other_stomach_and_intestinal_disorders" ///
                                                 if inrange(ccnum, 144, 148)
replace cond = "Other_GI"                        if inrange(ccnum, 153, 155)
replace cond = "Gallbladder, pancreatic, and liver disease" ///
                                                 if inrange(ccnum, 149, 152)
replace cond = "Kidney_Disease"                  if inrange(ccnum, 156, 158) | inlist(ccnum, 160, 161)
replace cond = "Urinary_tract_infections"        if ccnum == 159
replace cond = "Other_urinary"                   if inrange(ccnum, 162, 163)
replace cond = "Male_genital_disorders"          if inrange(ccnum, 164, 166)
replace cond = "Non-malignant breast disease"    if ccnum == 167
replace cond = "Complications_of_pregnancy_and_birth" ///
                                                 if inrange(ccnum, 177, 195)
replace cond = "Female genital disorders, and contraception" ///
                                                 if inrange(ccnum, 168, 176)
replace cond = "Normal_birth/live_born"          if inrange(ccnum, 196, 218)
replace cond = "Skin_disorders"                  if inrange(ccnum, 197, 200)
replace cond = "Osteoarthritis and other non-traumatic joint disorders" ///
                                                 if inrange(ccnum, 201, 204)
replace cond = "Back_problems"                   if ccnum == 205
replace cond = "Other_bone_and_musculoskeletal_disease" ///
                                                 if inrange(ccnum, 206, 209) | ccnum == 212
replace cond = "Systemic_lupus_and_connective_tissues_disorders" ///
                                                 if inrange(ccnum, 210, 211)
replace cond = "Congenital_anomalies"            if inrange(ccnum, 213, 217)
replace cond = "Perinatal_Conditions"            if inrange(ccnum, 219, 224)
replace cond = "Trauma-related_disorders"        if inrange(ccnum, 225, 236) | inlist(ccnum, 239, 240, 244)
replace cond = "Complications_of_surgery_or_device" ///
                                                 if inrange(ccnum, 237, 238)
replace cond = "Poisoning by medical and non-medical substances" ///
                                                 if inrange(ccnum, 241, 243)
replace cond = "Residual_Codes"                  if ccnum == 259
replace cond = "Other_care_and_screening"        if ccnum == 10 | inrange(ccnum, 254, 258)
replace cond = "Symptoms"                        if inrange(ccnum, 245, 252)
replace cond = "Allergic_reactions"              if ccnum == 253

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

* Number of people with care
quietly svy: total persons,  over(condition)
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)

* Number of events
quietly svy: total n_events, over(condition)
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)

* Total expenditures
quietly svy: total pers_XP,  over(condition)
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)

* Mean expenditure per person with care
quietly svy: mean pers_XP, over(condition)
estimates table, b(%20.0fc) se(%20.0fc) varwidth(30)


* Remove temporary files
capture erase RX2015_tmp.dta
capture erase IP2015_tmp.dta
capture erase ER2015_tmp.dta
capture erase OP2015_tmp.dta
capture erase OB2015_tmp.dta
capture erase HH2015_tmp.dta

capture erase CLNK2015_tmp.dta
capture erase stacked_events.dta
