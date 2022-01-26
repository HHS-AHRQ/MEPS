/*****************************************************************************/
/* Example code to replicate estimates from the MEPS-HC Data Tools summary tables
/*
/* Prescribed drugs, 2016
/*
/* Purchases and expenditures by Multum therapeutic class name (TC1)
/*  - Number of people with purchase
/*  - Total purchases
/*  - Total expenditures
/*
/* Input file: C:\MEPS\h188a.ssp (2016 RX event file)
/*****************************************************************************/

ods graphics off;

/* Define formats for therapeutic classes ***********************************/

  proc format;
    value TC1name
    -9  = 'Not ascertained                                        '
    -1  = 'Inapplicable                                           '
     1  = 'Anti-infectives                                        '
    19  = 'Antihyperlipidemic agents                              '
    20  = 'Antineoplastics                                        '
    28  = 'Biologicals                                            '
    40  = 'Cardiovascular agents                                  '
    57  = 'Central nervous system agents                          '
    81  = 'Coagulation modifiers                                  '
    87  = 'Gastrointestinal agents                                '
    97  = 'Hormones/hormone modifiers                             '
    105 = 'Miscellaneous agents                                   '
    113 = 'Genitourinary tract agents                             '
    115 = 'Nutritional products                                   '
    122 = 'Respiratory agents                                     '
    133 = 'Topical agents                                         '
    218 = 'Alternative medicines                                  '
    242 = 'Psychotherapeutic agents                               '
    254 = 'Immunologic agents                                     '
    358 = 'Metabolic agents                                       '
    ;
  run;


/* Load datasets ************************************************************/
/* For 1996-2013, need to merge RX event file with Multum Lexicon Addendum  */
/*  file to get therapeutic class categories and generic drug names         */

/* Load RX file */
FILENAME h188a "C:\MEPS\h188a.ssp";
proc xcopy in = h188a out = WORK IMPORT;
run;

/* Aggregate to person-level ***********************************************/

proc sort data = h188a;
	by DUPERSID VARSTR VARPSU PERWT16F TC1;
run;

proc means data = h188a noprint;
	by DUPERSID VARSTR VARPSU PERWT16F TC1;
	var RXXP16X;
	output out = TC1pers sum = pers_RXXP n = n_purchases;
run;

data TC1pers;
	set TC1pers;
	person = 1;
run;

/* Calculate estimates using survey procedures *******************************/

ods output Domain = out;
proc surveymeans data = TC1pers sum;
	format TC1 TC1name.;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT16F;
	var person n_purchases pers_RXXP;
	domain TC1;
run;

/* Number of people with purchase */
proc print data = out noobs label;
	label Sum = "Number of people with purchase" ;
	where VarName = "person";
	var TC1 Sum StdDev;
run;

/* Total purchases */
proc print data = out noobs label;
	label Sum = "Total purchases" ;
	where VarName = "n_purchases";
	var TC1 Sum StdDev;
run;

/* Total expenditures */
proc print data = out noobs label;
	label Sum = "Total expenditures" ;
	where VarName = "pers_RXXP";
	var TC1 Sum StdDev;
run;
