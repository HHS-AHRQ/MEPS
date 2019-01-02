options ls=120 ps=79 nodate;
ods noproctitle;
/************************************************************************************\
Program:      c:\meps\prog\Example_L2.sas

Description:  This example shows how to:
              (1) Create SAS files from ASCII files
              (2) Link 2001 MEPS to 1999 and 2000 NHIS
              (3) Compare persons' status in NHIS with their status in MEPS

Input Files:  c:\meps\data\nhisper99.dat (1999 NHIS Persons, renamed from PERSONSX)
              c:\meps\data\nhisper00.dat (2000 NHIS Persons, renamed from PERSONSX)
              c:\meps\data\nhmep01x.dat (NHIS-MEPS Link File - read in from diskette)
              c:\meps\data\h60.sas7bdat (2001 MEPS Persons)
\************************************************************************************/

libname hc 'c:\meps\data';

filename n99 'c:\meps\data\nhisper99.dat';
filename n00 'c:\meps\data\nhisper00.dat';
filename lnk 'c:\meps\data\nhmep01x.dat';

title 'AHRQ MEPS DATA USERS WORKSHOP (LINKING) -- NOV/DEC 2004';
title2 'NHIS-MEPS Link';

proc format;
  value anylim
   -9='-9 Not Ascer'
   -1='-1 Inapp'
    1='1 Yes'
    2='2 No';
  value sex  1='1 Male'  2='2 Female';
  value hstat
   -9='-9 Not Ascer'
   -8='-8 DK'
   -7='-7 Refused'
   -1='-1 Inapp'
    1='1 Excellent'
    2='2 Very Good'
    3='3 Good'
    4='4 Fair'
    5='5 Poor'
    7='7 Refused'
    8='8 Not Ascer'
    9='9 DK';
  value nhislim
    1='1 Limited'
    2='2 Not Limited'
    3='3 Unknown'
    7='7 Refused'
    8='8 Not Ascer'
    9='9 DK';
  value nhischron
    0='0 Not Limited'
    1='1 Lim, 1+ Chron Cond'
    2='2 Lim, Not Chron'
    3='3 Lim, Chron Unk'
    7='7 Refused'
    8='8 Not Ascer'
    9='9 DK';
run;

title3 '2001 MEPS';
data meps01;   set hc.h60(keep=dupersid anylim01 rthlth31 rthlth42 rthlth53
  perwt01f varstr01 varpsu01);   by dupersid;     /*  file is already sorted  */
         /*  construct annual health status from last nonmissing round variable  */
  if rthlth53 > 0 then MEPSHSTAT=rthlth53;
    else if rthlth42 > 0 then MEPSHSTAT=rthlth42;
    else if rthlth31 > 0 then MEPSHSTAT=rthlth31;
  label mepshstat='MEPS Health Status';
run;
proc contents position;   run;
proc print data=_last_(obs=60);   run;
title4 'Verify New Variable';
proc freq;   tables
  mepshstat
  mepshstat*rthlth53*rthlth42*rthlth31/list missing;
  format  mepshstat rthlth53 rthlth42 rthlth31 hstat.;
run;

title3 'Link File';
data link;   infile lnk;   input
  DUPERSID $1-8
  HHX      $9-14
  PX       $15-16
  LINKFLAG  17
  SRVY_YR   19-22;
run;
proc sort;   by dupersid;   run;
proc contents position;   run;
proc print data=_last_(obs=60);   run;
proc freq;   tables linkflag srvy_yr;   run;

title3 '1999 NHIS';
data nhis99;   infile n99 missover lrecl=829;   input
  SRVY_YR   3-6
  HHX      $7-12
  PX       $15-16
  SEX       18
  AGE       19-20
  NHISLIM   120
  NHISCHRON 563
  NHISHSTAT 564;
  label
    nhislim  ='NHIS Any Limitation'
    nhischron="NHIS Lim'n/Chronic Status"
    nhishstat='NHIS Health Status';
run;
proc sort;   by hhx px srvy_yr;   run;
proc contents position;   run;
proc print data=_last_(obs=60);   run;

title3 '2000 NHIS';
data nhis00;   infile n00 missover lrecl=789;   input
  SRVY_YR   3-6
  HHX      $7-12
  PX       $15-16
  SEX       18
  AGE       19-20
  NHISLIM   123
  NHISCHRON 566
  NHISHSTAT 567;
  label
    nhislim  ='NHIS Any Limitation'
    nhischron="NHIS Lim'n/Chronic Status"
    nhishstat='NHIS Health Status';
run;
proc sort;   by hhx px srvy_yr;   run;
proc contents position;   run;
proc print data=_last_(obs=60);   run;

title3 'Combine Link File & MEPS --> MEPSLINK';
data mepslink;   merge
  meps01(in=a drop=rthlth31 rthlth42 rthlth53)
  link(in=b drop=linkflag);   by dupersid;   if a & b;
run;
proc sort;   by hhx px srvy_yr;   run;
proc contents position;   run;
proc print data=_last_(obs=60);   run;

title3 'Combine 1999 & 2000 NHIS Files --> NHIS';
data nhis;   merge
  nhis99
  nhis00;   by hhx px srvy_yr;
run;
proc contents position;   run;
proc print data=_last_(obs=60);   run;

title3 'Combine MEPSLINK & NHIS --> TOTAL01';
data total01;   merge
  mepslink(in=a)
  nhis(in=b);   by hhx px srvy_yr;   if a & b;
run;
proc contents position;   run;
proc print data=_last_(obs=60);   run;

title3 'Unweighted';
proc freq;   tables
  anylim01 mepshstat sex nhislim nhischron nhishstat/missing;
  format  anylim01 anylim.  mepshstat nhishstat hstat.  sex sex.  nhislim nhislim.
    nhischron nhischron.;
run;
proc means n nmiss min max maxdec=0;   var age;   run;

title3 'Weighted';
title4 'Compare Limitation Status and Health Status Over Time';
proc freq;   tables
  nhislim*anylim01
  nhishstat*mepshstat/list missing;
  format  nhislim nhislim.  anylim01 anylim.  nhishstat mepshstat hstat.;
  weight  perwt01f;
run;
