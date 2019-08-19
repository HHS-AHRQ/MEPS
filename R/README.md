# Analyzing MEPS data using R


[Loading R packages](#loading-r-packages)<br>
[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [Manually](#manually)<br>
&nbsp; &nbsp; [Programmatically](#programmatically)<br>
&nbsp; &nbsp; [Saving R data file (.Rdata)](#saving-r-data-file-rdata)<br>
[Survey Package in R](#survey-package-in-r)<br>
[R examples](#r-examples)<br>


## Loading R packages

To load and analyze MEPS data in R, additional packages are needed. Packages are sets of R functions that are downloaded and installed into the R system. A package only needs to be installed once per R installation. Typically, this is done with the `install.packages` function to download the package from the internet and store it on your computer. The `library` function needs to be run every time the R session is re-started. Packages are tailor made to help perform certain statistical, graphical, or data tasks. Since R is used by many analysts, it is typical for only some packages to be loaded for each analysis. For analyzing MEPS data, the `foreign` package allows R to read SAS transport files (.ssp), and the `survey` package is used to analyze MEPS data.

``` r
# Only need to run these once:
  install.packages("foreign")  
  install.packages("survey")

# Run these every time you re-start R:
  library(foreign)
  library(survey)
```

## Loading MEPS data
Two methods for downloading MEPS transport files are available. The first requires the user to navigate to the website containing the MEPS dataset and manually download and unzip the SAS transport file. The second method uses the R function `download.file` to automatically download the file by pointing to its location on the MEPS website.

> <b>Warning!</b> R may not preserve SAS formats, labels, or variable types. For instance, a character variable on the SAS dataset could be read as a factor variable in the R dataset. Users are encouraged to be diligent in confirming that variables are stored as the appropriate type before proceeding with analyses.

### Manually

Once the SAS transport file has been saved to a local directory, R can read the file using the `read.xport` function from the `foreign` package. In the following example, the transport file <b>h163.ssp</b> has been downloaded from the MEPS website, unzipped, and saved in the local directory <b>C:\MEPS</b> (click [here](../README.md#accessing-meps-hc-data) for details).
``` r
h163 = read.xport("C:/MEPS/h163.ssp")
```
> <b>Note:</b> Directory names need to be separated by a forward slash ("/") or a double backslash ("\\\\") in R.

### Programmatically

Alternatively, MEPS data files can be downloaded directly from the MEPS website using the `download.file` and `unzip` functions. The following code downloads the 2013 full year consolidated file (h163) directly from the MEPS website and stores it in R memory:

``` r
download.file("https://meps.ahrq.gov/mepsweb/data_files/pufs/h163ssp.zip", temp <- tempfile())
unzipped_file = unzip(temp)
h163 = read.xport(unzipped_file)
unlink(temp)  # Unlink to delete temporary file
```
The `unlink` function is used to delete the temporary file, to free up space in memory. To download additional files programmatically, replace 'h163' with the desired filename (see [meps_files_names.csv](https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_file_names.csv) for a list of MEPS file names by data type and year).

### Saving R data file (.Rdata)

Once the MEPS data has been loaded into R using either of the two previous methods, it can be saved as a permanent R dataset (.Rdata) for faster loading. In the following code, the h163 dataset is saved in the 'R/data' folder, (first create the 'R/data' folder if needed):
``` r
save(h163, file = "C:/MEPS/R/data/h163.Rdata")
```
The h163 dataset can then be loaded into subsequent R sessions using the code:
``` r
load(file = "C:/MEPS/R/data/h163.Rdata")
```


## Survey package in R
To analyze MEPS data using R, the [`survey` package](https://cran.r-project.org/web/packages/survey/survey.pdf) should be used to ensure unbiased estimates. The survey package contains functions for analyzing survey data by defining a **survey design object** with information about the sampling procedure, then running analyses on that object. Some of the functions in the survey package that are most useful for analyzing MEPS data include:

*   `svydesign`: define the survey object
*   `svytotal`: population totals
*   `svymean`: proportions and means
*   `svyquantile`: quantiles (e.g. median)
*   `svyratio`: ratio statistics (e.g. percentage of total expenditures)
*   `svyglm`: generalized linear regression
*   `svyby`: run other survey functions by group

To use functions in the survey package, the `svydesign` function specifies the primary sampling unit, the strata, and the sampling weights for the data frame. The `survey.lonely.psu='adjust'` option ensures accurate standard error estimates when analyzing subsets. Once the survey design object is defined, population estimates can be calculated using functions from the survey package. As an example, the following code will estimate total healthcare expenditures in 2013:
``` r
options(survey.lonely.psu='adjust')

mepsdsgn = svydesign(id = ~VARPSU,
                     strata = ~VARSTR,
                     weights = ~PERWT13F,
                     data = h163,
                     nest = TRUE)  

svytotal(~TOTEXP13, design = mepsdsgn)
```

## R examples

In order to run the example codes, you must download the relevant MEPS files in SAS transport format (.ssp) from the MEPS website and save them to your local computer, as described above. The codes are written under the assumption that the .ssp files are saved in the local directory "C:/MEPS/". However, you can customize the programs to point to an alternate directory.


### Workshop exercises
The following codes from previous MEPS workshops are provided in the [workshop_exercises](workshop_exercises) folder:

[exercise_1.R](workshop_exercises/exercise_1.R): National health care expenses by age group, 2016
<br>
[exercise_2.R](workshop_exercises/exercise_2.R): Purchases and expenses for narcotic analgesics or narcotic analgesic combos, 2016
<br>
[exercise_3.R](workshop_exercises/exercise_3.R): Pooling MEPS FYC files, 2015 and 2016
<br>
[exercise_4.R](workshop_exercises/exercise_4.R):  Pooling longitudinal files, panels 17-19
<br>
[ggplot_example.R](workshop_exercises/ggplot_example.R): Code to re-create the data and plot for Figure 1 in [Statistical brief \#491](https://meps.ahrq.gov/data_files/publications/st491/stat491.shtml).

### Summary tables examples

The following codes provided in the [summary_tables_examples](summary_tables_examples) folder re-create selected statistics from the [MEPS online summary tables](https://meps.ahrq.gov/mepstrends/home/):

#### Accessibility and quality of care
[care1_child_dental.R](summary_tables_examples/care1_child_dental.R): Children with dental care, by poverty status, 2016
<br>
[care2_diabetes_a1c.R](summary_tables_examples/care2_diabetes_a1c.R): Adults with diabetes receiving hemoglobin A1c blood test, by race/ethnicity, 2016
<br>
[care3_access.R](summary_tables_examples/care3_access.R): Ability to schedule a routine appointment, by insurance coverage, 2016

#### Medical conditions
[cond1_expenditures.R](summary_tables_examples/cond1_expenditures.R): Utilization and expenditures by medical condition, 2015

#### Health Insurance
[ins1_age.R](summary_tables_examples/ins1_age.R): Health insurance coverage by age group, 2016

#### Prescribed drugs
[pmed1_therapeutic_class.R](summary_tables_examples/pmed1_therapeutic_class.R): Purchases and expenditures by Multum therapeutic class, 2016
<br>
[pmed2_prescribed_drug.R](summary_tables_examples/pmed2_prescribed_drug.R): Purchases and expenditures by generic drug name, 2016

#### Use, expenditures, and population
[use1_race_sex.R](summary_tables_examples/use1_race_sex.R): Utilization and expendiutres by race and sex, 2016
<br>
[use2_expenditures.R](summary_tables_examples/use2_expenditures.R): Expenditures for office-based and outpatient visits, by source of payment, 2016
<br>
[use3_events.R](summary_tables_examples/use3_events.R): Number of events and mean expenditure per event, for office-based and outpatient events, by source of payment, 2016
