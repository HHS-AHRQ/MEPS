/*********************************************************************

This program generates National Totals and Per-person Averages for Narcotic
 analgesics and Narcotic analgesic combos care for the U.S. civilian 
 non-institutionalized population (2018), including:
  - Number of purchases (fills)  
  - Total expenditures          
  - Out-of-pocket payments       
  - Third-party payments        

 Input files:
    - 2018 Prescribed medicines file
    - 2018 Full-year consolidated file

************************************************************************************/

/*********************************************************************************
    IMPORTANT NOTE:  Use the next 5 lines of code, only if you want SAS to create 
    separate files for SAS log and output.  Otherwise comment  out these lines.
***********************************************************************************/

%LET RootFolder= C:\Sep2021\sas_exercises\Exercise_2c;
FILENAME MYLOG "&RootFolder\Exercise2c_log.TXT";
FILENAME MYPRINT "&RootFolder\Exercise2c_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

/* Clear log, output, and ODSRESULTS from the previous run automatically */
DM "Log; clear; output; clear; odsresults; clear";
proc datasets lib=work nolist kill; quit; /* Delete  all files in the WORK library */

OPTIONS NOCENTER LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;

/* Create use-defined formats and store them in a catalog called FORMATS 
   in the work folder. They will be deleted at the end of tjr SAS session.
*/

PROC FORMAT;
  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0' ;
  VALUE SUBPOP    
          1 = 'OnePlusNacroticEtc'
		  2 = 'OTHERS';
RUN;

/* KEEP THE SPECIFIED VARIABLES WHEN READING THE INPUT DATA SET AND
   RESTRICT TO OBSERVATIONS HAVING THERAPEUTIC CLASSIFICATION (TC) CODES
   FOR NARCOTIC ANALGESICS OR NARCOTIC ANALGESIC COMBOS 
*/

%LET DataFolder = C:\MEPS_Data;  /* Adjust the folder name, if needed */
libname CDATA "&DataFolder"; 

DATA WORK.DRUG;
  SET CDATA.H206AV9 (KEEP=DUPERSID RXRECIDX LINKIDX TC1S1_1 RXXP18X RXSF18X
                   WHERE=(TC1S1_1 IN (60, 191))); 
RUN;

ODS HTML CLOSE; /* This will make the default HTML output no longer active,
                  and the output will not be displayed in the Results Viewer.*/
TITLE "A SAMPLE DUMP FOR PMED RECORDS WITH Narcotic analgesics or Narcotic analgesic combos, 2018";
PROC PRINT DATA=WORK.DRUG (OBS=12) noobs;
   VAR dupersid RXRECIDX LINKIDX TC1S1_1 RXXP18X RXSF18X;
RUN;


/* SUM "RXXP18X and RXSF18X" DATA TO PERSON-LEVEL*/

PROC SUMMARY DATA=WORK.DRUG NWAY;
  CLASS DUPERSID;
  VAR RXXP18X RXSF18X;
  OUTPUT OUT=WORK.PERDRUG  sum=TOT OOP;
RUN;

TITLE "A SAMPLE DUMP FOR PERSON-LEVEL EXPENDITURES FOR NARCOTIC ANALGESICS OR NARCOTIC ANALGESIC COMBOS";
PROC PRINT DATA=PERDRUG (OBS=3);
SUM _FREQ_;
RUN;

DATA WORK.PERDRUG2;
 SET PERDRUG  (DROP = _TYPE_ RENAME=(_FREQ_ = N_PHRCHASE)) ; /*# OF PURCHASES PER PERSON */
 /* CREATE A NEW VARIABLE FOR EXPENSES EXCLUDING OUT-OF-POCKET EXPENSES */
 THIRD_PAYER   = TOT - OOP; 
 RUN;
PROC SORT DATA=WORK.PERDRUG2; BY DUPERSID; RUN;

/*SORT THE FULL-YEAR(FY) CONSOLIDATED FILE*/
PROC SORT DATA=CDATA.H209V9 (KEEP=DUPERSID VARSTR VARPSU PERWT18f) OUT=WORK.H209;
BY DUPERSID; RUN;

/*MERGE THE PERSON-LEVEL EXPENDITURES TO THE FY PUF*/
DATA  WORK.FY;
MERGE WORK.H209 (IN=AA) 
      WORK.PERDRUG2  (IN=BB KEEP=DUPERSID N_PHRCHASE TOT OOP THIRD_PAYER);
   BY DUPERSID;
   IF AA AND BB THEN SUBPOP = 1; /*PERSONS WITH 1+ Narcotic analgesics or Narcotic analgesic combos */
   ELSE IF AA NE BB THEN DO;   
         SUBPOP         = 2 ;  /*PERSONS WITHOUT ANY PURCHASE OF Narcotic analgesics or Narcotic analgesic combos*/
         N_PHRCHASE  = 0 ;  /*# OF PURCHASES PER PERSON */
         THIRD_PAYER = 0 ;
         TOT         = 0 ;
         OOP         = 0 ;
    END;
    IF AA; 
	LABEL   TOT = 'TOTAL EXPENSES FOR NACROTIC ETC'
	        OOP = 'OUT-OF-POCKET EXPENSES'
            THIRD_PAYER = 'TOTAL EXPENSES MINUS OUT-OF-POCKET EXPENSES'
            N_PHRCHASE  = '# OF PURCHASES PER PERSON';
RUN;
/*DELETE ALL THE DATA SETS IN THE LIBRARY WORK and STOPS the DATASETS PROCEDURE*/
PROC DATASETS LIBRARY=WORK; 
 DELETE DRUG PERDRUG2 H209; 
RUN;
QUIT;
TITLE;

/* CALCULATE ESTIMATES ON USE AND EXPENDITURES*/
ods graphics off; /*Suppress the graphics */
ods listing; /* Open the listing destination*/
ods exclude Statistics /* Not to generate output for the overall population */
TITLE "PERSON-LEVEL ESTIMATES ON EXPENDITURES AND USE FOR NARCOTIC ANALGESICS or NARCOTIC COMBOS, 2098";
/* When you request SUM in PROC SURVEYMEANS, the procedure computes STD by default.*/
PROC SURVEYMEANS DATA=WORK.FY NOBS SUMWGT MEAN STDERR SUM;
  VAR  N_PHRCHASE TOT OOP THIRD_PAYER ;
  STRATA  VARSTR ;
  CLUSTER VARPSU;
  WEIGHT  PERWT18f;
  DOMAIN  SUBPOP("OnePlusNacroticEtc");
  FORMAT SUBPOP SUBPOP.;
 RUN;
title;
/* THE PROC PRINTTO null step is required to close the PROC PRINTTO, 
 only if used earlier., Otherswise. please comment out the next two lines  */

PROC PRINTTO;
RUN;

