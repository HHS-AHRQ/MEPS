/********************************************************************\

PROGRAM:    	C:\\MEPS\PROG\M2.SAS

DESCRIPTION: 	THIS EXAMPLE SHOWS THE NEED FOR USING THE
		         	STRATUM AND PSU VARIABLES WHEN ANALYZING MEPS 
		         	DATA FOR NATIONAL ESTIMATES.  THAT IS, TAKING
		         	THE MEPS COMPLEX DESIGN PROPERTIES INTO
		         	ACCOUNT.

INPUT FILE:  	C:\MEPS\DATA\H97.SAS7BDAT (2005 FULL-YEAR DATA FILE)                       

\********************************************************************/

FOOTNOTE 'PROGRAM: C:\MEPS\PROG\M2.SAS';

LIBNAME CDATA  'C:\MEPS\DATA' ;

TITLE1 'AHRQ MEPS DATA USERS WORKSHOP -- SEPTEMBER 2008';                                      
TITLE2 'EFFECT OF STRATA AND PSU VARIABLES ON COMPUTING';
TITLE3 'STANDARD ERRORS FOR TOTAL HEALTH-CARE EXPENDITURES';

* READ 2005 CONSOLIDATED FULL YEAR FILE;
DATA PUF97 ;
	SET CDATA.H97 (KEEP= TOTEXP05 VARPSU VARSTR PERWT05F);                                 
RUN;

/***** ASSUME SIMPLE RANDOM SAMPLE *****/

PROC SURVEYMEANS DATA= PUF97 NOBS SUM  ;                                                  
	WEIGHT PERWT05F ;                                                                     
	VAR TOTEXP05 ;                                                                         
	ODS OUTPUT STATISTICS= SRSTOT (KEEP= SUM STDDEV) ;
RUN;

/***** ACCOUNT FOR MEPS COMPLEX SAMPLE DESIGN *****/

PROC SURVEYMEANS DATA= PUF97 NOBS SUM  ;                                                   
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT PERWT05F ;                                                                       
	VAR TOTEXP05 ;                                                                          
	ODS OUTPUT STATISTICS= COMPTOT (KEEP= SUM STDDEV);
RUN;

DATA _NULL_;
	SET SRSTOT;
	PUT 'SRS    TOTAL IS ' SUM DOLLAR22.2 ;
	PUT 'SRS SE TOTAL IS ' STDDEV DOLLAR22.2 ;
RUN;

DATA _NULL_;
	SET COMPTOT;
	PUT 'COMPLEX DESIGN TOTAL    IS ' SUM DOLLAR22.2 ;
	PUT 'COMPLEX DESIGN TOTAL SE IS ' STDDEV DOLLAR22.2 ;
RUN;
