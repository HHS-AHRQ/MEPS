/* ----------------------------------------------------------------------------------------------------------------

MEPS-HC: Prescribed medicine utilization and expenditures for the treatment of hyperlipidemia

This example code shows how to link the MEPS-HC Medical Conditions file to the Prescribed Medicines file for data year 
2020 in order to estimate the following:

National totals:
   - Total number of people w/ at least one PMED fill for hyperlipidemia (HL)
   - Total PMED fills for HL
   - Total PMED expenditures for HL 

Per-person averages among people with at least one PMED fill for HL:
   - Avg PMED fills for HL, by sex and poverty (POVCAT20)
   - Avg PMED expenditures for HL, by sex and poverty (POVCAT20)

Input files:
  - h220a.sas7bdat        (2020 Prescribed Medicines file)
  - h222.sas7bdat         (2020 Conditions file)
  - h220if1.sas7bdat      (2020 CLNK: Condition-Event Link file)
  - h224.sas7bdat         (2020 Full-Year Consolidated file)

Resources:
  - CCSR codes: 
    https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv

  - MEPS-HC Public Use Files: 
    https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp

  - MEPS-HC online data tools: 
    https://datatools.ahrq.gov/meps-hc

---------------------------------------------------------------------------------------------------------------- */


/**** Read in data files --------------------------------------------------------------------------------------- */ 

/* Set libname for where MEPS SAS data files are saved on your computer */

libname meps 'C:\MEPS';


/* Read in PUFs and keep only needed variables */

/* PMED file (record = rx fill or refill for a person) */

data pmed20;
	set meps.h220a;
	evntidx = linkidx; /* rename LINKIDX to EVNTIDX for merging to conditions */ 
	keep dupersid drugidx rxrecidx evntidx rxdrgnam rxxp20x;
run;


/* Conditions file (record = medical condition for a person) */

data cond20;
	set meps.h222;
	keep dupersid condidx icd10cdx ccsr1x ccsr2x ccsr3x;
run;


/* Conditions-event link file (crosswalk between conditions and medical events, including PMEDs) */

data clnk20;
	set meps.h220if1;
run;


/* Full-year consolidated (person-level) file (record = MEPS sample member) */

data fyc20;
	set meps.h224;
	keep dupersid agelast sex povcat20 choldx perwt20f varpsu varstr;
run;


/**** Prepare data for estimation --------------------------------------------------------------------------------- */

/* Subset conditions file to only hyperlipidemia records (any CCSR = "END010") */

data hl;
	set cond20;  
	where ccsr1x = 'END010' or ccsr2x = 'END010' or ccsr3x = 'END010';
run; 


/* Example to show someone with 'duplicate' hyperlipidemia conditions with different CONDIDXs.  This usually happens 
when the collapsed 3-digit ICD10s are the same but the fully-specified ICD10s are different (e.g., one person has 
different condition records for both E78.1 and E78.5, which both map to END010 and collapse to E78 on the PUF). */

/* Note that in the code below, we are NOT actually de-duplicating our hl file in this step.
This code is just to identify duplicates for illustration purposes. */

proc sort data=hl nodupkey dupout=dup_hl out=temp1; /* duplicate IDs are output to dup_hl */
	by dupersid;										
run;														

proc print data=hl noobs;
	where dupersid = '2320134102'; /* using the first duplicate DUPERSID from dup_hl as an example */ 
run;


/* Get EVNTIDX values for hyperlipidemia records from CLNK file */
/* Remember that our hl file still contains duplicates! */ 

proc sort data=hl;
	by dupersid condidx;
run;

proc sort data=clnk20;
	by dupersid condidx;
run;

data clnk_hl;
	merge hl (in=A) clnk20 (in=B);
	by dupersid condidx;
	if A and B; /* only output records that are in both files */ 
run;


/* Revisit duplicate example after merging to CLNK. Note that two 'duplicate' HL conditions (CONDIDX ending in 0004 and 
0006) BOTH linked to the same PMED event (ENVTIDX ending in 3703). For example, someone may have linked BOTH their high
triglycerides AND their high cholesterol to the same PMED record. */

proc print data=clnk_hl noobs;
	where dupersid = '2320134102'; 
run;


/* De-duplicate clnk_hl by EVNTIDX because we don't want to double-count the same PMEDs for our 'duplicate'
hyperlipidemia records */

proc sort data=clnk_hl nodupkey out=clnk_hl_dedup;
	by dupersid evntidx;
run;


/* Revisit duplicate example after de-duplicating */

proc print data=clnk_hl_dedup noobs;
	where dupersid = '2320134102'; 
run;


/* Look at our data to see different event types */

proc freq data=clnk_hl_dedup;
	tables eventype;
