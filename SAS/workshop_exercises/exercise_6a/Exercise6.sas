/*******************************************************************

This program includes a regression example for persons receiving a flu shot
in the last 12 months for the civilian noninstitutionized population, including:
- Percentage of people with a flu shot (civilian noninstitutionized population), 2018:
- Logistic regression: to identify demographic factors associated with receiving a flu shot

 Input file: 
  - 2018 Full-year consolidated file

********************************************************************/

/*********************************************************************************
 IMPORTANT NOTE:  Use the next 5 lines of code, only if you want SAS to create 
    separate files for SAS log and output.  Otherwise comment  out these lines.
***********************************************************************************/


%LET RootFolder= C:\Sep2021\sas_exercises\Exercise_6;
FILENAME MYLOG "&RootFolder\Exercise6_log.TXT";
FILENAME MYPRINT "&RootFolder\Exercise6_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

/* Clear log, output, and ODSRESULTS from the previous run automatically */
DM "Log; clear; output; clear; odsresults; clear";
proc datasets lib=work nolist kill; quit; /* Delete  all files in the WORK library */

OPTIONS NOCENTER LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;

/* Create use-defined formats and store them in a catalog called FORMATS 
   in the work folder. They will be deleted at the end of the SAS session.
*/

PROC FORMAT;

value age18p_f 
    18-high = '18+'
    other = '0-17';


value age_f 
    18-34 = '18-34'
    35-64 = '35-64'
	65-High ='65+';

value ADFLST42_fmt
    -15 = "Cann't be computed"
	-1 = 'Inapplicable'
    1  = 'Yes'
	0,2  ='No';


value sex_fmt   1 = 'Male'
                2 = 'Female'; 
			

VALUE Racethx_fmt
  1 = 'Hispanic'
  2 = 'NH White only'
  3 = 'NH Black only'
  4 = 'NH Asian only'
  5 = 'NH Other etc';

 value INSCOV18_fmt
   1 = 'Any Private'
   2 = 'Public Only'
   3 = 'Uninsured';
run;

%LET DataFolder = C:\MEPS_Data;  /* Adjust the folder name, if needed */
libname CDATA "&DataFolder"; 
%let kept_vars_2018 =  VARSTR VARPSU perwt18f saqwt18f ADFLST42  AGELAST RACETHX POVCAT18 INSCOV18 SEX;
data meps_2018;
 set CDATA.h209v9 (keep= &kept_vars_2018);
 
if ADFLST42 = 1 then flushot =1;
else if ADFLST42 = 2 then flushot =0;
else flushot =.;
run;

title " 2018 MEPS";

ods graphics off;
ods select domain;
PROC SURVEYMEANS DATA=meps_2018 nobs mean stderr ;
    VAR flushot;
    STRATUM VARSTR;
    CLUSTER VARPSU;
    WEIGHT saqwt18f;
    DOMAIN  agelast('18+');
	format agelast age18p_f.;
RUN;
title 'PROC SURVEYLOGISTIC With param=ref option on the CLASS statement';
	PROC SURVEYLOGISTIC DATA=meps_2018 ;
    STRATUM VARSTR;
    CLUSTER VARPSU;
    WEIGHT saqwt18f;
    CLASS sex (ref='Male') RACETHX (ref='Hispanic') INSCOV18 (ref='Any Private')/param=ref;
         model flushot(ref= '0')= agelast sex RACETHX  INSCOV18;
      format agelast age18p_f. 
      sex sex_fmt. 
      RACETHX racethx_fmt. 
      INSCOV18 INSCOV18_fmt.;
    RUN;
title;

/* THE PROC PRINTTO null step is required to close the PROC PRINTTO, 
 only if used earlier., Otherswise. please comment out the next two lines  */


proc printto;
run;

