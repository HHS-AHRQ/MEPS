******************************************************************************************************************
*  Exercise 2: 
*  This program generates National Totals and Per-person Averages for Narcotic
*  analgesics and Narcotic analgesic combos for the U.S. civilian non-institutionalized population, including:
*   - Number of purchases (fills)  
*   - Total expenditures          
*   - Out-of-pocket payments       
*   - Third-party payments        
* 
*  Input files:
*   - C:/MEPS/h209.dat  (2018 Full-year file)
*   - C:/MEPS/h206a.dat (2018 Prescribed medicines file)
* 
*  This program is available at:
*  https://github.com/HHS-AHRQ/MEPS-workshop/tree/master/stata_exercises
******************************************************************************************************************

clear
set more off
capture log close
cd C:\MEPS
log using Ex2.log, replace

use C:\MEPS\DATA\h206a, clear
// 1) identify Narcotic analgesics or Narcotic analgesic combos using therapeutic classification (tc) codes, keep only narcotic Rx
keep if (tc1s1_1==60 | tc1s1_1==191)
list dupersid rxrecidx linkidx rxxp18x rxsf18x in 1/30, table
tab1 tc1s1_1

// 2) sum data to person-level
gen one=1
collapse (sum) n_purchase=one tot=rxxp18x oop=rxsf18x, by(dupersid)
gen third_payer   = tot - oop
list dupersid n_purchase tot oop third_payer in 1/20
save person_Rx, replace

// 3) merge the person-level expenditures to the FY PUF, identify subpopulation 
use C:\MEPS\DATA\h209, clear
merge 1:1 dupersid using person_Rx, gen(merge1)

recode n_purchase tot oop third_payer (missing=0)

gen sub=(merge1==3 & perwt18f>0)
tab sub

save merge_h209_h206a, replace
// 4) calculate estimates on expenditures and use
svyset [pweight= perwt18f], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)

svy, subpop(sub): mean n_purchase tot oop third_payer, cformat(%8.3g)
svy, subpop(sub): total n_purchase tot oop third_payer
estimates table, b(%13.0f) se(%11.0f)

svy, subpop(sub): mean tot oop third_payer, over(racethx)

/* Remove temporary files */
erase person_Rx.dta 
erase merge_h209_h206a.dta




