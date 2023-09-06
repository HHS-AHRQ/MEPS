/*****************************************************************************
Example code linking MEPS-HC Medical Conditions file to the Office-based
 medical visits file, data year 2020:

Event-level estimates:
  - Number of office-based visits for mental health
  - Total expenditures for office-based mental health treatment
  - Mean expenditure per office-based mental health visit

Person-level estimates 
  - Number of people with office-based mental health visits
  - Percent of people with office-based mental health visits
  - Mean expenditure per person for office-based mental health visits
  

Input files:
  - h220g.sas7bdat   (2020 Office-based event file)
  - h222.sas7bdat    (2020 Conditions file)
  - h220if1.sas7bdat (2020 CLNK: Condition-event link file)
  - h224.sas7bdat    (2020 Full-Year Consolidated file)
 
Resources:
 - CCSR codes: 
	 	https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv

 - MEPS-HC Public Use Files: 
		https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp

 - MEPS-HC data tools: 
		https://datatools.ahrq.gov/meps-hc

/*****************************************************************************/

ods graphics off;


/* Load datasets *************************************************************/
/*  First, download .sas7bdat data sets from MEPS website:                   */
/*   -> https://meps.ahrq.gov > Data Files                                   */

libname mylib "C:\MEPS";

data ob20;   set mylib.h220g;   run; /* Office-based medical visits  */
data cond20; set mylib.h222;    run; /* Medical conditions           */
data clnk20; set mylib.h220if1; run; /* Condition-event linkage file */
data fyc20;  set mylib.h224;    run; /* Person-level full-year file  */


/* Preview files */
title "Office-based visits";  proc print data = ob20   (obs=5); run;
title "Conditions";           proc print data = cond20 (obs=5); run;
title "Condition-event link"; proc print data = clnk20 (obs=5); run;

/* Keep only needed variables ************************************************/
/*  Browse variables using MEPS-HC data tools variable explorer: 
/*   -> http://datatools.ahrq.gov/meps-hc#varExp                  */ 

data ob20x;
	set ob20;
	keep PANEL DUPERSID EVNTIDX EVENTRN OBDATE:
		 TELE: OBXP20X PERWT20F VARSTR VARPSU;
run;

data cond20x; 
	set cond20;
	keep DUPERSID CONDIDX ICD10: CCSR:;
run;

data fyc20x;
	set fyc20;
	keep DUPERSID PERWT20F VARSTR VARPSU; 
run;


/* Filter COND file to only people with Mental Disorders ********************/
/*  >> GitHub: https://github.com/HHS-AHRQ/MEPS 
/* 		> Quick_Reference_Guides 
/* 		> meps_ccsr_conditions.csv                                          */

data cond20x;
	set cond20x;
	all_CCSR = CAT(CCSR1X, CCSR2X, CCSR3X);
run;


data mental_health;
	set cond20x;
	where all_CCSR contains "MBD" or 
		all_CCSR contains "FAC002" or
		all_CCSR contains "FAC007" or
		all_CCSR contains "NVS011" or
		all_CCSR contains "SYM008" or
		all_CCSR contains "SYM009";
run; 

title "Mental health conditions";
proc freq data = mental_health;
	tables ICD10CDX*CCSR1X*CCSR2X*CCSR3X / list missing;
run;


/* Filter CLNK file to only office-based visits ****************************/
/*  >> Data Tools: https://datatools.ahrq.gov/meps-hc#varExp 
/*
/*  >> EVENTYPE:
 	  1 = "Office-based"
 	  2 = "Outpatient" 
 	  3 = "Emergency room"
 	  4 = "Inpatient stay"
 	  7 = "Home health"
 	  8 = "Prescribed medicine"                                            */

data clnk_ob; 
	set clnk20;
	if EVENTYPE = 1;
run;

title "CLNK Office-based visits only";
proc freq data = clnk_ob;
	tables EVENTYPE / list missing;
