*********************************************************************
*
*PURPOSE:		THIS PROGRAM GENERATES SELECTED ESTIMATES FOR A 2016 VERSION OF Purchases and Expenses for Narcotic analgesics or Narcotic analgesic combos
*
*    				(1) FIGURE 1: TOTAL EXPENSE FOR Narcotic analgesics or Narcotic analgesic combos
*
*    				(2) FIGURE 2: TOTAL NUMBER OF PURCHASES OF Narcotic analgesics or Narcotic analgesic combos
*
*    				(3) FIGURE 3: TOTAL NUMBER OF PERSONS PURCHASING ONE OR MORE Narcotic analgesics or Narcotic analgesic combos
*
*    				(4) FIGURE 4: AVERAGE TOTAL, OUT OF POCKET, AND THIRD PARTY PAYER EXPENSE
*                  				FOR Narcotic analgesics or Narcotic analgesic combos PER PERSON WITH A Narcotic analgesics or Narcotic analgesic combos MEDICINE PURCHASE
*
*INPUT FILES:  (1) C:\MEPS\STATA\DATA\H192.dta  (2016 FULL-YEAR CONSOLIDATED PUF)
*              (2) C:\MEPS\STATA\DATA\H188A.dta (2016 PRESCRIBED MEDICINES PUF)
*
*********************************************************************

clear
set more off
capture log close
/*
log using c:\meps\stata\prog\exercise2.log, replace
cd c:\meps\stata\data

log using \\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\STATA\PROG\exercise2.log, replace
cd \\programs.ahrq.local\programs\MEPS\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018_Fall\STATA\DATA
*/

// 1) identify Narcotic analgesics or Narcotic analgesic combos using therapeutic classification (tc) codes
import sasxport5 "C:\MEPS\h188a.ssp"
keep dupersid rxrecidx linkidx tc1s1_1 rxxp16x rxsf16x
keep if (tc1s1_1==60 | tc1s1_1==191)

list dupersid rxrecidx linkidx rxxp16x rxsf16x in 1/30, table
tab1 tc1s1_1

// 2) sum data to person-level
sort dupersid
by dupersid: egen tot=sum(rxxp16x)
by dupersid: egen oop=sum(rxsf16x)
by dupersid: gen n_purchase=_n

list dupersid n_purchase tot oop rxxp16x rxsf16x in 1/20

by dupersid: keep if _n==_N
gen third_payer   = tot - oop

// 3) merge the person-level expenditures to the fy puf
tempfile perdrug
save "`perdrug'"

import sasxport5 "C:\MEPS\h192.ssp"
keep dupersid varstr varpsu perwt16f
sort dupersid

merge 1:m dupersid using "`perdrug'", keep(master matches)
*tabmiss  n_purchase tot oop third_payer

gen sub=(_merge==3)
tab sub

recode n_purchase tot oop third_payer (missing=0)
sum n_purchase tot oop third_payer if sub==0

 keep if perwt16f>0
// 4) calculate estimates on expenditures and use
svyset [pweight= perwt16f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy, subpop(sub): mean n_purchase tot oop third_payer, cformat(%8.3g)
svy, subpop(sub): total n_purchase tot oop third_payer
estimates table, b(%13.0f) se(%11.0f)

*log close
exit, clear
