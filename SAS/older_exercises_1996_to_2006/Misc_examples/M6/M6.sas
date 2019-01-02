/**************************************************************************\

PROGRAM:       C:\\MEPS\PROG\M6.SAS

DESCRIPTION:   THIS EXAMPLE SHOWS THE USE OF THE DIABETES CARE SUPPLEMENT
               (DCS) WEIGHT VARIABLE (DIABW05F) FOR GENERATING ESTIMATES                               
               FOR ANALYSES USING QUESTIONS FROM THE DCS.
               
               TWO DCS VARIABLES ARE USED:
               
               (1) DSA1C53  (NUMBER OF TIMES TESTED FOR HEMOGLOBIN A1C)
               (2) DSINSU53 (DIABETES TREATED WITH INSULIN INJECTIONS?)
               
INPUT FILES:  	C:\MEPS\DATA\H97.SAS7BDAT (2005 FULL-YEAR DATA FILE)                                           

\**************************************************************************/

FOOTNOTE 'PROGRAM: C:\MEPS\PROG\M6.SAS';

LIBNAME CDATA 'C:\MEPS\DATA' ;

TITLE1 'AHRQ MEPS DATA USERS WORKSHOP -- SEPTEMBER 2008';                                                
TITLE2 'DIABETES CARE SUPPLEMENT ESTIMATES';

PROC FORMAT;
   VALUE A1CF
   -9 = '-9 NOT ASCERTAINED'
   -8 = '-8 DK'
   -1 = '-1 INAPPLICABLE'
   1-20 = '1-20 TIMES'
   21-50 = '21-50 TIMES'
   50-HIGH = '51 TIMES OR MORE';
   VALUE INSF
   -9 = '-9 NOT ASCERTAINED'
   -8 = '-8 DK' 
   -1 = '-1 INAPPLICABLE'
   1 = '1 YES'
   0 = '0  NO';
RUN;

*READ 2005 CONSOLIDATED FULL YEAR FILE AND KEEP SELECTED DIABETES VARIABLES;
DATA FY2005;                                                                                                                                                                           
   SET CDATA.H97 (KEEP= DUPERSID DIABW05F VARSTR VARPSU                                           
                        DSA1C53 DSINSU53);                                                        
RUN;

PROC SURVEYFREQ DATA= FY2005 ;                                                                    
   STRATA VARSTR;
   CLUSTER VARPSU;
   WEIGHT DIABW05F;                                                                               
   TABLES DSA1C53 DSINSU53 ;
   FORMAT DSA1C53 A1CF. DSINSU53 INSF. ;
RUN;
   

   
