***********************************************************************************
*                                                                                           
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO CONSTRUCT FAMILY-LEVEL VARIABLES FROM
*              PERSON-LEVEL DATA
*
*              THERE ARE TWO DEFINITIONS OF FAMILY UNIT IN MEPS.
*                 1) CPS FAMILY:  ID IS DUID + CPSFAMID.  CORRESPONDING WEIGHT IS FAMWT12C.
*                 2) MEPS FAMILY: ID IS DUID + FAMIDYR.   CORRESPONDING WEIGHT IS FAMWT12F.
*
*              THE CPS FAMILY IS USED IN THIS EXERCISE.
*
*INPUT FILE:   C:\MEPS\STATA\DATA\H181.dta (2015 FY PUF DATA)
*
**********************************************************************************

clear
set more off
capture log close
log using C:\MEPS\stata\prog\Exercise3.log, replace
cd C:\MEPS\stata\data

use dupersid duid cpsfamid famwt15c varstr varpsu totslf15 ttlp15x using h181

sort duid cpsfamid
list duid cpsfamid totslf15 ttlp15x in 1/20

by duid cpsfamid: egen famoop=sum(totslf15)
by duid cpsfamid: egen faminc=sum(ttlp15x)
by duid cpsfamid: egen famsize=count(cpsfamid)

list duid cpsfamid famwt15c famsize famoop faminc totslf15 ttlp15x in 1/20

sort duid cpsfamid famwt15c
by duid cpsfamid: keep if famsize==_n

list duid cpsfamid famwt15c famsize famoop faminc in 1/20

tabmiss famsize famoop faminc

/* keep if the family weight is positive: famwt15c>0 */
svyset [pweight= famwt15c], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy, subpop(if famwt15c>0): mean famsize famoop faminc

log close
exit, clear
