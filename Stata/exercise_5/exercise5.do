**********************************************************************************
*
*PROGRAM:      C:\MEPS\STATA\PROG\EXERCISE5.do
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO CALCULATE EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH A CONDITION
*
*              THE CONDITION USED IN THIS EXERCISE IS DIABETES (CCS CODE=049 OR 050)
*
*THE DEFINITION OF 61 CONDITIONS BASED ON CCS CODE
*
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
*
*INPUT FILES:  1) C:\MEPS\STATA\DATA\H171.dta    (2014 FY PUF DATA)
*              2) C:\MEPS\STATA\DATA\H170.dta    (2014 CONDITION PUF DATA)
*              3) C:\MEPS\STATA\DATA\H168A.dta   (2014 PMED PUF DATA)
*              4) C:\MEPS\STATA\DATA\H168D.dta   (2014 INPATIENT VISITS PUF DATA)
*              5) C:\MEPS\STATA\DATA\H168E.dta   (2014 EROM VISITS PUF DATA)
*              6) C:\MEPS\STATA\DATA\H168F.dta   (2014 OUTPATIENT VISITS PUF DATA)
*              7) C:\MEPS\STATA\DATA\H168G.dta   (2014 OFFICE-BASED VISITS PUF DATA)
*              8) C:\MEPS\STATA\DATA\H168H.dta   (2014 HOME HEALTH PUF DATA)
*              9) C:\MEPS\STATA\DATA\H168IF1.dta  (2014 CONDITION-EVENT LINK PUF DATA)
*              
**********************************************************************************

clear
set more off
capture log close
log using c:\meps\stata\prog\exercise5.log, replace
cd c:\meps\stata\data

// 1) pull out conditions with diabetes (ccs code='049', '050') from 2014 condition puf - hc162
use dupersid cccodex condidx using h170, clear
keep if cccodex=="049" | cccodex=="050"
tab cccodex
sort condidx
save diab, replace

// 2) get event id for the diabetic conditions from condition-event link file
use condidx  evntidx  using h168if1, clear
sort condidx
merge m:1 condidx using diab, keep(matches)
drop _merge

// 3) delete duplicate cases per event
by evntidx, sort: keep if _n==1
save diab,replace

// 4) sum up pmed purchase-level data to event-level
use using h168a, clear
sort linkidx
by linkidx: egen sf=sum(rxsf14x)
by linkidx: egen mr=sum(rxmr14x)
by linkidx: egen md=sum(rxmd14x)
by linkidx: egen pv=sum(rxpv14x)
by linkidx: egen va=sum(rxva14x)
by linkidx: egen tr=sum(rxtr14x)
by linkidx: egen of=sum(rxof14x)
by linkidx: egen sl=sum(rxsl14x)
by linkidx: egen wc=sum(rxwc14x)
by linkidx: egen or=sum(rxor14x)
by linkidx: egen ou=sum(rxou14x)
by linkidx: egen ot=sum(rxot14x)
by linkidx: egen xp=sum(rxxp14x)
list linkidx rxxp14x xp rxmr14x mr in 1/20  
gen evntyp="pmed"
rename linkidx evntidx               
by evntidx: keep if _n==1
keep evntidx sf mr md pv va tr of sl wc or ou ot xp evntyp
save pmed, replace

// 5) align exp variables in different events with the same names
use h168g, clear
rename ob*14x *                
gen evntyp="ambu"
keep evntid sf mr md pv va tr of sl wc or ou ot xp evntyp
save ob, replace


use h168h, clear
rename hh*14x *
gen evntyp="hvis"
keep evntid sf mr md pv va tr of sl wc or ou ot xp evntyp
save hvis, replace

use h168e, clear
egen sf=rowtotal(erfsf14x erdsf14x)
egen mr=rowtotal(erfmr14x erdmr14x)
egen md=rowtotal(erfmd14x erdmd14x)
egen pv=rowtotal(erfpv14x erdpv14x)
egen va=rowtotal(erfva14x erdva14x)
egen tr=rowtotal(erftr14x erdtr14x)
egen of=rowtotal(erfof14x erdof14x)
egen sl=rowtotal(erfsl14x erdsl14x)
egen wc=rowtotal(erfwc14x erdwc14x)
egen or=rowtotal(erfor14x erdor14x)
egen ou=rowtotal(erfou14x erdou14x)
egen ot=rowtotal(erfot14x erdot14x)
rename erxp14x xp
gen evntyp="erom"
keep evntid sf mr md pv va tr of sl wc or ou ot xp evntyp
save erom, replace

use h168d, clear                                              
egen sf=rowtotal(ipfsf14x ipdsf14x)                             
egen mr=rowtotal(ipfmr14x ipdmr14x)                             
egen md=rowtotal(ipfmd14x ipdmd14x)                             
egen pv=rowtotal(ipfpv14x ipdpv14x)                             
egen va=rowtotal(ipfva14x ipdva14x)                             
egen tr=rowtotal(ipftr14x ipdtr14x)                             
egen of=rowtotal(ipfof14x ipdof14x)                             
egen sl=rowtotal(ipfsl14x ipdsl14x)                             
egen wc=rowtotal(ipfwc14x ipdwc14x)                             
egen or=rowtotal(ipfor14x ipdor14x)                             
egen ou=rowtotal(ipfou14x ipdou14x)                             
egen ot=rowtotal(ipfot14x ipdot14x)                                                          
rename ipxp14x xp         
gen evntyp="ipat"                                      
keep evntid sf mr md pv va tr of sl wc or ou ot xp evntyp  
save ipat, replace                                                        

