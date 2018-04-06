# Analyzing MEPS data using SAS
[Loading MEPS data](#loading-meps-data)<br>
[SAS SURVEY procedures](#sas-survey-procedures)<br>

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
