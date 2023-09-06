* MEPS-HC: Prescribed medicine utilization and expenditures for 
* the treatment of hyperlipidemia
* 
* This example code shows how to link the MEPS-HC Medical Conditions file, 
* the Prescribed Medicines file, and the Full-Year Consolidated file for 
* data year 2020 in order to estimate the following:
*
*   - Total number of people with one or more rx fills for hyperlipidemia
*   - Total rx fills for the treatment of hyperlipidemia
*   - Total rx expenditures for the treatment of hyperlipidemia 
*   - Mean number of Rx fills for hyperlipidemia per person, among those with any, by sex and household income
*   - Mean expenditures on Rx fills for hyperlipidemia per person, among those with any, by sex and household income
* 
* Input files:
*   - h220a.dta        (2020 Prescribed Medicines file)
*   - h222.dta         (2020 Conditions file)
*   - h220if1.dta      (2020 CLNK: Condition-Event Link file)
*   - h224.dta         (2020 Full-Year Consolidated file)
* 
* Resources:
*   - CCSR codes: 
*   https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv
* 
*   - MEPS-HC Public Use Files: 
*   https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp
* 
*   - MEPS-HC online data tools: 
*   https://datatools.ahrq.gov/meps-hc
*
* -----------------------------------------------------------------------------

clear
set more off
capture log close
cd C:\MEPS
log using Ex_Summer_2023.log, replace 

/* Get data from web (you can also download manually) */
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h220a/h220adta.zip" "h220adta.zip", replace
unzipfile "h220adta.zip", replace 
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h222/h222dta.zip" "h222dta.zip", replace
unzipfile "h222dta.zip", replace 
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h220i/h220if1dta.zip" "h220if1dta.zip", replace
unzipfile "h220if1dta.zip", replace 
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h224/h224dta.zip" "h224dta.zip", replace
unzipfile "h224dta.zip", replace 

/* linkage file */
use h220if1, clear
rename *, lower
// inspect file, save
list dupersid condidx evntidx eventype if _n<20
save CLNK_2020, replace

/* FY condolidated file, person-level */
use DUPERSID SEX AGELAST CHOLDX POVCAT20 VARSTR VARPSU PERWT20F using h224, clear
rename *, lower

/* create 0/1 variable identifying people ever diagnosed with HL */
recode choldx (1=1) (2=0) (*=.), gen(HL_ever)
// inspect file, save 
list if _n<20
tab1 HL_ever, m
tab sex HL_ever, m
save FY_2020, replace

/* PMED file, Rx fill-level */
use DUPERSID DRUGIDX RXRECIDX LINKIDX RXDRGNAM RXXP20X using h220a, clear
rename *, lower
rename linkidx evntidx
// inspect file, save
list dupersid drugidx rxrecidx evntidx if dupersid=="2320134102"
save PM_2020, replace

/* Conditions file, condition-level, subset to hyperlipidemia */
use DUPERSID CONDIDX ICD10CDX CCSR1X-CCSR3X using h222, clear
rename *, lower
// keep only records for HL
keep if ccsr1x == "END010" | ccsr2x == "END010" | ccsr3x == "END010"
// inspect file, save 
list dupersid condidx icd10cdx if dupersid=="2320134102"
save COND_2020, replace

/* merge conditions to CLNK file by condidx, drop unmatched */
merge m:m condidx using CLNK_2020
// drop observations that do not match
drop if _merge~=3
drop _merge
// inspect file
list dupersid condidx evntidx icd10cdx if dupersid=="2320134102"
// drop duplicate fills--- fills that would otherwise be counted twice */
duplicates drop evntidx, force
// inspect file after de-duplication
list dupersid condidx evntidx icd10cdx if dupersid=="2320134102"

/* merge to prescribed meds file by evntidx, drop unmatched */
merge 1:m evntidx using PM_2020
// drop observations for that do not match
drop if _merge~=3
drop _merge
// inspect file
list dupersid condidx icd10cdx evntidx rxrecidx rxdrgnam if dupersid=="2320134102"

/* collapse to person-level (DUPERSID), sum to get number of fills and expenditures */
gen one=1
collapse (sum) num_rx=one (sum) exp_rx=rxxp20x, by(dupersid)

/* merge to FY file, create flag for any Rx fill for HL */
merge 1:1 dupersid using FY_2020
replace exp_rx=0 if _merge==2
replace num_rx=0 if _merge==2
gen any_rx=(num_rx>0)

/* Set survey options */
svyset varpsu [pw = perwt20f], strata(varstr) vce(linearized) singleunit(centered)

/* Compare people ever diagnosed with hyperlipidemia (CHOLDX == 1) with those that have treated hyperlipidemia */
tab1 HL_ever any_rx, m
tab HL_ever any_rx, m
svy: total HL_ever
di %15.0f r(table)[1,1]
di %15.0f r(table)[2,1]
svy: mean HL_ever

/* total number of people with 1+ Rx fills for HL */
svy: total any_rx
di %15.0f r(table)[1,1]
di %15.0f r(table)[2,1]

/* Total rx fills for the treatment of hyperlipidemia */
svy: total num_rx
di %15.0f r(table)[1,1]
di %15.0f r(table)[2,1]

/* Total rx expenditures for the treatment of hyperlipidemia */
svy: total exp_rx
di %15.0f r(table)[1,1]
di %15.0f r(table)[2,1]

/* Percent with any Rx fills for hyperlipidemia, by sex and race */
svy: mean any_rx
svy: mean any_rx, over(sex)
svy: mean any_rx, over(povcat)

/* Mean number of Rx fills for hyperlipidemia per person, among those with any, by race and sex */
svy, sub(any_rx): mean num_rx
svy, sub(any_rx): mean num_rx, over(sex)
svy, sub(any_rx): mean num_rx, over(povcat)

/* mean expenditures on Rx fills for hyperlipidemia per person, among those with any by sex and race */
svy, sub(any_rx): mean exp_rx
svy, sub(any_rx): mean exp_rx, over(sex)
svy, sub(any_rx): mean exp_rx, over(povcat)