run;


/* Sort pmed20 data to prepare for merge */

proc sort data=pmed20;
	by dupersid evntidx;
run;


/* Get PMED events (and NOT other event types) linked to hyperlipidemia */
/* Our hl_merged data file is now at the PMED FILL level */ 

data hl_merged;
	merge clnk_hl_dedup (in=a) pmed20 (in=b);
	by dupersid evntidx;
	if a and b;  /* only keep records in both files */ 
run;


/* QC: Make sure all events have EVNTYPE = 8 (for PMED event) */ 

proc freq data=hl_merged;
	tables eventype;
run;


/* QC: Look at top PMEDs (by unweighted # fills) for hyperlipidemia to see if they make sense */

proc freq data=hl_merged order=freq;
	tables rxdrgnam / nocum maxlevels=10;
run;


/* Create dummy variable for each unique fill (this will be summed within each person to get total fills per person) */

data hl_merged;
	set hl_merged;
	hl_fill = 1;
run;


/* Roll up to person level by summing number of fills and pmed expenditures linked to hyperlipidemia within each person */

proc means data=hl_merged noprint nway sum;
	class dupersid;  /* within each person */
	var hl_fill rxxp20x;  /* summing number of fills and pmed expenditures */ 
	output out=drugs_by_pers (drop = _TYPE_ _FREQ_) sum=n_hl_fills hl_drug_exp; /* variable names for our sums */
run;


/* Merge person-level totals back to FYC and create flag for whether a person has any pmed fills for hyperlipidemia */

data fyc_hl;
	merge fyc20 (in=A) drugs_by_pers;
	by dupersid;
	if A;  /* keep all people on the FYC because we need their VARPSU and VARSTR information for correct SEs! */ 
	if n_hl_fills > 0 then hl_pmed_flag = 1;  /* create flag for anyone who has rx fills for HL */
	else hl_pmed_flag = 0;  /* set flag to 0 for people with no rx fills for HL */ 

	/* Set system missings caused by merging to zeroes - these are true zeroes */
	if n_hl_fills = . then n_hl_fills = 0;
   	if hl_drug_exp = . then hl_drug_exp = 0; 
run;


/* QC: compare adults *ever* diagnosed with hyperlipidemia (CHOLDX = 1) with people who have PMEDs for hyperlipidemia 
in 2020 (hl_pmed_flag = 1).  */

proc freq data=fyc_hl;
	tables choldx*hl_pmed_flag;
run; 


/* QC: check counts of hl_pmed_flag=1 and compare to the number of rows in drugs_by_pers (n=3912).  
Confirm there are no missing values */

proc freq data=fyc_hl;
	tables hl_pmed_flag / missing;
run;


/* QC: There should be no records where hl_pmed_flag=0 and (hl_drug_exp > 0 or n_hl_fills > 0) */

proc print data=fyc_hl;
	where hl_pmed_flag = 0 and (hl_drug_exp > 0 or n_hl_fills > 0); 
run;


/*** ESTIMATION -------------------------------------------------------------------------------------------------- */ 

/* Optional - suppress graphics */

 ods graphics off;


/**** National Totals */

/* Estimates for the following national totals:
	- sum of hl_pmed_flag = 1 -> total people with any rx fills for HL
	- sum of n_hl_fills -> total number of rx fills for HL
	- sum of hl_drug_exp -> total rx expenditures for HL */

proc surveymeans data=fyc_hl sum; 
	stratum varstr; /* stratum */ 
	cluster varpsu; /* PSU */ 
	weight perwt20f; /* person weight */ 
	var hl_pmed_flag n_hl_fills hl_drug_exp; /* variables we want to estimate totals for */
	ods output statistics=est_totals (drop = VarLabel); /* optional - output estimates to a SAS dataset */
run;


/**** Per-person averages for people with at least one PMED fill for hyperlipidemia (hl_pmed_flag = 1), by sex
and by poverty */ 

/* Estimates for:
	- mean of n_hl_fills = avg number of fills for HL per person with any rx fills for HL
	- mean of hl_drug_exp = avg expenditures per person on rx drugs for HL among people with rx fills for HL */

proc surveymeans data=fyc_hl mean;
	stratum varstr; /* stratum */
	cluster varpsu; /* PSU */ 
	weight perwt20f; /* person weight */ 
	domain hl_pmed_flag('1') hl_pmed_flag('1')*sex hl_pmed_flag('1')*povcat20; /* subpop is people with any rx fills for HL, overall and by sex and poverty*/ 
	var n_hl_fills hl_drug_exp; /* variables to estimate means for */
	ods output domain=est_means (drop = VarLabel); /* optional - output estimates to a SAS dataset */
run;

