/*****************************************************************************/
/* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
/*
/* Use, expenditures, and population, 2016
/*
/* Expenditures by event type and source of payment (SOP)
/*  - Total expenditures
/*  - Mean expenditure per person
/*  - Mean out-of-pocket (SLF) payment per person with an out-of-pocket expense
/*
/* Selected event types:
/*  - Office-based medical visits (OBV)
/*  - Office-based physician visits (OBD)
/*  - Outpatient visits (OPT)
/*  - Outpatient physician visits (OPV)
/*
/* Input file: C:\MEPS\h192.ssp (2016 full-year consolidated)
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

FILENAME h192 "C:\MEPS\h192.ssp";
proc xcopy in = h192 out = WORK IMPORT;
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
/*  PTR = Private (PRV) + TRICARE (TRI)
/*
/*  OTZ = other federal (OFD)  + State/local (STL) + other private (OPR) +
/*         other public (OPU)  + other unclassified sources (OSR) +
/*         worker's comp (WCP) + Veteran's (VA)                            */

data FYC;
	set h192;

	/* office-based visits */
	OBVPTR = OBVPRV16 + OBVTRI16;
	OBVOTZ = OBVOFD16 + OBVSTL16 + OBVOPR16 + OBVOPU16 + OBVOSR16 + OBVWCP16 + OBVVA16;

	/* office-based physician visits */
	OBDPTR = OBDPRV16 + OBDTRI16;
	OBDOTZ = OBDOFD16 + OBDSTL16 + OBDOPR16 + OBDOPU16 + OBDOSR16 + OBDWCP16 + OBDVA16;

	/* outpatient visits (facility + SBD expenses) */
	/*  - For 1996-2006: combined facility + SBD variables are not on PUF */
	OPTPTR = OPTPRV16 + OPTTRI16;
	OPTOTZ = OPTOFD16 + OPTSTL16 + OPTOPR16 + OPTOPU16 + OPTOSR16 + OPTWCP16 + OPTVA16;

	/* outpatient physician visits (facility expense) */
	OPVPTR = OPVPRV16 + OPVTRI16;
	OPVOTZ = OPVOFD16 + OPVSTL16 + OPVOPR16 + OPVOPU16 + OPVOSR16 + OPVWCP16 + OPVVA16;

	/* outpatient physician visits (SBD expense) */
	OPSPTR = OPSPRV16 + OPSTRI16;
	OPSOTZ = OPSOFD16 + OPSSTL16 + OPSOPR16 + OPSOPU16 + OPSOSR16 + OPSWCP16 + OPSVA16;

	/* Combine facility and SBD expenses for hospital-type events ************/
	/*  Note: for 1996-2006, also need to create OPT*** = OPF*** + OPD***    */
    OPpSLF = OPVSLF16  + OPSSLF16; * out-of-pocket payments;
    OPpMCR = OPVMCR16  + OPSMCR16; * Medicare;
    OPpMCD = OPVMCD16  + OPSMCD16; * Medicaid;
    OPpPTR = OPVPTR    + OPSPTR;   * private insurance (including TRICARE);
    OPpOTZ = OPVOTZ    + OPSOTZ;   * other sources of payment;

	/* Define domains for persons with out-of-pocket expense *****************/
	has_OBVSLF = (OBVSLF16 > 0);
	has_OBDSLF = (OBDSLF16 > 0);
	has_OPTSLF = (OPTSLF16 > 0);
	has_OPpSLF = (OPpSLF > 0);

run;

proc format;
	value $event
		"OBV" = "Office-based visits"
		"OBD" = "Office-based physician visits"
		"OPT" = "Outpatient visits"
		"OPp" = "Outpatient physician visits";

	value $sop
		"SLF" = "Out-of-pocket"
		"PTR" = "Private"
		"MCR" = "Medicare"
		"MCD" = "Medicaid"
		"OTZ" = "Other";
run;

/* Calculate estimates using survey procedures *******************************/

ods output Statistics = out;
proc surveymeans data = FYC sum mean missing nobs;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	VAR OBVSLF16 OBVPTR OBVMCR16 OBVMCD16 OBVOTZ /* office-based visits       */
	  	OBDSLF16 OBDPTR OBDMCR16 OBDMCD16 OBDOTZ /* office-based phys. visits */

		OPTSLF16 OPTPTR OPTMCR16 OPTMCD16 OPTOTZ /* outpatient visits       */
		OPpSLF   OPpPTR OPpMCR   OPpMCD   OPpOTZ /* outpatient phys. visits */
	;
run;

/* Format output */
data out;
	set out;
	event = substr(VarName, 1, 3);
	SOP = substr(VarName, 4, 3);
run;

/* Total expenditures and mean exp per person, by event type and source of payment */
proc print data = out noobs label;
	format event $event. sop $sop.;
	label Sum = "Total expenditures" Mean = "Mean expenditure per person";
	var event SOP Sum StdDev Mean StdErr;
run;


/* Mean expenditure per person with expense                                */
/*  - Mean out-of-pocket expense per person with an out-of-pocket expense  */

title "office-based visits";
proc surveymeans data = FYC mean;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_OBVSLF('1');
	VAR OBVSLF16;
run;

title "office-based phys. visits";
proc surveymeans data = FYC mean;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_OBDSLF('1');
	VAR OBDSLF16;
run;

title "outpatient visits";
proc surveymeans data = FYC mean;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_OPTSLF('1');
	VAR OPTSLF16;
run;

title "outpatient phys. visits";
proc surveymeans data = FYC mean;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_OPpSLF('1');
	VAR OPpSLF;
run;
