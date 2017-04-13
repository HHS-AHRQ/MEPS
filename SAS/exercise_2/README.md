# SAS Exercise 2


## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory. Create the folder 'C:\MEPS\data' on your hard drive if it is not there:

<b>Input Files</b>:
<br>[H171  (2014 Full year consolidated PUF)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)
<br>[H168A (2014 Prescribed medicines PUF)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168assp.zip)

Next, run the following code to convert the SAS transport file (.ssp) to a SAS dataset (.sas7bdat) and save to a local directory (first create the target folder 'C:\MEPS\SAS\data' if needed):
``` sas
LIBNAME SASdata 'C:\MEPS\SAS\data';

FILENAME in_h171 'C:\MEPS\data\h171.ssp';
FILENAME in_h168a 'C:\MEPS\data\h168a.ssp';

proc xcopy in = in_h171 out = SASdata IMPORT; run;
proc xcopy in = in_h168a out = SASdata IMPORT; run;
```
> <b>Note</b>: The target directory (e.g. 'C:\MEPS\SAS\data') must be different from the input directory (e.g. 'C:\MEPS\data'). If not, an error may occur.


## Summary
This exercise generates selected estimates for a 2014 version of the meps statistics brief \#275: [<i>Trends in Antipsychotics Purchases and Expenses for the U.S. Civilian Noninstitutionalized Population, 1997 and 2007</i>](https://meps.ahrq.gov/data_files/publications/st275/stat275.shtml)

1. **Figure 1**: Total expense for antipsychotics
2. **Figure 2**: Total number of purchases of antipsychotics
3. **Figure 3**: Total number of persons purchasing one or more antipsychotics
4. **Figure 4**: Average total out of pocket and third party payer expense for antipsychotics per person with an antipsychotic medicine purchase
