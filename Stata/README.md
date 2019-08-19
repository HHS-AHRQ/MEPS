# Analyzing MEPS data using Stata

[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [Manually](#manually)<br>
&nbsp; &nbsp; [Programmatically](#programmatically)<br>
&nbsp; &nbsp; [Saving Stata data file (.dta)](#saving-stata-data-file-dta)<br>
[Stata `svy` commands](#stata-svy-commands)<br>
[Stata examples](#stata-examples)<br>


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


## Stata examples

In order to run the example codes, you must download the relevant MEPS files from the MEPS website and save them to your local computer, as described above.

### Workshop exercises
The following example codes from previous MEPS workshops are provided in the [workshop_exercises](workshop_exercises) folder:

#### 1. National health care expenses
[Exercise1a.do](workshop_exercises/Exercise1a.do): National health care expenses by age group, 2016
<br>
[Exercise1b.do](workshop_exercises/Exercise1b.do): National health care expenses by age group and type of service, 2015
<br>

#### 2. Prescribed medicine purchases
[Exercise2a.do](workshop_exercises/Exercise2a.do): Trends in antipsychotics purchases and expenses, 2015
<br>
[Exercise2b.do](workshop_exercises/Exercise2b.do): Purchases and expenses for narcotic analgesics or narcotic analgesic combos, 2016

#### 3. Medical conditions
[Exercise3a.do](workshop_exercises/Exercise3a.do): Use and expenditures for persons with diabetes, 2015
<br>
[Exercise3b.do](workshop_exercises/Exercise3b.do): Expenditures for all events associated with diabetes, 2015
<br>

#### 4. Pooling data files
[Exercise4a.do](workshop_exercises/Exercise4a.do): Pooling MEPS FYC files, 2015 and 2016
<br>
[Exercise4b.do](workshop_exercises/Exercise4b.do): Pooling longitudinal files, panels 17-19

#### 5. Constructing variables
[Exercise5a.do](workshop_exercises/Exercise5a.do): Constructing family-level variables from person-level data, 2015
<br>
[Exercise5b.do](workshop_exercises/Exercise5b.do): Constructing insurance status from monthly insurance variables, 2015


### Summary tables examples

The following codes provided in the [summary_tables_examples](summary_tables_examples) folder re-create selected statistics from the [MEPS online summary tables](https://meps.ahrq.gov/mepstrends/home/). These example codes are written under the assumption that the .ssp files are saved in the local directory "C:/MEPS/". However, you can customize the programs to point to an alternate directory.

#### Accessibility and quality of care
[care1_child_dental.do](summary_tables_examples/care1_child_dental.do): Children with dental care, by poverty status, 2016
<br>
[care2_diabetes_a1c.do](summary_tables_examples/care2_diabetes_a1c.do): Adults with diabetes receiving hemoglobin A1c blood test, by race/ethnicity, 2016
<br>
[care3_access.do](summary_tables_examples/care3_access.do): Ability to schedule a routine appointment, by insurance coverage, 2016

#### Medical conditions
[cond1_expenditures.do](summary_tables_examples/cond1_expenditures.do): Utilization and expenditures by medical condition, 2015

#### Health Insurance
[ins1_age.do](summary_tables_examples/ins1_age.do): Health insurance coverage by age group, 2016

#### Prescribed drugs
[pmed1_therapeutic_class.do](summary_tables_examples/pmed1_therapeutic_class.do): Purchases and expenditures by Multum therapeutic class, 2016
<br>
[pmed2_prescribed_drug.do](summary_tables_examples/pmed2_prescribed_drug.do): Purchases and expenditures by generic drug name, 2016

#### Use, expenditures, and population
[use1_race_sex.do](summary_tables_examples/use1_race_sex.do): Utilization and expendiutres by race and sex, 2016
<br>
[use2_expenditures.do](summary_tables_examples/use2_expenditures.do): Expenditures for office-based and outpatient visits, by source of payment, 2016
<br>
[use3_events.do](summary_tables_examples/use3_events.do): Number of events and mean expenditure per event, for office-based and outpatient events, by source of payment, 2016
