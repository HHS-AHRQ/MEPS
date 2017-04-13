# SAS Exercise 6

## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory. Create the folder 'C:\MEPS\data' on your hard drive if it is not there:

**Input Files**:  
[H171 (2014 Full-year file)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)
<br>[H163 (2013 Full-year file)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h163ssp.zip)

Next, run the following code to convert the SAS transport file (.ssp) to a SAS dataset (.sas7bdat) and save to a local directory (first create the target folder 'C:\MEPS\SAS\data' if needed):
``` sas
LIBNAME SASdata 'C:\MEPS\SAS\data';

FILENAME in_h171 'C:\MEPS\data\h171.ssp';
FILENAME in_h163 'C:\MEPS\data\h163.ssp';

proc xcopy in = in_h171 out = SASdata IMPORT; run;
proc xcopy in = in_h163 out = SASdata IMPORT; run;
```
> <b>Note</b>: The target directory (e.g. 'C:\MEPS\SAS\data') must be different from the input directory (e.g. 'C:\MEPS\data'). If not, an error may occur.


## Summary
This exercise illustrates how to pool meps data files from different years the example used is population age 26-30 who are uninsured but have high income.

Data from 2013 and 2014 are pooled.

Variables with year specific names must be renamed before combining files in this program the insurance coverage variables 'INSCOV13' and 'INSCOV14' are renamed to 'INSCOV'.

See HC-036 (1996-2014 POOLED ESTIMATION FILE) For instructions on poooling and considerations for variance estimation for pre 2002 data
