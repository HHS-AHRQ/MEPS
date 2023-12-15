# MEPS quick reference guides

The following reference guides are provided for convenience:

[Condition Codes](#condition-codes)
<br>
[Entity Relationship Diagram](#entity-relationship-diagram)
<br>
[File names](#file-names)
<br>
[Programming Statements](#programming-statements)
<br>
[Variable Names](#variable-names)


## Condition Codes

Household-reported medical conditions in MEPS are coded into ICD-10 codes, which are then collapsed into the broader Clinical Classification Software Refined (CCSR) codes created by the Healthcare Cost and Utilization Project (HCUP). Prior to 2016, medical conditions were coded into ICD-9 codes, a predecessor to the ICD-10 codes, and were collapsed into Clinical Classification Software (CCS) codes. The HCUP website provides more information on the creation of [CCS for ICD-9 codes](https://www.hcup-us.ahrq.gov/toolssoftware/ccs/ccs.jsp) and [CCSR for ICD-10 codes](https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp).

For analytical purposes (including the creation of the [MEPS-HC Medical Conditions Data Tool](https://datatools.ahrq.gov/meps-hc/?tab=medical-conditions&dash=17)), MEPS created broader condition categories based on the CCS[R] codes. The following spreadsheets provide crosswalks between CCS[R] and MEPS collapsed condition categories, as well as descriptive labels for the 3-digit top-coded ICD variables on the MEPS Conditions files (ICD9CODX for 1996-2015; ICD10CDX for 2016 and later). The CCS[R] crosswalks also contain a Category Body System label, which is derived from the body systems defined by the CCSR codes. For collapsed categories that contain multiple CCSR body systems (e.g. "Complications of surgery or device"), the most common CCSR body system was selected as the "Category Body System".

**ICD-10/CCSR (2016 and later)**
* [meps_ccsr_conditions.csv](meps_ccsr_conditions.csv): CCSR - Collapsed Condition crosswalk 
* [meps_cond_icd10_labels.csv](meps_cond_icd10_labels.csv): Labels for ICD10CDX 

**ICD-9/CCS (1996-2015)**
* [meps_ccs_conditions.csv](meps_ccs_conditions.csv): CCS - Collapsed Condition crosswalk 
* [meps_cond_icd9_labels.csv](meps_cond_icd9_labels.csv): Labels for ICD9CODX 




### <i>Updated categories - August 2023</i>
The collapsing of the CCSR codes underwent extensive review and were updated in August 2023. This process included a systematic review with the goal of balancing continuity from the previous codes with increased precision based on natural splits in the MEPS data as well as clinical relevance. The collapsed categories were updated according to the following general guidelines:


  | Guideline                                                   | Example                                                    | Exceptions                                        |
  |------------------------------------------------------------|------------------------------------------------------------|--------------------------------------------------|
   | Collapsed Codes should not cross CCSR body systems     | All CCSR codes in "Nervous system disorders" should start with "NVS", and should not include "EAR" codes | "Complications of Surgery or Device" and "Symptoms" can cross body systems |
  | Generic or masked CCSRs (ending in "000") should be in an "Other" category | "Other diseases of circulatory system"               |                                                  |
  | Only 1 "Other" category within each body system    | "Other eye disorders" is the only "Other" category in the "EYE" body system     | "CIR" and "MUS" have more specific "Other" categories (e.g. "Other cardiovascular disease", Other conditions of circulatory system")  |
  | Add plain language to include common condition names  | Hypertension (high blood pressure); Acute bronchitis and URI (including common cold)|                                                  |
  | Combine categories with low treated prevalence* | | Categories that are rare and difficult to combine with other groups (e.g. "External cause codes", "Complications of surgery or device"); Categories that are clinically relevant or have very different expenditures (e.g. "Multiple sclerosis") |                                                  |
  | Split categories with high prevalence* |  | Generic categories will include many CCSRs |

\* prevalence is defined based on MEPS data


The collapsed categories derived from the ICD-9/CCS classifications (for 1996-2015) were *not* regrouped or recategorized during this process. However, some label changes were made for consistency with the newly-revised CCSR-based categories (e.g. "Other urinary" changed to "Other genitourinary conditions" and "Trauma-related disorders" changed to "Injury"). In addition, the category body systems were backwards mapped to apply to the CCS-based condition categories.

Older versions of the crosswalks provided above can be found in the [archive](archive) folder.




## Entity Relationship Diagram
[meps_erd.pdf](meps_erd.pdf) is a printable entity relationship diagram of the most commonly used MEPS public use files (PUFs). Short descriptions of the datasets and example programming codes in SAS, R, and Stata are available on page 2.

[<img src = "../_images/meps_erd.png" alt = "preview of ERD" width = 500>](meps_erd.pdf)

## File names
[meps_file_names.csv](meps_file_names.csv) lists the names of the MEPS Public Use Files (PUFs). These can be helpful when users are downloading MEPS datasets programatically. 

[meps_longitudinal_file_names.csv](meps_longitudinal_file_names.csv) contains the names of the MEPS Longitudinal files, where each file contains multiple rounds for a single panel.

> **Note**: Panels 23 and 24 were extended for 4 years of data collection, so these panels have 3-year and 4-year longitudinal files along with the typical 2-year files


[![preview of file names](../_images/meps_file_names.png)](meps_file_names.csv)


**Abbreviations used in file:**
* CLNK:	Condition Event Link file
* FS:	Food Security file
* FYC: 	Full-Year-Consolidated
* MOS:	Medical Organizations Survey
* PIT:	Point-in-time
* PMED:	Prescription Medicines
* PRPL: Person-Round-Plan
* PSAQ:	Preventive Care Self-Administered Questionnaire
* RXLK: Prescribed Medicines Link file


## Programming Statements
[meps_programming_statements.md](meps_programming_statements.md) offers a quick reference of programming statements needed to analyze MEPS data using survey methods in R, SAS, and Stata.
[![preview of programming statements](../_images/meps_programming_statements.png)](meps_programming_statements.md)

## Variable Names
[meps_variables.md](meps_variables.md) is a guide for identifying variable names of utilization and  expenditure variables by source of payment in the [MEPS Full-Year-Consolidated (FYC) files](https://meps.ahrq.gov/mepsweb/data_stats/download_data_files_results.jsp?cboDataYear=All&cboDataTypeY=1%2CHousehold+Full+Year+File&buttonYearandDataType=Search&cboPufNumber=All&SearchTitle=Consolidated+Data).

[![preview of variable names](../_images/meps_variables.png)](meps_variables.md)
