/*****************************************************************************/
/* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
/*
/* Use, expenditures, and population, 2019
/*
/* Expenditures by event type and source of payment (SOP)
/*  - Mean expenditure per person
/*
/* Selected event types:
/*  - All event types (TOT)
/*  - Emergency room visits (ERT)
/*  - Inpatient stays (IPT)
/*
/* Input file: C:\MEPS\h216.sas7bdat (2019 full-year consolidated)
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

libname mylib "C:\MEPS";

data inFYC;
	set mylib.h216;
run;


/* Aggregate payment sources *************************************************/
/*
/*  Notes:
/*   - For 1996-1999: TRICARE label is CHM (changed to TRI in 2000)
/*
/*   - For 1996-2006: combined facility + SBD variables for hospital-type events
/*      are not on PUF
/*
/*   - Starting in 2019, 'Other public' (OPU) and 'Other private' (OPR) are  
/*      dropped from the files 
/*
/*
/*  OTZ = other federal (OFD)  + State/local (STL) + 
/*         other unclassified sources (OSR) +
/*         worker's comp (WCP) + Veteran's (VA)                             */

data FYC;
	set inFYC;

	/* All event types */
    TOTOTZ = TOTOFD19 + TOTSTL19 + TOTOSR19 + TOTWCP19 + TOTVA19;
    
 	/* Emergency room visits (facility + SBD expenses) */
    ERTOTZ = ERTOFD19 + ERTSTL19 + ERTOSR19 + ERTWCP19 + ERTVA19;

  	/* Inpatient stays (facility + SBD expenses) */
    IPTOTZ = IPTOFD19 + IPTSTL19 + IPTOSR19 + IPTWCP19 + IPTVA19;

run;

proc format;
	value $event
		"TOT" = "Any event"
		"ERT" = "Emergency room visits"
		"IPT" = "Inpatient stays";

	value $sop
		"EXP" = "Any source" 
		"SLF" = "Out-of-pocket"
		"PTR" = "Private"
		"MCR" = "Medicare"
		"MCD" = "Medicaid"
		"OTZ" = "Other";
run;

/* Calculate estimates using survey procedures *******************************/

ods output Statistics = out;
proc surveymeans data = FYC mean missing nobs;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT19F;
	VAR TOTEXP19 TOTSLF19 TOTPTR19 TOTMCR19 TOTMCD19 TOTOTZ /* Any event type  */
		ERTEXP19 ERTSLF19 ERTPTR19 ERTMCR19 ERTMCD19 ERTOTZ /* ER visits       */
		IPTEXP19 IPTSLF19 IPTPTR19 IPTMCR19 IPTMCD19 IPTOTZ /* Inpatient stays */
	;
run;


/* Format output */
data out;
	set out;
	event = substr(VarName, 1, 3);
	SOP = substr(VarName, 4, 3);
run;


/* Mean expenditure per person, by event type and source of payment */
proc print data = out noobs label;
	format event $event. sop $sop.;
	label Mean = "Mean expenditure per person";
	var event SOP Mean StdErr;
run;
