# -----------------------------------------------------------------------------
# This program generates the following estimates on national health care for 
# the U.S. civilian non-institutionalized population, 2018:
#  - Overall expenses (National totals)
#  - Percentage of persons with an expense
#  - Mean expense per person
#  - Mean/median expense per person with an expense:
#    - Mean expense per person with an expense
#    - Mean expense per person with an expense, by age group
#    - Median expense per person with an expense, by age group
#
# Input file:
#  - C:/MEPS/h209.dta (2018 Full-year file - Stata format)
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------

# Can skip this part if already installed
  install.packages("survey")   # for survey analysis
  install.packages("foreign")  # for loading SAS transport (.ssp) files
  install.packages("haven")    # for loading Stata (.dta) files
  install.packages("dplyr")    # for data manipulation
  install.packages("devtools") # for loading "MEPS" package from GitHub

# Run this part each time you re-start R
  library(survey)
  library(foreign)
  library(haven)
  library(dplyr)
  library(devtools)

# This package facilitates file import
  install_github("e-mitchell/meps_r_pkg/MEPS") 
  library(MEPS)

# Set options to deal with lonely psu
  options(survey.lonely.psu='adjust');


# Read in data from FYC file --------------------------------------------------
 
# Option 1: use 'MEPS' package
  fyc18 = read_MEPS(year = 2018, type = "FYC") # 2018 FYC

# Option 2: Use Stata format (recommended for Data Year 2018 and later)
  fyc18_opt2 = read_dta("C:/MEPS/h209.dta")

# View data
  head(fyc18) 
  head(fyc18_opt2)
  

# Keep only needed variables --------------------------------------------------
# - codebook: https://meps.ahrq.gov/mepsweb/data_stats/download_data_files_codebook.jsp?PUFId=H209

# Using tidyverse syntax. The '%>%' is a pipe operator, which inverts
# the order of the function call. For example, f(x) becomes x %>% f
  
  fyc18_sub = fyc18 %>%
    select(
      AGELAST, TOTEXP18,
      DUPERSID, VARSTR, VARPSU, PERWT18F) # needed for survey design
  
  head(fyc18_sub)
  
  
# Add variables for persons with any expense and persons under 65 -------------

  fyc18x = fyc18_sub %>%
    mutate(
      has_exp = (TOTEXP18 > 0),                     # persons with any expense
      age_cat = ifelse(AGELAST < 65, "<65", "65+")  # persons under age 65
    )
  
  head(fyc18x)


# QC check on new variables
  
  fyc18x %>% 
    count(has_exp, age_cat)
  
  fyc18x %>%
    group_by(has_exp) %>%
    summarise(
      min = min(TOTEXP18), 
      max = max(TOTEXP18))
  
  fyc18x %>%
    group_by(age_cat) %>%
    summarise(
      min = min(AGELAST), 
      max = max(AGELAST))


# Define the survey design ----------------------------------------------------
    
  mepsdsgn = svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT18F,
    data = fyc18x,
    nest = TRUE)

  
# Calculate estimates ---------------------------------------------------------
#  - Overall expenses (National totals)
#  - Percentage of persons with an expense
#  - Mean expense per person
#  - Mean/median expense per person with an expense:
#    - Mean expense per person with an expense
#    - Mean expense per person with an expense, by age group
#    - Median expense per person with an expense, by age group

# Overall expenses (National totals)
  svytotal(~TOTEXP18, design = mepsdsgn) 

# Percentage of persons with an expense
  svymean(~has_exp, design = mepsdsgn)

# Mean expense per person
  svymean(~TOTEXP18, design = mepsdsgn) 
  
  
# Mean/median expense per person with an expense --------------------
# Subset design object to people with expense:
  has_exp_dsgn <- subset(mepsdsgn, has_exp)
  
# Mean expense per person with an expense
  svymean(~TOTEXP18, design = has_exp_dsgn)

# Mean expense per person with an expense, by age category
  svyby(~TOTEXP18, by = ~age_cat, FUN = svymean, design = has_exp_dsgn)


# Median expense per person with an expense, by age category
  svyby(~TOTEXP18, by  = ~age_cat, FUN = svyquantile, design = has_exp_dsgn,
    quantiles = c(0.5), ci = T)
