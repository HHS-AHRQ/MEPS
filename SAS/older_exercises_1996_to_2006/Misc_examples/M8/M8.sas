/**********************************************************************\

PROGRAM:     C:\MEPS\PROG\M8.SAS

DESCRIPTION: THIS EXAMPLE SHOWS HOW TO COMPUTE PRESCRIBED
		         MEDICINE EXPENDITURES ASSOCIATED WITH CANCER 
		         CONDITIONS.
		
		         IN ADDITION TO THE MEDICAL CONDITIONS AND FULL-
		         YEAR FILES, THE PRESCRIBED MEDICINES EVENT FILE AND 
		         THE CLNK FILE ARE USED.
		         THE PMED EXPENDITURES ARE SUMMED TO THE EVENT 
		         LEVEL.
		         MODIFIED SOURCE OF PAYMENT (SOP) CATEGORIES
		         ARE CREATED AS COLUMN CATEGORIES.
		         ROW CATEGORIES ARE AGE AND RACE/ETHNICITY (FROM
		         THE FULL-YEAR FILE).
		         USE PROC TABULATE TO COMPUTE AND DISPLAY OUTPUT.

INPUT FILES: (1) C:\MEPS\DATA\H97.SAS7BDAT (2005 FULL-YEAR DATA FILE)                        
		         (2) C:\MEPS\DATA\H96.SAS7BDAT (2005 MEDICAL CONDITIONS FILE)                     
		         (3) C:\MEPS\DATA\H94I1.SAS7BDAT (2005 CLNK FILE)                                 
			               THIS FILE LINKS CONDITIONS TO EVENTS
		         (4) C:\MEPS\DATA\H94A.SAS7BDAT (2005 PRESCRIBED MED. FILE)                        

\**********************************************************************/

FOOTNOTE 'PROGRAM: C:\MEPS\PROG\M8.SAS';

LIBNAME CDATA 'C:\MEPS\DATA';

TITLE1 'AHRQ MEPS DATA USERS WORKSHOP -- SEPTEMBER 2008';                                           
TITLE2 'PRESCRIBED MEDICINES EXPENDITURES FOR CANCER CONDITIONS';

PROC FORMAT;
	VALUE AGECAT 
	.='TOTAL'
	1=' < 18'
	2='18-64'
	3='65+'
	;
	VALUE RACETHNB
	1 = 'HISPANIC'
	2 = 'BLACK'
	3 = 'ASIAN'
	4 = 'OTHER';
RUN;
 
/***** USE CCCODEX VALUES TO SELECT PEOPLE WITH CANCER FROM 2005 CONDITION FILE. *****/           

DATA COND05 (KEEP=DUPERSID CONDIDX);                                                               
	SET CDATA.H96 (KEEP=DUPERSID CCCODEX CONDIDX                                                 
	           WHERE =('011' <= CCCODEX <= '045' ) );                                              
RUN;

/***** GET PRESCRIBED MEDICINES EXPENSES FROM 2005 PMED FILE. *****/


PROC SORT DATA= CDATA.H94A (KEEP= DUPERSID RXRECIDX LINKIDX RXSF05X RXMD05X RXPV05X               
				RXMR05X RXXP05X RXNDC)                                                              
		OUT= PMEDACQ;                                                                              
	BY LINKIDX RXRECIDX;
RUN;

TITLE3 'ILLUSTRATION OF PMED RECORDS AT THE ACQUISITION LEVEL';
TITLE4 'PRE-SELECTED PERSONS';

PROC PRINT DATA= PMEDACQ LABEL ;
	VAR DUPERSID LINKIDX RXRECIDX RXXP05X RXSF05X RXPV05X RXMD05X RXMR05X ;                           
	LABEL 	RXXP05X = 'TOTAL EXP'                                                                     
		      RXSF05X = 'OOP'                                                                         
		      RXMD05X = 'MEDICAID'                                                                     
		      RXMR05X = 'MEDICARE'                                                                   
		      RXPV05X = 'PRIVATE' ;                                                                  
   WHERE DUPERSID IN ('32663024', '33634027') ;                                                                        
RUN;

/***** SUM PMED EXPENSES TO EVENT LEVEL *****/

DATA PMEDEVNT (KEEP= DUPERSID EVNTIDX OOP MEDICARE MEDICAID PRIVATE OTHER TOTRX05 RXNDC);             
	SET PMEDACQ;
	BY LINKIDX RXRECIDX;
	ARRAY EXPVARS{5} OOP MEDICARE MEDICAID PRIVATE TOTRX05  ;                                         
	IF FIRST.LINKIDX
		THEN DO XX = 1 TO 5;
			EXPVARS{XX} = 0;
		     END;
	OOP+RXSF05X;                                                                                  
	MEDICARE+RXMR05X;                                                                             
	MEDICAID+RXMD05X;                                                                             
	PRIVATE+RXPV05X;                                                                              
	TOTRX05+RXXP05X;                                                                                                                                                           
	EVNTIDX=LINKIDX;                                                                              
	IF LAST.LINKIDX
		THEN
		DO;
			OTHER= ROUND(TOTRX05-(MEDICARE+MEDICAID+PRIVATE+OOP));                                 
			OUTPUT;
		END;
	LABEL 	OOP = 'OUT-OF-POCKET'
		      MEDICARE = 'MEDICARE'
		      MEDICAID = 'MEDICAID'
		      PRIVATE = 'PRIVATE'
		      OTHER = 'OTHER'
		      TOTRX05 = 'TOTAL PMED EXPENSES';                                                     
