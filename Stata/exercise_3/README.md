# Stata Exercise 3

## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory (e.g. 'C:\MEPS\data'):

<b>Input Files</b>: [H171  (2014 Full year consolidated PUF)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)

Next, run the following code to convert the transport file (.ssp) to a Stata dataset (.dta) and save to a local directory (first create the target folder 'C:\MEPS\Stata\data' if needed):
``` stata
import sasxport "C:\MEPS\data\h171.ssp"
compress
save "C:\MEPS\Stata\data\h171.dta"
clear
```

## Summary
This exercise illustrates how to construct family level variables from person level data.

There are two definitions of family unit in MEPS:
1. **CPS Family**:  ID is DUID + CPSFAMID.  Corresponding weight is FAMWT14C.
2. **MEPS Family**: ID is DUID + FAMIDYR.   Corresponding weight is FAMWT14F.

The CPS family is used in this exercise.
