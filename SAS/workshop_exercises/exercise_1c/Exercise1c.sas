/**********************************************************************************

This program generates the following estimates on national health care expenses
for the civilian noninstitutionized population, 2018:
  - Overall expenses (National totals)
  - Percentage of persons with an expense
  - Mean expense per person
  - Mean/median expense per person with an expense:
    - Mean expense per person with an expense
    - Mean expense per person with an expense, by age group
    - Median expense per person with an expense, by age group
 Input file:
 - 2018 Full-year consolidated file

*******************************************************************************************************/

/*********************************************************************************
 IMPORTANT NOTE:  Use the next 5 lines of code, only if you want SAS to create 
    separate files for SAS log and output.  Otherwise comment  out these lines.
***********************************************************************************/

%LET RootFolder= C:\Sep2021\sas_exercises\Exercise_1c;
FILENAME MYLOG "&RootFolder\Exercise1c_log.TXT";
FILENAME MYPRINT "&RootFolder\Exercise1c_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

/* Clear log, output, and ODSRESULTS from the previous run automatically */
DM "Log; clear; output; clear; odsresults; clear";
proc datasets lib=work nolist kill; quit; /* Delete  all files in the WORK library */

OPTIONS NOCENTER LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;

/* Create user-defined formats and store them in a catalog called FORMATS 
   in the work folder. They will be automatically deleted at the end of the SAS session.
*/

PROC FORMAT;
  VALUE AGECAT
       low-64 = '0-64'
	   65-high = '65+';

   VALUE totexp18_cate
      0         = 'No Expense'
      Other     = 'Any Expense';
RUN;



%LET DataFolder = C:\MEPS_Data;  /* Create a macro variable. Adjust the folder name, if needed */
%put &DataFolder;  /* Display the name and value of the specific macro variable */
%put _user_;      /* Display the names and values of all user-defined macro variables */

libname CDATA "&DataFolder";  /* Assign a libref () to a SAS library.
/* READ IN DATA FROM 2018 CONSOLIDATED DATA FILE (HC-209) */
DATA WORK.PUF209;
  SET CDATA.H209V9 (KEEP = TOTEXP18 AGELAST   VARSTR  VARPSU  PERWT18F panel);
     WITH_AN_EXPENSE= TOTEXP18; /* Create another version of the TOTEXP18 variable */

	 /* Create a character variable based on a numeric variable using a table lookup */
	 CHAR_WITH_AN_EXPENSE = PUT(TOTEXP18,totexp18_cate.); 
	 
  RUN;
TITLE;
%put %sysfunc(pathname(work));

proc datasets;
quit;
proc catalog catalog=work.formats;
contents stat;
run;

proc contents data=PUF209;
ods select variables;
run;


TITLE "MEPS FULL-YEAR CONSOLIDATED FILE, 2018";
ODS HTML CLOSE; /* This will make the default HTML output no longer active,
                  and the output will not be displayed in the Results Viewer.*/

ods graphics off; /*Suppress the graphics */
ods listing; /* Open the listing destination*/
TITLE2 'PERCENTAGE OF PERSONS WITH AN EXPENSE, 2018 _Method 1';
PROC SURVEYMEANS DATA=WORK.PUF209 NOBS MEAN STDERR sum ;
    VAR  WITH_AN_EXPENSE  ;
	STRATUM VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT18F;
	class WITH_AN_EXPENSE;
	FORMAT WITH_AN_EXPENSE TOTEXP18_CATE. ;
RUN;

TITLE2 'PERCENTAGE OF PERSONS WITH AN EXPENSE, 2018 - Method 2';
PROC SURVEYMEANS DATA=WORK.PUF209 NOBS MEAN STDERR sum ;
    VAR  CHAR_WITH_AN_EXPENSE  ;
	STRATUM VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT18F;
RUN;

TITLE2 'PERCENTAGE OF PERSONS WITH AN EXPENSE, 2018 - Method 3';
PROC SURVEYFREQ DATA=WORK.PUF209 ;
    TABLES  CHAR_WITH_AN_EXPENSE ;
	STRATUM VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT18F;
RUN;

TITLE2 'MEAN AND MEDIAN EXPENSE PER PERSON WITH AN EXPENSE, OVEALL and FOR AGES 0-64, AND 65+, 2018';

PROC SURVEYMEANS DATA= WORK.PUF209 NOBS MEAN STDERR sum median  ;
    VAR  totexp18;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT18F ;	
	DOMAIN WITH_AN_EXPENSE('Any Expense') WITH_AN_EXPENSE('Any Expense')*AGELAST;
	FORMAT WITH_AN_EXPENSE TOTEXP18_CATE. AGELAST agecat.;
RUN;
title;
/* THE PROC PRINTTO null step is required to close the PROC PRINTTO,  only if used earlier.
   Otherswise. please comment out the next two lines */


PROC PRINTTO;
RUN;
