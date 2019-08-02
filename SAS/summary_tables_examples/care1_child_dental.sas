/*****************************************************************************/
/* Accessibility and quality of care, 2016
/*
/* Children with dental care
/*
/* Example SAS code to replicate number and percentage of children with dental
/*  care, by poverty status
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

FILENAME h192 "C:\MEPS\h192.ssp";
proc xcopy in = h192 out = WORK IMPORT;
run;

/* Define variables **********************************************************/
/*  - For 1996-2007, AGELAST must be created from AGEyyX, AGE42X, AGE31X     */
/*  - For 1996, use 'POVCAT' instead of 'POVCAT96'                           */

data MEPS;
  	SET h192;
 
 /* Children receiving dental care */
	child_2to17 = (1 < AGELAST & AGELAST < 18)*1;
	child_dental = ((DVTOT16 > 0) & (child_2to17 = 1))*1;
run;

proc format;
  value child_dental
	  1 = "One or more dental visits"
	  0 = "No dental visits in past year";

  value POVCAT
	  1 = "Negative or poor"
	  2 = "Near-poor"
	  3 = "Low income"
	  4 = "Middle income"
	  5 = "High income";
run;

/* Calculate estimates using survey procedures *******************************/

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT child_dental child_dental. POVCAT16 POVCAT.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	TABLES child_2to17*POVCAT16*child_dental / row;
run;

proc print data = out noobs label;
	where child_2to17 = 1 and child_dental ne . and POVCAT16 ne .;
	var child_dental POVCAT16 WgtFreq StdDev RowPercent RowStdErr;
run;
