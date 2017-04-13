**********************************************************************************
*
*PROGRAM:      C:\MEPS\STATA\PROG\EXERCISE7.do
*
*DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO CONSTRUCT INSURANCE STATUS VARIABLES FROM
*              MONTHLY INSURANCE VARIABLES (see below) IN THE PERSON-LEVEL DATA 
*
*TRImm14X   Covered by TRICARE/CHAMPVA in mm (Ed)
*MCRmm14    Covered by Medicare in mm
*MCRmm14X   Covered by Medicare in mm (Ed)
*MCDmm14    Covered by Medicaid or SCHIP in mm            
*MCDmm14X   Covered by Medicaid or SCHIP in mm  (Ed)
*OPAmm14    Covered by Other Public A Ins in mm 
*OPBmm14    Covered by Other Public B Ins in mm 
*PUBmm14X   Covered by Any Public Ins in mm (Ed)
*PEGmm14    Covered by Empl Union Ins in mm 
*PDKmm14    Coverer by Priv Ins (Source Unknown) in mm 
*PNGmm14    Covered by Nongroup Ins in mm 
*POGmm14    Covered by Other Group Ins in mm 
*PRSmm14    Covered by Self-Emp Ins in mm 
*POUmm14    Covered by Holder Outside of RU in mm 
*PRImm14    Covered by Private Ins in mm                       
*
*where mm = JA-DE  (January - December)   
*
*INPUT FILE:   C:\MEPS\STATA\DATA\H171.dta (2014 FY PUF DATA)
*
*********************************************************************************
clear
set more off
capture log close
log using c:\meps\stata\prog\exercise7.log, replace
cd c:\meps\stata\data

use dupersid varstr varpsu perwt14f racethx peg??14 pou??14 pdk??14 png??14 pog??14 prs??14 pri??14 ins??14x mcd??14x mcr??14x tri??14x opa??14 opb??14 using h171

local opalist opaja14 opafe14 opama14 opaap14 opamy14 opaju14 opajl14 opaau14 opase14 opaoc14 opano14 opade14
local opblist opbja14 opbfe14 opbma14 opbap14 opbmy14 opbju14 opbjl14 opbau14 opbse14 opboc14 opbno14 opbde14
local peglist pegja14 pegfe14 pegma14 pegap14 pegmy14 pegju14 pegjl14 pegau14 pegse14 pegoc14 pegno14 pegde14
local trilist trija14x trife14x trima14x triap14x trimy14x triju14x trijl14x triau14x trise14x trioc14x trino14x tride14x
local poulist pouja14 poufe14 pouma14 pouap14 poumy14 pouju14 poujl14 pouau14 pouse14 pouoc14 pouno14 poude14
local pdklist pdkja14 pdkfe14 pdkma14 pdkap14 pdkmy14 pdkju14 pdkjl14 pdkau14 pdkse14 pdkoc14 pdkno14 pdkde14
local pnglist pngja14 pngfe14 pngma14 pngap14 pngmy14 pngju14 pngjl14 pngau14 pngse14 pngoc14 pngno14 pngde14
local poglist pogja14 pogfe14 pogma14 pogap14 pogmy14 pogju14 pogjl14 pogau14 pogse14 pogoc14 pogno14 pogde14
local prslist prsja14 prsfe14 prsma14 prsap14 prsmy14 prsju14 prsjl14 prsau14 prsse14 prsoc14 prsno14 prsde14
local mcrlist mcrja14x mcrfe14x mcrma14x mcrap14x mcrmy14x mcrju14x mcrjl14x mcrau14x mcrse14x mcroc14x mcrno14x mcrde14x
local mcdlist mcdja14x mcdfe14x mcdma14x mcdap14x mcdmy14x mcdju14x mcdjl14x mcdau14x mcdse14x mcdoc14x mcdno14x mcdde14x
local prilist prija14 prife14 prima14 priap14 primy14 priju14 prijl14 priau14 prise14 prioc14 prino14 pride14
local inslist insja14x insfe14x insma14x insap14x insmy14x insju14x insjl14x insau14x insse14x insoc14x insno14x insde14x

/*1) count # of months with insurance*/
egen pri_n=anycount(`prilist'), v(1)
egen ins_n=anycount(`inslist'), v(1)
egen unins_n=anycount(`inslist'), v(2)
egen mcd_n=anycount(`mcdlist'), v(1)
egen mcr_n=anycount(`mcrlist'), v(1)
egen tri_n=anycount(`trilist'), v(1)
egen ref_n=anycount(`inslist'), v(1 2)

/*2) create flags for various types of insu*/
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
       local png=word("`pnglist'",`i')
       local pog=word("`poglist'",`i')
       local prs=word("`prslist'",`i')
       gen ng`i'=(`png'==1 | `pog'==1 |`prs'==1)
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

label define racethx 1 "1 Hispanic" 2 "2 White" 3 "3 Black" 4 "4 Asian" 5 "5 Other"
label value racethx racethx

tab1 pri_n ins_n unins_n mcd_n mcr_n tri_n opab_n grp_n ng_n pub_n ref_n 
tab1 full_ins group_ins1 group_ins2 ng_ins
tab full_insu unins_n
tab group_ins1 grp_n
tab ng_ins ng_n

/*3) calculate % of persons covered by insu*/
svyset [pweight=perwt14f], strata(varstr) psu(varpsu) vce(linearized) singleunit(missing)
svy: mean full_insu group_ins1 group_ins2 ng_ins, over(racethx)

log close  
exit, clear
