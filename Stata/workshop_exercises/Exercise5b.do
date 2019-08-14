**********************************************************************************
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO CONSTRUCT INSURANCE STATUS VARIABLES FROM
*              MONTHLY INSURANCE VARIABLES (see below) IN THE PERSON-LEVEL DATA
*
*TRImm15X   Covered by TRICARE/CHAMPVA in mm (Ed)
*MCRmm15    Covered by Medicare in mm
*MCRmm15X   Covered by Medicare in mm (Ed)
*MCDmm15    Covered by Medicaid or SCHIP in mm
*MCDmm15X   Covered by Medicaid or SCHIP in mm  (Ed)
*OPAmm15    Covered by Other Public A Ins in mm
*OPBmm15    Covered by Other Public B Ins in mm
*PUBmm15X   Covered by Any Public Ins in mm (Ed)
*PEGmm15    Covered by Empl Union Ins in mm
*PDKmm15    Coverer by Priv Ins (Source Unknown) in mm
*PNGmm15    Covered by Nongroup Ins in mm
*POGmm15    Covered by Other Group Ins in mm
*PRSmm15    Covered by Self-Emp Ins in mm
*POUmm15    Covered by Holder Outside of RU in mm
*PRImm15    Covered by Private Ins in mm
*
*
*
*where mm = JA-DE  (January - December)
*
*INPUT FILE:   C:\MEPS\STATA\DATA\H181.dta (2015 FY PUF DATA)
*********************************************************************************
clear
set more off
capture log close
log using C:\MEPS\stata\prog\Exercise7.log, replace
cd C:\MEPS\stata\data

use dupersid varstr varpsu perwt15f racethx prx??15 peg??15 pou??15 pdk??15 png??15 pog??15 prs??15 pri??15 ins??15x mcd??15x mcr??15x tri??15x opa??15 opb??15 using h181

local opalist opaja15 opafe15 opama15 opaap15 opamy15 opaju15 opajl15 opaau15 opase15 opaoc15 opano15 opade15
local opblist opbja15 opbfe15 opbma15 opbap15 opbmy15 opbju15 opbjl15 opbau15 opbse15 opboc15 opbno15 opbde15
local prxlist prxja15 prxfe15 prxma15 prxap15 prxmy15 prxju15 prxjl15 prxau15 prxse15 prxoc15 prxno15 prxde15
local peglist pegja15 pegfe15 pegma15 pegap15 pegmy15 pegju15 pegjl15 pegau15 pegse15 pegoc15 pegno15 pegde15
local trilist trija15x trife15x trima15x triap15x trimy15x triju15x trijl15x triau15x trise15x trioc15x trino15x tride15x
local poulist pouja15 poufe15 pouma15 pouap15 poumy15 pouju15 poujl15 pouau15 pouse15 pouoc15 pouno15 poude15
local pdklist pdkja15 pdkfe15 pdkma15 pdkap15 pdkmy15 pdkju15 pdkjl15 pdkau15 pdkse15 pdkoc15 pdkno15 pdkde15
local pnglist pngja15 pngfe15 pngma15 pngap15 pngmy15 pngju15 pngjl15 pngau15 pngse15 pngoc15 pngno15 pngde15
local poglist pogja15 pogfe15 pogma15 pogap15 pogmy15 pogju15 pogjl15 pogau15 pogse15 pogoc15 pogno15 pogde15
local prslist prsja15 prsfe15 prsma15 prsap15 prsmy15 prsju15 prsjl15 prsau15 prsse15 prsoc15 prsno15 prsde15
local mcrlist mcrja15x mcrfe15x mcrma15x mcrap15x mcrmy15x mcrju15x mcrjl15x mcrau15x mcrse15x mcroc15x mcrno15x mcrde15x
local mcdlist mcdja15x mcdfe15x mcdma15x mcdap15x mcdmy15x mcdju15x mcdjl15x mcdau15x mcdse15x mcdoc15x mcdno15x mcdde15x
local prilist prija15 prife15 prima15 priap15 primy15 priju15 prijl15 priau15 prise15 prioc15 prino15 pride15
local inslist insja15x insfe15x insma15x insap15x insmy15x insju15x insjl15x insau15x insse15x insoc15x insno15x insde15x

/*1) COUNT # OF MONTHS WITH INSURANCE*/
egen pri_n=anycount(`prilist'), v(1)
egen prx_n=anycount(`prxlist'), v(1)
egen ins_n=anycount(`inslist'), v(1)
egen unins_n=anycount(`inslist'), v(2)
egen mcd_n=anycount(`mcdlist'), v(1)
egen mcr_n=anycount(`mcrlist'), v(1)
egen tri_n=anycount(`trilist'), v(1)
egen ref_n=anycount(`inslist'), v(1 2)

/*2) CREATE FLAGS FOR VARIOUS TYPES OF INSU*/
forval i=1/12 {
       local opa=word("`opalist'",`i')
       local opb=word("`opblist'",`i')
       gen op`i'=(`opa'==1 | `opb'==1)
       }
egen opab_n=anycount(op1-op12), v(1)

forval i=1/12 {
       local peg=word("`peglist'",`i')
       local tri=word("`trilist'",`i')
       local pou=word("`poulist'",`i')
       local pdk=word("`pdklist'",`i')
       gen grp`i'=(`peg'==1 | `tri'==1 |`pou'==1 | `pdk'==1 )
       }
egen grp_n=anycount(grp1-grp12), v(1)

forval i=1/12 {
       local prx=word("`prxlist'",`i')
       local png=word("`pnglist'",`i')
       local pog=word("`poglist'",`i')
       local prs=word("`prslist'",`i')
       gen ng`i'=(`png'==1 | `pog'==1 |`prs'==1 | `prx'==1)
       }
egen ng_n=anycount(ng1-ng12), v(1)

forval i=1/12 {
       local mcr=word("`mcrlist'",`i')
       local mcd=word("`mcdlist'",`i')
       local opa=word("`opalist'",`i')
       local opb=word("`opblist'",`i')
       gen pub`i'=(`mcr'==1 | `mcd'==1 |`opa'==1 | `opb'==1 )
       }
egen pub_n=anycount(pub1-pub12), v(1)

gen full_insu=(unins_n==0)
gen group_ins1=(grp_n>0)
gen group_ins2=(grp_n>0 & grp_n==ref_n)
gen ng_ins=(ng_n>0)
gen exch_ins=(prx_n>0)

tab1 pri_n ins_n unins_n mcd_n mcr_n tri_n opab_n grp_n ng_n pub_n ref_n
tab1 full_ins group_ins1 group_ins2 ng_ins
tab full_insu unins_n
tab group_ins1 grp_n
tab ng_ins ng_n
tab exch_ins prx_n

/*3) CALCULATE % OF PERSONS COVERED BY INSU*/
label define racethx 1 "hispanic" 2 "white" 3 "black" 4 "asian" 5 "other"
label values racethx racethx
svyset [pweight=perwt15f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy: mean full_insu group_ins1 group_ins2 ng_ins exch_ins
svy: mean full_insu group_ins1 group_ins2 ng_ins exch_ins, over(racethx)

log close
exit, clear
