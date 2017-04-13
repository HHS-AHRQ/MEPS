# Stata Exercise 6


## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory (e.g. 'C:\MEPS\data'):

**Input Files**:  
[H171 (2014 Full-year file)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)
<br>[H163 (2013 Full-year file)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h163ssp.zip)

Next, run the following code to convert the transport files (.ssp) to Stata datasets (.dta) and save to a local directory (first create the target folder 'C:\MEPS\Stata\data' if needed):
``` stata
clear
import sasxport "C:\MEPS\data\h171.ssp"
save "C:\MEPS\Stata\data\h171.dta", replace
clear

import sasxport "C:\MEPS\data\h163.ssp"
save "C:\MEPS\Stata\data\h163.dta", replace
clear
```

## Summary
This exercise  illustrates how to pool meps data files from different years the example used is population age 26-30 who are uninsured but have high income.

Data from 2013 and 2014 are pooled.

Variables with year specific names must be renamed before combining files in this program the insurance coverage variables 'INSCOV13' and 'INSCOV14' are renamed to 'INSCOV'.

See HC-036 (1996-2014 POOLED ESTIMATION FILE) For instructions on poooling and considerations for variance estimation for pre 2002 data
