*********************************************************************
*
*PROGRAM: 	C:\MEPS\STATA\PROG\EXERCISE2.do
*
*PURPOSE:	  THIS PROGRAM UPDATES SELECTED ESTIMATES FOR A 2015 VERSION OF THE
*           MEPS STATISTICS BRIEF # 275,
*		        "Trends in Antipsychotics Purchases and Expenses for the U.S. Civilian
*                 Noninstitutionalized Population, 1997 and 2007"
*
*          (1) FIGURE 1: TOTAL EXPENSE FOR ANTIPSYCHOTICS
*
*          (2) FIGURE 2: TOTAL NUMBER OF PURCHASES OF ANTIPSYCHOTICS
*
*          (3) FIGURE 3: TOTAL NUMBER OF PERSONS PURCHASING ONE OR MORE ANTIPSYCHOTICS
*
*          (4) FIGURE 4: AVERAGE TOTAL, OUT OF POCKET, AND THIRD PARTY PAYER EXPENSE
*                        FOR ANTIPSYCHOTICS PER PERSON WITH AN ANTIPSYCHOTIC MEDICINE PURCHASE
*
*INPUT FILES:  (1) C:\MEPS\STATA\DATA\H181.dta  (2015 FULL-YEAR CONSOLIDATED PUF)
*              (2) C:\MEPS\STATA\DATA\H178A.dta (2015 PRESCRIBED MEDICINES PUF  )
*
*********************************************************************

clear
set more off
capture log close
log using C:\MEPS\stata\prog\Exercise2.log, replace
cd C:\MEPS\stata\data

/* 1) IDENTIFY ANTIPSYCHOTIC DRUGS USING THERAPEUTIC CLASSIFICATION (TC) CODES */
use dupersid rxrecidx linkidx tc1 tc1s1 rxxp15x rxsf15x if tc1==242 & tc1s1==251 using h178a
list dupersid rxrecidx linkidx rxxp15x rxsf15x in 1/30, table
tab1 tc1 tc1s1

/* 2) SUM DATA TO PERSON-LEVEL */
sort dupersid
by dupersid: egen tot=sum(rxxp15x)
by dupersid: egen oop=sum(rxsf15x)
by dupersid: gen n_purchase=_n

list dupersid n_purchase tot oop rxxp15x rxsf15x in 1/20

by dupersid: keep if _n==_n
gen third_payer   = tot - oop

/* 3) MERGE THE PERSON-LEVEL EXPENDITURES TO THE FY PUF */

tempfile perdrug
save "`perdrug'"

use dupersid varstr varpsu perwt15f using h181
sort dupersid

merge 1:m dupersid using "`perdrug'", keep(master matches)
bysort dupersid: egen max=max(n_purchase)
keep if max==n_purchase
tabmiss  n_purchase tot oop third_payer

gen sub=(_merge==3)
tab sub

recode n_purchase tot oop third_payer (missing=0)
sum n_purchase tot oop third_payer if sub==0

*keep if perwt15f>0
 
/* 4) CALCULATE ESTIMATES ON EXPENDITURES AND USE */
svyset [pweight= perwt15f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy, subpop(sub): mean n_purchase tot oop third_payer, cformat(%8.3g)
svy, subpop(sub): total n_purchase tot oop third_payer
estimates table, b(%13.0f) se(%11.0f)

log close  
exit, clear
