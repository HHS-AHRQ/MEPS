# Stata Exercise 8

## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory (e.g. 'C:\MEPS\data'):

**Input Files**:
<br>[H172 (Panel 18 Longitudinal File)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h172ssp.zip)
<br>[H164 (Panel 17 Longitudinal File)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h164ssp.zip)
<br>[H156 (Panel 16 Longitudinal File)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h156ssp.zip)


Next, run the following code to convert the transport files (.ssp) to Stata datasets (.dta) and save to a local directory (first create the target folder 'C:\MEPS\Stata\data' if needed):
``` stata
clear
import sasxport "C:\MEPS\data\h172.ssp"
save "C:\MEPS\Stata\data\h172.dta", replace
clear

import sasxport "C:\MEPS\data\h164.ssp"
save "C:\MEPS\Stata\data\h164.dta", replace
clear

import sasxport "C:\MEPS\data\h156.ssp"
compress
save "C:\MEPS\Stata\data\h156.dta"
clear
```
> <b>IMPORTANT!</b> If you are using the IC version of Stata, download the .dta files with the '_IC' extension included in this folder. The files and the line numbers are: [h172_IC.dta](https://github.com/HHS-AHRQ/MEPS/raw/master/Stata/exercise_8/h172_IC.dta) (line 23), [h164_IC.dta](https://github.com/HHS-AHRQ/MEPS/raw/master/Stata/exercise_8/h164_IC.dta) (line 27), and [h156_IC.dta](https://github.com/HHS-AHRQ/MEPS/raw/master/Stata/exercise_8/h156_IC.dta) (line 31). These files have been created with fewer variables, since the IC version of Stata is limited to loading data files with 2,047 variables. Make sure to edit the code in the .do file to reflect these file names.

## Summary
This exercise illustrates how to pool meps longitudinal data files from different panels.

The example used is panel 16, 17, and 18 population age 26-30 who are uninsured but have high income in the first year

Data from panels 15, 16, and 17 are pooled.
