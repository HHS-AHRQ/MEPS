/********************************************************************\

PROGRAM:        C:\\MEPS\PROG\M9.SAS

DESCRIPTION:   THIS EXAMPLE USES THE 2005 FULL-YEAR FILE TO OUTPUT                                
               DESCRIPTIVE STATISTICS SHOWING HEALTH INSURANCE
               STATUS AND HEALTHCARE UTILIZATION.
               
               TYPES OF EVENTS USED IN THIS PROGRAM:
               
               PRESCRIBED MEDICINE USE (RXTOT05)
               OFFICE-BASED VISITS (OBTOT05)
               EMERGENCY DEPT. VISITS (ERTOT05)

INPUT FILE:  	 C:\MEPS\DATA\H97.SAS7BDAT (2005 FULL-YEAR DATA FILE)                               

\********************************************************************/

FOOTNOTE 'PROGRAM: C:\MEPS\PROG\M9.SAS';

LIBNAME CDATA 'C:\MEPS\DATA' ;

TITLE1 'AHRQ MEPS DATA USERS WORKSHOP -- SEPTEMBER 2008';                                                  
TITLE2 'HEALTH INSURANCE STATUS AND HEALTHCARE UTILIZATION';

PROC FORMAT;
   VALUE YESNO
   -9 = '-9 NOT ASCERTAINED'
   -8 = '-8 DK'
   -7 = '-7 REFUSED'
   -1 = '-1 INAPPLICABLE'
   1 = 'UNINSURED'
   2 = 'INSURED';
   VALUE INSCOV
   1 = 'ANY PRIVATE'
   2 = 'PUBLIC ONLY'
   3 = 'UNINSURED';
RUN;

*READ 2005 CONSOLIDATED FULL YEAR FILE;
DATA PUF97 ;                                                                     
	SET CDATA.H97 (KEEP= UNINS05 INSCOV05 RXTOT05 OBTOTV05 ERTOT05
	                     VARPSU VARSTR PERWT05F);                                
	LABEL OBTOTV05= ' '
	      RXTOT05 = ' '
	      ERTOT05 = ' '
	      UNINS05 = ' '
	      INSCOV05= ' ';                                                         
RUN;

TITLE3 'MEAN NUMBER OF PRESCRIPTIONS AND REFILLS BY INSURANCE COVERAGE STATUS';

PROC SURVEYMEANS DATA= PUF97 NOBS SUMWGT MEAN STDERR;                          
   VAR RXTOT05;                                                                
   STRATA VARSTR;
   CLUSTER VARPSU;
   WEIGHT PERWT05F;                                                            
   DOMAIN UNINS05 INSCOV05;                                                    
   FORMAT UNINS05 YESNO. INSCOV05 INSCOV. ;                                    
RUN;

TITLE3 'MEAN NUMBER OF OFFICE VISITS BY INSURANCE COVERAGE STATUS';

PROC SURVEYMEANS DATA= PUF97 NOBS SUMWGT MEAN STDERR;                        
   VAR OBTOTV05;                                                             
   STRATA VARSTR;
   CLUSTER VARPSU;
   WEIGHT PERWT05F;                                                         
   DOMAIN UNINS05 INSCOV05;                                                 
   FORMAT UNINS05 YESNO. INSCOV05 INSCOV. ;                                 
RUN;

TITLE3 'MEAN NUMBER OF EMERGENCY DEPT. VISITS BY INSURANCE COVERAGE STATUS';

PROC SURVEYMEANS DATA= PUF97 NOBS SUMWGT MEAN STDERR;                        
   VAR ERTOT05;                                                             
   STRATA VARSTR;
   CLUSTER VARPSU;
   WEIGHT PERWT05F;                                                         
   DOMAIN UNINS05 INSCOV05;                                                 
   FORMAT UNINS05 YESNO. INSCOV05 INSCOV. ;                                 
RUN;