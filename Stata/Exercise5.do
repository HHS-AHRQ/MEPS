**********************************************************************************
*PROGRAM:      C:\MEPS\STATA\PROG\EXERCISE5.do
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO CALCULATE EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH A CONDITION
*              THE CONDITION USED IN THIS EXERCISE IS DIABETES (CCS CODE=049 OR 050)
*THE DEFINITION OF 61 CONDITIONS BASED ON CCS CODE
*  1  Infectious diseases                                           : CCS CODE = 1-9
*  2  Cancer                                                        : CCS CODE = 11-45
*  3  Non-malignant neoplasm                                        : CCS CODE = 46, 47
*  4  Thyroid disease                                               : CCS CODE = 48
*  5  Diabetes mellitus                                             : CCS CODE = 49,50
*  6  Other endocrine, nutritional & immune disorder                : CCS CODE = 51, 52, 54 - 58
*  7  Hyperlipidemia                                                : CCS CODE = 53
*  8  Anemia and other deficiencies                                 : CCS CODE = 59
*  9  Hemorrhagic, coagulation, and disorders of White Blood cells  : CCS CODE = 60-64
*  10 Mental disorders                                              : CCS CODE = 650-670
*  11 CNS infection                                                 : CCS CODE = 76-78
*  12 Hereditary, degenerative and other nervous system disorders   : CCS CODE = 79-81
*  13 Paralysis                                                     : CCS CODE = 82
*  14 Headache                                                      : CCS CODE = 84
*  15 Epilepsy and convulsions                                      : CCS CODE = 83
*  16 Coma, brain damage                                            : CCS CODE = 85
*  17 Cataract                                                      : CCS CODE = 86
*  18 Glaucoma                                                      : CCS CODE = 88
*  19 Other eye disorders                                           : CCS CODE = 87, 89-91
*  20 Otitis media                                                  : CCS CODE = 92
*  21 Other CNS disorders                                           : CCS CODE = 93-95
*  22 Hypertension                                                  : CCS CODE = 98,99
*  23 Heart disease                                                 : CCS CODE = 96, 97, 100-108
*  24 Cerebrovascular disease                                       : CCS CODE = 109-113
*  25 Other circulatory conditions arteries, veins, and lymphatics  : CCS CODE = 114 -121
*  26 Pneumonia                                                     : CCS CODE = 122
*  27 Influenza                                                     : CCS CODE = 123
*  28 Tonsillitis                                                   : CCS CODE = 124
*  29 Acute Bronchitis and URI                                      : CCS CODE = 125 , 126
*  30 COPD, asthma                                                  : CCS CODE = 127-134
*  31 Intestinal infection                                          : CCS CODE = 135
*  32 Disorders of teeth and jaws                                   : CCS CODE = 136
*  33 Disorders of mouth and esophagus                              : CCS CODE = 137
*  34 Disorders of the upper GI                                     : CCS CODE = 138-141
*  35 Appendicitis                                                  : CCS CODE = 142
*  36 Hernias                                                       : CCS CODE = 143
*  37 Other stomach and intestinal disorders                        : CCS CODE = 144- 148
*  38 Other GI                                                      : CCS CODE = 153-155
*  39 Gallbladder, pancreatic, and liver disease                    : CCS CODE = 149-152
*  40 Kidney Disease                                                : CCS CODE = 156-158, 160, 161
*  41 Urinary tract infections                                      : CCS CODE = 159
*  42 Other urinary                                                 : CCS CODE = 162,163
*  43 Male genital disorders                                        : CCS CODE = 164-166
*  44 Non-malignant breast disease                                  : CCS CODE = 167
*  45 Female genital disorders, and contraception                   : CCS CODE = 168-176
*  46 Complications of pregnancy and birth                          : CCS CODE = 177-195
*  47 Normal birth/live born                                        : CCS CODE = 196, 218
*  48 Skin disorders                                                : CCS CODE = 197-200
*  49 Osteoarthritis and other non-traumatic joint disorders        : CCS CODE = 201-204
*  50 Back problems                                                 : CCS CODE = 205
*  51 Other bone and musculoskeletal  disease                       : CCS CODE = 206-209, 212
*  52 Systemic lupus and connective tissues disorders               : CCS CODE = 210-211
*  53 Congenital anomalies                                          : CCS CODE = 213-217
*  54 Perinatal Conditions                                          : CCS CODE = 219-224
*  55 Trauma-related disorders                                      : CCS CODE = 225-236, 239, 240, 244
*  56 Complications of surgery or device                            : CCS CODE = 237, 238
*  57 Poisoning by medical and non-medical substances               : CCS CODE = 241 - 243
*  58 Residual Codes                                                : CCS CODE = 259
*  59 Other care and screening                                      : CCS CODE = 10, 254-258
*  60 Symptoms                                                      : CCS CODE = 245-252
*  61 Allergic reactions                                            : CCS CODE = 253
*
*INPUT FILES:  1) C:\MEPS\STATA\DATA\H181.dta   (2015 FY PUF DATA)
*              2) C:\MEPS\STATA\DATA\H180.dta    (2015 CONDITION PUF DATA)
*              3) C:\MEPS\STATA\DATA\H178A.dta   (2015 PMED PUF DATA)
*              4) C:\MEPS\STATA\DATA\H178D.dta   (2015 INPATIENT VISITS PUF DATA)
*              5) C:\MEPS\STATA\DATA\H178E.dta   (2015 EROM VISITS PUF DATA)
*              6) C:\MEPS\STATA\DATA\H178F.dta   (2015 OUTPATIENT VISITS PUF DATA)
*              7) C:\MEPS\STATA\DATA\H178G.dta   (2015 OFFICE-BASED VISITS PUF DATA)
*              8) C:\MEPS\STATA\DATA\H178H.dta   (2015 HOME HEALTH PUF DATA)
*              9) C:\MEPS\STATA\DATA\H178I1.dta  (2015 CONDITION-EVENT LINK PUF DATA)
**********************************************************************************

