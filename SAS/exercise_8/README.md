# SAS Exercise 8

## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory. Create the folder 'C:\MEPS\data' on your hard drive if it is not there:

**Input Files**:
<br>[H172 (Panel 18 Longitudinal File)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h172ssp.zip)
<br>[H164 (Panel 17 Longitudinal File)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h164ssp.zip)
<br>[H156 (Panel 16 Longitudinal File)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h156ssp.zip)

Next, run the following code to convert the SAS transport file (.ssp) to a SAS dataset (.sas7bdat) and save to a local directory (first create the target folder 'C:\MEPS\SAS\data' if needed):
``` sas
LIBNAME SASdata 'C:\MEPS\SAS\data';

FILENAME in_h172 'C:\MEPS\data\h172.ssp';
FILENAME in_h164 'C:\MEPS\data\h164.ssp';
FILENAME in_h156 'C:\MEPS\data\h156.ssp';

proc xcopy in = in_h172 out = SASdata IMPORT; run;
proc xcopy in = in_h164 out = SASdata IMPORT; run;
proc xcopy in = in_h156 out = SASdata IMPORT; run;
```
> <b>Note</b>: The target directory (e.g. 'C:\MEPS\SAS\data') must be different from the input directory (e.g. 'C:\MEPS\data'). If not, an error may occur.


## Summary
This exercise  illustrates how to pool meps longitudinal data files from different panels.

The example used is panel 16, 17, and 18 population age 26-30 who are uninsured but have high income in the first year

Data from panels 15, 16, and 17 are pooled.
