/*****************************************************************************/
/* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
/*
/* Use, expenditures, and population, 2016
/*
/* Utilization and expenditures by event type and source of payment (SOP)
/*  - Total number of events
/*  - Mean expenditure per event, by source of payment
/*  - Mean events per person, for office-based visits
/*
/* Selected event types:
/*  - Office-based medical visits (OBV)
/*  - Office-based physician visits (OBD)
/*  - Outpatient visits (OPT)
/*  - Outpatient physician visits (OPV)
/*
/* Input files:
/*	- C:\MEPS\h192.ssp (2016 full-year consolidated)
/* 	- C:\MEPS\h188f.ssp (2016 OP event file)
/* 	- C:\MEPS\h188g.ssp (2016 OB event file)
/*****************************************************************************/

ods graphics off;

/* Load datasets *************************************************************/

/* Macro to import data from .ssp files */
%macro load(file);
	FILENAME &file. "C:\MEPS\&file..ssp";
	proc xcopy in = &file. out = WORK IMPORT;
	run;
%mend;

%load(h192);  /* FYC file      */
%load(h188f); /* OP event file */
%load(h188g); /* OB event file */


/* Aggregate payment sources for each dataset *********************************/
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
/*  PR = Private (PV) + TRICARE (TR)
/*
/*  OZ = other federal (OF)  + State/local (SL) + other private (OR) +
/*        other public (OU)  + other unclassified sources (OT) +
/*        worker's comp (WC) + Veteran's (VA)                                */

data OB;
	set h188g;
	if OBXP16X >= 0; /* Remove inapplicable events */

  	PR = OBPV16X + OBTR16X;
    OZ = OBOF16X + OBSL16X + OBVA16X + OBOT16X + OBOR16X + OBOU16X + OBWC16X;

	count = 1; * add counter for event totals;
	phys_count = (SEEDOC = 1);
run;

data OP;
	set h188f;
	if OPXP16X >= 0; /* Remove inapplicable events */

  	PR_fac = OPFPV16X + OPFTR16X;
    PR_sbd = OPDPV16X + OPDTR16X;

    OZ_fac = OPFOF16X + OPFSL16X + OPFOR16X + OPFOU16X + OPFVA16X + OPFOT16X + OPFWC16X;
    OZ_sbd = OPDOF16X + OPDSL16X + OPDOR16X + OPDOU16X + OPDVA16X + OPDOT16X + OPDWC16X;

	/* Combine facility and SBD expenses for hospital-type events */
	SF = OPFSF16X + OPDSF16X; * out-of-pocket payments;
    MR = OPFMR16X + OPDMR16X; * Medicare;
    MD = OPFMD16X + OPDMD16X; * Medicaid;
    PR = PR_fac + PR_sbd;     * private insurance (including TRICARE);
    OZ = OZ_fac + OZ_sbd;     * other sources of payment;

	count = 1; * add counter for event totals;
run;


/* Merge with FYC to retain all PSUs *****************************************/
proc sort data = h192 (keep = DUPERSID VARSTR VARPSU PERWT16F) out = FYC; 
	by DUPERSID; 
run;

proc sort data = OB (drop = VARSTR VARPSU PERWT16F); by DUPERSID; run;
proc sort data = OP (drop = VARSTR VARPSU PERWT16F); by DUPERSID; run;

data OB_FYC;
	merge OB FYC;
	by DUPERSID;
run;

data OP_FYC;
	merge OP FYC;
	by DUPERSID;
run;


/* Calculate estimates using survey procedures *******************************/
/*
/* Sources of payment (SOP) abbreviations:
/*  - SF: Out-of-pocket
/*  - PR: Private insurance, including TRICARE (PTR)
/*  - MR: Medicare 
/*  - MD: Medicaid
/*  - OZ: Other 

/* Office-based visits: Total number of events and Mean expenditure per event ******/
ods output Statistics = OB_out Domain = OB_domain_out ;
proc surveymeans data = OB_FYC sum mean missing;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN SEEDOC;
	var count OBSF16X PR OBMR16X OBMD16X OZ;
run;

title "Office-based visits";
proc print data = OB_out noobs label;
	label Sum = "Total number of events";
	where VarName = "count";
	var Sum StdDev;
run;
proc print data = OB_out noobs label;
	label Mean = "Mean expenditure per event" VarName = "Source of Payment";
	where VarName ne "count";
	var VarName Mean StdErr;
run;

title "Office-based physician visits";
proc print data = OB_domain_out noobs label;
	label Sum = "Total number of events";
	where SEEDOC = 1 and VarName = "count";
	var Sum StdDev;
run;
proc print data = OB_domain_out noobs label;
	label Mean = "Mean expenditure per event" VarName = "Source of Payment";
	where SEEDOC = 1 and VarName ne "count";
	var VarName Mean StdErr;
run;



/* Outpatient visits: Number of events and Mean expenditure per event ********/
ods output Statistics = OP_out Domain = OP_domain_out ;
proc surveymeans data = OP_FYC sum mean missing;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN SEEDOC;
	var count SF PR MR MD OZ;
run;

title "Outpatient visits";
proc print data = OP_out noobs label;
	label Sum = "Total number of events";
	where VarName = "count";
	var Sum StdDev;
run;
proc print data = OP_out noobs label;
	label Mean = "Mean expenditure per event" VarName = "Source of Payment";
	where VarName ne "count";
	var VarName Mean StdErr;
run;

title "Outpatient physician visits";
proc print data = OP_domain_out noobs label;
	label Sum = "Total number of events";
	where SEEDOC = 1 and VarName = "count";
	var Sum StdDev;
run;
proc print data = OP_domain_out noobs label;
	label Mean = "Mean expenditure per event" VarName = "Source of Payment";
	where SEEDOC = 1 and VarName ne "count";
	var VarName Mean StdErr;
run;


/* Mean events per person, office-based medical visits ***********************/

/* Aggregate to person-level */
	proc means data = OB_FYC noprint;
		by DUPERSID VARSTR VARPSU;
		var count phys_count PERWT16F;
		output out = pers_OB
			sum  = n_events n_phys_events
			mean = m_events m_phys PERWT16F;
	run;

	data pers_OB;
		set pers_OB;
		if n_events = . then n_events = 0;
		if n_phys_events = . then n_phys_events = 0;
	run;

/* Mean events per person */
	ods html close; ods html;
	proc surveymeans data = pers_OB sum mean missing;
		STRATA VARSTR;
		CLUSTER VARPSU;
		WEIGHT PERWT16F;
		var n_events n_phys_events;
	run;
