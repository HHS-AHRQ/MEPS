# Medical Expenditure Panel Survey (MEPS) <!-- omit in toc -->

This repository contains instructions and example code for loading and analyzing data from the Agency for Healthcare Research and Quality's [Medical Expenditure Panel Survey](https://meps.ahrq.gov/mepsweb/) (MEPS) <b>Household Component</b> (HC). [Quick reference guides](Quick_Reference_Guides) are also provided for convenience.

- [MEPS Workshops](#meps-workshops)
- [Survey Background](#survey-background)
- [Accessing MEPS-HC data](#accessing-meps-hc-data)
- [Analyzing MEPS-HC data](#analyzing-meps-hc-data)
- [Additional Survey Components](#additional-survey-components)
- [Contact MEPS](#contact-meps)

<b>Example code</b> for loading and analyzing MEPS data in R, SAS, and Stata is available in the following folders. These folders also include example exercises from recent MEPS workshops. In addition, the SAS folder contains exercises from older workshops (1996-2006):
 * [R](R) <br>
 * [SAS](SAS) <br>
 * [Stata](Stata) <br>

 > **Note to User**: All code provided in this repository is intended as an example for loading and analyzing MEPS data. AHRQ cannot certify the quality of your analysis. It is the user's responsibility to verify the accuracy of the results.

## MEPS Workshops

The Agency for Healthcare Research and Quality (AHRQ) conducts several workshops throughout the year. These workshops provide extended knowledge about MEPS data, practical information about usage of MEPS public use data files and an opportunity to construct analytic files with the assistance of AHRQ staff. The workshops are designed for health services researchers who have a background or interest in using national health surveys. For questions regarding MEPS Workshops, please contact Anita Soni at [WorkshopInfo@ahrq.hhs.gov](mailto:WorkshopInfo@ahrq.hhs.gov). Information on upcoming workshops is posted on the [MEPS website](https://meps.ahrq.gov/about_meps/workshops_events.jsp). Check back regularly for updates.

The agenda, presentation slides, and programming exercises for the most recent workshop are available in the [MEPS-workshop](https://github.com/HHS-AHRQ/MEPS-workshop) repository.


## Survey Background
The Medical Expenditure Panel Survey, which began in 1996, is a set of large-scale surveys of families and individuals, their medical providers (doctors, hospitals, pharmacies, etc.), and employers across the United States. The <b>MEPS Household Component (MEPS-HC)</b> survey collects information from families and individuals pertaining to medical expenditures, conditions, and events; demographics (e.g., age, ethnicity, and income); health insurance coverage; access to care; health status; and jobs held. Historically, each surveyed household was interviewed five times (rounds) over a two-year period. However, in the spring of 2020, the COVID-19 pandemic created significant challenges to in-person data collection. To offset the decrease in the number of cases for 2020 data, Panels 23 and 24 were extended to nine rounds (four years) of data collection, so that data year 2020 includes Rounds 6-7 from Panel 23, Rounds 3-5 from Panel 24, and Rounds 1-3 from Panel 25:

![MEPS over-lapping panel design](_images/panel_design.png)

The MEPS-HC is designed to produce national and regional estimates of the health care use, expenditures, sources of payment, and insurance coverage of the <b>U.S. civilian noninstitutionalized population</b>. The sample design of the survey includes weighting, stratification, clustering, multiple stages of selection, and disproportionate sampling.

## Accessing MEPS-HC data

Data from the Household Component of MEPS are [available for download as public use files](https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp). For data years 2017 and later (and also for the 2016 Medical Conditions file), .zip files for multiple file formats are available, including ASCII (.dat), SAS V9 (.sas7bdat), Stata (.dta), and Excel (.xlsx). Prior to 2017, ASCII (.dat) and SAS transport (.ssp) files are provided for all datasets. The following table summarizes the various file formats available by data year:



|Data Years         |ASCII<sup>1</sup>  <br>(.dat) |SAS XPORT <br>(.ssp) |SAS V9 (.sas7dat) <br> Stata (.dta) <br> Excel (.xlsx) |
|:-----------------|:----:|:--------:|:--:|
|2017 and later    |X     | (not recommended) <sup>2</sup>       |X   |
|2016 Medical Conditions file  |X | (not recommended) <sup>2</sup>  |X   |
|All Other 2016 files  |X     |X         |    |
|1996-2015              |X     |X         |    |


<sub><sup>1</sup> Additional programming statements with column widths, types, and names are required to read ASCII files. SAS and Stata programming statements are available for all data files. R programming statements are available for most files from data years 2018 and later.
<br><sup>2</sup> Starting with 2017 data files (and also for the 2016 Medical Conditions file), SAS Transport formats for most of the MEPS Public Use Files were converted from the SAS XPORT to the SAS CPORT engine. Importing XPORT and CPORT files into SAS requires different procedures. In addition, CPORT data files cannot be read directly into R or Stata; alternative file formats must be used. More details are available in the sub-folders for each programming language.</sub>

Zip files of each data format can be downloaded from the web page for each MEPS public use file. 

![GIF of file download](_images/download-video.gif)

The steps for loading the MEPS files into [R](R), [SAS](SAS), and [Stata](Stata), depends on the file type being used. Details for loading MEPS data in these languages are available in the corresponding folders.


## Analyzing MEPS-HC data
The complex survey design of MEPS requires special methods for analyzing MEPS data. These tools are available in many common programming languages. Failure to account for the survey design can result in biased estimates. Details and examples of using the appropriate survey methods are provided in the [R](R), [SAS](SAS), and [Stata](Stata) folders. Additional examples comparing these three languages can be found in the quick reference guide [meps_programming_statements.md](Quick_Reference_Guides/meps_programming_statements.md).

#### Sample size and precision <!-- omit in toc -->

When analyzing MEPS data, it is the user's responsibility to ensure that sample sizes and precision are adequate for the user's purposes. Please refer to [AHRQ's guidelines](https://meps.ahrq.gov/survey_comp/precision_guidelines.shtml) for specific recommendations.

#### MEPS variables across the years <!-- omit in toc -->

When analyzing multiple years of MEPS data, it is important to note that MEPS variable names may differ across years. Here are just a few examples:

* 1996: Round-specific variables have only one round number (e.g. AGE2X instead of AGE42X)
* 1996-1998: PERWT variable is WTDPERyy (yy = '96', '97', '98')
* 1996-2001: VARPSU variable has 2-digit year at end (e.g. VARPSU96)
* 2018 and later: Panel number is appended to the beginning of Person ID variable (DUPERSID)

The <b>[MEPS-HC Variable Explorer Tool](https://datatools.ahrq.gov/meps-hc#varExp)</b> can be used to search variables and labels across the years of the most commonly used MEPS public-use files. For detailed information on variables in a specific file, refer to the documentation and codebook that is provided with each data file.


## Additional Survey Components

In addition to the Household Component (MEPS-HC), MEPS is comprised of two additional components: The <b>MEPS Medical Provider Component (MEPS-MPC)</b> and the <b>MEPS Insurance Component (MEPS-IC)</b>. The MEPS-MPC survey collects information from providers of medical care that supplements the information collected from persons in the MEPS-HC sample in order to provide the most accurate cost data possible. The MEPS-IC survey collects information from employers in the private sector and state and local governments on the health insurance coverage offered to their employees. It also includes information on the number and types of private health insurance plans offered, benefits associated with these plans, annual premiums and contributions to premiums by employers and employees, copayments and coinsurance, by various employer characteristics (for example, State, industry and firm size). Interactive summary tables as well as complete PDF links of the table series are available at the  [MEPS-IC Data Tools page](https://datatools.ahrq.gov/meps-ic). Additional information about the MEPS-IC can be found at the [MEPS Website](https://meps.ahrq.gov/mepsweb/survey_comp/Insurance.jsp).

Special permissions are required to access microdata from the MPC and IC components. Access to the MEPS-MPC data can be requested from the [AHRQ data center](https://meps.ahrq.gov/mepsweb/data_stats/onsite_datacenter.jsp). For MEPS-IC data, researchers with approved projects can access the data at one of the [Federal Statistical Research Data Centers](https://www.census.gov/content/census/en/about/adrm/fsrdc/locations.html). If you would like to use MEPS-IC data, please contact AHRQ so that we can assist you with your request.

## Contact MEPS

Please review the [Frequently Asked Questions](https://meps.ahrq.gov/mepsweb/about_meps/faq_results.jsp?ChooseTopic=All+Categories&keyword=&Submit2=Search) on our website before contacting us to see if we already have an answer to your question. Also read our [Privacy Policy](https://meps.ahrq.gov/mepsweb/privacy_policy.jsp) for answers to any questions you may have about the use of your e-mail address.

You can contact us by e-mail, mail, or telephone:

<b>MEPS Project Director</b><br>
Medical Expenditure Panel Survey<br>
Agency for Healthcare Research and Quality<br>
5600 Fishers Lane<br>
Rockville, MD 20857<br>
[mepsprojectdirector@ahrq.hhs.gov](mailto:mepsprojectdirector@ahrq.hhs.gov)<br>
(301) 427-1406<br>
