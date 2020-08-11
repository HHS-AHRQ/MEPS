# Analyzing MEPS data using SAS
[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [Using `PROC XCOPY` (1996-2017)](#using-proc-xcopy-1996-2017)<br>
&nbsp; &nbsp; [Using `PROC CIMPORT` (2018 and later)](#using-proc-cimport-2018-and-later)<br>
&nbsp; &nbsp; [Automating file download](#automating-file-download)<br>
&nbsp; &nbsp; [Saving SAS data (.sas7bdat)](#saving-sas-data-sas7bdat)<br>
[SAS SURVEY procedures](#sas-survey-procedures)<br>
[SAS examples](#sas-examples)<br>
&nbsp; &nbsp; [Workshop Exercises](#workshop-exercises)<br>
&nbsp; &nbsp; [Summary tables examples](#summary-tables-examples)<br>
&nbsp; &nbsp; [Older Exercises (1996 to 2006)](#older-exercises-1996-to-2006)<br>

## Loading MEPS data

> <b> IMPORTANT! </b> Starting in 2018, the SAS Transport formats for MEPS Public Use Files were converted from the SAS XPORT to the SAS CPORT engine. The `PROC CIMPORT` procedure must be used to download these files, as detailed in the sections below.

### Using `PROC XCOPY` (1996-2017)

In SAS 9.4 or later, SAS transport (.ssp) files can be read in using PROC XCOPY for 1996-2017 PUFs. In the following examples, the SAS transport file for the 2017 Dental Visits file (h197b.ssp) has been downloaded from the MEPS website, unzipped, and saved in the local directory '<b>C:\MEPS</b>' (click [here](../README.md#accessing-meps-hc-data) for details).
``` sas
FILENAME in_h197b 'C:\MEPS\h197b.ssp';
PROC XCOPY in = in_h197b out = WORK IMPORT;
RUN;

/* View first 10 rows of data */
PROC PRINT data = h197b (obs=10);
RUN;
```

### Using `PROC CIMPORT` (2018 and later)
Starting in 2018, design changes in the MEPS survey instrument resulted in SAS transport files being converted from the XPORT to the CPORT format. Thus, the `CIMPORT` procedure must be used for to load these files into SAS for data years 2018 and later. In the following examples, the SAS transport file for the 2018 Dental Visits file (h206b.ssp) Dental Visits event files have been downloaded from the MEPS website, unzipped, and saved in the local directory '<b>C:\MEPS</b>' (click [here](../README.md#accessing-meps-hc-data) for details).
``` sas
FILENAME in_h206b 'C:\MEPS\h206b.ssp';
PROC CIMPORT data = work.h206b infile = in_h206b;
RUN;

/* View first 10 rows of data */
PROC PRINT data = h206b (obs=10);
RUN;
```

### Automating file download
> <b> Warning!</b> This macro was developed for use with SAS XPORT file types (applicable to MEPS PUFs from 1996-2017), and has not been tested on PUFs from 2018 and later.

Instead of having to manually download, unzip, and store MEPS data files in a local directory, it may be beneficial to automatically download MEPS data directly from the MEPS website. This can be accomplished using the `proc http` procedure. First, run the macro provided in [load_MEPS_macro.sas](load_MEPS_macro.sas). This macro downloads the .zip file from the MEPS website, unzips it, and loads the SAS transport file (.ssp) into memory.

Next, use the following code to load MEPS datasets into memory. In this example, the 2014 full year consolidated file (h171) is downloaded directly from the MEPS website and stored in SAS memory in the data file `WORK.h171`:


``` sas
%load_MEPS(h171);

/* View first 10 observations of dataset */
  proc print data = work.h171 (obs=10);
  run;
```
To download additional files programmatically, replace 'h171' with the desired filename (see [meps_files_names.csv](https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_file_names.csv) for a list of MEPS file names by data type and year).

### Saving SAS data (.sas7bdat)

Once the MEPS data has been loaded into SAS using either of the two previous methods, it can be saved as a permanent SAS dataset (.sas7bdat). In the following code, the h206b dataset is saved in the 'SAS\data' folder (first create the 'SAS\data' folder if needed):
``` sas
LIBNAME sasdata 'C:\MEPS\SAS\data';

data sasdata.h197b;
  set WORK.h197b;
run;
```

## SAS SURVEY procedures
To analyze MEPS data using SAS, [SURVEY procedures](https://support.sas.com/rnd/app/stat/procedures/SurveyAnalysis.html) should be used (e.g. SURVEYMEANS, SURVEYREG) to ensure unbiased estimates. As an example, the following code will estimate the total healthcare expenditures in 2014:
``` sas
proc surveymeans data = h197b sum;
  stratum VARSTR;
  cluster VARPSU;
  weight PERWT17F;
  var DVXP17X;
run;
```


## SAS examples

In order to run the example codes, you must download the relevant MEPS files from the MEPS website and save them to your local computer, as described above.

### Workshop exercises
Example codes from previous MEPS workshops are provided in the [workshop_exercises](workshop_exercises) folder. Each exercise contains three files: SAS code (e.g. Exercise1.sas), a SAS log file (e.g. Exercise1_log.TXT) and a SAS output file (e.g. Exercise1_OUTPUT.TXT):

#### 1. National health care expenses
[exercise_1a](workshop_exercises/exercise_1a): National health care expenses by age group, 2016
<br>
[exercise_1b](workshop_exercises/exercise_1b): National health care expenses by age group and type of service, 2015
<br>

#### 2. Prescribed medicine purchases
[exercise_2a](workshop_exercises/exercise_2a): Trends in antipsychotics purchases and expenses, 2015
<br>
[exercise_2b](workshop_exercises/exercise_2b): Purchases and expenses for narcotic analgesics or narcotic analgesic combos, 2016

#### 3. Medical conditions
[exercise_3a](workshop_exercises/exercise_3a): Use and expenditures for persons with diabetes, 2015
<br>
[exercise_3b](workshop_exercises/exercise_3b): Expenditures for all events associated with diabetes, 2015
<br>

#### 4. Pooling data files
[exercise_4a](workshop_exercises/exercise_4a): Pooling MEPS FYC files, 2015 and 2016
<br>
[exercise_4b](workshop_exercises/exercise_4b): Pooling longitudinal files, panels 17-19

#### 5. Constructing variables
[exercise_5a](workshop_exercises/exercise_5a): Constructing family-level variables from person-level data, 2015
<br>
[exercise_5b](workshop_exercises/exercise_5b): Constructing insurance status from monthly insurance variables, 2015


### Summary tables examples

The following codes provided in the [summary_tables_examples](summary_tables_examples) folder re-create selected statistics from the [MEPS online summary tables](https://meps.ahrq.gov/mepstrends/home/). These example codes are written under the assumption that the .ssp files are saved in the local directory "C:/MEPS/". However, you can customize the programs to point to an alternate directory.

#### Accessibility and quality of care
[care1_child_dental.sas](summary_tables_examples/care1_child_dental.sas): Children with dental care, by poverty status, 2016
<br>
[care2_diabetes_a1c.sas](summary_tables_examples/care2_diabetes_a1c.sas): Adults with diabetes receiving hemoglobin A1c blood test, by race/ethnicity, 2016
<br>
[care3_access.sas](summary_tables_examples/care3_access.sas): Ability to schedule a routine appointment, by insurance coverage, 2016

#### Medical conditions
[cond1_expenditures.sas](summary_tables_examples/cond1_expenditures.sas): Utilization and expenditures by medical condition, 2015

#### Health Insurance
[ins1_age.sas](summary_tables_examples/ins1_age.sas): Health insurance coverage by age group, 2016

#### Prescribed drugs
[pmed1_therapeutic_class.sas](summary_tables_examples/pmed1_therapeutic_class.sas): Purchases and expenditures by Multum therapeutic class, 2016
<br>
[pmed2_prescribed_drug.sas](summary_tables_examples/pmed2_prescribed_drug.sas): Purchases and expenditures by generic drug name, 2016

#### Use, expenditures, and population
[use1_race_sex.sas](summary_tables_examples/use1_race_sex.sas): Utilization and expendiutres by race and sex, 2016
<br>
[use2_expenditures.sas](summary_tables_examples/use2_expenditures.sas): Expenditures for office-based and outpatient visits, by source of payment, 2016
<br>
[use3_events.sas](summary_tables_examples/use3_events.sas): Number of events and mean expenditure per event, for office-based and outpatient events, by source of payment, 2016


### Older Exercises (1996 to 2006)

Codes provided in the [older_exercises_1996_to_2006](older_exercises_1996_to_2006) folder include older SAS programs for analyzing earlier years of MEPS data. Each folder includes a SAS program (.sas) and SAS output (.pdf)

#### Estimation examples

[E1](older_exercises_1996_to_2006/Estimation_examples/E1):
Person-level estimates (means, proportions, and totals) for healthcare expenditures, 2001
<br>
[E2](older_exercises_1996_to_2006/Estimation_examples/E2): Average total healthcare expenditures for children ages 0-5, 1996-1999
<br>
[E3](older_exercises_1996_to_2006/Estimation_examples/E3): Longitudinal estimates of insurance coverage and expenditures, 1999-2000
<br>
[E4](older_exercises_1996_to_2006/Estimation_examples/E4): Family-level estimates for healthcare expenditures, 2001
<br>
[E5](older_exercises_1996_to_2006/Estimation_examples/E5): Event-level expenditure estimates for  hospital inpatient stays and office-based medical provider visits, 2001
<br>
[E6](older_exercises_1996_to_2006/Estimation_examples/E6): National health care expenditures by type of service, 2005 (Statistical Brief #193)
<br>
[E7](older_exercises_1996_to_2006/Estimation_examples/E7): Colonoscopy screening estimates, 2005 (Statistical Brief #188)
<br>
[E8](older_exercises_1996_to_2006/Estimation_examples/E8): Expenditures for inpatient stays by source of payment, per stay, per diem, with and without surgery, 2005

#### Employment examples
[EM1](older_exercises_1996_to_2006/Employment_examples/EM1): Relationship between health status and current main job weekly earnings, 2002
<br>
[EM2](older_exercises_1996_to_2006/Employment_examples/EM2): Determine how many people working at the beginning of the year changed jobs, 2002

#### Linking examples
[L1](older_exercises_1996_to_2006/Linking_examples/L1): Merge the 2001 MEPS full-year file and the 2001 MEPS Jobs file
<br>
[L1A](older_exercises_1996_to_2006/Linking_examples/L1A): Combine the 2000 and 2001 MEPS Jobs files
<br>
[L2](older_exercises_1996_to_2006/Linking_examples/L2): Link 2001 MEPS data with 1999 and 2000 NHIS data
<br>
[L3](older_exercises_1996_to_2006/Linking_examples/L3): Merge 2001 MEPS Office-based Medical Provider Visits file with full-year file
<br>
[L4](older_exercises_1996_to_2006/Linking_examples/L4): Merge 2001 MEPS Medical Conditions file with full-year file
<br>
[L5](older_exercises_1996_to_2006/Linking_examples/L5): Merge 2001 MEPS Medical Conditions file with full-year file and various event files

#### Miscellaneous examples
[M1](older_exercises_1996_to_2006/Misc_examples/M1): Demonstrates need for weight variables when analyzing MEPS data, 2005
<br>
[M2](older_exercises_1996_to_2006/Misc_examples/M2): Demonstrates need for using the STRATUM and PSU variables when analyzing MEPS data, 2005
<br>
[M3](older_exercises_1996_to_2006/Misc_examples/M3): Using ID variables to merge MEPS files, 2005
<br>
[M4](older_exercises_1996_to_2006/Misc_examples/M4): Illustrates two ways to calculate the number of events associated with conditions. (1) using the evNUM variables on the CONDITIONS file. (2) using the number of matches between the CONDITIONS file and the CLINK file, 2003
<br>
[M5](older_exercises_1996_to_2006/Misc_examples/M5): Demonstrates the difference between two uses of the term "priority condition" in MEPS, 2005
<br>
[M6](older_exercises_1996_to_2006/Misc_examples/M6): Demonstrates use of the Diabetes Care Supplement (DCS) weight variable, 2006
<br>
[M7](older_exercises_1996_to_2006/Misc_examples/M7): Person-level prescribed medicine expenditures for persons with at least one PMED event, 2003
<br>
[M8](older_exercises_1996_to_2006/Misc_examples/M8): Prescribed medicine expenditures associated with cancer conditions, 2005
<br>
[M9](older_exercises_1996_to_2006/Misc_examples/M9): Descriptive statistics of health insurance status and healthcare utilization, 2005
<br>
[M10](older_exercises_1996_to_2006/Misc_examples/M10): Compares hospital inpatient expenditures (facility, physician, total) for stays that do and do not include facility expenditures for the preceding emergency room visit, 2003
<br>
[M11](older_exercises_1996_to_2006/Misc_examples/M11): Merge parents' employment status variable  to children's records, 2006
