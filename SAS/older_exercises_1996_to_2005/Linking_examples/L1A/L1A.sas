options ls=120 ps=79 nodate;
ods noproctitle;

/************************************************************************************\
Program:      c:\meps\prog\Example_L1A.sas

Description:  This example shows how to:
              (1) Identify 2001 jobs in that began in 2000
              (2) Identify first-reported 2000 jobs
              (3) Update missing 2001 values with 2000 values

Input Files:  c:\meps\data\h40.sas7bdat (2000 Jobs)
              c:\meps\data\h56.sas7bdat (2001 Jobs)
\************************************************************************************/

libname hc 'c:\meps\data';

title 'AHRQ MEPS DATA USERS WORKSHOP (LINKING) -- NOV/DEC 2004';
title2 'Link 2000 and 2001 JOBS Files';

proc format;
  value yn
    -9='-9 Not Asc'
    -8='-8 DK'
    -7='-7 Refised'
    -1='-1 Inappl'
     1=' 1 Yes'
     2=' 2 No';
run;

*---------------------------------------------------------------------------------------;

title3 'Sample Listing, All Job Records for Persons Who Have the Same Job in 2000 and 2001';
title4 'Variables of Interest Are SICKPAY, PAYDRVST, & PAYVACTN';

data s00;   set hc.h40(where=(dupersid in('80001021','80005018','80005025','80006012',
  '80006029') & rn in(1,2)));   YEAR=2000;
run;
proc sort;   by dupersid jobsn rn;   run;

data s01;   set hc.h56(where=(dupersid in('80001021','80005018','80005025','80006012',
  '80006029')));   YEAR=2001;
run;
proc sort;   by dupersid jobsn rn;   run;

data;   set
  s00
  s01;   by dupersid jobsn;
  label dupersid=' ';        /* drop label for print output */

proc print;   by dupersid;
  var  year rn jobsn subtype stillat sickpay--payvactn;
run;

*---------------------------------------------------------------------------------------;

title3 '2001 Current Main Jobs that Began in 2000';

         /* Identify 2001 CMJs (panel 5, rn 3) that began in 2000 */
data cmj01;  set hc.h56(keep=dupersid panel rn jobsn subtype stillat sickpay--payvactn);
  if panel=5 & rn=3 & subtype=1 & stillat=1;
run;
proc sort;   by dupersid jobsn rn;   run;

title4 '2001 (Panel 5 Round 3) Records';
proc freq;   tables
  sickpay--payvactn/missing;
  format  sickpay--payvactn yn.;
run;
proc print data=cmj01(obs=60);
  var  dupersid panel rn jobsn subtype stillat sickpay--payvactn;
run;

         /* Identify newly-reported 2000 CMJs (panel 5, rn 1,2) */
data cmj00;   set hc.h40(keep=dupersid panel rn jobsn subtype stillat sickpay--payvactn);
  if panel=5 & rn in(1,2) & subtype=1 & stillat=-1;
run;
proc sort;   by dupersid jobsn rn;   run;

title4 '2000 (Panel 5 Round 1,2) Records';
proc freq;   tables
  sickpay--payvactn/missing;
  format  sickpay--payvactn yn.;
run;
proc print data=cmj00(obs=60);
  var  dupersid panel rn jobsn subtype stillat sickpay--payvactn;
run;

         /* Concatenate records from both years */
data;   set
  cmj00(in=a)
  cmj01(in=b);   by dupersid jobsn;
run;

title4 'Records from Both Years';
proc print data=_last_(obs=60);
  var  dupersid panel rn jobsn subtype stillat sickpay--payvactn;
run;

         /* Merge records from both years, rename 2000 variables*/
data new;   merge
  cmj01(in=a)
  cmj00(in=b rename=(sickpay=SICKPAYX paydrvst=PAYDRVSTX payvactn=PAYVACTNX)
    drop=stillat);               /* drop STILLAT here so it doesn't overwrite 2001 value */
  by dupersid jobsn;   if a & b;
  drop rn;
  label
    SICKPAYX ='SICKPAY from First-Reported Round'
    PAYDRVSTX='PAYDRVST from First-Reported Round'
    PAYVACTNX='PAYVACTN from First-Reported Round';
run;

title4 'New Variables';
proc print data=_last_(obs=60);
  var  dupersid panel jobsn subtype stillat sickpayx paydrvstx payvactnx;
run;

proc freq;   tables
  sickpayx *sickpay
  paydrvstx*paydrvst
  payvactnx*payvactn/list missing;
  format _numeric_ yn.;
run;