clear
set more off
capture log close
log using C:\MEPS\stata\prog\Exercise5.log, replace
cd C:\MEPS\stata\data

/* 1) PULL OUT CONDITIONS WITH DIABETES (CCS CODE='049', '050') FROM 2015 CONDITION PUF - HC180 */
use dupersid cccodex condidx using h180.dta
keep if cccodex=="049" | cccodex=="050"
tab cccodex
sort condidx
save diab, replace

/* 2) GET EVENT ID FOR THE DIABETIC CONDITIONS FROM CONDITION-EVENT LINK FILE */
use condidx  evntidx  using h178if1, clear
sort condidx
merge m:1 condidx using diab, keep(matches)
drop _merge

/* 3) DELETE DUPLICATE CASES PER EVENT */
by evntidx, sort: keep if _n==1
save diab, replace

/* 4) SUM UP PMED PURCHASE-LEVEL DATA TO EVENT-LEVEL */
use using h178A.dta, clear
sort linkidx
global array1 sf mr md pv va tr of sl wc or ou ot xp
foreach xp in $array1 {
by linkidx: egen `xp'=sum(rx`xp'15x)
}
list linkidx rxxp15x xp rxmr15x mr in 1/20  
gen evntyp="PMED"
rename linkidx evntidx               
by evntidx: keep if _n==1
keep evntidx $array1 evntyp
save pmed, replace

// 5) ALIGN EXP VARIABLES IN DIFFERENT EVENTS WITH THE SAME NAMES
use h178g.dta,  clear
rename ob*15x *
gen evntyp="AMBU"
keep evntid $array1 evntyp
save ob, replace

use h178h.dta,  clear
rename hh*15x *
gen evntyp="HVIS"
keep evntid $array1 evntyp
save hvis, replace

use h178e.dta, clear
global array1 sf mr md pv va tr of sl wc or ou ot 
foreach xp in $array1 {
egen `xp'=rowtotal(erf`xp'15x erd`xp'15x)
}
rename erxp15x xp
gen evntyp="EROM"
keep evntid $array1 xp evntyp
save erom, replace

use h178d.dta, clear     
foreach xp in $array1 {
egen `xp'=rowtotal(ipf`xp'15x ipd`xp'15x)
}                                           
rename ipxp15x xp         
gen evntyp="IPAT"                                      
keep evntid $array1 xp evntyp
save ipat, replace                                                        

use h178f.dta, clear   
foreach xp in $array1 {
egen `xp'=rowtotal(opf`xp'15x opd`xp'15x)
}                                                                                                   
rename opxp15x xp              
gen evntyp="AMBU"                                 
keep evntid $array1 xp evntyp

/* 6)  COMBINE ALL EVENTS INTO ONE DATASET */
append using ob erom ipat hvis pmed, generate(filenum)  
keep if xp>=0
tab evntyp

/* 7) SUBSET EVENTS TO THOSE ONLY WITH DIABETES */
sort evntidx
merge 1:m evntidx using diab, keep(matches)

/* 8) CALCULATE ESTIMATES ON EXPENDITURES AND USE BY TYPE OF SERVICE */
sort dupersid evntyp
global array1 sf mr md pv va tr of sl wc or ou ot xp
foreach xp in $array1 {
by dupersid evntyp: egen `xp'_evnt=sum(`xp')
}

by dupersid evntyp: gen n_visits=_n
by dupersid evntyp: keep if _n==_N
keep dupersid evntyp evntidx *_evnt n_visits
save allevnt, replace

/* 9) CALCULATE ESTIMATES ON EXPENDITURES AND USE, ALL TYPES OF SERVICE */
sort dupersid
foreach xp in $array1 {
by dupersid: egen `xp'_per=sum(`xp'_evnt)
}
by dupersid: keep if _n==1  
keep dupersid *_per
save allper, replace

use dupersid varpsu varstr perwt15f using h181.dta, clear
sort dupersid
merge 1:m dupersid using allper, generate(merge_per)

foreach xp in $array1 {
recode `xp'_per (missing=0)
tab `xp'_per if merge_per==1
}

svyset [pweight= perwt15f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy, subpop(if merge_per==3): mean sf_per mr_per md_per pv_per va_per tr_per of_per sl_per wc_per or_per ou_per ot_per xp_per

use dupersid varpsu varstr perwt15f using h181.dta, clear
sort dupersid 
merge 1:m dupersid using allevnt, generate(merge_evnt)
recode n_visits (missing=0)
tab n_visits if merge_evnt==1
foreach xp in  $array1 {
recode `xp'_evnt (missing=0)
tab `xp'_evnt if merge_evnt==1
}

svyset [pweight= perwt15f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
global event AMBU EROM HVIS IPAT PMED
foreach ev in $event {
display "`ev'"
svy, subpop(if merge_evnt==3 & evntyp=="`ev'"): mean n_visits sf_evnt mr_evnt md_evnt pv_evnt va_evnt tr_evnt of_evnt sl_evnt wc_evnt or_evnt ou_evnt ot_evnt xp_evnt       
}

log close  
exit, clear
