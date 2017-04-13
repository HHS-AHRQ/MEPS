/**********************************************************************************

PROGRAM:      C:\MEPS\SAS\PROG\EXERCISE5.SAS

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


INPUT FILES:  1) C:\MEPS\SAS\DATA\H171.SAS7BDAT    (2014 FY PUF DATA)
              2) C:\MEPS\SAS\DATA\H170.SAS7BDAT    (2014 CONDITION PUF DATA)
              3) C:\MEPS\SAS\DATA\H168A.SAS7BDAT   (2014 PMED PUF DATA)
              4) C:\MEPS\SAS\DATA\H168D.SAS7BDAT   (2014 INPATIENT VISITS PUF DATA)
              5) C:\MEPS\SAS\DATA\H168E.SAS7BDAT   (2014 EROM VISITS PUF DATA)
              6) C:\MEPS\SAS\DATA\H168F.SAS7BDAT   (2014 OUTPATIENT VISITS PUF DATA)
              7) C:\MEPS\SAS\DATA\H168G.SAS7BDAT   (2014 OFFICE-BASED VISITS PUF DATA)
              8) C:\MEPS\SAS\DATA\H168H.SAS7BDAT   (2014 HOME HEALTH PUF DATA)
              9) C:\MEPS\SAS\DATA\H168IF1.SAS7BDAT  (2014 CONDITION-EVENT LINK PUF DATA)

*********************************************************************************/;

LIBNAME CDATA 'C:\MEPS\SAS\DATA';
*LIBNAME CDATA "\\programs.ahrq.local\programs\meps\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2017\SAS\Data";

OPTIONS  NODATE;
TITLE1 'AHRQ MEPS DATA USERS WORKSHOP -- 2017';
TITLE2 'EXERCISE5.SAS: CALCULATE EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH A CONDITION (DIABETES)';

PROC FORMAT;
  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0'
               ;
  VALUE GEZERO
     0 - HIGH = 'GE 0' ;
RUN;

/*1) PULL OUT CONDITIONS WITH DIABETES (CCS CODE='049', '050') FROM 2014 CONDITION PUF - HC154*/

DATA DIAB;
 SET CDATA.H170;
 IF CCCODEX IN ('049', '050');
RUN;

TITLE3 "CHECK CCS CODES";
PROC FREQ DATA=DIAB;
  TABLES CCCODEX / LIST MISSING;
RUN;


/*2) GET EVENT ID FOR THE DIABETIC CONDITIONS FROM CONDITION-EVENT LINK FILE*/

DATA  DIAB2 ;
MERGE DIAB          (IN=AA KEEP=DUPERSID CONDIDX CCCODEX)
      CDATA.H168IF1 (IN=BB KEEP=CONDIDX  EVNTIDX );
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

PROC SORT DATA=CDATA.H168A  OUT=PMED (KEEP=LINKIDX RXXP14X  RXSF14X--RXOU14X RENAME=(LINKIDX=EVNTIDX));
  BY LINKIDX;
RUN;

PROC SUMMARY DATA=PMED NWAY;
CLASS EVNTIDX;
VAR RXXP14X  RXSF14X--RXOU14X;
OUTPUT OUT=PMED2 SUM=;
RUN;


/*5) ALIGN EXP VARIABLES IN DIFFERENT EVENTS WITH THE SAME NAMES*/

