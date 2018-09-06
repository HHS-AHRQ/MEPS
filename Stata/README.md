# Analyzing MEPS data using Stata

[Stata examples](#stata-examples)<br>
[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [Manually](#manually)<br>
&nbsp; &nbsp; [Programmatically](#programmatically)<br>
&nbsp; &nbsp; [Saving SAS data](#saving-sas-data)<br>
[Stata `svy` commands](#stata-svy-commands)<br>


## Stata examples

The following example codes are provided in this folder.

[Exercise1.do](Exercise1.do): National health care expenses by type of service, 2015
<br>
[Exercise2.do](Exercise2.do): Trends in antipsychotics purchases and expenses, 2015
<br>
[Exercise3.do](Exercise3.do): Constructing family-level variables from person-level data, 2015
<br>
[Exercise4.do](Exercise4.do): Use and expenditures for persons with diabetes, 2015
<br>
[Exercise5.do](Exercise5.do): Expenditures for all events associated with diabetes, 2015
<br>
[Exercise6.do](Exercise6.do): Pooling MEPS FYC files, 2014 and 2015
<br>
[Exercise7.do](Exercise7.do): Constructing insurance status from monthly insurance variables, 2015
<br>
[Exercise8.do](Exercise8.do): Pooling longitudinal files, panels 17-19

## Loading MEPS data

Two methods for downloading MEPS files into Stata are available. The first requires the user to navigate to the website containing the MEPS dataset and manually download and unzip the SAS transport file. The second method uses the `copy` and `unzipfile` commands to automatically download the file by pointing to its location on the MEPS website.

### Manually

In Stata, SAS transport (.ssp) files can be loaded using the `import` command. In the following example, the transport file <b>h171.ssp</b> has been downloaded from the MEPS website, unzipped, and saved in the local directory <b>C:\MEPS</b> (click [here](../README.md#accessing-meps-hc-data) for details).
``` stata
set more off
import sasxport "C:\MEPS\h171.ssp"
```

### Programmatically

Alternatively, Stata can download MEPS data directly from the MEPS website using the `copy` and `unzipfile` commands. The following code downloads the 2014 full year consolidated file (h171) directly from the MEPS website and stores it in Stata memory:

``` stata
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip" "h171ssp.zip"
unzipfile "h171ssp.zip"
import sasxport "h171.ssp", clear

browse /* View dataset */
```
To download additional files programmatically, replace 'h171' with the desired filename (see [meps_files_names.csv](https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_file_names.csv) for a list of MEPS file names by data type and year).

### Saving Stata data file (.dta)

Once the MEPS data has been loaded into R using either of the two previous methods, it can be saved as a permanent Stata dataset (.dta). In the following code,  the h171 dataset is saved in the 'Stata\data' folder (first create the 'Stata\data' folder if needed):
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
