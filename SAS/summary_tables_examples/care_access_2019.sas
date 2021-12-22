/*****************************************************************************/
/* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
/*
/* Accessibility and quality of care: Access to Care, 2019
/*
/* Did not receive treatment because couldn't afford it
/*  - Number/percent of people
/*  - By poverty status
/*
/* Input file: C:/MEPS/h216.sas7bdat (2019 full-year consolidated)
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

data h216;
	set "C:/MEPS/h216.sas7bdat";
run;


/* Define variables **********************************************************/

data MEPS;
  	SET h216;

/* Didn't receive care because couldn't afford it       */
	afford_MD = (AFRDCA42 = 1); /* medical care         */
    afford_DN = (AFRDDN42 = 1); /* dental care          */
    afford_PM = (AFRDPM42 = 1); /* prescribed medicines */
    afford_ANY = (afford_MD | afford_DN | afford_PM); /* any care */

 /* Define domain and adjust weights so SAS doesn't drop observations       */
 /*  - includes persons eligible to receive the 'access to care' supplement */

	domain = (ACCELI42 = 1);
	if domain = 0 and PERWT19F = 0 then PERWT19F = 1;

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
	tables  AFRDCA42*afford_MD
			AFRDDN42*afford_DN
			AFRDPM42*afford_PM
			afford_MD*afford_DN*afford_PM*afford_ANY / list;																	
run;


/* Calculate estimates using survey procedures *******************************/

/* Did not receive treatment because of cost, by poverty status */
/*  sum  = Number of people    			                        */
/* 	mean = Percent of people                                    */

proc surveymeans data = MEPS missing sum mean;
	FORMAT POVCAT19 poverty.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT19F;
	DOMAIN domain('1')*POVCAT19;
	var afford_ANY afford_MD afford_DN afford_PM;
run;