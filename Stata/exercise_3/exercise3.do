***********************************************************************************        
*
*PROGRAM:      C:\MEPS\STATA\PROG\EXERCISE3.do
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO CONSTRUCT FAMILY-LEVEL VARIABLES FROM PERSON-LEVEL DATA 
*
*              THERE ARE TWO DEFINITIONS OF FAMILY UNIT IN MEPS.
*                 1) CPS FAMILY:  ID IS DUID + CPSFAMID.  CORRESPONDING WEIGHT IS FAMWT14C.
*                 2) MEPS FAMILY: ID IS DUID + FAMIDYR.   CORRESPONDING WEIGHT IS FAMWT14F.
*
*              THE CPS FAMILY IS USED IN THIS EXERCISE.
*
*INPUT FILE:   C:\MEPS\STATA\DATA\H171.dta (2014 FY PUF DATA)                              
*                                                                                         
**********************************************************************************     

clear
set more off
capture log close
log using c:\meps\stata\prog\exercise3.log, replace
cd c:\meps\stata\data

use dupersid duid cpsfamid famwt14c varstr varpsu totslf14 ttlp14x using h171

sort duid cpsfamid
list duid cpsfamid totslf14 ttlp14x in 1/20

by duid cpsfamid: egen famoop=sum(totslf14)
by duid cpsfamid: egen faminc=sum(ttlp14x)
by duid cpsfamid: gen  famsize=_N

list duid cpsfamid famwt14c famsize famoop faminc totslf14 ttlp14x in 1/20

sort duid cpsfamid famwt14c
by duid cpsfamid: keep if _n==_N

list duid cpsfamid famwt14c famsize famoop faminc in 1/20

tabmiss famsize famoop faminc // user-written command to tabulate missing values

keep if famwt14c>0
svyset [pweight= famwt14c], strata( varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy: mean famsize famoop faminc

log close  
exit, clear