run;


/* Merge datasets **********************************************************/

/* Merge conditions file with the conditions-event link file (CLNK) */
proc sort data = mental_health; by DUPERSID CONDIDX; run;
proc sort data = clnk_ob;       by DUPERSID CONDIDX; run;

data mh_clnk;
	merge mental_health (in = a) clnk_ob (in = b);
	by DUPERSID CONDIDX;
	if a and b;
run;


title "Example of one condition treated in different events";
proc print data = mh_clnk;
	where CONDIDX = "2320109103009";
run;

title "Example of one event treating multiple Mental Health conditions";
proc print data = mh_clnk;
	where EVNTIDX = "2320051101205101";
run;


/* De-duplicate by event ID ('EVNTIDX'), since someone can have multiple visits 
/* for Mental Health. We don't want to count the same event twice */
proc sort data = mh_clnk (keep = DUPERSID EVNTIDX EVENTYPE) 
	out = mh_clnk_nodup nodupkey; 
	by DUPERSID EVNTIDX EVENTYPE; 
run;



/* Merge on event files *****************************************************/
ods html close; ods html;
title "mh_clnk"; proc print data = mh_clnk_nodup (obs=5); run;
title "ob20x";   proc print data = ob20x (obs=5); run;

proc sort data = ob20x; by DUPERSID EVNTIDX; run;
data ob_mental_health;
	merge mh_clnk_nodup (in = a) ob20x (in = b);
	by DUPERSID EVNTIDX;
	if a and b;
	mh_ob_visit = 1; * set indicator variable for all visits to help with counting later;
run;


/* QC */
title "ob_mental_health";
proc print data = ob_mental_health (obs=5); run;
proc freq data = ob_mental_health;
	tables EVENTYPE*mh_ob_visit / list missing; 
	* should be EVENTYPE = 1 for all rows ;
	* should be mh_ob_visit = 1 for all rows;
run;


/* DO NOT RUN */
/* Survey estimates? Not quite! Need to merge with FYC file first,
/* to get complete Strata (VARSTR) and PSUs (VARPSU) for entire MEPS sample */

/* THIS CODE IS INCLUDED AS AN EXAMPLE OF WHAT NOT TO DO
/* THIS WILL GIVE WRONG SEs:

title "SEs are WRONG!";
proc surveymeans data = ob_mental_health mean sum;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT20F;
	var mh_ob_visit OBXP20X;
run;

/* END DO NOT RUN */



/* Merge on FYC file for complete Strata, PSUs *****************************/

proc sort data = ob_mental_health; by DUPERSID; run;
proc sort data = fyc20x; by DUPERSID; run;

data ob_mh_fyc;
	merge ob_mental_health (in = a) fyc20x (in = b);
	by DUPERSID;
	if a then mh_ob = 1;
	if b then fyc = 1;
run;

/* QC */
title "ob_mh_fyc";
proc freq data = ob_mh_fyc;
	tables mh_ob*mh_ob_visit*fyc / list missing;
run;

/* Reset missing indicators to 0 */
data ob_mh_fyc;
	set ob_mh_fyc;
	if mh_ob = .       then mh_ob = 0;
    if mh_ob_visit = . then mh_ob_visit = 0;
run;

proc freq data = ob_mh_fyc;
	tables mh_ob*mh_ob_visit / list missing;
run;

proc print data = ob_mh_fyc (obs=5); where mh_ob = 0; run;
proc print data = ob_mh_fyc (obs=5); where mh_ob = 1; run;


/* Event-level estimates *********************************************************************/
/*  - Number of office-based visits for mental health:       343,810,085 (SE: 22,252,863)
/*  - Total exp. for office-based mental health visits:  $60,209,392,314 (SE: 4,437,433,004)
/*  - Mean exp. per visit:                                       $175.12 (SE: 6.46)          */

