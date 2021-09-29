
/******************************************************************************************

 This program illustrates how to pool MEPS data files from different years. It
 highlights one example of a discontinuity that may be encountered when 
 working with data from before and after the 2018 CAPI re-design.
 

 The program pools 2017 and 2018 data and calculates for the civilian noninstitutionized population:
  - Percentage of people with Joint Pain / Arthritis (JTPAIN**, ARTHDX)
  - Average expenditures per person, by Joint Pain status (TOTEXP, TOTSLF)

 Notes:
  - Variables with year-specific names must be renamed before combining files
    (e.g. 'TOTEXP17' and 'TOTEXP18' renamed to 'totexp')

Input files:
  - 2017 Full-year consolidated file
  - 2018 Full-year consolidated file

*/

/*********************************************************************************
 IMPORTANT NOTE:  Use the next 5 lines of code, only if you want SAS to create 
    separate files for SAS log and output.  Otherwise comment  out these lines.
***********************************************************************************/

%LET RootFolder= C:\Sep2021\sas_exercises\Exercise_4c;
FILENAME MYLOG "&RootFolder\Exercise4c_log.TXT";
FILENAME MYPRINT "&RootFolder\Exercise4c_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;


/* Clear log, output, and ODSRESULTS from the previous run automatically */
DM "Log; clear; output; clear; odsresults; clear";
proc datasets lib=work nolist kill; quit; /* Delete  all files in the WORK library */

OPTIONS NOCENTER LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
/* Turn Off the Warning Message  
WARNING: Multiple lengths were specified for the variable Name by input data set(s).
*/
OPTIONS varlenchk=nowarn;

/* Create use-defined formats and store them in a catalog called FORMATS 
   in the work folder. They will be deleted at the end of the SAS session.
*/
PROC FORMAT;

  VALUE totexp_fmt
      0         = 'No Expense'
      Other     = 'Any Expense';

  VALUE agecat_fmt
       18-49 = '18-49'
       50-64 = '50-64'
       65-high= '65+';

   
     value yes_no_fmt
      1 = 'Yes'
      2 = 'No'; 

	
run;
***************  MEPS 2017;
%LET DataFolder = C:\MEPS_Data;  /* Adjust the folder name, if needed */
libname CDATA "&DataFolder"; 

%let kept_vars_2017 =  VARSTR VARPSU perwt17f agelast ARTHDX JTPAIN31 totexp17 totslf17;
data meps_2017;
 set CDATA.h201v9 (keep= &kept_vars_2017
                 rename=(totexp17=totexp
                         totslf17=totslf));
  perwtf = perwt17f/2;;

  
   * Create a subpopulation indicator called SPOP
    and a new variable called JOINT_PAIN  based on ARTHDX and JTPAIN31;

   spop=2;
   if agelast>=18 and not (ARTHDX <=0 and JTPAIN31 <0) then do;
  	  SPOP=1; 
   	 if ARTHDX=1 | JTPAIN31=1 then joint_pain =1;
   	 else joint_pain=2;
   end;

   label totexp = 'TOTAL HEALTH CARE EXP'
         totslf = 'TOTAL AMOUNT PAID - SELF-FAMILY';
run;


*** 2018 MEPS ; 

%let kept_vars_2018 =  VARSTR VARPSU perwt18f agelast ARTHDX JTPAIN31_M18 totexp18 totslf18;
data meps_2018;
 set CDATA.h209v9 (keep= &kept_vars_2018
                 rename=(totexp18=totexp
                         totslf18=totslf));
  perwtf = perwt18f/2;

  * Create a subpopulation indicator called SPOP
    and a new variable called JOINT_PAIN  based on ARTHDX and JTPAIN31_M18;

   spop=2;
   if agelast>=18 and not (ARTHDX <=0 and JTPAIN31_M18 <0) then do;
  	  SPOP=1; 
   	 if ARTHDX=1 | JTPAIN31_M18=1 then joint_pain =1;
   	 else joint_pain=2;
   end;
run;


**** Concatenate 2017 and 2018 analytic data files;

data MEPS_1718;
  set meps_2017(rename=(JTPAIN31 = JTPAIN))
      meps_2018 (rename=(JTPAIN31_M18 = JTPAIN));
	   TOTEXP_X = TOTEXP;
run;



title 'MEPS 2017-18 combined';

proc freq data=MEPS_1718;
tables ARTHDX*JTPAIN*joint_pain
       ARTHDX*JTPAIN*spop 
       spop joint_pain /list missing;
run;

title 'MEPS 2017-18 combined';
ods exclude statistics;
PROC SURVEYMEANS DATA=meps_1718  nobs mean stderr sum ;
    VAR joint_pain ;
    STRATUM VARSTR ;
    CLUSTER VARPSU;
    WEIGHT perwtf;
	domain spop('1');
	class joint_pain;
  	format joint_pain yes_no_fmt. ;
RUN;

title 'MEPS 2017-18 combined';
ods exclude statistics;
PROC SURVEYMEANS DATA=meps_1718  nobs mean stderr sum;
    VAR totexp totslf;
    STRATUM VARSTR ;
    CLUSTER VARPSU;
    WEIGHT perwtf;
	domain spop('1')*joint_pain;
	format joint_pain yes_no_fmt.  ;
RUN;
TITLE;
/* THE PROC PRINTTO null step is required to close the PROC PRINTTO, 
 only if used earlier., Otherswise. please comment out the next two lines  */

proc printto;
run;

