# -----------------------------------------------------------------------------
# This program illustrates how to pool MEPS data files from different years. It
# highlights one example of a discontinuity that may be encountered when 
# working with data from before and after the 2018 CAPI re-design.
# 
# The program pools 2017 and 2018 data and calculates:
#  - Percentage of people with Joint Pain / Arthritis (JTPAIN**, ARTHDX)
#  - Average expenditures per person, by Joint Pain status (TOTEXP, TOTSLF)
#
# Notes:
#  - Variables with year-specific names must be renamed before combining files
#    (e.g. 'TOTEXP17' and 'TOTEXP18' renamed to 'totexp')
#
#  - For pre-2002 data, see HC-036 (1996-2017 pooled estimation file) for 
#    instructions on pooling and considerations for variance estimation.
#
# Input files: 
#  - C:/MEPS/h209.dat (2018 Full-year file)
#  - C:/MEPS/h201.dat (2017 Full-year file)
#
# This program is available at:
# https://github.com/HHS-AHRQ/MEPS-workshop/tree/master/r_exercises
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------
# 
#   # Can skip this part if already installed
#   install.packages("survey")
#   install.packages("foreign")
#   install.packages("dplyr")
#   install.packages("devtools")
#   
#   # Run this part each time you re-start R
#   library(survey)
#   library(foreign)
#   library(dplyr)
#   library(devtools)
#   
#   # This package facilitates file import
#   install_github("e-mitchell/meps_r_pkg/MEPS") 
#   library(MEPS)

# Set options to deal with lonely psu
  options(survey.lonely.psu='adjust');


# Read in data from FYC file --------------------------------------------------
#  !! IMPORTANT -- must use ASCII (.dat) file for 2017 and 2018 FYC files !!

  fyc18 = read_MEPS(year = 2018, type = "FYC") # 2018 FYC
  fyc17 = read_MEPS(year = 2017, type = "FYC") # 2017 FYC


# View data -------------------------------------------------------------------
# JTPAIN** and ARTHDX values
#  -15 = Cannot be computed (2018 and later)
#   -9 = Not ascertained (pre-2018)
#   -8 = Don't know
#   -7 = Refused
#   -1 = Inapplicable
#    1 = Yes
#    2 = No


# In 2018, DUPERSID now has PANEL as first 2 digits
fyc17 %>% select(PANEL, DUPERSID, starts_with("JTPAIN"), ARTHDX)
fyc18 %>% select(PANEL, DUPERSID, starts_with("JTPAIN"), ARTHDX)


# In 2018, most people that report Arthritis (ARTHDX = '1 Yes') have 
#  JTPAIN31_M18 = '-1 Inapplicable' (due to new skip pattern)
fyc17 %>% filter(ARTHDX == 1) %>% count(ARTHDX, JTPAIN31) 
fyc18 %>% filter(ARTHDX == 1) %>% count(ARTHDX, JTPAIN31_M18) 


# Create variables ------------------------------------------------------------
#  - any_jtpain = "1 YES" if JTPAIN** = 1 OR ARTHDX = 1
#  - any_jtpain = "Missing" if JTPAIN < 0 AND ARTHDX < 0 

fyc18x <- fyc18 %>% 
  mutate(any_jtpain = case_when(
    JTPAIN31_M18 == 1 | ARTHDX == 1 ~ "1 Yes",
    JTPAIN31_M18 < 0  & ARTHDX < 0 ~ "Missing",
    TRUE ~ "2 No"))


fyc17x <- fyc17 %>% 
  mutate(any_jtpain = case_when(
    JTPAIN31 == 1 | ARTHDX == 1 ~ "1 Yes",
    JTPAIN31 < 0  & ARTHDX < 0 ~ "Missing",
    TRUE ~ "2 No"))


# QC variables:
fyc18x %>% 
  # filter(AGELAST >= 18) %>%   
  count(any_jtpain, JTPAIN31_M18, ARTHDX)

fyc17x %>% 
  # filter(AGELAST >= 18) %>%
  count(any_jtpain, JTPAIN31, ARTHDX) %>%
  print(n = 50)


# Rename year-specific variables prior to combining ---------------------------

fyc18p = fyc18x %>%
  rename(
    perwt  = PERWT18F,
    totslf = TOTSLF18,
    totexp = TOTEXP18) %>%
  select(DUPERSID, VARSTR, VARPSU, AGELAST, perwt, totslf, totexp, matches("JTPAIN"))

fyc17p = fyc17x %>%
  rename(
    perwt  = PERWT17F,
    totslf = TOTSLF17,
    totexp = TOTEXP17) %>%
  select(DUPERSID, VARSTR, VARPSU, AGELAST, perwt, totslf, totexp, matches("JTPAIN"))

head(fyc18p)
head(fyc17p)


# Stack data and define pooled weight variable and subpop of interest ---------
#  - Subpop: AGELAST >= 18 AND any_jtpain not missing

pool = bind_rows(fyc18p, fyc17p) %>%
  mutate(
  # for poolwt, divide perwt by number of years (2):
    poolwt = perwt / 2, 
    subpop = (AGELAST >=18 & any_jtpain != "Missing"))


# Define the survey design ----------------------------------------------------

pool_dsgn = svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~poolwt,
  data = pool,
  nest = TRUE)


# Calculate survey estimates ---------------------------------------------------
#  - Percentage of people with Joint Pain / Arthritis (any_jtpain)
#  - Average expenditures per person, by Joint Pain status (totexp, totslf)

# Percent with any joint pain (any_jtpain)
svymean(~any_jtpain, design = subset(pool_dsgn, subpop))

# Avg. expenditures per person
svyby(~totslf + totexp, by = ~any_jtpain, FUN = svymean, 
      design = subset(pool_dsgn, subpop))


