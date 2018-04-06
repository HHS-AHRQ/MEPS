/**********************************************************************************

PROGRAM:      C:\MEPS\SAS\Exercise_5\EXERCISE5.SAS

DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO CALCULATE EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH A CONDITION

              THE CONDITION USED IN THIS EXERCISE IS DIABETES (CCS CODE=049 OR 050)

THE DEFINITION OF 61 CONDITIONS BASED ON CCS CODE

  1  Infectious diseases                                           : CCS CODE = 1-9
  2  Cancer                                                        : CCS CODE = 11-45
  3  Non-malignant neoplasm                                        : CCS CODE = 46, 47
  4  Thyroid disease                                               : CCS CODE = 48
  5  Diabetes mellitus                                             : CCS CODE = 49,50
  6  Other endocrine, nutritional & immune disorder                : CCS CODE = 51, 52, 54 - 58
  7  Hyperlipidemia                                                : CCS CODE = 53
  8  Anemia and other deficiencies                                 : CCS CODE = 59
  9  Hemorrhagic, coagulation, and disorders of White Blood cells  : CCS CODE = 60-64
  10 Mental disorders                                              : CCS CODE = 650-670
  11 CNS infection                                                 : CCS CODE = 76-78
  12 Hereditary, degenerative and other nervous system disorders   : CCS CODE = 79-81
  13 Paralysis                                                     : CCS CODE = 82
  14 Headache                                                      : CCS CODE = 84
  15 Epilepsy and convulsions                                      : CCS CODE = 83
  16 Coma, brain damage                                            : CCS CODE = 85
  17 Cataract                                                      : CCS CODE = 86
  18 Glaucoma                                                      : CCS CODE = 88
  19 Other eye disorders                                           : CCS CODE = 87, 89-91
  20 Otitis media                                                  : CCS CODE = 92
  21 Other CNS disorders                                           : CCS CODE = 93-95
  22 Hypertension                                                  : CCS CODE = 98,99
  23 Heart disease                                                 : CCS CODE = 96, 97, 100-108
  24 Cerebrovascular disease                                       : CCS CODE = 109-113
  25 Other circulatory conditions arteries, veins, and lymphatics  : CCS CODE = 114 -121
  26 Pneumonia                                                     : CCS CODE = 122
  27 Influenza                                                     : CCS CODE = 123
  28 Tonsillitis                                                   : CCS CODE = 124
  29 Acute Bronchitis and URI                                      : CCS CODE = 125 , 126
  30 COPD, asthma                                                  : CCS CODE = 127-134
  31 Intestinal infection                                          : CCS CODE = 135
  32 Disorders of teeth and jaws                                   : CCS CODE = 136
  33 Disorders of mouth and esophagus                              : CCS CODE = 137
  34 Disorders of the upper GI                                     : CCS CODE = 138-141
  35 Appendicitis                                                  : CCS CODE = 142
  36 Hernias                                                       : CCS CODE = 143
  37 Other stomach and intestinal disorders                        : CCS CODE = 144- 148
  38 Other GI                                                      : CCS CODE = 153-155
  39 Gallbladder, pancreatic, and liver disease                    : CCS CODE = 149-152
  40 Kidney Disease                                                : CCS CODE = 156-158, 160, 161
  41 Urinary tract infections                                      : CCS CODE = 159
  42 Other urinary                                                 : CCS CODE = 162,163
  43 Male genital disorders                                        : CCS CODE = 164-166
  44 Non-malignant breast disease                                  : CCS CODE = 167
  45 Female genital disorders, and contraception                   : CCS CODE = 168-176
  46 Complications of pregnancy and birth                          : CCS CODE = 177-195
  47 Normal birth/live born                                        : CCS CODE = 196, 218
  48 Skin disorders                                                : CCS CODE = 197-200
  49 Osteoarthritis and other non-traumatic joint disorders        : CCS CODE = 201-204
  50 Back problems                                                 : CCS CODE = 205
  51 Other bone and musculoskeletal  disease                       : CCS CODE = 206-209, 212
  52 Systemic lupus and connective tissues disorders               : CCS CODE = 210-211
  53 Congenital anomalies                                          : CCS CODE = 213-217
  54 Perinatal Conditions                                          : CCS CODE = 219-224
  55 Trauma-related disorders                                      : CCS CODE = 225-236, 239, 240, 244
  56 Complications of surgery or device                            : CCS CODE = 237, 238
  57 Poisoning by medical and non-medical substances               : CCS CODE = 241 - 243
  58 Residual Codes                                                : CCS CODE = 259
  59 Other care and screening                                      : CCS CODE = 10, 254-258
  60 Symptoms                                                      : CCS CODE = 245-252
  61 Allergic reactions                                            : CCS CODE = 253


INPUT FILES:  1) C:\MEPS\SAS\DATA\H181.SAS7BDAT    (2015 FY PUF DATA)
              2) C:\MEPS\SAS\DATA\H180.SAS7BDAT    (2015 CONDITION PUF DATA)
              3) C:\MEPS\SAS\DATA\H178A.SAS7BDAT   (2015 PMED PUF DATA)
              4) C:\MEPS\SAS\DATA\H178D.SAS7BDAT   (2015 INPATIENT VISITS PUF DATA)
              5) C:\MEPS\SAS\DATA\H178E.SAS7BDAT   (2015 EROM VISITS PUF DATA)
              6) C:\MEPS\SAS\DATA\H178F.SAS7BDAT   (2015 OUTPATIENT VISITS PUF DATA)
              7) C:\MEPS\SAS\DATA\H178G.SASBDAT   (2015 OFFICE-BASED VISITS PUF DATA)
              8) C:\MEPS\SAS\DATA\H178H.SAS7BDAT   (2015 HOME HEALTH PUF DATA)
              9) C:\MEPS\SAS\DATA\H178IF1.SAS7BDAT  (2015 CONDITION-EVENT LINK PUF DATA)

*********************************************************************************/;
OPTIONS LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;
FILENAME MYLOG "U:\MEPS\SAS\Exercise_5\Exercise5_log.TXT";
FILENAME MYPRINT "U:\MEPS\SAS\Exercise_5\Exercise5_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;
LIBNAME CDATA 'C:\MEPS\SAS\DATA';
*LIBNAME CDATA "\\programs.ahrq.local\programs\meps\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2018\SAS\Data";

