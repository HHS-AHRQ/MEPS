/* ****************************************************************************/
/* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
/*
/* Medical Conditions, 2015:
/*  - Number of people with care
/*  - Number of events
/*  - Total expenditures
/*  - Mean expenditure per person
/*
/* Note: Starting in 2016, conditions were converted from ICD-9 and CCS codes
/*  to ICD-10 and CCSR codes 
/*
/* Input files:
/* 	- C:\MEPS\h178a.ssp (2015 RX event file)
/* 	- C:\MEPS\h178d.ssp (2015 IP event file)
/* 	- C:\MEPS\h178e.ss (2015 ER event file)
/* 	- C:\MEPS\h178f.ss (2015 OP event file)
/* 	- C:\MEPS\h178g.ss (2015 OB event file)
/* 	- C:\MEPS\h178h.ss (2015 HH event file)
/* 	- C:\MEPS\h178if1.ss (2015 CLNK: Condition-event link file)
/* 	- C:\MEPS\h180.ss (2015 Conditions file)
/*****************************************************************************/

ods graphics off;

/* Define formats for CCS codes to collapsed conditions **********************/

  proc format;
   value CCCFMT
    -9 - -1                = ' '
    1-9                    = 'Infectious diseases                                         '
    11-45                  = 'Cancer                                                      '
    46, 47                 = 'Non-malignant neoplasm                                      '
    48                     = 'Thyroid disease                                             '
    49,50                  = 'Diabetes mellitus                                           '
    51, 52, 54 - 58        = 'Other endocrine, nutritional & immune disorder              '
    53                     = 'Hyperlipidemia                                              '
    59                     = 'Anemia and other deficiencies                               '
    60-64                  = 'Hemorrhagic, coagulation, and disorders of White Blood cells'
    65-75, 650-670         = 'Mental disorders                                            '
    76-78                  = 'CNS infection                                               '
    79-81                  = 'Hereditary, degenerative and other nervous system disorders '
    82                     = 'Paralysis                                                   '
    84                     = 'Headache                                                    '
    83                     = 'Epilepsy and convulsions                                    '
    85                     = 'Coma, brain damage                                          '
    86                     = 'Cataract                                                    '
    88                     = 'Glaucoma                                                    '
    87, 89-91              = 'Other eye disorders                                         '
    92                     = 'Otitis media                                                '
    93-95                  = 'Other CNS disorders                                         '
    98,99                  = 'Hypertension                                                '
    96, 97, 100-108        = 'Heart disease                                               '
    109-113                = 'Cerebrovascular disease                                     '
    114 -121               = 'Other circulatory conditions arteries, veins, and lymphatics'
    122                    = 'Pneumonia                                                   '
    123                    = 'Influenza                                                   '
    124                    = 'Tonsillitis                                                 '
    125 , 126              = 'Acute Bronchitis and URI                                    '
    127-134                = 'COPD, asthma                                                '
    135                    = 'Intestinal infection                                        '
    136                    = 'Disorders of teeth and jaws                                 '
    137                    = 'Disorders of mouth and esophagus                            '
    138-141                = 'Disorders of the upper GI                                   '
    142                    = 'Appendicitis                                                '
    143                    = 'Hernias                                                     '
    144- 148               = 'Other stomach and intestinal disorders                      '
    153-155                = 'Other GI                                                    '
    149-152                = 'Gallbladder, pancreatic, and liver disease                  '
    156-158, 160, 161      = 'Kidney Disease                                              '
    159                    = 'Urinary tract infections                                    '
    162,163                = 'Other urinary                                               '
    164-166                = 'Male genital disorders                                      '
    167                    = 'Non-malignant breast disease                                '
    168-176                = 'Female genital disorders, and contraception                 '
    177-195                = 'Complications of pregnancy and birth                        '
    196, 218               = 'Normal birth/live born                                      '
    197-200                = 'Skin disorders                                              '
    201-204                = 'Osteoarthritis and other non-traumatic joint disorders      '
    205                    = 'Back problems                                               '
    206-209, 212           = 'Other bone and musculoskeletal disease                     '
    210-211                = 'Systemic lupus and connective tissues disorders             '
    213-217                = 'Congenital anomalies                                        '
    219-224                = 'Perinatal Conditions                                        '
    225-236, 239, 240, 244 = 'Trauma-related disorders                                    '
    237, 238               = 'Complications of surgery or device                          '
    241 - 243              = 'Poisoning by medical and non-medical substances             '
    259                    = 'Residual Codes                                              '
    10, 254-258            = 'Other care and screening                                    '
    245-252                = 'Symptoms                                                    '
    253                    = 'Allergic reactions                                          '
    OTHER                  = 'Other                                                       '
    ;
  run;


