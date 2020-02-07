# MEPS quick reference guides

The following reference guides are provided for convenience:

[Condition Codes - CCS (1996-2015)](#condition-codes-ccs-1996-2015)
<br>
[Condition Codes - CCSR (2016 and later)](#condition-codes-ccsr-2016-and-later)
<br>
[Entity Relationship Diagram](#entity-relationship-diagram)
<br>
[File names](#file-names)
<br>
[Programming Statements](#programming-statements)
<br>
[Variable Names](#variable-names)


## Condition Codes - CCS (1996-2015)

[meps_ccs_conditions.csv](meps_ccs_conditions.csv) provides a cross-reference between collapsed condition categories commonly used in MEPS analyses and the Healthcare Cost and Utilization Project's (HCUP) Clinical Classification Software (CCS) Codes. Information on how [CCS codes relate to ICD-9](https://www.hcup-us.ahrq.gov/toolssoftware/ccs/ccs.jsp) codes is available on the HCUP website.
[![preview of ccs condition codes](../_images/meps_ccs_conditions.png)](meps_ccs_conditions.csv)

For more information on Medical Condition data in MEPS, CCS codes, and collapsed condition categories, see ["Understanding and Analyzing MEPS Household Component Medical Condition Data"](https://meps.ahrq.gov/survey_comp/MEPS_condition_data.pdf) by Steven Machlin, Anita Soni, and Zhengyi Fang.


## Condition Codes - CCSR (2016 and later)

[meps_ccsr_conditions.csv](meps_ccsr_conditions.csv) provides a cross-reference between collapsed condition categories commonly used in MEPS analyses and the Healthcare Cost and Utilization Project's (HCUP) Clinical Classification Software Refined (CCSR) Codes. Information on how [CCSR codes relate to ICD-10](https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp) codes is available on the HCUP website.
[![preview of ccsr condition codes](../_images/meps_ccsr_conditions.png)](meps_ccsr_conditions.csv)






## Entity Relationship Diagram
[meps_erd.pdf](meps_erd.pdf) is a printable entity relationship diagram of the most commonly used MEPS public use files (PUFs). Short descriptions of the datasets and example programming codes in SAS, R, and Stata are available on page 2.
[<img src = "../_images/meps_erd.png" alt = "preview of ERD" width = 500>](meps_erd.pdf)

## File names
[meps_file_names.csv](meps_file_names.csv) lists the names of the MEPS Public Use Files (PUFs). These can be helpful when users are downloading MEPS datasets programatically.
[![preview of file names](../_images/meps_file_names.png)](meps_file_names.csv)

## Programming Statements
[meps_programming_statements.md](meps_programming_statements.md) offers a quick reference of programming statements needed to analyze MEPS data using survey methods in R, SAS, and Stata.
[![preview of programming statements](../_images/meps_programming_statements.png)](meps_programming_statements.md)

## Variable Names
[meps_variables.md](meps_variables.md) is a guide for identifying variable names of utilization and  expenditure variables by source of payment in the [MEPS Full-Year-Consolidated (FYC) files](https://meps.ahrq.gov/mepsweb/data_stats/download_data_files_results.jsp?cboDataYear=All&cboDataTypeY=1%2CHousehold+Full+Year+File&buttonYearandDataType=Search&cboPufNumber=All&SearchTitle=Consolidated+Data).

[![preview of variable names](../_images/meps_variables.png)](meps_variables.md)
