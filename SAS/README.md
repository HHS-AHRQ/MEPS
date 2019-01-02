# Analyzing MEPS data using SAS
[SAS examples](#sas-examples)<br>
[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [Manually](#manually)<br>
&nbsp; &nbsp; [Programmatically](#programmatically)<br>
&nbsp; &nbsp; [Saving SAS data file (.sas7bdat)](#saving-sas-data-file-sas7bdat)<br>
[SAS SURVEY procedures](#sas-survey-procedures)<br>

## SAS examples

The following example codes are provided in this folder. Each exercise contains three files: SAS code (e.g. Exercise1.sas), a SAS log file (e.g. Exercise1_log.TXT) and a SAS output file (e.g. Exercise1_OUTPUT.TXT)

#### 1. National health care expenses
[exercise_1a](exercise_1a): National health care expenses by age group, 2016
<br>
[exercise_1b](exercise_1b): National health care expenses by age group and type of service, 2015
<br>

#### 2. Prescribed medicine purchases
[exercise_2a](exercise_2a): Trends in antipsychotics purchases and expenses, 2015
<br>
[exercise_2b](exercise_2b): Purchases and expenses for narcotic analgesics or narcotic analgesic combos, 2016

#### 3. Medical conditions
[exercise_3a](exercise_3a): Use and expenditures for persons with diabetes, 2015
<br>
[exercise_3b](exercise_3b): Expenditures for all events associated with diabetes, 2015
<br>

#### 4. Pooling data files
[exercise_4a](exercise_4a): Pooling MEPS FYC files, 2015 and 2016
<br>
[exercise_4b](exercise_4b): Pooling longitudinal files, panels 17-19

#### 5. Constructing variables
[exercise_5a](exercise_5a): Constructing family-level variables from person-level data, 2015
<br>
[exercise_5b](exercise_5b): Constructing insurance status from monthly insurance variables, 2015



#### Older Exercises (1996 to 2006)

These exercises include older SAS programs presented during previous MEPS workshops. Each folder includes a SAS program (.sas) and SAS output (.pdf)

##### Estimation examples

[E1](estimation_examples/E1):
Person-level estimates (means, proportions, and totals) for healthcare expenditures, 2001
<br>
[E2](estimation_exampes/E2): Average total healthcare expenditures for children ages 0-5, 1996-1999
<br>
[E3](estimation_exampes/E3): Longitudinal estimates of insurance coverage and expenditures, 1999-2000
<br>
[E4](estimation_exampes/E4): Family-level estimates for healthcare expenditures, 2001
<br>
[E5](estimation_exampes/E5): Event-level expenditure estimates for  hospital inpatient stays and office-based medical provider visits, 2001
<br>
[E6](estimation_exampes/E6): National health care expenditures by type of service, 2005 (Statistical Brief #193)
<br>
[E7](estimation_exampes/E7): Colonoscopy screening estimates, 2005 (Statistical Brief #188)
<br>
[E8](estimation_exampes/E8): Expenditures for inpatient stays by source of payment, per stay, per diem, with and without surgery, 2005

##### Employment examples
[EM1](employment_examples/EM1): Relationship between health status and current main job weekly earnings, 2002
<br>
[EM2](employment_examples/EM2): Determine how many people working at the beginning of the year changed jobs, 2002

##### Linking examples
[L1](linking_examples/L1): Merge the 2001 MEPS full-year file and the 2001 MEPS Jobs file
<br>
[L1A](linking_examples/L1A): Combine the 2000 and 2001 MEPS Jobs files
<br>
[L2](linking_examples/L2): Link 2001 MEPS data with 1999 and 2000 NHIS data
<br>
[L3](linking_examples/L3): Merge 2001 MEPS Office-based Medical Provider Visits file with full-year file
<br>
[L4](linking_examples/L4): Merge 2001 MEPS Medical Conditions file with full-year file
<br>
[L5](linking_examples/L5): Merge 2001 MEPS Medical Conditions file with full-year file and various event files

##### Miscellaneous examples
[M1](misc_examples/M1): Demonstrates need for weight variables when analyzing MEPS data, 2005
<br>
[M2](misc_examples/M2): Demonstrates need for using the STRATUM and PSU variables when analyzing MEPS data, 2005
<br>
[M3](misc_examples/M3): Using ID variables to merge MEPS files, 2005
<br>
[M4](misc_examples/M4): Illustrates two ways to calculate the number of events associated with conditions. (1) using the evNUM variables on the CONDITIONS file. (2) using the number of matches between the CONDITIONS file and the CLINK file, 2003
<br>
[M5](misc_examples/M5): Demonstrates the difference between two uses of the term "priority condition" in MEPS, 2005
<br>
[M6](misc_examples/M6): Demonstrates use of the Diabetes Care Supplement (DCS) weight variable, 2006
<br>
[M7](misc_examples/M7): Person-level prescribed medicine expenditures for persons with at least one PMED event, 2003
<br>
[M8](misc_examples/M8): Prescribed medicine expenditures associated with cancer conditions, 2005
<br>
[M9](misc_examples/M9): Descriptive statistics of health insurance status and healthcare utilization, 2005
<br>
[M10](misc_examples/M10): Compares hospital inpatient expenditures (facility, physician, total) for stays that do and do not include facility expenditures for the preceding emergency room visit, 2003
<br>
[M11](misc_examples/M11): Merge parents' employment status variable  to children's records, 2006



## Loading MEPS data

Two methods for downloading MEPS SAS transport files are available. The first requires the user to navigate to the website containing the MEPS dataset and manually download and unzip the SAS transport file. The second method uses a macro to automatically download the file by pointing to its location on the MEPS website.

### Manually

In SAS 9.4, SAS transport (.ssp) files can be read in using PROC XCOPY. In the following example, the SAS transport file <b>h171.ssp</b> has been downloaded from the MEPS website, unzipped, and saved in the local directory '<b>C:\MEPS</b>' (click [here](../README.md#accessing-meps-hc-data) for details).
``` sas
FILENAME in_h171 'C:\MEPS\h171.ssp';

proc xcopy in = in_h171 out = WORK IMPORT;
run;
```

### Programmatically

Alternatively, MEPS data can be downloaded directly from the MEPS website using `proc http`. First, run the macro provided in [load_MEPS_macro.sas](load_MEPS_macro.sas). This macro downloads the .zip file from the MEPS website, unzips it, and loads the SAS transport file (.ssp) into memory.

Next, use the following code to load MEPS datasets into memory. In this example, the 2014 full year consolidated file (h171) is downloaded directly from the MEPS website and stored in SAS memory in the data file `WORK.h171`:

``` sas
%load_MEPS(h171);

/* View first 10 observations of dataset */
  proc print data = work.h171 (obs=10);
  run;
```
To download additional files programmatically, replace 'h171' with the desired filename (see [meps_files_names.csv](https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_file_names.csv) for a list of MEPS file names by data type and year).

### Saving SAS data file (.sas7bdat)

Once the MEPS data has been loaded into SAS using either of the two previous methods, it can be saved as a permanent SAS dataset (.sas7bdat). In the following code, the h171 dataset is saved in the 'SAS\data' folder (first create the 'SAS\data' folder if needed):
``` sas
LIBNAME sasdata 'C:\MEPS\SAS\data';

data sasdata.h171;
  set WORK.h171;
run;
```

## SAS SURVEY procedures
To analyze MEPS data using SAS, [SURVEY procedures](https://support.sas.com/rnd/app/stat/procedures/SurveyAnalysis.html) should be used (e.g. SURVEYMEANS, SURVEYREG) to ensure unbiased estimates. As an example, the following code will estimate the total healthcare expenditures in 2014:
``` sas
proc surveymeans data = h171 sum;
  stratum VARSTR;
  cluster VARPSU;
  weight PERWT14F;
  var TOTEXP14;
run;
```