RUN;

TITLE3 'ILLUSTRATION OF PMED RECORDS AT THE EVENT LEVEL';
TITLE4 'PRE-SELECTED PERSONS';

PROC PRINT DATA= PMEDEVNT ;
	VAR DUPERSID EVNTIDX RXNDC TOTRX05 OOP PRIVATE MEDICARE MEDICAID OTHER;                      
  WHERE DUPERSID IN ('32663024', '33634027') ;
RUN;
	
/***** MERGE CONDITIONS FILE TO PRESCRIBED MEDICINE EVENTS THROUGH CLNK FILE *****/

* READ 2005 CLNK FILE;
DATA CLNK;
	SET CDATA.H94I1 (KEEP=CONDIDX EVNTIDX);                                                     
RUN;

PROC SORT DATA=CLNK;
	BY CONDIDX;
RUN;

PROC SORT DATA=COND05;                                                                          
	BY CONDIDX;
RUN;

/***** MERGE BY CONDIDX TO GET EVNTIDS ASSOCIATED WITH CANCER EVENTS *****/

DATA CONDCLNK;
	MERGE COND05 (IN=A) CLNK (IN=B) ;                                                   
	BY CONDIDX;
	IF A;
RUN;

PROC SORT DATA=PMEDEVNT;
	BY  EVNTIDX;
RUN;

PROC SORT DATA=CONDCLNK;
	BY EVNTIDX;
RUN;

/***** NOW MERGE CONDITIONS FILE WITH EVENTIDS TO PMED EVENT FILE. *****/
/***** ONLY KEEP RECORDS THAT MATCH.                               *****/

DATA CONDPMED;
	MERGE CONDCLNK (IN=A) PMEDEVNT(IN=B) ;
	BY EVNTIDX;
	IF A AND B; 
	
RUN;

PROC SORT DATA= CONDPMED;
	BY EVNTIDX CONDIDX;
RUN;

TITLE3 'ILLUSTRATION OF DUPLICATE EVENTS/EXPENDITURES';
TITLE4 'PRE-SELECTED PERSONS';

PROC PRINT DATA= CONDPMED ;
	VAR DUPERSID CONDIDX EVNTIDX TOTRX05 OOP 
	    PRIVATE MEDICARE MEDICAID OTHER;                                                          
   WHERE DUPERSID IN ('32663024', '33634027') ;
RUN;

/***** DE-DUPLICATE EXPENDITURES *****/


PROC SORT DATA=CONDPMED NODUPKEY;
	BY EVNTIDX;
RUN;

TITLE3 'ILLUSTRATION OF DE-DUPLICATED EVENTS/EXPENDITURES';
TITLE4 'PRE-SELECTED PERSONS';

PROC PRINT DATA=CONDPMED ;
	VAR DUPERSID CONDIDX EVNTIDX TOTRX05 OOP 
	    PRIVATE MEDICARE MEDICAID OTHER;                                                
   WHERE DUPERSID IN ('32663024', '33634027') ;
RUN;

/***** USE FULL-YEAR FILE TO GET AGE AND RACE/ETHNICITY VARIABLES.   *****/
/***** SET AGE AS LATEST VALID AGE AND RE-CATEGORIZE RACE/ETHNICITY. *****/

* READ 2005 CONSOLIDATED FULL YEAR FILE;
DATA PUF97 (KEEP= DUPERSID AGECAT  RACETHNX PERWT05F);                                   
	SET CDATA.H97 (KEEP= DUPERSID AGE: RACETHNX RACEX 
	                PERWT05F);                                                          
	IF AGE05X>=0 THEN AGE=AGE05X;                                                       
	ELSE IF AGE53X>=0 THEN AGE=AGE53X;
	ELSE IF AGE42X>=0 THEN AGE=AGE42X;
	ELSE IF AGE31X>=0 THEN AGE=AGE31X;
	ELSE AGE=AGE05X;                                                                    
	IF 0<= AGE <18 THEN AGECAT=1;
	ELSE IF 18 <= AGE <65 THEN AGECAT=2;
	ELSE IF AGE>=65 THEN AGECAT=3;
	LABEL 	AGECAT='AGE IN YEARS'
		RACETHNX='RACE/ENTHNICITY';
RUN;

/***** MERGE RACE/ETHNICITY VARIABLES ONTO COND/PMED FILE *****/

DATA TEMP;
	MERGE CONDPMED(IN=A) PUF97 (IN=B);                                             
	BY DUPERSID;
	IF A;
	OOP=OOP/1000;
	PRIVATE=PRIVATE/1000;
	MEDICARE=MEDICARE/1000;
	MEDICAID=MEDICAID/1000;
	OTHER=OTHER/1000;
	TOTRX05=TOTRX05/1000;                                                         
RUN;

TITLE3 'DOLLARS IN THOUSANDS';

PROC TABULATE DATA=TEMP MISSING FORMAT=COMMA10.0 ;
	CLASS AGECAT  RACETHNX;
	VAR   TOTRX05 OOP PRIVATE MEDICARE MEDICAID OTHER;                         
	FORMAT AGECAT AGECAT.   RACETHNX RACETHNB.;  
	TABLE  ALL='TOTAL' AGECAT RACETHNX , 
		TOTRX05*SUM OOP*SUM PRIVATE*SUM MEDICARE*SUM
		MEDICAID*SUM OTHER*SUM
		/RTS=20 ;                                                             
	WEIGHT PERWT05F;                                                          
RUN;

