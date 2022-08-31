
/******************************************************************************************
PROGRAM:      EXERCISE4.SAS

 This program illustrates how to pool MEPS data files from different years. It
 highlights one example of a discontinuity that may be encountered when 
 working with data from before and after the 2018 MEPS CAPI re-design.
 
 The program pools 2017, 2018 and 2019 data and calculates  
  - percentage of people with Joint Pain / Arthritis (JTPAIN**, ARTHDX)
  - average expenditures per person, by Joint Pain status (TOTEXP, TOTSLF)
  - standard errors by specifying common variance structure when pooling data.
 for the U.S. civilian noninstitutionized population.

 Input files:
  - 2017 Full-year consolidated file
  - 2018 Full-year consolidated file
  - 2019 Full-year consolidated file
  - 1996-2019 pooled linkage variance estimation file
*/


/* Clear log, output, and ODSRESULTS from the previous run automatically */
DM "Log; clear; output; clear; odsresults; clear";
proc datasets nolist lib=work kill; quit; /* Delete  all files in the WORK library */
OPTIONS NOCENTER LS=132 PS=79 NODATE FORMCHAR="|----|+|---+=|-/\<>*" PAGENO=1;

/* Turn Off the Warning Message  
WARNING: Multiple lengths were specified for the variable Name by input data set(s).
*/
OPTIONS varlenchk=nowarn;

/*********************************************************************************
 IMPORTANT NOTE:  Use the next 5 lines of code, only if you want SAS to create 
    separate files for SAS log and output.  Otherwise comment  out these lines.
***********************************************************************************/

%LET RootFolder= C:\Mar2022\sas_exercises\Exercise_4;
FILENAME MYLOG "&RootFolder\Exercise4_log.TXT";
FILENAME MYPRINT "&RootFolder\Exercise4_OUTPUT.TXT";
PROC PRINTTO LOG=MYLOG PRINT=MYPRINT NEW;
RUN;


/* Create use-defined formats and store them in a catalog called FORMATS 
   in the work folder. They get deleted at the end of the SAS session.
*/
PROC FORMAT;

  VALUE agecat_fmt
       19-49 = '19-49'
       50-64 = '50-64'
       65-high= '65+';

     value yes_no_fmt
      1 = 'Yes'
      2 = 'No'
      -1,-7,-8,-15,.= 'DK/REF/INAPP/MISSING'; 

	  value spop_fmt
      1 = 'Age 18+'
	  0 = 'Age 0-17';
run;

%LET DataFolder = C:\MEPS_Data;  /* Adjust the folder name, if needed */
libname NEW "&DataFolder"; 

/* Create 3 macro variables, assigning a list of variables to each */
%let kept_vars_2017 =  dupersid panel VARSTR VARPSU perwt17f agelast ARTHDX JTPAIN31 totexp17 totslf17;
%let kept_vars_2018 =  dupersid panel VARSTR VARPSU perwt18f agelast ARTHDX JTPAIN31_m18 totexp18 totslf18;
%let kept_vars_2019 =  dupersid panel VARSTR VARPSU perwt19f agelast ARTHDX JTPAIN31_M18 totexp19 totslf19;

/* Concatenate 2017, 2018 and 2018 Full Year Consolidated Files 
* Use KEEP= abd RENAME= data set options on the SET statement for effeciency
*/
data MEPS_171819;
 set NEW.h201v9 (keep= &kept_vars_2017
                 rename=(totexp17=totexp
                         totslf17=totslf DUPERSID=t_DUPERSID) in=a)
     NEW.h209v9 (keep= &kept_vars_2018
                 rename=(totexp18=totexp
                         totslf18=totslf) in=b)
     NEW.h216 (keep= &kept_vars_2019
                 rename=(totexp19=totexp
                         totslf19=totslf) in=c);

	  *Create new variable (YEAR) for data-checks; 
      if a =1 then year=2017;
      else if b=1 then year=2018;
	  else if c=1 then year=2019;

	  *Create a new weight variable by dividing the original weight by 3 for the pooled data set;
      if year = 2017 then perwtf = perwt17f/3;
      else if year = 2018 then perwtf = perwt18f/3;
      else if year = 2019 then perwtf = perwt19f/3;

   /***********************************************************************************
   *  Create new variables: JOINT_PAIN, SPOP (subpopulation indicator), 
   *  ZERO_WEIGHT (zero survey weight for QC purposes).
   *  Change the 8-character DUPERSID to a 10-character one for 2017.
   *  Such change is not needed for 2018 and 2019 because DUPERSID is a 10-character 
   *  variable for those years.
   ************************************************************************************/ 
   
   if year = 2017 then do;
        spop=0;
   		if agelast>=18 and not (ARTHDX <=0 and JTPAIN31 <0) then do;
		    DUPERSID = CATS(PANEL, T_DUPERSID);
			drop t_DUPERSID;
  		    spop=1; 
   		   if ARTHDX=1 | JTPAIN31=1 then joint_pain =1;	 else joint_pain=2;
        end;
    end;
    else if year in (2018, 2019) then do;
            spop=0;
   			if agelast>=18 and not (ARTHDX <0 and JTPAIN31_M18 <0) then do;
     		  spop=1; 
			  if ARTHDX=1 | JTPAIN31_M18=1 then joint_pain =1; else joint_pain=2;
   		     end;
     end;

	if perwtf = 0 then zero_weight=1;
	else zero_weight=0;

   label totexp = 'TOTAL HEALTH CARE EXPENSES 2017-19'
         totslf='AMOUNT PAID BY SELF/FAMILY 2017-2019';
 run;

