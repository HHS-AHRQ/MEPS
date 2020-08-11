# Analyzing MEPS data using R


[Loading R packages](#loading-r-packages)<br>
[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [Using the `MEPS` package (all data years)](#using-the-meps-package-all-data-years)<br>
&nbsp; &nbsp; [Using the `foreign` package (1996-2017)](#using-the-foreign-package-1996-2017)<br>
&nbsp; &nbsp; [Using the `readr` package (2018 and later)](#using-the-readr-package-2018-and-later)<br>
&nbsp; &nbsp; [Automating file download](#automating-file-download)<br>
&nbsp; &nbsp; [Saving R data (.Rdata)](#saving-r-data-rdata)<br>
[Survey Package in R](#survey-package-in-r)<br>
[R examples](#r-examples)<br>
&nbsp; &nbsp; [Workshop Exercises](#workshop-exercises)<br>
&nbsp; &nbsp; [Summary tables examples](#summary-tables-examples)<br>

## Loading R packages

To load and analyze MEPS data in R, additional packages are needed. Packages are sets of R functions that are downloaded and installed into the R system. A package only needs to be installed once per R installation. Typically, this is done with the `install.packages` function to download the package from the internet and store it on your computer. The `library` function needs to be run every time the R session is re-started. Packages are tailor-made to help perform certain statistical, graphical, or data tasks. Since R is used by many analysts, it is typical for only some packages to be loaded for each analysis.

``` r
# Only need to run these once:
  install.packages("foreign")  
  install.packages("survey")
  install.packages("devtools")
  install.packages("tidyverse")

# Run these every time you re-start R:
  library(foreign)
  library(survey)
  library(devtools)
  library(tidyverse)
```

## Loading MEPS data

> <b> IMPORTANT! </b> Starting in 2018, the SAS Transport formats for MEPS Public Use Files were converted from the SAS XPORT to the SAS CPORT engine. These CPORT data files cannot be read directly into R. The ASCII data file format (.dat) must be used instead.

Several methods are available for importing MEPS public use files (PUFs) into R. The easiest method is to use the `read_MEPS` function from the [`MEPS` package](https://github.com/e-mitchell/meps_r_pkg)</b>, which was created to facilitate loading and manipulation of MEPS PUFs. Alternatively, R users can use the `read.xport` function from the `foreign` package to import SAS transport (.ssp) files from data years 1996-2017, or the `read_fwf` function from the `readr` package to import ASCII (.dat) files from data years 2018 and later.

### Using the `MEPS` Package (all data years)

The MEPS R Package was created to facilitate loading and manipulation of MEPS PUFs. It can be installed using the following commands:
``` r
library(devtools)

install_github("e-mitchell/meps_r_pkg/MEPS")
library(MEPS)
```

The `read_MEPS` function can then be used to import MEPS data into R, either directly from the MEPS website, or from a local directory. This function automatically detects the best file format (.ssp or .dat) to import based on the specified data year.

In the following example, the 2017 (h197b) and 2018 (h206b) Dental visits files are automatically downloaded from the MEPS website and imported into R. Either the file name or the year and MEPS data type can be specified:

``` r
# Specifying year and MEPS data type
dn2017 <- read_MEPS(year = 2017, type = "DV")
dn2018 <- read_MEPS(year = 2018, type = "DV")

# Specifying MEPS file name
dn2017 <- read_MEPS(file = "h197b")
dn2018 <- read_MEPS(file = "h206b")

```

Files can also be read from a local folder using the 'dir' argument. This method is faster, since the file has already been downloaded. In the following example, the 2017 and 2018 Dental visits files have already been manually downloaded, unzipped, and stored in the local directory <b>C:/MEPS</b>:
``` r
dn2017 <- read_MEPS(year = 2017, type = "DV", dir = "C:/MEPS")
dn2018 <- read_MEPS(year = 2018, type = "DV", dir = "C:/MEPS")
```

For users that prefer not to use the MEPS R package to load MEPS public use files, care must be taken to ensure that the correct version of the file is being imported in accordance with the data year, as detailed in the next sections.


### Using the `foreign` package (1996-2017)

The preferred file format for downloading MEPS public use files from data years 1996-2017 is the SAS transport file format (.ssp). These files can be read into R using the `read.xport` function from the `foreign` package. In the following example, the transport file <b>h197b.ssp</b> has been downloaded from the MEPS website, unzipped, and saved in the local directory <b>C:/MEPS</b> (click [here](../README.md#accessing-meps-hc-data) for details).

```r
dn2017 <- read.xport("C:/MEPS/h197b.ssp")
```

### Using the `readr` package (2018 and later)
Starting in 2018, design changes in the MEPS survey instrument resulted in SAS transport files being converted from the XPORT to the CPORT format. These CPORT file types are not readable by R. Thus, the ASCII (.dat) files must be used instead.

<i> At this time, the R programming statements are being finalized, but have not been published to the MEPS website. </i> The following code pulls the needed information about the ASCII file from the Stata programming statements, including variable names, formats, and positions. The `read_fwf` function is then used to read the ASCII file using the specified information. In the following example, the transport file <b>h206b.dat</b> has been downloaded from the MEPS website, unzipped, and saved in the local directory <b>C:/MEPS</b> (click [here](../README.md#accessing-meps-hc-data) for details).

``` r
# Set file name
filename <- "h206b"

# Read in ASCII data info from Stata programming statements
foldername <- filename %>% gsub("f[0-9]+", "", .)
stata_commands <-
  readLines(sprintf("https://meps.ahrq.gov/data_stats/download_data/pufs/%s/%sstu.txt",
                    foldername, filename))

infix_start <- which(stata_commands == "infix")
infix_end  <-  which(tolower(stata_commands) == sprintf("using %s.dat;", filename))
infix_data <- stata_commands[(infix_start + 1):(infix_end - 1)]

# Convert text data into data frame
infix_df <- infix_data %>%
  str_trim %>%
  gsub("-\\s+", "-", .) %>%
  tibble::as_tibble() %>%
  separate(
    value,
    into = c("var_type", "var_name", "start", "end"),
    sep = "\\s+|-", fill = "left") %>%
  mutate(var_type = replace_na(var_type, "double"))

# Extract positions, names, and variable types
pos_start <- infix_df %>% pull(start) %>% as.numeric
pos_end <- infix_df %>% pull(end) %>% as.numeric
cnames <- infix_df %>% pull(var_name)
ctypes <- infix_df %>% mutate(
  typeR = case_when(
    var_type %in% c("str") ~ "c",
    var_type %in% c("long", "int", "byte", "double") ~ "n",
    TRUE ~ "ERROR")) %>%
  pull(typeR) %>%
  setNames(cnames)

dn2018 <- read_fwf(
  "C:/MEPS/h206b.dat",
  col_positions =
    fwf_positions(
      start = pos_start,
      end   = pos_end,
      col_names = cnames),
  col_types = ctypes)
```

### Automating file download

Instead of having to manually download, unzip, and store MEPS data files in a local directory, it may be beneficial to automatically download MEPS data directly from the MEPS website. This can be accomplished using the `download.file` and `unzip` functions. The following code downloads and unzips the 2017 dental visits file, and stores it in a temporary folder (alternatively, the .ssp file can be stored permanently by editing the `exdir` argument). The .ssp file can then be loaded into R using the `read.xport` function:
``` r
# Download .ssp file
url <- "https://meps.ahrq.gov/mepsweb/data_files/pufs/h197bssp.zip"
download.file(url, temp <- tempfile())

# Unzip and save .ssp file to temporary folder
meps_file <- unzip(temp, exdir = tempdir())

# Alternatively, this will save a permanent copy of hte .ssp file to the local folder "C:/MEPS/R-downloads"
# meps_file <- unzip(temp, exdir = "C:/MEPS/R-downloads")

# Read the .ssp file into R
dn2017 <- read.xport(meps_file)
```

To download additional files programmatically, replace 'h197b' with the desired filename (see [meps_files_names.csv](https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_file_names.csv) for a list of MEPS file names by data type and year).

### Saving R data (.Rdata)

Once the MEPS data has been loaded into R using either of the two previous methods, it can be saved as a permanent R dataset (.Rdata) for faster loading. In the following code, the h197b dataset is saved in the 'R/data' folder, (first create the 'R/data' folder if needed):
``` r
save(dn2017, file = "C:/MEPS/R/data/h197b.Rdata")
```
The h197b dataset can then be loaded into subsequent R sessions using the code:
``` r
load(file = "C:/MEPS/R/data/h197b.Rdata")
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

To use functions in the survey package, the `svydesign` function specifies the primary sampling unit, the strata, and the sampling weights for the data frame. The `survey.lonely.psu='adjust'` option ensures accurate standard error estimates when analyzing subsets. Once the survey design object is defined, population estimates can be calculated using functions from the survey package. As an example, the following code will estimate total dental expenditures in 2017:
``` r
options(survey.lonely.psu='adjust')

mepsdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT17F,
  data = dn2017,
  nest = TRUE)  

svytotal(~DVXP17X, design = mepsdsgn)
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
