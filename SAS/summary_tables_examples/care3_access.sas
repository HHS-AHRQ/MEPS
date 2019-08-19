/*****************************************************************************/
/* Accessibility and quality of care, 2016
/*
/* Self-administered questionnaire (SAQ):
/*  Ability to schedule a routine appointment (adults)
/*
/* Example SAS code to replicate number and percentage of adults by their ability
/*  to schedule a routine appointment, by insurance coverage
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

FILENAME h192 "C:\MEPS\h192.ssp";
proc xcopy in = h192 out = WORK IMPORT;
run;

/* Define variables **********************************************************/
/*  - For 1996-2011, create INSURC from INSCOV and 'EV' variables
/*     (for 1996, use 'EVER' vars)                                          */

data MEPS;
  	SET h192;

 /* Define domain and adjust weights to keep all people in analysis */
	domain = (ADRTCR42 = 1 & AGELAST >= 18);
	if domain = 0 and SAQWT16F = 0 then SAQWT16F = 1;

run;

proc format;
	value freq
		 4 = "Always"
		 3 = "Usually"
		 1,2 = "Sometimes/Never"
		-7,-8,-9 = "Don't know/Non-response"
		-1 = "Inapplicable"
		. = "Missing";

	value insurance
		1 = "<65, Any private"
		2 = "<65, Public only"
		3 = "<65, Uninsured"
		4 = "65+, Medicare only"
		5 = "65+, Medicare and private"
		6 = "65+, Medicare and other public"
		7,8 = "65+, No medicare";
run;

/* Calculate estimates using survey procedures *******************************/

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT ADRTWW42 freq. INSURC16 insurance.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT SAQWT16F;
	TABLES domain*INSURC16*ADRTWW42 / row;
run;

proc print data = out noobs label;
	where domain = 1 and ADRTWW42 ne . and INSURC16 ne .;
	var ADRTWW42 INSURC16 WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
