# Analyzing MEPS data using SAS


# SAS Exercises

## Summary of Exercises

[Exercise 1](exercise_1): National health care expenses by type of service
<br>[Exercise 2](exercise_2): Expenditures and utilization of antipsychotics (from [statistical brief #275](https://meps.ahrq.gov/data_files/publications/st275/stat275.shtml))
<br>[Exercise 3](exercise_3): Constructing family-level estimates
<br>[Exercise 4](exercise_4): Use and expenditures for persons with diabetes
<br>[Exercise 5](exercise_5): Expenditures for all events associated with diabetes
<br>[Exercise 6](exercise_6): Pooling multiple years of MEPS data
<br>[Exercise 7](exercise_7): Constructing insurance status variables from monthly insurance variables
<br>[Exercise 8](exercise_8): Pooling longitudinal files

## Contents of each exercise

1. SAS program file (.sas)
2. SAS log file (.LOG)
3. SAS list file containing output (.LST)
4. Rich text file containing both the log and output files (.rtf).

## Data files

The MEPS data files listed below used in the exercises. The following steps can be used to access the data sets:
1. Click on the [provided links](#full-year-files) to download the SAS transport zip files (.zip) (Alternatively, all MEPS public use files can be found at the [MEPS website](https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp)).

2. Unzip and save all the .ssp files into a folder on your local computer (e.g. "C:\MEPS\SAS\transfer").

3. Use SAS code to convert each file to a SAS dataset and store it in a local folder (e.g. "C:\MEPS\SAS\data"). The following SAS code demonstrates this process for MEPS public use file h171:

``` sas
LIBNAME data 'C:\MEPS\SAS\data';

FILENAME in_h171 'C:\MEPS\SAS\transfer\h171.ssp';

proc xcopy in = in_h171 out = data IMPORT;
run;
```
> <b> Important! </b> The folder containing the sas transport files (.ssp) must be different from the target folder for the SAS datasets (.sas7bdat). Failing to do so can result in an error.


#### Full-year Files:
* [h163](https://meps.ahrq.gov/mepsweb/data_files/pufs/h163ssp.zip) (2013 Full year consolidated PUF)
* [h171](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip) (2014 Full year consolidated PUF)

#### Conditions File:
* [h170](https://meps.ahrq.gov/mepsweb/data_files/pufs/h170ssp.zip) (2014 Condition file)

#### Event Files:
* [h168a](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168assp.zip) (2014 Prescribed medicines)
* [h168d](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168dssp.zip) (2014 Inpatient visits)
* [h168e](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168essp.zip) (2014 ER visits)
* [h168f](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168fssp.zip) (2014 Outpatient visits)
* [h168g](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168gssp.zip) (2014 Office-based visits)
* [h168h](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168hssp.zip) (2014 Home Health)
* [h168if1](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168if1ssp.zip) (2014 Condition-event link)

#### Longitudinal Files:
* [h172](https://meps.ahrq.gov/mepsweb/data_files/pufs/h172ssp.zip) (Panel 18)
* [h164](https://meps.ahrq.gov/mepsweb/data_files/pufs/h164ssp.zip) (Panel 17)
* [h156](https://meps.ahrq.gov/mepsweb/data_files/pufs/h156ssp.zip) (Panel 16)