title "SEs are STILL WRONG for total exp!";
title2 "What is SAS doing?!?  Hint: Check the Log";
proc surveymeans data = ob_mh_fyc mean sum;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT20F;
	var mh_ob_visit OBXP20X;
run;

title "Event-level estimates";
title2 "EUREKA!";
proc surveymeans data = ob_mh_fyc mean sum;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT20F;
	var mh_ob_visit OBXP20X;
	domain mh_ob; * need domain so SAS treats the lonely PSU correctly;
run;


/* A note on Telehealth *******************************************************/
/*  - telehealth questions were added to the survey in Fall of 2020           */
/*  - TELEHEALTHFLAG = -15 for events reported before telehealth questions    */
/*  - Recommendation: imputation or sensitivity analysis                      */

ods html close; ods html;
title "Telehealth flag by Month";
title2 "All office-based visits";
proc freq data = ob20;
	tables OBDATEMM*TELEHEALTHFLAG / norow nocol nopercent;
run;



/* Person-level estimates ****************************************************
/*  - Number of people with office visit for MH:  29,816,984 (SE: 1,192,676)
/*  - Percent of people with office visit for MH:      9.08% (SE: 0.29%)
/*  - Mean exp per person for office visits for MH: $2019.30 (SE: 126.16) 
/* 
/*  - Number of visits (QC)       343,810,085 (SE: 22,252,863)
/*  - Total exp. (QC)         $60,209,392,314 (SE: 4,437,433,004)
*/


/* Aggregate to person-level */

ods html close; ods html;
title "ob_mh_fyc"; 
proc print data = ob_mh_fyc (obs=5); 
	where mh_ob = 1; 
run;

proc sort data = ob_mh_fyc; by DUPERSID VARSTR VARPSU; run;
proc means data = ob_mh_fyc noprint;
	by DUPERSID VARSTR VARPSU;
	var OBXP20X mh_ob_visit mh_ob;
	output out = pers_mh
		mean(PERWT20F)    = PERWT20F 
		sum(OBXP20X)      = persXP
		sum(mh_ob_visit)  = pers_nevents
		mean(mh_ob_visit) = mh_ob_visit_pers
		mean(mh_ob)       = mh_ob_pers;
run;

/* QC: ***********************************************/

	/* - same number of records as fyc file              */
	title "pers_mh vs. fyc";
	proc freq data = pers_mh; tables mh_ob_pers / list missing; run;
	proc freq data = fyc20;  tables PANEL / list missing; run;

	/*  - mh_pers and mh_ob_visit_pers = 1  OR           */
	/*  - mh_pers and mh_ob_visit_pers = 0               */
	title "pers_mh QC";
	proc freq data = pers_mh;
		tables mh_ob_pers*mh_ob_visit_pers / list missing;
	run;

	/*  - pers_nevents = 0 when mh or mh_ob_visit = 0    */
	title "pers_mh QC";
	proc freq data = pers_mh;
		where mh_ob_pers = 0 or mh_ob_visit_pers = 0;
		tables pers_nevents / list missing;
	run;

	/* view person with several events */
	ods html close; ods html;
	title "ob_mh_fyc"; proc print data = ob_mh_fyc; where DUPERSID = "2320109103"; run;
	title "pers_mh";   proc print data = pers_mh;   where DUPERSID = "2320109103"; run;

	/* view person with 0 events */
	title "ob_mh_fyc"; proc print data = ob_mh_fyc; where DUPERSID = "2320005101"; run;
	title "pers_mh";   proc print data = pers_mh;   where DUPERSID = "2320005101"; run;


/* Run person-level estimates ************************/

title "Person-level estimates";
proc surveymeans data = pers_mh mean sum;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT20F;
	var mh_ob_visit_pers  /* Number of ppl (sum), percent of ppl (mean)           */
		persXP            /* Total (sum) and Mean exp per person with OB MH visit */
		pers_nevents ;    /* Number of OB MH visits (QC)                          */
	domain mh_ob_pers;
run;



