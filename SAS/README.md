# Analyzing MEPS data using SAS
[SAS examples](#sas-examples)<br>
[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [Manually](#manually)<br>
&nbsp; &nbsp; [Programmatically](#programmatically)<br>
&nbsp; &nbsp; [Saving SAS data file (.sas7bdat)](#saving-sas-data-file-sas7bdat)<br>
[SAS SURVEY procedures](#sas-survey-procedures)<br>

## SAS examples


The following example codes are provided in this folder.

[exercise_1](exercise_1): National health care expenses by type of service, 2015
<br>
[exercise_2](exercise_2): Trends in antipsychotics purchases and expenses, 2015
<br>
[exercise_3](exercise_3): Constructing family-level variables from person-level data, 2015
<br>
[exercise_4](exercise_4): Use and expenditures for persons with diabetes, 2015
<br>
[exercise_5](exercise_5): Expenditures for all events associated with diabetes, 2015
<br>
[exercise_6](exercise_6): Pooling MEPS FYC files, 2014 and 2015
<br>
[exercise_7](exercise_7): Constructing insurance status from monthly insurance variables, 2015
<br>
[exercise_8](exercise_8): Pooling longitudinal files, panels 17-19


Each exercise contains three files: SAS code (e.g. Exercise1.sas), a SAS log file (e.g. Exercise1_log.TXT) and a SAS output file (e.g. Exercise1_OUTPUT.TXT)

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