* Sort the pooled 2017-19 MEPS file by DUPERSID before match-merging 
  with the pooled linkage variance estimation file;

proc sort data=MEPS_171819;
  by dupersid ;
run;


 * Change the 8-character DUPERSID to 10-character DUPERSID for years before 2018;
  Data VSfile ;
    set new.h36u19 (rename=(DUPERSID=t_DUPERSID));
	LENGTH DUPERSID $10;
	if length(STRIP(t_dupersid))=8 then DUPERSID=CATS(put(panel,z2.), t_DUPERSID);
  	else DUPERSID = t_DUPERSID;   
  drop t_DUPERSID;
run;

* Sort the pooled linkage variance estimation file for panels 21-24
  by DUPERSID before match-merging ...;
proc sort data= VSfile (where = (panel in (21,22,23,24))) nodupkey
   out=sorted_VSfile ;
 by dupersid;
 run;

* Match-merge the 2017-19 file with the pooled linkage variance estimation file 
  for panels 21-24;

data MEPS_171819_m;
 merge MEPS_171819 (in=a) Sorted_VSfile ;
   by dupersid;
 if a;
run;


/* The following PROC FREQ and PROC MEANS steps are for QC purposes */
/*
title 'MEPS 2017-19 combined for QC purposes';
proc freq data= MEPS_171819_m;
tables zero_weight ;
run;

title 'MEPS 2017-19 combined, perwtf>0 for QC purposes';
proc freq data= MEPS_171819_m;
tables spop*joint_pain/list missing nopercent;
format joint_pain yes_no_fmt. spop spop_fmt.;
where  perwtf>0;
run;

title 'MEPS 2017-19 combined, spop=1 & perwtf>0 for QC purposes';
proc freq data= MEPS_171819_m;
tables joint_pain/list missing nopercent;
format joint_pain yes_no_fmt. spop spop_fmt.;
where  spop=1 & perwtf>0;
run;

proc means data= MEPS_171819_m N NMISS MIN MAX maxdec=0;
var stra9619  psu9619;
where  spop=1 & perwtf>0;
run;

title 'MEPS 2017-19 combined, spop=1 & perwtf>0  & not  (stra9619 = . | psu9619=.)  ';
title2 'for QC purposes';

proc freq data= MEPS_171819_m;
tables joint_pain/list missing nopercent;
format joint_pain yes_no_fmt. spop spop_fmt.;
where  spop=1 & perwtf>0 & not (stra9619 = . | psu9619=.) ;
run;
title;
*/
title 'Pooled estiamtes for MEPS 2017-19';
ods graphics off;
ods select summary domain;
PROC SURVEYMEANS DATA=MEPS_171819_m  nobs mean stderr sum;
    VAR joint_pain ;
    stratum stra9619;
	cluster psu9619;
    WEIGHT perwtf;
	domain spop('1');
	class joint_pain;
  	format joint_pain yes_no_fmt. ;
RUN;
ods graphics off;
ods select summary domain;
PROC SURVEYMEANS DATA=MEPS_171819_m  nobs mean stderr sum;
    VAR totexp totslf;
    stratum stra9619;
	cluster psu9619;
    WEIGHT perwtf;
	domain spop('1')*joint_pain;
	format joint_pain yes_no_fmt.  ;
RUN;
TITLE;
/* THE PROC PRINTTO null step is required to close the PROC PRINTTO, 
 only if used earlier., Otherswise. please comment out the next two lines  */
proc printto;
run;

