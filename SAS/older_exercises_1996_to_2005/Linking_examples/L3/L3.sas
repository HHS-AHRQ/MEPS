options ls=120 ps=79 nodate;
ods noproctitle;
/************************************************************************************\
Program:      c:\meps\prog\Example_L3.sas

Description:  This example shows how to:
              (1) Aggregate event records to the person level
              (2) Make 1 annual variable from 3 round variables
              (3) Make a categorical variable from a continuous variable
              (4) Use SUDAAN to calculate standard errors

Input Files:  c:\meps\data\h59g.sas7bdat (2001 Office-Based Visits)
              c:\meps\data\h60.sas7bdat (2001 Full-Year File)
\************************************************************************************/

libname hc 'c:\meps\data';

title 'AHRQ MEPS DATA USERS WORKSHOP (LINKING) -- NOV/DEC 2004';
title2 'Link 2001 Household File and 2001 Events File';

proc format;
  value inscov  1='1 Any Private'  2='2 Public Only'  3='3 Uninsured';
  value insured  1='1 Insured'  2='2 Uninsured';
  value agecat
    1='1. 0-3'
    2='2. 4-7'
    3='3. 8-11'
    4='4. 12-15'
    5='5. 16-17'
    6='6. 18+';
  value genckup  1='1 General Checkup'  2='2 No General Checkup';
run;

         /* 2001 Office-based medical provider visits                                 */
         /* Identify persons with a visit for a general check-up & their expenditures */

title3 "# Persons with a General Checkup in a Provider's Office";
data h59g;   set hc.h59g(keep=dupersid vstctgry obxp01x obsf01x);   by dupersid;
  if first.dupersid then do;
    genckup=.;
    ambtotpd=0;
    ambfampd=0;
  end;
  retain genckup ambtotpd ambfampd;
  if vstctgry = 1 then do;
     genckup = 1;
     ambtotpd + obxp01x;
     ambfampd + obsf01x;
  end;
  if last.dupersid;
  label
    genckup ='Had Office-Based General Checkup'
    ambtotpd='Total Amount Paid'
    ambfampd='Amount Paid by Family';
  keep  dupersid genckup ambtotpd ambfampd;
run;
proc freq;   tables genckup/missing;   run;

title3 'Variables from Full-Year File (Persons w/ Positive Weight)';
data h60;  set hc.h60(keep=dupersid perwt01f varstr01 varpsu01 age31x--age53x inscov01);
  by dupersid;
         /* subset to positive weight persons */
  if perwt01f > 0;
         /* define AGE as last nonmissing age in 2001 */
  if age53x ge 0 then age=age53x;
    else if age42x ge 0 then age=age42x;
    else if age31x ge 0 then age=age31x;
         /* make age category variable */
  agecat = (age ge 0) + (age gt 3) + (age gt 7) + (age gt 11) + (age gt 15) + (age gt 17);
         /* make insurance status variable */
  if inscov01>2 then insured=2;   else insured=1;
  label insured='Had Health Insurance in 2001';
run;
proc freq;   tables
  insured*inscov01
  agecat/list missing;
  format  insured insured.  inscov01 inscov.  agecat agecat.;
run;
proc means nmiss min max maxdec=0;   class agecat;   var age;   format agecat agecat.;   run;

title3 'Link Person-Level File from Events File with Full-Year Person File';
data pers;   merge
  h59g
  h60(drop=age31x--age53x inscov01 in=a);   by dupersid;   if a;
  if genckup = . then genckup=2;
run;
proc freq;   tables genckup;   format genckup genckup.;   run;

         /* sort for SUDAAN */
proc sort;   by varstr01 varpsu01;   run;

title3 'Persons Age 18+';
proc crosstab data=pers filetype=sas design=wr notot norow;
  subpopn  agecat=6;
  nest  varstr01 varpsu01/missunit;
  weight  perwt01f;
  subgroup  genckup insured;
  levels  2 2;
  tables  genckup genckup*insured;
  print  nsum colper secol / style=box wsumfmt=f15.0 nodate notime;
  rformat  genckup genckup.;
  rformat  insured insured.;
run;

title3 'Persons Age 18+ with a General Checkup';
proc means data=pers(where=(agecat=6 & genckup=1)) n mean maxdec=2;
  class  insured;
  format  insured insured.;
  var  ambtotpd ambfampd;
  weight perwt01f;
run;