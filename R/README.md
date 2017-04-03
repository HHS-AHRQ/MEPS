# Analyzing MEPS data using R

[Loading R packages](#loading-r-packages)<br>
[Loading MEPS data](#loading-meps-data)<br>
&nbsp; &nbsp; [Manually](#manually)<br>
&nbsp; &nbsp; [Programmatically](#programatically)<br>
[Survey Package in R](#survey-package-in-r)<br>
[R examples](#r-examples)

## Loading R packages

Code for this section is also available in [loading_MEPS.R](loading_MEPS.R).

To load MEPS data into R, we first need to load some additional packages. We will use the `foreign` package, which allows R to read SAS transport files. We will also install the `survey` package, which will be used to analyze MEPS data. The `install.packages` function only needs to be run once (to download the package from the internet and store it on your computer). Typically, this is done with the command `install.packages("foreign")`. The `library` function needs to be run every time you re-start your R session.
``` r
 install.packages("foreign")  # Only need to run these once
 install.packages("survey")

 library(foreign) # Run these every time you re-start R
 library(survey)
```
> **Installing and Loading Packages**: Packages are sets of R functions that are downloaded and installed into the R system. A package only needs to be installed once per R installation. However, the `library` function needs to be run every time you re-start your R session to load the package. Packages are tailor made to help perform certain statistical, graphical, or data tasks. Since R is used by many analysts, it is typical for only some packages to be loaded for each analysis.

## Loading MEPS data
Two methods for downloading MEPS transport files are available. The first requires the user to navigate to the website containing the MEPS dataset and manually download and unzip the SAS transport file. The second method uses the R function 'download.file' to automatically download the file by pointing to its location on the website.

> <b>Warning!</b> R does not preserve any SAS formats, labels, or variable types. For instance, a character variable on the SAS dataset could be read as a factor variable in the R dataset. Users are encouraged to be diligent in confirming that variables are stored as the appropriate type before proceeding with analyses.

### Manually

If the SAS transport file has been saved to a local directory, R can read the file using the `read.xport` function from the `foreign` package. In the following example, the transport file <b>h171.ssp</b> has been downloaded from the MEPS website, unzipped, and saved in the local directory <b>C:\MEPS\data</b> (click [here](./README.md#accessing-meps-hc-data) for details)
``` r
h171 = read.xport("C:/MEPS/data/h171.ssp")
```
To save the loaded data as a permanent R dataset (.Rdata), run the following code (first create the 'R\data' folders if needed):
``` r
save(h171, file="C:/MEPS/R/data/h171.Rdata")
```

> <b>Note:</b> Directory names need to be separated by a slash ("/") or a double backslash ("\\\\") in R.

### Programmatically

Data downloading tasks can also be automated using R. This offers several advantages when:

1. a large number of files need to be downloaded
2. another researcher needs to verify which files were downloaded (and from where)
3. data files might be updated periodically

To do this, use the `download.file` function to save the zip file from the MEPS website to the temporary file `temp`. To find the name of the zip file, navigate to the dataset on the MEPS website, right-click on the ZIP link, then select 'Copy link address' to copy the location to your the clipboard. Alternatively, the quick reference guide [meps_file_names.csv](./Quick_Reference_Guides/meps_file_names.csv) contains a table of the names of MEPS data files by type and year.

![](images/copy_link_address.png)

Then, paste this address into the R code below. The file location for the full-year-consolidated data from 2013 is: "https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip". Next, use the `unzip` and `read.xport` functions to unzip and load the SAS transport data into R as a data frame. The `unlink` function is used to delete the temporary file, to free up space on your computer.
``` r
download.file("https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip", temp <- tempfile())
unzipped_file = unzip(temp)
h171 = read.xport(unzipped_file)
unlink(temp)  # Unlink to delete temporary file

save(h171, file="C:/MEPS/R/data/h171.Rdata")  # save as .Rdata file
```

## Survey package in R
To analyze MEPS data using R, the [`survey` package](https://cran.r-project.org/web/packages/survey/survey.pdf) should be used to ensure unbiased estimates. The survey package contains functions for analyzing survey data by defining a **survey design object** with information about the sampling procedure, then running analyses on that object. Here are some of the functions in the survey package that are most useful for analyzing data from MEPS.

*   `svydesign`: define the survey object
*   `svytotal`: population totals
*   `svymean`: proportions and means
*   `svyquantile`: quantiles (e.g. median)
*   `svyratio`: ratio statistics (e.g. percentage of total expenditures)
*   `svyglm`: generalized linear regression
*   `svyby`: run other survey functions by group

To use functions in the survey package, the `svydesign` function specifies the primary sampling unit, the strata, and the sampling weights for the data frame. Once the survey design object is defined, population estimates can be calculated using functions from the suvey package. As an example, the following code will estimate the total healthcare expenditures in 2014:
``` r
mepsdsgn = svydesign(id = ~VARPSU,
                     strata = ~VARSTR,
                     weights = ~PERWT14F,
                     data = h171,
                     nest = TRUE)  

svytotal(~TOTEXP14, design = mepsdsgn)
```

## R examples

The following codes are provided in this folder (check back regularly for additional exercises):

[loading_MEPS.R](loading_MEPS.R): example code to download MEPS files from [the MEPS website](https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp).<br>
[example_1.R](example_1.R): code to re-create some of the estimates from the [MEPS summary table for 2013 data.](https://meps.ahrq.gov/mepsweb/data_stats/tables_compendia_hh_interactive.jsp?_SERVICE=MEPSSocket0&_PROGRAM=MEPSPGM.TC.SAS&File=HCFY2013&Table=HCFY2013_PLEXP_%40&VAR1=AGE&VAR2=SEX&VAR3=RACETH5C&VAR4=INSURCOV&VAR5=POVCAT13&VAR6=REGION&VAR7=HEALTH&VARO1=4+17+44+64&VARO2=1&VARO3=1&VARO4=1&VARO5=1&VARO6=1&VARO7=1&_Debug=).<br>
[example_2.R](example_2.R): code to re-create the data and plot for Figure 1 in [Statistical brief \#491](https://meps.ahrq.gov/data_files/publications/st491/stat491.shtml) (includes [ggplot2](http://www.r-graph-gallery.com/portfolio/ggplot2-package/) example).
