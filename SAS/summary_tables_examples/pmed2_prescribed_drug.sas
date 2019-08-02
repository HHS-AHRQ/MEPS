/*****************************************************************************/
/* Prescribed drugs, 2016
/*
/* Purchases and expenditures by Multum therapeutic class name
/*
/* Example SAS code to replicate the following estimates in the MEPS-HC summary
/*  tables by Multum therapeutic class:
/*  - Number of people with purchase
/*  - Total purchases
/*  - Total expenditures
/*****************************************************************************/

ods graphics off;

/* Load datasets ************************************************************/
/* For 1996-2013, need to merge RX event file with Multum Lexicon Addendum  */
/*  file to get therapeutic class categories and generic drug names         */

/* Load RX file */
FILENAME h188a "C:\MEPS\h188a.ssp";
proc xcopy in = h188a out = WORK IMPORT;
run;

/* Aggregate to person-level ***********************************************/

/* Remove missing drug names */
data RX;
	set h188a;
	where RXNDC ne "-9" and RXDRGNAM ne "-9";
run;

proc sort data = RX;
	by DUPERSID VARSTR VARPSU PERWT16F RXDRGNAM;
run;

proc means data = RX noprint;
	by DUPERSID VARSTR VARPSU PERWT16F RXDRGNAM;
	var RXXP16X;
	output out = RX_pers sum = pers_RXXP n = n_purchases;
run;

data RX_pers;
	set RX_pers;
	person = 1;
run;

/* Calculate estimates using survey procedures *******************************/

ods output Domain = out;
proc surveymeans data = RX_pers sum;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT16F;
	var person n_purchases pers_RXXP;
	domain RXDRGNAM;
run;

/* Number of people with purchase */
proc print data = out noobs label;
	label Sum = "Number of people with purchase" ;
	where VarName = "person";
	var RXDRGNAM Sum StdDev;
run;

/* Number of purchases */
proc print data = out noobs label;
	label Sum = "Number of purchases" ;
	where VarName = "n_purchases";
	var RXDRGNAM Sum StdDev;
run;

/* Total expenditures */
proc print data = out noobs label;
	label Sum = "Total expenditures" ;
	where VarName = "pers_RXXP";
	var RXDRGNAM Sum StdDev;
run;
