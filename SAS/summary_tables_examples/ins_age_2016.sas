/*****************************************************************************/
/* Health insurance
/*
/* Example SAS code to replicate number and percentage of people by insurance
/*  coverage and age groups
/*
/* Input file: C:\MEPS\h192.ssp (2016 full-year consolidated)
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

FILENAME h192 "C:\MEPS\h192.ssp";
proc xcopy in = h192 out = WORK IMPORT;
run;

/* Define variables **********************************************************/
/*  - For 1996-2007, AGELAST must be created from AGEyyX, AGE42X, AGE31X     */
/*  - For 1996-2011, create INSURC from INSCOV and 'EV' variables
/*     (for 1996, use 'EVER' vars):
/*
/*     public   = (MCDEV16 = 1) or (OPAEV16=1) or (OPBEV16=1);
/*     medicare = (MCREV16 = 1);
/*     private  = (INSCOV16 = 1);
/*
/*     mcr_priv = (medicare and  private);
/*     mcr_pub  = (medicare and ~private and public);
/*     mcr_only = (medicare and ~private and ~public);
/*     no_mcr   = (~medicare);
/*
/*     ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;
/*     if AGELAST < 65 then INSURC16 = INSCOV16;
/*      else INSURC16 = ins_gt65;                                            */

proc format;
	value agegrps
	    low-4 = "Under 5"
	    5-17  = "5-17"
	    18-44 = "18-44"
	    45-64 = "45-64"
	    65-high = "65+";

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
proc surveyfreq data = h192 missing;
	FORMAT AGELAST agegrps. INSURC16 insurance.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	TABLES AGELAST*INSURC16 / row;
run;

proc print data = out noobs label;
	where Frequency > 0 and AGELAST ne . and INSURC16 ne .;
	var AGELAST INSURC16 WgtFreq StdDev Row: ;
run;
