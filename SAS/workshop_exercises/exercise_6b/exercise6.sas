/*******************************************************************
program:      exercise6.sas
this program includes an example of 3 logistic regression models, each with a
sepatate dependent variable. 

	
cvdlayca53 - delay med care for covid r5/3 - recoded to yes/no (1,0)
cvdlaypm53 - delay getting pmed for covid r5/3 - recoded to yes/no (1,0)
cvdlaydn53 - delay getting dental for covid r5/3 - recoded to yes/no (1,0)

covariates: age, gender, race/ethnicity, health insurance coverage status, and region

the program also estimate the propotion of persons with delayed care events 
in the civilian noninstitutionized population.

input file: 2020 full-year consolidated file
********************************************************************/
/* clear log, output, and odsresults from the previous run automatically */
dm "log; clear; output; clear; odsresults; clear";
proc datasets nolist lib=work  kill; quit; /* delete  all files in the work library */

options nocenter ls=132 ps=79 nodate formchar="|----|+|---+=|-/\<>*" pageno=1;

/*********************************************************************************
 uncomment the next 5 lines of code, only if you want sas to create 
 separate files for sas log and output  
***********************************************************************************/
/*
%let rootfolder= c:\SASHandsOnSep2022\sas_exercises\exercise_6;
filename mylog "&rootfolder\exercise6_log.txt";
filename myprint "&rootfolder\exercise6_output.txt";
proc printto log=mylog print=myprint new;
run;
*/
/* create use-defined formats and store the the work folder */
proc format;

value sex_fmt   1 = '1. male'
                2 = '2. female'; 
			
value region_fmt 1 = '1. northeast'
		 2 = '2. midwest'	
		 3 = '3. south'
		 4 = '4. west';

 value inscov20_fmt
   1 = '1. any private'
   2 = '2. public only'
   3 = '3. uninsured';

value racethx_fmt
  1 = '1. hispanic'
  2 = '2. nh white only'
  3 = '3. nh black only'
  4 = '4. nh asian only'
  5 = '5. nh other etc';
run;

%let datafolder = c:\meps_data;  /* adjust the folder name, if needed */
libname cdata "&datafolder"; 
%let kept_vars_2020 =  %cmpres(varstr varpsu perwt20f cvdlayca53 cvdlaypm53 cvdlaydn53
                       agelast sex racethx povcat20 inscov20 region53);
%put &=kept_vars_2020;

data meps_2020;
 set cdata.h224 (keep= &kept_vars_2020);
 region = region53; if region53 = -1 then region =.; /* region recode */
 array x[3] cvdlayca53  cvdlaydn53 cvdlaypm53;
 array y{3] delayed_care_med delayed_care_dental delayed_care_pmeds;
 do i = 1 to 3;
 	if x[i] = 1 then y[i] = 1;
 	else if x[i] = 2 then y[i] = 0;
    else if x[i] <0 then y[i] = .;
 end;
run;

title 'proportion of persons with delayed care events';
ods graphics off;
proc surveymeans data=meps_2020 nobs mean stderr ;
    var delayed_care_med delayed_care_dental delayed_care_pmeds;
    stratum varstr;
	cluster varpsu;
    weight perwt20f;
   run;
title 'proc surveylogistic with param=ref option on the class statement';
title2 "dependent variable: delayed medical care";
	proc surveylogistic data=meps_2020 ;
	stratum varstr;
    cluster varpsu;
    weight perwt20f;
    class sex (ref='1. male') racethx (ref='1. hispanic') inscov20 (ref='1. any private')
          region (ref='1. northeast') /param=ref;
	 model delayed_care_med (ref= '0')= agelast sex racethx  inscov20 region;
	format   sex sex_fmt. 
      		 racethx racethx_fmt. 
			 inscov20 inscov20_fmt.
			 region region_fmt.	;
    run;
title2 'dependent variable: delayed  dental care';
	proc surveylogistic data=meps_2020 ;
	stratum varstr;
    cluster varpsu;
    weight perwt20f;
    class sex (ref='1. male') racethx (ref='1. hispanic') inscov20 (ref='1. any private')
          region (ref='1. northeast') /param=ref;
    model delayed_care_dental (ref= '0')= agelast sex racethx  inscov20 region;
	format   sex sex_fmt. 
      		 racethx racethx_fmt. 
			 inscov20 inscov20_fmt.
			 region region_fmt.;
    run;
   title2 'dependent variable: delayed prescribed medicines';
	proc surveylogistic data=meps_2020 ;
	stratum varstr;
    cluster varpsu;
    weight perwt20f;
    class sex (ref='1. male') racethx (ref='1. hispanic') inscov20 (ref='1. any private')
          region (ref='1. northeast') /param=ref;
    model delayed_care_pmeds (ref= '0')= agelast sex racethx  inscov20 region;
	format   sex sex_fmt. 
      		 racethx racethx_fmt. 
			 inscov20 inscov20_fmt.
			 region region_fmt. ;
    run;
title; /* cancel the TITLE and TITLE2 statements */

/* uncomment the next two lines of code to close the proc printto, only if used earlier. */
/*
proc printto;
run;
*/
