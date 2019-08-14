/*****************************************************************************/
/* Use, expenditures, and population
/*
/* Expenditures by event type and source of payment (SOP)
/*
/* Example SAS code to replicate the following estimates in the MEPS-HC summary
/*  tables, by source of payment (SOP), for selected event types:
/*  - total expenditures
/*  - mean expenditure per person
/*  - mean out-of-pocket (SLF) payment per person with a SLF payment
/*
/* Selected event types:
/*  - Office-based medical visits (OBV)
/*  - Office-based physician visits (OBD)
/*  - Outpatient visits (OPT)
/*  - Outpatient physician visits (OPV)
/*
/* Sources of payment (SOPs):
/*  - Out-of-pocket (SLF)
/*  - Medicare (MCR)
/*  - Medicaid (MCD)
/*  - Private insurance, including TRICARE (PTR)
/*  - Other (OTH)
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/

FILENAME h192 "C:\MEPS\h192.ssp";
proc xcopy in = h192 out = WORK IMPORT;
run;


/* Aggregate payment sources *************************************************/
/*  1996-1999: TRICARE label is CHM (changed to TRI in 2000)
/*
/*  PTR = Private (PRV) + TRICARE (TRI)
/*  OTZ = other federal (OFD)  + State/local (STL) + other private (OPR) +
/*         other public (OPU)  + other unclassified sources (OSR) +
/*         worker's comp (WCP) + Veteran's (VA)                              */

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
    OPTSLF_p = OPVSLF16  + OPSSLF16; * out-of-pocket payments;
    OPTMCR_p = OPVMCR16  + OPSMCR16; * Medicare;
    OPTMCD_p = OPVMCD16  + OPSMCD16; * Medicaid;
    OPTPTR_p = OPVPTR    + OPSPTR;   * private insurance (including TRICARE);
    OPTOTZ_p = OPVOTZ    + OPSOTZ;   * other sources of payment;

	/* Define domains for persons with out-of-pocket expense *****************/
	has_OBVSLF = (OBVSLF16 > 0);
	has_OBDSLF = (OBDSLF16 > 0);
	has_OPTSLF = (OPTSLF16 > 0);
	has_OPTSLF_p = (OPTSLF_p > 0);

run;

proc format;
	value $event
		"OB" = "Office-based visits"
		"OP" = "Outpatient visits";

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
	VAR OBVSLF16 OBVPTR OBVMCR16 OBVMCD16 OBVOTZ /* office-based visits */
	  	OBDSLF16 OBDPTR OBDMCR16 OBDMCD16 OBDOTZ /* office-based phys. visits */

		OPTSLF16 OPTPTR   OPTMCR16 OPTMCD16 OPTOTZ   /* OP visits */
		OPTSLF_p OPTPTR_p OPTMCR_p OPTMCD_p OPTOTZ_p /* OP phys. visits */
	;
run;

/* Format output */
data out;
	set out;
	event = substr(VarName, 1, 2);
	SOP = substr(VarName, 4, 3);
	phys = (substr(VarName, 1, 3) = "OBD" or substr(VarName, 8, 1) = "p");
run;

/* Total expenditures and mean exp per person */
proc print data = out noobs label;
	format event $event. sop $sop.;
	label Sum = "Total expenditures" Mean = "Mean expenditure per person";
	var event SOP phys Sum StdDev Mean StdErr;
run;


/* Mean out-of-pocket expense per person with an out-of-pocket expense */

title "office-based visits";
proc surveymeans data = FYC mean;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_OBVSLF;
	VAR OBVSLF16;
run;

title "office-based phys. visits";
proc surveymeans data = FYC mean;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_OBdSLF;
	VAR OBDSLF16;
run;

title "outpatient visits";
proc surveymeans data = FYC mean;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_OPTSLF;
	VAR OPTSLF16;
run;

title "outpatient phys. visits";
proc surveymeans data = FYC mean;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_OPTSLF_p;
	VAR OPTSLF_p;
run;