/* Load datasets *************************************************************/

/* Macro to import data from .ssp files */
%macro load(file);
	FILENAME &file. "C:\MEPS\&file..ssp";
	proc xcopy in = &file. out = WORK IMPORT;
	run;
%mend;

/* Load and stack event files */
%load(h178a); /* RX */
%load(h178d); /* IP */
%load(h178e); /* ER */
%load(h178f); /* OP */
%load(h178g); /* OB */
%load(h178h); /* HH */

/* For RX events, count number of fills per event */
proc sort data = h178a; by DUPERSID LINKIDX VARSTR VARPSU PERWT15F; run;
proc means data = h178a noprint;
	by DUPERSID LINKIDX VARSTR VARPSU PERWT15F;
	var RXXP15X;
	output out = RX sum = XP15X n = n_fills;
run;

/* Stack event files */
data stacked_events;
	set RX (in = RX rename = (LINKIDX = EVNTIDX))
		h178d (in = IP rename = (IPXP15X = XP15X))
		h178e (in = ER rename = (ERXP15X = XP15X))
		h178f (in = OP rename = (OPXP15X = XP15X))
		h178g (in = OB rename = (OBXP15X = XP15X))
		h178h (in = HH rename = (HHXP15X = XP15X));

	if RX then data = "RX";
	else if IP then data = "IP";
	else if ER then data = "ER";
	else if OP then data = "OP";
	else if OB then data = "OB";
	else if HH then data = "HH";

	/* Count events (for RX, each fill is an event) */
	n_events = max(n_fills, 1);

	keep data EVNTIDX DUPERSID n_events XP15X VARSTR VARPSU PERWT15F;
run;

/* Load in event-condition linking file */
%load(h178if1);

/* Load in conditions file */
%load(h180);


/* Merge datasets ************************************************************/

/* Merge conditions data with the conditions-event link file (CLNK)           */
/*  then de-duplicate by event ID ('EVNTIDX') and collapsed code ('Condition')*/

proc sort data = h178if1 (keep = DUPERSID CONDIDX EVNTIDX); by DUPERSID CONDIDX; run;
proc sort data = h180 (keep = DUPERSID CONDIDX CCCODEX); by DUPERSID CONDIDX; run;

data cond_clink;
	merge h178if1 h180;
	by DUPERSID CONDIDX;
	Condition = put(CCCODEX*1, CCCFMT.);
run;

proc sort data = cond_clink nodupkey;
	by DUPERSID EVNTIDX Condition;
run;


/* Merge events with linked conditions file and remove any observations with */
/*  missing 'Condition' or negative expenditures                             */

proc sort data = stacked_events; by DUPERSID EVNTIDX; run;
proc sort data = cond_clink; by DUPERSID EVNTIDX; run;
data all_events;
	merge stacked_events cond_clink;
	by DUPERSID EVNTIDX;
	if Condition ne '' and XP15X >= 0;
run;

/* Aggregate to person-level, by Condition ***********************************/

proc sort data = all_events; by DUPERSID VARSTR VARPSU Condition; run;
proc means data = all_events noprint;
	by DUPERSID VARSTR VARPSU Condition;
	var XP15X n_events PERWT15F;
	output out = all_pers
	 mean = mean_XP avg_events PERWT15F
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
	weight PERWT15F;
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
