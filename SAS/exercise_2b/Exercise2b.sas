/*********************************************************************\

PURPOSE:	THIS PROGRAM GENERATES SELECTED ESTIMATES FOR A 2016 VERSION OF THE Purchases and Expenses for Narcotic analgesics or Narcotic analgesic combos


    (1) FIGURE 1: TOTAL EXPENSE FOR Narcotic analgesics or Narcotic analgesic combos

    (2) FIGURE 2: TOTAL NUMBER OF PURCHASES OF Narcotic analgesics or Narcotic analgesic combos

    (3) FIGURE 3: TOTAL NUMBER OF PERSONS PURCHASING ONE OR MORE Narcotic analgesics or Narcotic analgesic combos

    (4) FIGURE 4: AVERAGE TOTAL, OUT OF POCKET, AND THIRD PARTY PAYER EXPENSE
                  FOR Narcotic analgesics or Narcotic analgesic combos PER PERSON WITH AN Narcotic analgesics or Narcotic analgesic combos MEDICINE PURCHASE

INPUT FILES:  (1) C:\MEPS\SAS\DATA\H1192.SAS7BDAT (2016 FULL-YEAR CONSOLIDATED PUF)
              (2) C:\MEPS\SAS\DATA\H188A.SAS7BDAT (2016 PRESCRIBED MEDICINES PUF)

*********************************************************************/
/* IMPORTANT NOTES: Use the next 6 lines of code, if you want to specify an alternative destination for SAS log and
SAS procedure output.*/

%LET MyFolder= U:\Workshop_Fall2018_PradipM\Exercise_2;
OPTIONS LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
FILENAME MYLOG "&MyFolder\Exercise2_log.TXT";
FILENAME MYPRINT "&MyFolder\Exercise2_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;

proc datasets lib=work nolist kill; quit; /* delete  all files in the WORK library */
LIBNAME CDATA 'C:\MEPS\SAS\DATA';

TITLE1 '2018 AHRQ MEPS DATA USERS WORKSHOP';
TITLE2 "EXERCISE2.SAS: Narcotic analgesics or Narcotic analgesic combos, 2016";

PROC FORMAT;
  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0'
     ;
RUN;

/*1) IDENTIFY Narcotic analgesics or Narcotic analgesic combos USING THERAPEUTIC CLASSIFICATION (TC) CODES*/

DATA DRUG;
  SET CDATA.H188A;
  IF TC1S1_1 IN (60, 191) ; /*definition of Narcotic analgesics or Narcotic analgesic combos*/
RUN;

TITLE3 "A SAMPLE DUMP FOR PMED RECORDS WITH Narcotic analgesics or Narcotic analgesic combos";
PROC PRINT DATA=DRUG (OBS=30);
VAR RXRECIDX LINKIDX TC1S1_1 RXXP16X RXSF16X;
 BY DUPERSID;
RUN;


/*2) SUM DATA TO PERSON-LEVEL*/

PROC SUMMARY DATA=DRUG NWAY;
  CLASS DUPERSID;
  VAR RXXP16X RXSF16X;
  OUTPUT OUT=PERDRUG (DROP=_TYPE_) sum=TOT OOP;
RUN;

TITLE3 "A SAMPLE DUMP FOR PERSON-LEVEL EXPENDITURES FOR Narcotic analgesics or Narcotic analgesic combos";
PROC PRINT DATA=PERDRUG (OBS=30);
RUN;

DATA PERDRUG2;
 SET PERDRUG;
     RENAME _FREQ_ = N_PHRCHASE ;
     THIRD_PAYER   = TOT - OOP;
RUN;

/*3) MERGE THE PERSON-LEVEL EXPENDITURES TO THE FY PUF*/

DATA  FY;
MERGE CDATA.H192 (IN=AA KEEP=DUPERSID VARSTR VARPSU PERWT16F)
      PERDRUG2  (IN=BB KEEP=DUPERSID N_PHRCHASE TOT OOP THIRD_PAYER);
   BY DUPERSID;

      IF AA AND BB THEN DO;
         SUB      = 1 ;
      END;

      ELSE IF NOT BB THEN DO;   /*FOR PERSONS WITHOUT ANY PURCHASE OF Narcotic analgesics or Narcotic analgesic combos*/
         SUB         = 2 ;
         N_PHRCHASE  = 0 ;
         THIRD_PAYER = 0 ;
         TOT         = 0 ;
         OOP         = 0 ;
      END;

      IF AA;

      LABEL
            THIRD_PAYER = 'TOTAL-OOP'
            N_PHRCHASE  = '# OF PURCHASES PER PERSON'
            SUB         = 'POPULATION FLAG FOR PERSONS WITH 1+ Narcotic analgesics or Narcotic analgesic combos'
                        ;
RUN;

TITLE3 "SUPPORTING CROSSTABS FOR NEW VARIABLES";
PROC FREQ DATA=FY;
  TABLES  SUB * N_PHRCHASE * TOT * OOP * THIRD_PAYER / LIST MISSING ;
  FORMAT N_PHRCHASE TOT OOP THIRD_PAYER gtzero. ;
RUN;


/*4) CALCULATE ESTIMATES ON USE AND EXPENDITURES*/

ODS EXCLUDE ALL; /* Suppress the printing of output */
TITLE3 "PERSON-LEVEL ESTIMATES ON EXPENDITURES AND USE FOR Narcotic analgesics or Narcotic analgesic combos, 2016";
PROC SURVEYMEANS DATA=FY NOBS SUMWGT SUM STD MEAN STDERR;
  STRATA  VARSTR ;
  CLUSTER VARPSU;
  WEIGHT  PERWT16F;
   VAR TOT N_PHRCHASE  OOP THIRD_PAYER ;
   DOMAIN  SUB('1');
  ODS OUTPUT DOMAIN=work.domain_results;
RUN;

ODS EXCLUDE NONE; /* Unsuppress the printing of output */
TITLE4 "SUBSET THE ESTIMATES FOR PERSONS ONLY WITH 1+ Narcotic analgesics or Narcotic analgesic combos";
proc print data= work.domain_results noobs split='*';
 var   VARLABEL N  SumWgt  mean StdErr  Sum stddev;
 label SumWgt = 'Population*Size'
       mean = 'Mean'
       StdErr = 'SE of Mean'
       Sum = 'Total'
       Stddev = 'SE of*Total';
       format N SumWgt Comma12. mean comma9.1 stderr 9.4
              sum Stddev comma17.;
run;
ODS _ALL_ CLOSE;
/* THE PROC PRINTTO null step is required to close the PROC PRINTTO */
PROC PRINTTO;
RUN;
