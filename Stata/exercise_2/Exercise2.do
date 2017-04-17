*********************************************************************
*
*PROGRAM: 	C:\MEPS\STATA\PROG\EXERCISE2.do
*
*PURPOSE:		THIS PROGRAM GENERATES SELECTED ESTIMATES FOR A 2014 VERSION OF THE
*          	MEPS STATISTICS BRIEF # 275: "Trends in Antipsychotics Purchases and Expenses for the U.S. Civilian
*                                        Noninstitutionalized Population, 1997 and 2007"
*
*    				(1) FIGURE 1: TOTAL EXPENSE FOR ANTIPSYCHOTICS
*
*    				(2) FIGURE 2: TOTAL NUMBER OF PURCHASES OF ANTIPSYCHOTICS
*
*    				(3) FIGURE 3: TOTAL NUMBER OF PERSONS PURCHASING ONE OR MORE ANTIPSYCHOTICS
*
*    				(4) FIGURE 4: AVERAGE TOTAL, OUT OF POCKET, AND THIRD PARTY PAYER EXPENSE
*                  				FOR ANTIPSYCHOTICS PER PERSON WITH AN ANTIPSYCHOTIC MEDICINE PURCHASE
*
*INPUT FILES:  (1) C:\MEPS\STATA\DATA\H171.dta  (2014 FULL-YEAR CONSOLIDATED PUF)
*              (2) C:\MEPS\STATA\DATA\H168A.dta (2014 PRESCRIBED MEDICINES PUF)
*
*********************************************************************

clear
set more off
capture log close
log using c:\meps\stata\prog\exercise2.log, replace
cd c:\meps\stata\data

// 1) identify antipsychotic drugs using therapeutic classification (tc) codes
use dupersid rxrecidx linkidx tc1 tc1s1 rxxp14x rxsf14x if tc1==242 & tc1s1==251 using h168a
list dupersid rxrecidx linkidx rxxp14x rxsf14x in 1/30, table
tab1 tc1 tc1s1

// 2) sum data to person-level
sort dupersid
by dupersid: egen tot=sum(rxxp14x)
by dupersid: egen oop=sum(rxsf14x)
by dupersid: gen n_purchase=_n

list dupersid n_purchase tot oop rxxp14x rxsf14x in 1/20

by dupersid: keep if _n==_N
gen third_payer   = tot - oop

// 3) merge the person-level expenditures to the fy puf
tempfile perdrug
save "`perdrug'"

use dupersid varstr varpsu perwt14f using h171
sort dupersid

merge 1:m dupersid using "`perdrug'", keep(master matches)
tabmiss  n_purchase tot oop third_payer // user-written command to tabulate missing values

gen sub=(_merge==3)
tab sub

recode n_purchase tot oop third_payer (missing=0)
sum n_purchase tot oop third_payer if sub==0

 keep if perwt14f>0
// 4) calculate estimates on expenditures and use
svyset [pweight= perwt14f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy, subpop(sub): mean n_purchase tot oop third_payer, cformat(%8.3g)
svy, subpop(sub): total n_purchase tot oop third_payer
estimates table, b(%13.0f) se(%11.0f)

log close
exit, clear
