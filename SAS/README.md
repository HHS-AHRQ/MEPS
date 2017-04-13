# Analyzing MEPS data using SAS
[Loading MEPS data](#loading-meps-data)<br>
[SAS SURVEY procedures](#sas-survey-procedures)<br>
[SAS exercises](#sas-exercises)

## Loading MEPS data
In SAS 9.4, transport (.ssp) files can be read in using PROC XCOPY. In the following example, the SAS transport file '<b>h171.ssp</b>' has been downloaded from the MEPS website, unzipped, and saved in the local directory '<b>C:\MEPS\data</b>' (click [here](../README.md#accessing-meps-hc-data) for details)
``` sas
FILENAME in_h171 'C:\MEPS\data\h171.ssp';

proc xcopy in = in_h171 out = WORK IMPORT;
run;
```
To save the loaded data as a permanent SAS dataset (.sas7bdat), run the following code (first create the 'SAS\data' folders if needed):
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

## SAS exercises

Several exercises are provided as examples of calculating estimates using MEPS data:

[Exercise 1](exercise_1): National health care expenses by type of service
<br>[Exercise 2](exercise_2): Expenditures and utilization of antipsychotics (from [statistical brief #275](https://meps.ahrq.gov/data_files/publications/st275/stat275.shtml))
<br>[Exercise 3](exercise_3): Constructing family-level estimates
<br>[Exercise 4](exercise_4): Use and expenditures for persons with diabetes
<br>[Exercise 5](exercise_5): Expenditures for all events associated with diabetes
<br>[Exercise 6](exercise_6): Pooling multiple years of MEPS data
<br>[Exercise 7](exercise_7): Constructing insurance status variables from monthly insurance variables
<br>[Exercise 8](exercise_8): Pooling longitudinal files

Each folder contains three files:

1. SAS program file (.sas)
2. SAS log file (.LOG)
3. SAS list file containing output (.LST)
