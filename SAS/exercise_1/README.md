# SAS Exercise 1

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
This exercise generates the following estimates on national health care expenses by type of service, 2014:

1. Percentage distribution of expenses by type of service
2. Percentage of persons with an expense, by type of service
3. Mean expense per person with an expense, by type of service

Defined service categories are:
- Hospital inpatient
- Ambulatory services: office-based & hospital outpatient visits
- Prescribed medicines
- Dental visits
- Emergency room
- Home health care (agency & non-agency) and other (total expenditures - above expenditure categories)

<b>Note</b>: expenses include both facility and physician expenses.