use h168f, clear                                               
egen sf=rowtotal(opfsf14x opdsf14x)                             
egen mr=rowtotal(opfmr14x opdmr14x)                             
egen md=rowtotal(opfmd14x opdmd14x)                             
egen pv=rowtotal(opfpv14x opdpv14x)                             
egen va=rowtotal(opfva14x opdva14x)                             
egen tr=rowtotal(opftr14x opdtr14x)                             
egen of=rowtotal(opfof14x opdof14x)                             
egen sl=rowtotal(opfsl14x opdsl14x)                             
egen wc=rowtotal(opfwc14x opdwc14x)                             
egen or=rowtotal(opfor14x opdor14x)                             
egen ou=rowtotal(opfou14x opdou14x)                             
egen ot=rowtotal(opfot14x opdot14x)                                                          
rename opxp14x xp              
gen evntyp="ambu"                                 
keep evntid sf mr md pv va tr of sl wc or ou ot xp evntyp     

// 6)  combine all events into one dataset
append using ob erom ipat hvis pmed, generate(filenum)  
keep if xp>=0
tab evntyp

// 7) subset events to those only with diabetes
sort evntidx
merge 1:m evntidx using diab, keep(matches) 

// 8) calculate estimates on expenditures and use by type of service
sort dupersid evntyp
by dupersid evntyp: egen sf_evnt=sum(sf)
by dupersid evntyp: egen mr_evnt=sum(mr)
by dupersid evntyp: egen md_evnt=sum(md)
by dupersid evntyp: egen pv_evnt=sum(pv)
by dupersid evntyp: egen va_evnt=sum(va)
by dupersid evntyp: egen tr_evnt=sum(tr)
by dupersid evntyp: egen of_evnt=sum(of)
by dupersid evntyp: egen sl_evnt=sum(sl)
by dupersid evntyp: egen wc_evnt=sum(wc)
by dupersid evntyp: egen or_evnt=sum(or)
by dupersid evntyp: egen ou_evnt=sum(ou)
by dupersid evntyp: egen ot_evnt=sum(ot)
by dupersid evntyp: egen xp_evnt=sum(xp)
by dupersid evntyp: gen n_visits=_N
by dupersid evntyp: keep if _n==1
keep dupersid evntyp evntidx *_evnt n_visits
save allevnt, replace

// 9) calculate estimates on expenditures and use, all types of service
sort dupersid
by dupersid: egen sf_per=sum(sf_evnt)
by dupersid: egen mr_per=sum(mr_evnt)
by dupersid: egen md_per=sum(md_evnt)
by dupersid: egen pv_per=sum(pv_evnt)
by dupersid: egen va_per=sum(va_evnt)
by dupersid: egen tr_per=sum(tr_evnt)
by dupersid: egen of_per=sum(of_evnt)
by dupersid: egen sl_per=sum(sl_evnt)
by dupersid: egen wc_per=sum(wc_evnt)
by dupersid: egen or_per=sum(or_evnt)
by dupersid: egen ou_per=sum(ou_evnt)
by dupersid: egen ot_per=sum(ot_evnt)
by dupersid: egen xp_per=sum(xp_evnt)
by dupersid: keep if _n==1  
keep dupersid *_per
save allper, replace

use dupersid varpsu varstr perwt14f using h171, clear
sort dupersid
merge 1:m dupersid using allper, generate(merge_per)
foreach var in sf_per mr_per md_per pv_per va_per tr_per of_per sl_per wc_per or_per ou_per ot_per xp_per {
recode `var' (missing=0)
tab `var' if merge_per==1
}

svyset [pweight= perwt14f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy, subpop(if merge_per==3): mean sf_per mr_per md_per pv_per va_per tr_per of_per sl_per wc_per or_per ou_per ot_per xp_per 

use dupersid varpsu varstr perwt14f using h171, clear
sort dupersid 
merge 1:m dupersid using allevnt, generate(merge_evnt)
foreach var in n_visits sf_evnt mr_evnt md_evnt pv_evnt va_evnt tr_evnt of_evnt sl_evnt wc_evnt or_evnt ou_evnt ot_evnt xp_evnt {
recode `var' (missing=0)
tab `var' if merge_evnt==1
}

svyset [pweight= perwt14f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy, subpop(if merge_evnt==3 & evntyp=="ambu"): mean n_visits sf_evnt mr_evnt md_evnt pv_evnt va_evnt tr_evnt of_evnt sl_evnt wc_evnt or_evnt ou_evnt ot_evnt xp_evnt       
svy, subpop(if merge_evnt==3 & evntyp=="erom"): mean n_visits sf_evnt mr_evnt md_evnt pv_evnt va_evnt tr_evnt of_evnt sl_evnt wc_evnt or_evnt ou_evnt ot_evnt xp_evnt 
svy, subpop(if merge_evnt==3 & evntyp=="hvis"): mean n_visits sf_evnt mr_evnt md_evnt pv_evnt va_evnt tr_evnt of_evnt sl_evnt wc_evnt or_evnt ou_evnt ot_evnt xp_evnt 
svy, subpop(if merge_evnt==3 & evntyp=="ipat"): mean n_visits sf_evnt mr_evnt md_evnt pv_evnt va_evnt tr_evnt of_evnt sl_evnt wc_evnt or_evnt ou_evnt ot_evnt xp_evnt 
svy, subpop(if merge_evnt==3 & evntyp=="pmed"): mean n_visits sf_evnt mr_evnt md_evnt pv_evnt va_evnt tr_evnt of_evnt sl_evnt wc_evnt or_evnt ou_evnt ot_evnt xp_evnt 

log close  
exit, clear
