options ls=120 ps=79 nodate;
ods noproctitle;

/************************************************************************************\
Program:      c:\meps\prog\Example_L1.sas

Description:  This example shows how to:
              (1) Identify jobs in first part of 2001
              (2) Count the numbers of each type of job for each person
              (3) Merge JOBS and FY files
              (4) Use SUDAAN to calculate standard errors
              (5) Use SAS to calculate relative standard errors from SUDAAN output

Input Files:  c:\meps\data\h56.sas7bdat (2001 Jobs)
              c:\meps\data\h60.sas7bdat (2001 Full-Year Persons)
\************************************************************************************/

libname hc 'c:\meps\data';

title 'AHRQ MEPS DATA USERS WORKSHOP (LINKING) -- NOV/DEC 2004';
title2 '2001 JOBS';
title3 'Types and Numbers of Jobs at Beginning of Year';

proc format;
  value subtype
    1='1 Current Main'
    2='2 Current Miscellaneous'
    3='3 Former Main'
    4='4 Former Miscellaneous'
    5='5 Last Job Outside Rn'
    6='6 Retirement';
  value age  -1='-1'  0-15='0-15'  16-17='16-17'  18-high='18+';
value pos  0<-high='>0';
run;

         /* Subset JOBS file to first-round  records */
data;  set hc.h56;   by dupersid;
  if (panel=5 & rn=3) | (panel=6 & rn=1);
run;

title4 'All Jobs at Beginning of Year';
proc freq;   tables subtype;   format subtype subtype.;   run;

         /* Get person-level counts of each type of job from first-round JOBS records */
data jobsper;  set _last_;   by dupersid;
  if first.dupersid then do;                       /* initialize count variables */
    n1=0;   n2=0;   n3=0;   n4=0;   n5=0;   n6=0;   totjobs=0;
  end;
  if subtype=1 then n1+1;
    else if subtype=2 then n2+1;
    else if subtype=3 then n3+1;
    else if subtype=4 then n4+1;
    else if subtype=5 then n5+1;
    else if subtype=6 then n6+1;
  totjobs+1;
  if last.dupersid;
  keep dupersid totjobs n1-n6;
  label
    totjobs='Total # Jobs in Rn 1/3'
    n1     ='# Current Main Jobs in Rn 1/3'
    n2     ='# Current Miscellaneous Jobs in Rn 1/3'
    n3     ='# Former Main Jobs in Rn 1/3'
    n4     ='# Former Miscellaneous Jobs in Rn 1/3'
    n5     ='# Last Jobs Outside Rn 1/3'
    n6     ='# Retirement Jobs in Rn 1/3';
run;

title4 'Persons w/ a First-Round JOBS Record';
proc freq;   tables 
  totjobs n1-n6
  totjobs*n1*n2*n3*n4*n5*n6/list missing;
run;

         /* Combine new person-level file w/ full-year PUF */
data allper;   merge
  hc.h60(keep=dupersid panel01 age31x perwt01f varstr01 varpsu01)
  jobsper;   by dupersid;
run;

title3 'Persons Age 18+: # of Current Main & Miscellaneous Jobs at Beginning of Year';
data curr;   set allper;
         /* Get count of current main or miscellaneous jobs in Rn 1/3 */
         /*   & collapse into categories                              */
         /* New var must begin w/ 1 for SUDAAN                        */
  numcurr=n1+n2;
  ncurr=numcurr+1;
  if ncurr>3 then ncurr=4;
run;

         /* Sort by the Stratum & PSU variables for SUDAAN */
proc sort;   by varstr01 varpsu01;   run;

proc crosstab data=curr filetype=sas design=wr noprint;
  subpopn  age31x >= 18;
  nest varstr01 varpsu01;
  weight  perwt01f;
  subgroup  ncurr;
  levels  4;
  tables  ncurr;
  output  nsum wsum sewgt colper secol / filename=x;
run;

         /* Calculate relative standard errors (RSE) */
data y;   set x;
  if wsum > 0 then rsewgt = sewgt / wsum;       /* only if denominator > 0 */
  if colper > 0 then rsecol = secol / colper;
  if rsewgt > .3 or rsecol > .3 then flag = '*';
run;

proc format;   value ncurr
  0='TOTAL'
  1='None'
  2=' 1'
  3=' 2'
  4=' 3+';
run;
proc print l split='*';   id ncurr;
  var  nsum wsum sewgt rsewgt colper secol rsecol flag;
  format  ncurr ncurr.  nsum comma6.  wsum comma11.  sewgt comma9.  rsewgt rsecol 5.3
    colper 6.2  secol 4.2;
  label
    ncurr ='# Curr*Jobs'
    nsum  ='Sample'
    wsum  ='Population'
    sewgt ='SE*Pop'
    rsewgt='RSE*Pop'
    colper='Column*%'
    secol ='SE*Col %'
    rsecol='RSE*Col %';
run;