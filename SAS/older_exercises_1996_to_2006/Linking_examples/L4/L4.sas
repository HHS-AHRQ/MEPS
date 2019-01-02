options ls=120 ps=79 nodate;
ods noproctitle;
/************************************************************************************\
Program:      c:\meps\prog\Example_L4.sas

Description:  This example shows how to:
              (1) Identify persons with specific condition(s)
              (2) Subset condition file to person level
              (3) Make one variable from five variables
              (4) Use SUDAAN to calculate standard errors

Input Files:  c:\meps\data\h61.sas7bdat (2001 Conditions)
              c:\meps\data\h60.sas7bdat (2001 Full-Year Persons)
\************************************************************************************/

libname hc 'c:\meps\data';

title 'AHRQ MEPS DATA USERS WORKSHOP (LINKING) -- NOV/DEC 2004';
title2 'Link 2001 Household File and 2001 Conditions File';

proc format;
   value ovr  1-4='1-4';
   value overall
     1='1 Very Serious'
     2='2 Somewhat Serious'
     3='3 Not Very Serious'
     4='4 Not at All'
     5='5 Missing'
     6='6 Not Have Asthma';
  value asthma
    1='1 Has Asthma'
    2='2 No Asthma';
  value agecat  1='1. 0-17'  2='2. 18+';
run;

         /* Identify persons with asthma */
title3 'Persons with Asthma';
data;   set hc.h61(where=(icd9codx='493') keep=dupersid panel01 condrn icd9codx
  ovrall1-ovrall5);
run;

         /* Keep first-reported asthma record for person */
proc sort data=_last_;   by dupersid condrn;   run;
data;   set _last_;   by dupersid;   if first.dupersid;   run;

proc freq;   tables
  panel01*condrn*ovrall1*ovrall2*ovrall3*ovrall4*ovrall5/list missing;
  format  ovrall1-ovrall5 ovr.;
run;

         /* Assign first-reported OVRALLi to OVERALL */
data asthma;   set _last_;   by dupersid;
  if ovrall1 > -1 then overall = ovrall1;
    else if ovrall2 > -1 then overall = ovrall2;
    else if ovrall3 > -1 then overall = ovrall3;
    else if ovrall4 > -1 then overall = ovrall4;
    else if ovrall5 > -1 then overall = ovrall5;
  if overall=. then overall=5;
run;

proc freq;   tables
  overall
  overall*ovrall1*ovrall2*ovrall3*ovrall4*ovrall5/list missing;
  format  ovrall1-ovrall5 ovr.  overall overall.;
run;

title3 'All Persons (with Positive Weight)';
data pers;   merge
  hc.h60(keep=dupersid perwt01f varstr01 varpsu01 age31x age42x age53x)
  asthma(in=a drop=panel01 condrn icd9codx ovrall1-ovrall5);   by dupersid;
  if perwt01f > 0;
  if a then asthma=1;   else asthma=2;
  if overall=. then overall=6;
  if age53x ge 0 then age=age53x;
    else if age42x ge 0 then age=age42x;
    else if age31x ge 0 then age=age31x;
  if  0 le age < 18 then agecat=1;
    else if age ge 18 then agecat=2;
  drop age31x age42x age53x;
  label
    overall='How Asthma Affects Overall Health'
    asthma ='1 if P Has Asthma'
    agecat ='Age 0-17, 18+';
run;
proc sort;   by varstr01 varpsu01;   run;

proc freq;   tables
  asthma (asthma overall)*agecat/missing;
  format  asthma asthma.  overall overall.  agecat agecat.;
run;

         /* Output on asthma */
proc crosstab data=pers filetype=sas design=wr notot norow;
  nest  varstr01 varpsu01/missunit;
  weight  perwt01f;
  subgroup  asthma;
  levels  2;
  tables  asthma;
  print / style=nchs wsumfmt=f15.0 nodate notime;
  rformat  asthma asthma.;
run;

         /* How asthma affects health */
proc crosstab data=pers filetype=sas design=wr notot norow;
  nest  varstr01 varpsu01/missunit;
  weight  perwt01f;
  subgroup  overall agecat;
  levels  5 2;
  subpopn  asthma=1;
  tables  overall overall*agecat;
  print / style=nchs wsumfmt=f15.0 nodate notime;
  rformat  overall overall.;
  rformat  agecat agecat.;
run;