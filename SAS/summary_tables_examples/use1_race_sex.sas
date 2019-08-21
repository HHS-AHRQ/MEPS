/*****************************************************************************/
/* Use, expenditures, and population
/*
/* Expenditures by race and sex
/*
/* Example SAS code to replicate the following estimates in the MEPS-HC summary
/*  tables, by race and sex:
/*  - number of people
/*  - percent of population with an expense
/*  - total expenditures
/*  - mean expenditure per person
/*  - mean expenditure per person with expense
/*  - median expenditure per person with expense
/*
/* Input file: C:\MEPS\h192.ssp (2016 full-year consolidated)
/*****************************************************************************/

ods graphics off;

/* Load FYC file *************************************************************/
FILENAME h192 "C:\MEPS\h192.ssp";
proc xcopy in = h192 out = WORK IMPORT;
run;


/* Define variables **********************************************************/

/* Race/ethnicity */
/*  - 1996-2002: race/ethnicity variable based on RACETHNX (see documentation)
/*  - 2002-2011: race/ethnicity variable based on RACETHNX and RACEX:
      hisp   = (RACETHX = 1);
      white  = (RACETHX = 2);
      black  = (RACETHX = 3);
      native = (RACETHX > 3 and RACEV1X in (3,6));
      asian  = (RACETHX > 3 and RACEV1X in (4,5));

/*  - For 2012 and later, use RACETHX and RACEV1X: */

	data MEPS; set h192;
		hisp   = (RACETHX = 1);
		white  = (RACETHX = 2);
		black  = (RACETHX = 3);
		native = (RACETHX > 3 and RACEV1X in (3,6));
		asian  = (RACETHX > 3 and RACEV1X in (4,5));

		race = 1*hisp + 2*white + 3*black + 4*native + 5*asian;

		person = 1;               /* counter for population totals */
		has_exp = (TOTEXP16 > 0); /* 1 if person has expense       */
	run;

proc format;
	value race
		1 = "Hispanic"
		2 = "White"
		3 = "Black"
		4 = "Amer. Indian, AK Native, or mult. races"
		5 = "Asian, Hawaiian, or Pacific Islander";

	value SEX
		1 = "Male"
		2 = "Female";
run;

/* Calculate estimates using survey procedures *******************************/

ods output Domain = out;
proc surveymeans data = MEPS mean sum missing;
	FORMAT SEX sex. race race.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN sex*race;
	VAR person has_exp TOTEXP16;
run;

/* Number of people, by race and sex */
proc print data = out noobs label;
	label Sum = "Number of people" ;
	where VarName = "person";
	var SEX race Sum;
run;

/* Percent of population with any expense in 2016, by race and sex */
proc print data = out noobs label;
	label Mean = "Percent of population with an expense";
	where VarName = "has_exp";
	var SEX race Mean StdErr;
run;

/* Total and mean expenditures per person, by race and sex */
proc print data = out noobs label;
	label Sum = "Total expenditures"  Mean = "Mean expenditure per person";;
	where VarName = "TOTEXP16";
	var SEX race Sum StdDev Mean StdErr;
run;



/* Mean and median expenditure per person with expense ***********************/
ods output Domain = out_mean  DomainQuantiles = out_median;
proc surveymeans data = MEPS mean median missing;
	FORMAT SEX sex. race race.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT16F;
	DOMAIN has_exp*sex*race;
	VAR TOTEXP16;
run;


/* Mean expenditure per person with expense, by race and sex */
proc print data = out_mean noobs label;
	where has_exp = 1;
	label Mean = "Mean expenditure per person with expense";
	var SEX race Mean StdErr;
run;


/* Median expenditure per person with expense, by race and sex              */
/*  Note: Estimates may vary in R, SAS, and Stata, due to different methods */
/*        of estimating survey quantiles                                    */
proc print data = out_median noobs label;
	where has_exp = 1;
	label Estimate = "Median expenditure per person with expense";
	var SEX race Estimate StdErr LowerCL UpperCL;
run;
