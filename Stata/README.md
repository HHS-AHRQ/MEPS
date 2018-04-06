# Analyzing MEPS data using Stata
[Loading MEPS data](#loading-meps-data)<br>
[Stata `svy` commands](#stata-svy-commands)<br>
[Stata exercises](#stata-exercises)

## Loading MEPS data
In Stata, transport (.ssp) files can be loaded using the `import` function. In the following example, the transport file <b>h171.ssp</b> has been downloaded from the MEPS website, unzipped, and saved in the local directory <b>C:\MEPS\data</b> (click [here](../README.md#accessing-meps-hc-data) for details)
``` stata
set more off
import sasxport "C:\MEPS\data\h171.ssp"
```

To save the loaded data as a permanent Stata dataset (.dta), run the following code (first create the 'Stata\data' folders if needed):
``` Stata
save "C:\MEPS\Stata\data\h171.dta"
clear
```

## Stata `svy` commands
To analyze MEPS data using Stata, [`svy` commands](http://www.stata.com/manuals13/svysvyestimation.pdf) should be used to ensure unbiased estimates. As an example, the following code will estimate the total healthcare expenditures in 2014:
``` stata
use dupersid perwt14f varpsu varstr totexp14 using "C:\MEPS\Stata\data\h171.dta", clear
svyset varpsu [pweight=perwt14f], str(varstr)
svy: total totexp14
```
