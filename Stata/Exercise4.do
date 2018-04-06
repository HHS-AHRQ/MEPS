**********************************************************************************
*
*PROGRAM:      C:\MEPS\STATA\PROG\EXERCISE4.do
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO IDENTIFY PERSONS WITH A CONDITION AND
*              CALCULATE ESTIMATES ON USE AND EXPENDITURES FOR PERSONS WITH THE CONDITION
*
*              THE CONDITION USED IN THIS EXERCISE IS DIABETES (CCS CODE=049 OR 050)
*
*DEFINITION OF 61 CONDITIONS BASED ON THE CCS CODE
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
*INPUT FILES:  1) C:\MEPS\STATA\DATA\H180.dta (2015 CONDITION PUF DATA)
*              2) C:\MEPS\STATA\DATA\H181.dta (2015 FY PUF DATA)
*
*********************************************************************************;
clear
set more off
capture log close
log using C:\MEPS\stata\prog\Exercise4.log, replace
cd C:\MEPS\stata\data

/* 1) PULL OUT CONDITIONS WITH DIABETES (CCS CODE='049', '050') FROM 2015 CONDITION PUF - HC180 */
use dupersid cccodex using h180

keep if cccodex=="049" | cccodex=="050"
/* CHECK CCS CODES FOR DIABETIC CONDITIONS */
tab cccodex

/* 2) IDENTIFY PERSONS WHO REPORTED DIABETES */
keep dupersid
sort dupersid
by dupersid: keep if _n==1

tempfile diab
save "`diab'"

use dupersid varstr varpsu perwt15f sex totexp15 totslf15 obtotv15 using h181

sort dupersid
merge 1:1 dupersid using "`diab'"

/* 3) CREATE A FLAG FOR PERSONS WITH DIABETES IN THE 2015 FY DATA */
gen diabper=(_merge==3)
tab diabper _merge

/* UNWEIGHTED # OF PERSONS WHO REPORTED DIABETES, 2015 */
tab diabper sex

/* WEIGHTED # OF PERSONS WHO REPORTED DIABETES, 2015 */
tab diabper sex [iweight=perwt15f]

tabmiss  totexp15 totslf15 obtotv15

/* 4) CALCULATE ESTIMATES ON USE AND EXPENDITURES FOR PERSONS WHO REPORTED DIABETES */
svyset [pweight= perwt15f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy, subpop(diabper): mean totexp15 totslf15 obtotv15
svy, subpop(diabper): mean totexp15 totslf15 obtotv15, over(sex)

svy, subpop(diabper): tabulate sex, obs count percent format(%14.3gc)

log close  
exit, clear