DATA PMED3 (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  PMED2;

     SF     = RXSF14X ;
     MR     = RXMR14X ;
     MD     = RXMD14X ;
     PV     = RXPV14X ;
     VA     = RXVA14X ;
     TR     = RXTR14X ;
     OF     = RXOF14X ;
     SL     = RXSL14X ;
     WC     = RXWC14X ;
     OR     = RXOR14X ;
     OU     = RXOU14X ;
     OT     = RXOT14X ;
     TOTEXP = RXXP14X ;

     IF TOTEXP GE 0 ;
RUN;


DATA OB (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
 SET CDATA.H168G ;

     SF     = OBSF14X ;
     MR     = OBMR14X ;
     MD     = OBMD14X ;
     PV     = OBPV14X ;
     VA     = OBVA14X ;
     TR     = OBTR14X ;
     OF     = OBOF14X ;
     SL     = OBSL14X ;
     WC     = OBWC14X ;
     OR     = OBOR14X ;
     OU     = OBOU14X ;
     OT     = OBOT14X ;
     TOTEXP = OBXP14X ;

     IF TOTEXP GE 0 ;
RUN ;

DATA EROM (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H168E;
     SF     = ERFSF14X + ERDSF14X ;
     MR     = ERFMR14X + ERDMR14X ;
     MD     = ERFMD14X + ERDMD14X ;
     PV     = ERFPV14X + ERDPV14X ;
     VA     = ERFVA14X + ERDVA14X ;
     TR     = ERFTR14X + ERDTR14X ;
     OF     = ERFOF14X + ERDOF14X ;
     SL     = ERFSL14X + ERDSL14X ;
     WC     = ERFWC14X + ERDWC14X ;
     OR     = ERFOR14X + ERDOR14X ;
     OU     = ERFOU14X + ERDOU14X ;
     OT     = ERFOT14X + ERDOT14X ;
     TOTEXP = ERXP14X ;

     IF TOTEXP GE 0;
RUN;

DATA IPAT (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H168D ;

     SF    = IPFSF14X + IPDSF14X ;
     MR    = IPFMR14X + IPDMR14X ;
     MD    = IPFMD14X + IPDMD14X ;
     PV    = IPFPV14X + IPDPV14X ;
     VA    = IPFVA14X + IPDVA14X ;
     TR    = IPFTR14X + IPDTR14X ;
     OF    = IPFOF14X + IPDOF14X ;
     SL    = IPFSL14X + IPDSL14X ;
     WC    = IPFWC14X + IPDWC14X ;
     OR    = IPFOR14X + IPDOR14X ;
     OU    = IPFOU14X + IPDOU14X ;
     OT    = IPFOT14X + IPDOT14X ;
     TOTEXP= IPXP14X ;

     IF TOTEXP GE 0 ;
RUN;

DATA HVIS (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H168H;

     SF     = HHSF14X ;
     MR     = HHMR14X ;
     MD     = HHMD14X ;
     PV     = HHPV14X ;
     VA     = HHVA14X ;
     TR     = HHTR14X ;
     OF     = HHOF14X ;
     SL     = HHSL14X ;
     WC     = HHWC14X ;
     OR     = HHOR14X ;
     OU     = HHOU14X ;
     OT     = HHOT14X ;
     TOTEXP = HHXP14X ;

     IF TOTEXP GE 0;
RUN;

DATA OPAT (KEEP=EVNTIDX SF MR MD PV VA TR OF SL WC OR OU OT TOTEXP);
SET  CDATA.H168F ;

     SF     = OPFSF14X + OPDSF14X ;
     MR     = OPFMR14X + OPDMR14X ;
     MD     = OPFMD14X + OPDMD14X ;
     PV     = OPFPV14X + OPDPV14X ;
     VA     = OPFVA14X + OPDVA14X ;
     TR     = OPFTR14X + OPDTR14X ;
     OF     = OPFOF14X + OPDOF14X ;
     SL     = OPFSL14X + OPDSL14X ;
     WC     = OPFWC14X + OPDWC14X ;
     OR     = OPFOR14X + OPDOR14X ;
     OU     = OPFOU14X + OPDOU14X ;
     OT     = OPFOT14X + OPDOT14X ;
     TOTEXP = OPXP14X ;

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
MERGE CDATA.H171 (IN=AA KEEP=DUPERSID VARPSU VARSTR PERWT14F /*ADD MORE VARIABLES*/)
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
       IF PERWT14F > 0 ;
RUN;

ODS LISTING CLOSE;
PROC SURVEYMEANS DATA=FY1 NOBS SUMWGT SUM STD MEAN STDERR;
	STRATA  VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT PERWT14F ;
	DOMAIN  SUB ;
	VAR TOTEXP  SF    MR      MD      PV    VA    TR    OF    SL    WC    OR    OU  OT;
    ODS OUTPUT DOMAIN=OUT1;
RUN;
ODS LISTING;


TITLE3 "ESTIMATES ON USE AND EXPENDITURES FOR ALL EVENTS ASSOCIATED WITH DIABETES, 2014";
PROC PRINT DATA=OUT1 (WHERE=(SUB=1)) NOOBS LABEL;
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
MERGE CDATA.H171 (IN=AA KEEP=DUPERSID VARPSU VARSTR PERWT14F /*ADD MORE VARIABLES*/)
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

     IF PERWT14F > 0 ;
RUN;

ODS LISTING CLOSE;
PROC SURVEYMEANS DATA=FYTOS NOBS SUMWGT SUM STD MEAN STDERR;
	STRATA  VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT14F ;
	DOMAIN SUB * EVNTYP ;
	VAR N_VISITS TOTEXP  SF    MR      MD      PV    VA    TR    OF    SL    WC    OR    OU OT;
    ODS OUTPUT DOMAIN=OUT2 ;
RUN;
ODS LISTING;

PROC SORT DATA=OUT2;
  BY EVNTYP;
RUN;

TITLE3 "ESTIMATES ON USE AND EXPENDITURES FOR EVENTS ASSOCIATED WITH DIABETES, BY TYPE OF SERVICE, 2014";
PROC PRINT DATA=OUT2 (WHERE=(SUB=1)) NOOBS LABEL;
VAR  VARNAME /*VARLABEL*/ N SUMWGT SUM STDDEV MEAN STDERR;
BY EVNTYP;
FORMAT N                    comma6.0
       SUMWGT SUM    STDDEV comma17.0
       MEAN   STDERR        comma9.2
 ;
RUN;
