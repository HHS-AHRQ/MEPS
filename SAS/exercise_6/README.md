# SAS Exercise 6

Use the following links to download the data .zip files (see ['Loading MEPS data'](../README.md#loading-meps-data) for instructions on loading the .ssp files into SAS):

**Input Files**:  
[H171 (2014 Full-year file)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)
<br>[H163 (2013 Full-year file)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h163ssp.zip)


This program illustrates how to pool meps data files from different years the example used is population age 26-30 who are uninsured but have high income.

Data from 2013 and 2014 are pooled.

Variables with year specific names must be renamed before combining files in this program the insurance coverage variables 'INSCOV13' and 'INSCOV14' are renamed to 'INSCOV'.

See HC-036 (1996-2014 POOLED ESTIMATION FILE) For instructions on poooling and considerations for variance estimation for pre 2002 data
