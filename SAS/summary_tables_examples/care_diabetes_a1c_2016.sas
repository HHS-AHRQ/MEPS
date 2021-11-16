/*****************************************************************************/
/* Accessibility and quality of care, 2016
/*
/* Diabetes care survey (DCS):
/*  Adults receiving hemoglobin A1c blood test
/*
/* Example SAS code to replicate number and percentage of adults with diabetes
/*  who had a hemoglobin A1c blood test, by race/ethnicity
/*
/* Input file: C:\MEPS\h192.ssp (2016 full-year consolidated)
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

FILENAME h192 "C:\MEPS\h192.ssp";
proc xcopy in = h192 out = WORK IMPORT;
run;

/* Define variables **********************************************************/

data MEPS;
  	SET h192;

/* Define domain and adjust weights to keep all people in analysis */
	domain = (DIABW16F > 0);
	if domain = 0 then DIABW16F = 1;

 /* Race/ethnicity */
 /* 1996-2002: race/ethnicity variable based on RACETHNX (see documentation) */
 /* 2002-2011: race/ethnicity variable based on RACETHNX and RACEX:
 /*   hisp   = (RACETHNX = 1);
 /*   white  = (RACETHNX = 4 & RACEX = 1);
 /*   black  = (RACETHNX = 2);
 /*   native = (RACETHNX ge 3 and RACEX in (3,6));
 /*   asian  = (RACETHNX ge 3 and RACEX in (4,5))) */

 /* For 2012 and later, use RACETHX and RACEV1X: */
    hisp   = (RACETHX = 1);
    white  = (RACETHX = 2);
    black  = (RACETHX = 3);
    native = (RACETHX > 3 and RACEV1X in (3,6));
    asian  = (RACETHX > 3 and RACEV1X in (4,5));

	race = 1*hisp + 2*white + 3*black + 4*native + 5*asian;
run;

proc format;
	value diab_a1c
		-9,-8,-7 = "Don't know/Non-response"
		-1 = "Inapplicable"
		0,96 = "Did not have measurement"
		1-95 = "Had measurement";

	value race
		1 = "Hispanic"
		2 = "White"
		3 = "Black"
		4 = "Amer. Indian, AK Native, or mult. races"
		5 = "Asian, Hawaiian, or Pacific Islander"
		. = "Missing";
run;

/* Calculate estimates using survey procedures *******************************/

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT DSA1C53 diab_a1c. race race.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT DIABW16F;
	TABLES domain*race*DSA1C53 / row;
run;

proc print data = out noobs label;
	where domain = 1 and DSA1C53 ne . and race ne .;
	var DSA1C53 race WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
