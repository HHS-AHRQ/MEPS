# Analyzing MEPS data using Stata

[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [SAS transport files (1996-2017)](#sas-transport-files-1996-2017)<br>
&nbsp; &nbsp; [ASCII (.dat) files](#ascii-dat-files)<br>
&nbsp; &nbsp; [Automating file download](#automating-file-download)<br>
&nbsp; &nbsp; [Saving Stata data (.dta)](#saving-stata-data-dta)<br>
[Stata `svy` commands](#stata-svy-commands)<br>
[Stata examples](#stata-examples)<br>
&nbsp; &nbsp; [Workshop Exercises](#workshop-exercises)<br>
&nbsp; &nbsp; [Summary tables examples](#summary-tables-examples)<br>

## Loading MEPS data
> <b> IMPORTANT! </b> Starting in 2018, the SAS Transport formats for MEPS Public Use Files were converted from the SAS XPORT to the SAS CPORT engine. These CPORT data files cannot be read directly into Stata at this time. The ASCII data file format (.dat) must be used instead.

Stata users can download MEPS files using the SAS transport (.ssp) format for data years 1996-2017, or the ASCII (.dat) data files. Note that the case of variable names may differ depending on which type of data file is used. Loading SAS transport (.ssp) files typically results in all lowercase variable names, while the Stata programming statements used to import ASCII (.dat) files will generally create uppercase variable names. Users may wish to use the `rename *, lower` command to convert all variables to lowercase for consistency.

### SAS transport files (1996-2017)

In Stata, SAS transport (.ssp) files can be loaded using the `import` command (for 1996-2017 PUFs). In the following example, the transport file for the 2017 Dental Visits file <b>h197b.ssp</b> has been downloaded from the MEPS website, unzipped, and saved in the local directory <b>C:\MEPS\DATA</b> (click [here](../README.md#accessing-meps-hc-data) for details).
``` stata
/* Note: for Stata version 15 or earlier, use sasxport instead of sasxport5 */

set more off
import sasxport5 "C:\MEPS\DATA\h197b.ssp"

/* View dataset */
browse
```

### ASCII (.dat) files
Starting in 2018, design changes in the MEPS survey instrument resulted in SAS transport files being converted from the XPORT to the CPORT format. These CPORT file types are not readable by Stata at this time. Thus, the ASCII (.dat) files must be used instead. The following example imports the 2018 Dental visits ASCII file (<b>h206b.dat</b>) by running the Stata programming statements provided on the MEPS website.

> IMPORTANT! The Stata programming statements in the .txt file below require that the ASCII (.dat) file is stored in the <b>C:/MEPS/DATA</b> directory. If that is not possible, the user must navigate to the Stata programming statements (.txt file) for each needed MEPS data file, and follow the instructions for loading the ASCII file into Stata. For example, for the 2018 dental visits file, instructions can be found at: https://meps.ahrq.gov/data_stats/download_data/pufs/h206b/h206bstu.txt


``` stata
set more off
do "https://meps.ahrq.gov/data_stats/download_data/pufs/h206b/h206bstu.txt"

/* View dataset */
browse

/* Optional: convert all variable names to lower-case */
rename *, lower
```

### Automating file download

Instead of having to manually download, unzip, and store MEPS data files in a local directory, it may be beneficial to automatically download MEPS data directly from the MEPS website. This can be accomplished using the `copy` and `unzipfile` commands.

The following code downloads the 2017 Dental Visits (h197b.ssp) directly from the MEPS website and stores it in the "C:/MEPS/DATA" folder. The `import` command is then used to read the .ssp file into Stata:

``` stata
/* 2017 Dental Visits */
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h197bssp.zip" ///
"C:/MEPS/DATA/h197bssp.zip"

/* Note: for Stata version 15 or earlier, use sasxport instead of sasxport5 */
unzipfile "C:/MEPS/DATA/h197bssp.zip"
import sasxport5 "h197b.ssp", clear

/* View dataset */
browse
```

This example downloads the 2018 Dental Visits file (h206b.dat) and calls the Stata programming statements from the MEPS website to load the ASCII (.dat) file.

> IMPORTANT! The Stata programming statements in the .txt file below require that the ASCII (.dat) file is stored in the <b>C:/MEPS/DATA</b> directory. If that is not possible, the user must navigate to the Stata programming statements (.txt file) for each needed MEPS data file, and follow the instructions for loading the ASCII file into Stata. For example, for the 2018 dental visits file, instructions can be found at: https://meps.ahrq.gov/data_stats/download_data/pufs/h206b/h206bstu.txt

``` stata
/* 2018 Dental Visits */
copy "https://meps.ahrq.gov/mepsweb/data_files/pufs/h206bdat.zip" ///
"C:/MEPS/DATA/h206bdat.zip"

unzipfile "C:/MEPS/DATA/h206bdat.zip"

do "https://meps.ahrq.gov/data_stats/download_data/pufs/h206b/h206bstu.txt"

/* View dataset */
browse

/* Optional: convert all variable names to lower-case */
rename *, lower

```


To download additional files programmatically, replace 'h197b' (for 1996-2017 data) or 'h206b' (for 2018 and later) with the desired filename (see [meps_files_names.csv](https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_file_names.csv) for a list of MEPS file names by data type and year).

### Saving Stata data (.dta)

Once the MEPS data has been loaded into R using either of the two previous methods, it can be saved as a permanent Stata dataset (.dta). In the following code,  the h197b dataset is saved in the 'Stata\data' folder (first create the 'Stata\data' folder if needed):
``` Stata
save "C:\MEPS\Stata\data\h197b.dta"
clear
```

## Stata `svy` commands
To analyze MEPS data using Stata, [`svy` commands](http://www.stata.com/manuals13/svysvyestimation.pdf) should be used to ensure unbiased estimates. As an example, the following code will estimate the total dental expenditures in 2017:
``` stata
use dupersid perwt17f varpsu varstr dvxp17x using "C:\MEPS\Stata\data\h197b.dta", clear
svyset varpsu [pweight=perwt17f], str(varstr)
svy: total dvxp17x
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