TITLE1 'AHRQ MEPS DATA USERS WORKSHOP -- 2018';
TITLE2 'EXERCISE5.SAS: CALCULATE EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH A CONDITION (DIABETES)';

PROC FORMAT;
  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0'
               ;
  VALUE GEZERO
     0 - HIGH = 'GE 0' ;
RUN;

/*1) PULL OUT CONDITIONS WITH DIABETES (CCS CODE='049', '050') FROM 2015 CONDITION PUF - HC180*/

DATA DIAB;
 SET CDATA.H180;
 IF CCCODEX IN ('049', '050');
RUN;

TITLE3 "CHECK CCS CODES";
PROC FREQ DATA=DIAB;
  TABLES CCCODEX / LIST MISSING;
RUN;


/*2) GET EVENT ID FOR THE DIABETIC CONDITIONS FROM CONDITION-EVENT LINK FILE*/

DATA  DIAB2 ;
MERGE DIAB          (IN=AA KEEP=DUPERSID CONDIDX CCCODEX)
      CDATA.H178IF1 (IN=BB KEEP=CONDIDX  EVNTIDX );
   BY CONDIDX;
      IF AA AND BB ;
RUN;

TITLE3 "SAMPLE DUMP FOR CONDITION-EVEL LINK FILE";
PROC PRINT DATA=DIAB2 (OBS=20);
BY CONDIDX;
RUN;


/*3) DELETE DUPLICATE CASES PER EVENT*/

PROC SORT DATA=DIAB2 (KEEP=DUPERSID EVNTIDX) OUT=DIAB3 NODUPKEY;
  BY EVNTIDX;
RUN;

TITLE3 "SAMPLE DUMP AFTER DUPLICATE CASES ARE DELETED";
PROC PRINT DATA=DIAB3 (OBS=30);
RUN;


/*4) SUM UP PMED PURCHASE-LEVEL DATA TO EVENT-LEVEL */

