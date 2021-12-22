/* ****************************************************************************/
/* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
/*
/* Medical Conditions, 2018:
/*  - Number of people with care
/*  - Number of events
/*  - Total expenditures
/*  - Mean expenditure per person
/*
/* Note: Starting in 2016, conditions were converted from ICD-9 and CCS codes
/*  to ICD-10 and CCSR codes 
/*
/* Input files:
/* 	- C:/MEPS/h206a.sas7bdat (2018 RX event file)
/* 	- C:/MEPS/h206d.sas7bdat (2018 IP event file)
/* 	- C:/MEPS/h206e.sas7bdat (2018 ER event file)
/* 	- C:/MEPS/h206f.sas7bdat (2018 OP event file)
/* 	- C:/MEPS/h206g.sas7bdat (2018 OB event file)
/* 	- C:/MEPS/h206h.sas7bdat (2018 HH event file)
/* 	- C:/MEPS/h206if1.sas7bdat (2018 CLNK: Condition-event link file)
/* 	- C:/MEPS/h207.sas7bdat    (2018 Conditions file)
/*****************************************************************************/

ods graphics off;


/* Load datasets *************************************************************/

libname mylib "C:\MEPS";

/* Event files */
data rx; set mylib.h206a; run;
data ip; set mylib.h206d; run;
data er; set mylib.h206e; run;
data op; set mylib.h206f; run;
data ob; set mylib.h206g; run;
data hh; set mylib.h206h; run;


/* For RX events, count number of fills per event */
proc sort data = rx; by DUPERSID LINKIDX VARSTR VARPSU PERWT18F; run;
proc means data = rx noprint;
	by DUPERSID LINKIDX VARSTR VARPSU PERWT18F;
	var RXXP18X;
	output out = rx_pers sum = XP18X n = n_fills;
run;

/* Stack event files */
data stacked_events;
	set rx_pers (in = RX rename = (LINKIDX = EVNTIDX))
		ip (in = IP rename = (IPXP18X = XP18X))
		er (in = ER rename = (ERXP18X = XP18X))
		op (in = OP rename = (OPXP18X = XP18X))
		ob (in = OB rename = (OBXP18X = XP18X))
		hh (in = HH rename = (HHXP18X = XP18X));

	if RX then data = "RX";
	else if IP then data = "IP";
	else if ER then data = "ER";
	else if OP then data = "OP";
	else if OB then data = "OB";
	else if HH then data = "HH";

	/* Count events (for RX, each fill is an event) */
	n_events = max(n_fills, 1);

	keep data EVNTIDX DUPERSID n_events XP18X VARSTR VARPSU PERWT18F;
run;

/* Load in event-condition linking file */
data clnk1; set mylib.h206if1; run;

/* Load in conditions file */
data cond_puf; set mylib.h207; run;

/* Load crosswalk for CCSR and collapsed conditions codes */
filename ccsr_url url "https://raw.githubusercontent.com/HHS-AHRQ/MEPS/master/Quick_Reference_Guides/meps_ccsr_conditions.csv";
proc import file = ccsr_url 
	out = work.condition_codes 
	dbms = csv
	replace ;
run;

data condition_codes;
	set condition_codes;
	rename CCSR_Code = CCSR MEPS_collapsed_condition_categor = Condition;
	drop CCSR_Description;
run;


/* Merge datasets *************************************************************/

/* Merge conditions file with the conditions-event link file (CLNK) */
proc sort data = clnk1    (keep = DUPERSID CONDIDX EVNTIDX); by DUPERSID CONDIDX; run;
proc sort data = cond_puf (keep = DUPERSID CONDIDX CCSR:); by DUPERSID CONDIDX; run;

data cond_clink;
	merge clnk1 cond_puf;
	by DUPERSID CONDIDX;
run;


/* Convert multiple CCSRs to separate lines (wide to long) */
proc transpose data = cond_clink 
	out = cond_long (rename = (COL1 = CCSR) drop = _NAME_ _LABEL_);
	by DUPERSID CONDIDX EVNTIDX ;
	var CCSR: ;
run;

data cond_long;
	set cond_long;
	if CCSR not in ("-1");
run;


/* Merge on collapsed condition codes */
proc sort data = cond_long; by CCSR; run;
proc sort data = condition_codes; by CCSR; run;

data cond;
	merge cond_long (in = keepit) condition_codes;
	by CCSR;
	if keepit;
	if Condition = "" then delete;
run;


/* De-duplicate by event ID ('EVNTIDX') and collapsed code ('Condition') */
proc sort data = cond (keep = DUPERSID EVNTIDX Condition) nodupkey;
	by DUPERSID EVNTIDX Condition;
run;


/* Merge conditions and event files *********************************************/
/*  - remove any observations with missing 'Condition' or negative expenditures */
proc sort data = stacked_events; by DUPERSID EVNTIDX; run;
proc sort data = cond; by DUPERSID EVNTIDX; run;
data all_events;
	merge stacked_events cond;
	by DUPERSID EVNTIDX;
	if Condition ne '' and XP18X >= 0;
run;


/* Aggregate to person-level, by Condition ***********************************/

proc sort data = all_events; by DUPERSID VARSTR VARPSU Condition; run;
proc means data = all_events noprint;
	by DUPERSID VARSTR VARPSU Condition;
	var XP18X n_events PERWT18F;
	output out = all_pers
	 mean = mean_XP avg_events PERWT18F
	 sum  = pers_XP n_events;
run;

data all_pers;
	set all_pers;
	person = 1;
run;


/* Calculate estimates using survey procedures *******************************/

ods output Domain = out;
proc surveymeans data = all_pers mean sum;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT18F;
	var person n_events pers_XP;
	domain Condition;
run;

/* Number of people with care */
proc print data = out noobs label;
	label Sum = "Number of people with care";
	where VarName = "person";
	var Condition Sum StdDev;
run;

/* Number of events */
proc print data = out noobs label;
	label Sum = "Number of events";
	where VarName = "n_events";
	var Condition Sum StdDev;
run;

/* Expenditures */
proc print data = out noobs label;
	label Sum = "Total expenditures" Mean = "Mean expenditure per person with care";
	where VarName = "pers_XP";
	var Condition Sum StdDev Mean StdErr ;
run;
