# SAS Exercise 3

## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory. Create the folder 'C:\MEPS\data' on your hard drive if it is not there:

<b>Input Files</b>:  [H171 (2014 Full-year file)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)

Next, run the following code to convert the SAS transport file (.ssp) to a SAS dataset (.sas7bdat) and save to a local directory (first create the target folder 'C:\MEPS\SAS\data' if needed):
``` sas
LIBNAME SASdata 'C:\MEPS\SAS\data';

FILENAME in_h171 'C:\MEPS\data\h171.ssp';
proc xcopy in = in_h171 out = SASdata IMPORT;
run;
```
> <b>Note</b>: The target directory (e.g. 'C:\MEPS\SAS\data') must be different from the input directory (e.g. 'C:\MEPS\data'). If not, an error may occur.


## Summary
This exercise illustrates how to construct family level variables from person level data.

There are two definitions of family unit in MEPS:
1. **CPS Family**:  ID is DUID + CPSFAMID.  Corresponding weight is FAMWT14C.
2. **MEPS Family**: ID is DUID + FAMIDYR.   Corresponding weight is FAMWT14F.

The CPS family is used in this exercise.
