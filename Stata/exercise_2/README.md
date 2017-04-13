# Stata Exercise 2


## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory (e.g. 'C:\MEPS\data'):

<b>Input Files</b>:
<br>[H171  (2014 Full year consolidated PUF)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)
<br>[H168A (2014 Prescribed medicines PUF)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h168assp.zip)


Next, run the following code to convert the transport files (.ssp) to Stata datasets (.dta) and save to a local directory (first create the target folder 'C:\MEPS\Stata\data' if needed):
``` stata
clear
import sasxport "C:\MEPS\data\h171.ssp"
save "C:\MEPS\Stata\data\h171.dta", replace
clear

import sasxport "C:\MEPS\data\h168a.ssp"
save "C:\MEPS\Stata\data\h168a.dta", replace
clear
```

## Summary
This exercise generates selected estimates for a 2014 version of the meps statistics brief \#275: <i>Trends in Antipsychotics Purchases and Expenses for the U.S. Civilian Noninstitutionalized Population, 1997 and 2007</i>

1. **Figure 1**: Total expense for antipsychotics
2. **Figure 2**: Total number of purchases of antipsychotics
3. **Figure 3**: Total number of persons purchasing one or more antipsychotics
4. **Figure 4**: Average total out of pocket and third party payer expense for antipsychotics per person with an antipsychotic medicine purchase