PROC SORT DATA=CDATA.H178A  OUT=PMED (KEEP=LINKIDX RXXP15X  RXSF15X--RXOU15X RENAME=(LINKIDX=EVNTIDX));
  BY LINKIDX;
RUN;

PROC SUMMARY DATA=PMED NWAY;
CLASS EVNTIDX;
VAR RXXP15X  RXSF15X--RXOU15X;
OUTPUT OUT=PMED2 SUM=;
RUN;


/*5) ALIGN EXP VARIABLES IN DIFFERENT EVENTS WITH THE SAME NAMES*/

DATA PMED3 (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  PMED2;

     SF     = RXSF15X ;
     MR     = RXMR15X ;
     MD     = RXMD15X ;
     PV     = RXPV15X ;
     VA     = RXVA15X ;
     TR     = RXTR15X ;
     OF     = RXOF15X ;
     SL     = RXSL15X ;
     WC     = RXWC15X ;
     OR     = RXOR15X ;
     OU     = RXOU15X ;
     OT     = RXOT15X ;
     TOTEXP = RXXP15X ;

     IF TOTEXP GE 0 ;
RUN;


DATA OB (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
 SET CDATA.H178G ;

     SF     = OBSF15X ;
     MR     = OBMR15X ;
     MD     = OBMD15X ;
     PV     = OBPV15X ;
     VA     = OBVA15X ;
     TR     = OBTR15X ;
     OF     = OBOF15X ;
     SL     = OBSL15X ;
     WC     = OBWC15X ;
     OR     = OBOR15X ;
     OU     = OBOU15X ;
     OT     = OBOT15X ;
     TOTEXP = OBXP15X ;

     IF TOTEXP GE 0 ;
RUN ;

DATA EROM (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H178E;
     SF     = ERFSF15X + ERDSF15X ;
     MR     = ERFMR15X + ERDMR15X ;
     MD     = ERFMD15X + ERDMD15X ;
     PV     = ERFPV15X + ERDPV15X ;
     VA     = ERFVA15X + ERDVA15X ;
     TR     = ERFTR15X + ERDTR15X ;
     OF     = ERFOF15X + ERDOF15X ;
     SL     = ERFSL15X + ERDSL15X ;
     WC     = ERFWC15X + ERDWC15X ;
     OR     = ERFOR15X + ERDOR15X ;
     OU     = ERFOU15X + ERDOU15X ;
     OT     = ERFOT15X + ERDOT15X ;
     TOTEXP = ERXP15X ;

     IF TOTEXP GE 0;
RUN;

DATA IPAT (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H178D ;

     SF    = IPFSF15X + IPDSF15X ;
     MR    = IPFMR15X + IPDMR15X ;
     MD    = IPFMD15X + IPDMD15X ;
     PV    = IPFPV15X + IPDPV15X ;
     VA    = IPFVA15X + IPDVA15X ;
     TR    = IPFTR15X + IPDTR15X ;
     OF    = IPFOF15X + IPDOF15X ;
     SL    = IPFSL15X + IPDSL15X ;
     WC    = IPFWC15X + IPDWC15X ;
     OR    = IPFOR15X + IPDOR15X ;
     OU    = IPFOU15X + IPDOU15X ;
     OT    = IPFOT15X + IPDOT15X ;
     TOTEXP= IPXP15X ;

     IF TOTEXP GE 0 ;
RUN;

DATA HVIS (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H178H;

     SF     = HHSF15X ;
     MR     = HHMR15X ;
     MD     = HHMD15X ;
     PV     = HHPV15X ;
     VA     = HHVA15X ;
     TR     = HHTR15X ;
     OF     = HHOF15X ;
     SL     = HHSL15X ;
     WC     = HHWC15X ;
     OR     = HHOR15X ;
     OU     = HHOU15X ;
     OT     = HHOT15X ;
     TOTEXP = HHXP15X ;

     IF TOTEXP GE 0;
RUN;

DATA OPAT (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H178F ;

     SF     = OPFSF15X + OPDSF15X ;
     MR     = OPFMR15X + OPDMR15X ;
     MD     = OPFMD15X + OPDMD15X ;
     PV     = OPFPV15X + OPDPV15X ;
     VA     = OPFVA15X + OPDVA15X ;
     TR     = OPFTR15X + OPDTR15X ;
     OF     = OPFOF15X + OPDOF15X ;
     SL     = OPFSL15X + OPDSL15X ;
     WC     = OPFWC15X + OPDWC15X ;
     OR     = OPFOR15X + OPDOR15X ;
     OU     = OPFOU15X + OPDOU15X ;
     OT     = OPFOT15X + OPDOT15X ;
     TOTEXP = OPXP15X ;

     IF TOTEXP GE 0;
RUN;


/*6)  COMBINE ALL EVENTS INTO ONE DATASET*/

DATA ALLEVENT;
   SET OB   (IN=MV KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
       EROM (IN=ER KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
       IPAT (IN=ST KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
       HVIS (IN=HH KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
       OPAT (IN=OP KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP)
      PMED3 (IN=RX KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
   BY EVNTIDX;

      LENGTH EVNTYP $4;

      LABEL  EVNTYP = 'EVENT TYPE'
             TOTEXP = 'TOTAL EXPENDITURE FOR EVENT'
             SF     = "SOURCE OF PAYMENT: FAMILY"
             MR     = "SOURCE OF PAYMENT: MEDICARE"
             MD     = "SOURCE OF PAYMENT: MEDICAID"
             PV     = "SOURCE OF PAYMENT: PRIVATE INSURANCE"
             VA     = "SOURCE OF PAYMENT: VETERANS"
             TR     = "SOURCE OF PAYMENT: TRICARE"
             OF     = "SOURCE OF PAYMENT: OTHER FEDERAL"
             SL     = "SOURCE OF PAYMENT: STATE & LOCAL GOV"
             WC     = "SOURCE OF PAYMENT: WORKERS COMP"
             OR     = "SOURCE OF PAYMENT: OTHER PRIVATE"
             OU     = "SOURCE OF PAYMENT: OTHER PUBLIC"
             OT     = "SOURCE OF PAYMENT: OTHER INSURANCE"
                    ;

           IF MV OR OP THEN EVNTYP = 'AMBU' ;
      ELSE IF ER       THEN EVNTYP = 'EROM' ;
      ELSE IF ST       THEN EVNTYP = 'IPAT' ;
      ELSE IF HH       THEN EVNTYP = 'HVIS' ;
      ELSE IF RX       THEN EVNTYP = 'PMED' ;
RUN;

TITLE3 "ALL EVENTS ARE COMBINED INTO ONE FILE";
PROC FREQ DATA=ALLEVENT;
  TABLES EVNTYP TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT /LIST MISSING;
  FORMAT TOTEXP  SF MR MD PV VA TR OF SL WC OR OU OT gezero. ;
RUN;

PROC PRINT DATA=ALLEVENT (OBS=20);
RUN;


/*7) SUBSET EVENTS TO THOSE ONLY WITH DIABETES*/

DATA DIAB4;
  MERGE DIAB3(IN=AA) ALLEVENT(IN=BB);
  BY EVNTIDX;
  IF AA AND BB;
RUN;


/*8) CALCULATE ESTIMATES ON EXPENDITURES AND USE, ALL TYPES OF SERVICE*/

PROC SUMMARY DATA=DIAB4 NWAY;
  CLASS DUPERSID;
  VAR TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT;
  OUTPUT OUT=ALL SUM=;
RUN;


DATA  FY1;
MERGE CDATA.H181 (IN=AA KEEP=DUPERSID VARPSU VARSTR PERWT15F /*ADD MORE VARIABLES*/)
      ALL        (IN=BB KEEP=DUPERSID TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT);
   BY DUPERSID;

      LABEL SUB = 'PERSONS WHO HAVE AT LEAST 1 EVENT ASSOCIATED WITH DIABETES';

           IF AA AND     BB THEN SUB=1;
      ELSE IF AA AND NOT BB THEN DO ;  /*PERSONS WITHOUT EVENTS WITH DIABETES*/
           SUB   = 2 ;
           TOTEXP= 0 ;
           SF    = 0 ;
           MR    = 0 ;
           MD    = 0 ;
           PV    = 0 ;
           VA    = 0 ;
           TR    = 0 ;
           OF    = 0 ;
           SL    = 0 ;
           WC    = 0 ;
           OR    = 0 ;
           OU    = 0 ;
           OT    = 0 ;
       END;
       IF PERWT15F > 0 ;
RUN;
ODS GRAPHICS OFF;
ODS LISTING CLOSE;
PROC SURVEYMEANS DATA=FY1 NOBS SUMWGT SUM STD MEAN STDERR;
	STRATA  VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT PERWT15F ;
	DOMAIN  SUB('1') ;
	VAR TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT;
    ODS OUTPUT DOMAIN=OUT1;
RUN;
ODS LISTING;
TITLE3 "ESTIMATES ON USE AND EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH DIABETES, 2015";
PROC PRINT DATA=OUT1 NOOBS LABEL;
VAR  VARNAME /*VARLABEL*/ N SUMWGT SUM STDDEV MEAN STDERR;
FORMAT N                    comma6.0
       SUMWGT SUM    STDDEV comma17.0
       MEAN   STDERR        comma9.2
    ;
RUN;


/*9) CALCULATE ESTIMATES ON EXPENDITURES AND USE BY TYPE OF SERVICE */

PROC SUMMARY DATA=DIAB4 NWAY;
  CLASS DUPERSID EVNTYP;
  VAR TOTEXP SF MR MD PV VA TR OF SL WC OR OU OT;
  OUTPUT OUT=TOS SUM=;
RUN;

DATA TOS2;
  SET TOS (DROP=_TYPE_ RENAME=(_FREQ_=N_VISITS));
  LABEL N_VISITS = '# OF VISITS PER PERSON FOR EACH TYPE OF SERVICE' ;
RUN;

TITLE3 "SAMPLE DUMP AFTER DATA IS SUMMED UP TO PERSON-EVENT TYPE-LEVEL";
PROC PRINT DATA=TOS2 (OBS=20);
  BY DUPERSID;
RUN;

DATA  FYTOS;
MERGE CDATA.H181 (IN=AA KEEP=DUPERSID VARPSU VARSTR PERWT15F /*ADD MORE VARIABLES*/)
      TOS2       (IN=BB);
  BY DUPERSID;

          IF AA AND     BB THEN SUB=1;
     ELSE IF AA AND NOT BB THEN DO ;   /*PERSONS WITHOUT EVENTS WITH DIABETES*/
          SUB=2;
          EVNTYP   = 'NA';
          N_VISITS = 0 ;
          TOTEXP   = 0 ;
          SF       = 0 ;
          MR       = 0 ;
          MD       = 0 ;
          PV       = 0 ;
          VA       = 0 ;
          TR       = 0 ;
          OF       = 0 ;
          SL       = 0 ;
          WC       = 0 ;
          OR       = 0 ;
          OU       = 0 ;
          OT       = 0 ;
     END;

     LABEL SUB = 'PERSONS WHO HAVE AT LEAST 1 EVENT ASSOCIATED WITH DIABETES';

     IF PERWT15F > 0 ;
RUN;

ODS GRAPHICS OFF;
ODS LISTING CLOSE;
PROC SURVEYMEANS DATA=FYTOS NOBS SUMWGT SUM STD MEAN STDERR;
	STRATA  VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT15F ;
	DOMAIN SUB('1') * EVNTYP ;
	VAR N_VISITS TOTEXP  SF  MR  MD PV VA TR OF SL WC OR OU OT;
    ODS OUTPUT DOMAIN=OUT2 ;
RUN;
ODS LISTING;

PROC SORT DATA=OUT2;
  BY EVNTYP;
RUN;

TITLE3 "ESTIMATES ON USE AND EXPENDITURES FOR EVENTS ASSOCIATED WITH DIABETES, BY TYPE OF SERVICE, 2015";
PROC PRINT DATA=OUT2 NOOBS LABEL;
BY EVNTYP;
VAR  VARNAME /*VARLABEL*/ N SUMWGT SUM STDDEV MEAN STDERR;
FORMAT N                    comma6.0
       SUMWGT SUM    STDDEV comma17.0
       MEAN   STDERR        comma9.2
 ;
RUN;
PROC PRINTTO; 
RUN;
