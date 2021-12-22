/*****************************************************************************/
/* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
/*
/* Accessibility and quality of care: Access to Care, 2017
/*
/* Reasons for difficulty receiving needed care
/*  - Number/percent of people
/*  - By poverty status
/*
/* Input file: C:/MEPS/h201.sas7bdat (2017 full-year consolidated)
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

data h201;
	set "C:/MEPS/h201.sas7bdat";
run;


/* Define variables **********************************************************/

data MEPS;
  	SET h201;

/* Reasons for difficulty receiving needed care */

	/* any delay / unable to receive needed care   */
    delay_MD  = (MDUNAB42 = 1 | MDDLAY42 = 1);
    delay_DN  = (DNUNAB42 = 1 | DNDLAY42 = 1);
    delay_PM  = (PMUNAB42 = 1 | PMDLAY42 = 1);
    
    /* Among people unable or delayed, how many... */
    /* ...couldn't afford */
    afford_MD = (MDDLRS42 = 1 | MDUNRS42 = 1);
    afford_DN = (DNDLRS42 = 1 | DNUNRS42 = 1);
    afford_PM = (PMDLRS42 = 1 | PMUNRS42 = 1);
    
    /* ...had insurance problems */
    insure_MD = (MDDLRS42 in (2,3) | MDUNRS42 in (2,3));
    insure_DN = (DNDLRS42 in (2,3) | DNUNRS42 in (2,3));
    insure_PM = (PMDLRS42 in (2,3) | PMUNRS42 in (2,3));
    
    /* ...other */
    other_MD  = (MDDLRS42 > 3 | MDUNRS42 > 3);
    other_DN  = (DNDLRS42 > 3 | DNUNRS42 > 3);
    other_PM  = (PMDLRS42 > 3 | PMUNRS42 > 3);
    
    delay_ANY  = (delay_MD  | delay_DN  | delay_PM);
    afford_ANY = (afford_MD | afford_DN | afford_PM);
    insure_ANY = (insure_MD | insure_DN | insure_PM);
    other_ANY  = (other_MD  | other_DN  | other_PM);


 /* Define domain and adjust weights so SAS doesn't drop observations   */
 /*  - domain includes persons eligible to receive the 'access to care' */
 /*    supplement and who experienced difficulty receiving needed care  */

	domain = (ACCELI42 = 1 & delay_ANY = 1);
	if domain = 0 and PERWT17F = 0 then PERWT17F = 1;

run;

proc format;
	value poverty
		1 = '1 Negative or poor'
	    2 = '2 Near-poor'
	    3 = '3 Low income'
	    4 = '4 Middle Income'
	    5 = '5 High Income';
run;


/* QC new variables */
proc freq data = MEPS;
	tables  delay_MD*MDUNAB42*MDDLAY42 
			delay_DN*DNUNAB42*DNDLAY42 
			delay_PM*PMUNAB42*PMDLAY42 
			delay_ANY*delay_MD*delay_DN*delay_PM/ list;
 			/*...repeat for "couldn't afford", "insurance", and "other" */
run;


/* Calculate estimates using survey procedures *******************************/

/* Reasons for difficulty receiving any needed care, by poverty status       */
/*  sum  = Number of people    			                        			 */
/* 	mean = Percent of people                                    			 */

proc surveymeans data = MEPS missing sum mean;
	FORMAT POVCAT17 poverty.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT17F;
	DOMAIN domain('1')*POVCAT17;
	var afford_ANY insure_ANY other_ANY;
run;
