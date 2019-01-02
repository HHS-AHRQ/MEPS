options ls=120 ps=79 nodate;
ods noproctitle;
/************************************************************************************\
Program:      c:\meps\prog\Example_L5.sas

Description:  This example shows how to:
              (1) Use condition file to identify events for asthma
              (2) Link conditions to events
              (3) Merge the condition-event linked file to event files
              (4) For each event, construct variables with the same name across events
              (5) Combine facility and doctor expenditures
              (6) Combine event files, identify type of event
              (7) Aggregate event-level records to person level

Input Files:  c:\meps\data\h61.sas7bdat (2001 Conditions)
              c:\meps\data\h59if1.sas7bdat (2001 Condition-Event Link File)
              c:\meps\data\h59a.sas7bdat (2001 Prescribed Medicines)
              c:\meps\data\h59e.sas7bdat (2001 Emergency Room Visits)
              c:\meps\data\h59f.sas7bdat (2001 Outpatient Visits)
              c:\meps\data\h59g.sas7bdat (2001 Office-Based Medical Provider Visits)
              c:\meps\data\h60.sas7bdat (2001 Full-Year Persons)
\************************************************************************************/

libname hc 'c:\meps\data';

proc format;
  value inscov
    1='Any private'
    2='Public only'
    3='Uninsured';
  value $vistype
    'ob'='Office-Based'
    'op'='Outpatient'
    'er'='Emergency'
    'pm'='Drug Purchase';
  value age
    0-4  ='0-4'
    5-17 ='5-17'
    18-24='18-24'
    25-44='25-44'
    45-64='45-64'
    65-90='65-90';
  value sex  1='Male'  2='Female';
  value racethnx
    1='Hispanic'
    2='Black, not Hispanic'
    3='Other';
run;

title 'AHRQ MEPS DATA USERS WORKSHOP (LINKING) -- NOV/DEC 2004';
title2 'Link 2001 Conditions and Event Files';

         /* Identify Asthma conditions */
data cond;   set hc.h61(keep=condidx icd9codx dupersid where=(icd9codx='493'));
  by condidx;
  drop icd9codx;
run;

         /* Merge link file (CLNK) & CONDS by CONDIDX */
data condev;   merge
  cond(in=a)
  hc.h59if1(in=b);   by condidx;
  if a & b;                          /*  keep only records that are in both files  */
run;
         /*  Sort by EVNTIDX for merges w/ event files  */
proc sort nodupkey;   by evntidx;   run;

         /* Prescribed medicines */
data h59a;   set hc.h59a(keep=rxrecidx linkidx rxsf01x rxxp01x rename=(linkidx=evntidx));
  by evntidx;
run;

         /* Combine Conditions & Prescribed medicines */
data pm;   merge
  condev(in=a)
  h59a(in=b);   by evntidx;   if a & b;
  ambtotev=rxxp01x;  /*  construct expenditure variables  */
  ambfamev=rxsf01x;
run;

         /* Aggregate PMED events to person level */
proc sort;   by dupersid;   run;
data perpmed;   set pm;   by dupersid;
  if first.dupersid then do;
    ambtotpd=0;
    ambfampd=0;
  end;
  retain ambtotpd ambfampd;
  ambtotpd = ambtotpd + ambtotev;
  ambfampd = ambfampd + ambfamev;
  if last.dupersid then output;
  label
    ambtotpd='Total Paid: Prescriptions'
    ambfampd='Amount Paid by Family: Prescriptions';
  keep  dupersid ambtotpd ambfampd;
run;

         /* Add person characteristics */
data pers1;   merge
  perpmed(in=a)
  hc.h60(keep=dupersid inscov01 perwt01f);   by dupersid;   if a;
run;

title3
 'Average Prescription Expenditures per Person, for Persons with Asthma -- Total and Paid by Family';
proc means mean maxdec=2;
  class  inscov01;
  format  inscov01 inscov.;
  var  ambtotpd ambfampd;
  weight  perwt01f;
run;


         /*  Merge Asthma Conditions w/ each event file                      */
         /*  Construct expenditure variables, using same name across events  */

         /* Office-based */
proc sort data=hc.h59g(keep=evntidx obxp01x obsf01x) out=h59g;   by evntidx;   run;
data ob;   merge
  condev(in=a)
  h59g(in=b);   by evntidx;   if a & b;
         /*  construct expenditure variables  */
  ambtotev=obxp01x;
  ambfamev=obsf01x;
run;

         /* Outpatient */
proc sort data=hc.h59f(keep=evntidx opxp01x opfsf01x opdsf01x) out=h59f;
  by evntidx;
run;
data op;   merge
  condev(in=a)
  h59f(in=b);   by evntidx;   if a & b;
         /*  construct expenditure variables  */
  ambtotev=opxp01x;
  ambfamev=sum(opfsf01x,opdsf01x);         /*  combine facility & doctor amounts  */
run;

         /* Emergency room */
proc sort data=hc.h59e(keep=evntidx erxp01x erfsf01x erdsf01x) out=h59e;
  by evntidx;
run;
data er;   merge
  condev(in=a)
  h59e(in=b);   by evntidx;   if a & b;
         /*  construct expenditure variables  */
  ambtotev=erxp01x;
  ambfamev=sum(erfsf01x,erdsf01x);         /*  combine facility & doctor amounts  */
run;

         /* Combine 4 event files */
data allevnt;   set
  ob(in=a)
  op(in=b)
  er(in=c)
  pm(in=d);   by evntidx;
         /*  use temporary 'in=' variables to define type of visit or purchase  */
  if a then vistype='ob';
    else if b then vistype='op';
    else if c then vistype='er';
    else if d then vistype='pm';
run;

title3 'Frequency of Ambulatory Visits for Asthma, by Type of Event';
proc freq data=allevnt;   tables vistype/missing;   format  vistype $vistype.;   run;

         /*  aggregate events to person level  */

proc sort data=allevnt;   by dupersid;   run;
data perev;   set allevnt;   by dupersid;
  if first.dupersid then do;
    ambtotpd=0;   ambfampd=0;
  end;
  ambtotpd + ambtotev;
  ambfampd + ambfamev;
  if last.dupersid;
  label
    ambtotpd='Total Paid, Ambulatory Care for Asthma'
    ambfampd="Amt Paid by Fam, Ambul'y Care for Asthma";
  keep  dupersid ambtotpd ambfampd;
run;

         /* Add person characteristics */
data pers;   merge
  perev(in=a)
  hc.h60(keep=dupersid perwt01f age31x age42x age53x sex racethnx);
    by dupersid;   if a;
         /*  construct latest age from round-specific vars  */
  if age53x >= 0 then age=age53x;
    else if age42x >= 0 then age=age42x;
    else if age31x >= 0 then age=age31x;
run;

title3 'Average Expenditures per Person -- Total and Paid by Family';
proc means data=pers mean maxdec=2;
  class  age racethnx sex;
  format  age age.  racethnx racethnx.  sex sex.;
  var  ambtotpd ambfampd;
  weight  perwt01f;
run;