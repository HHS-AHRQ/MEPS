# -----------------------------------------------------------------------------
# Accessibility and quality of care: Access to Care, 2017
#
# Reasons for difficulty receiving needed care
#  - Number/percent
#  - By Poverty Status
#
# Input file: C:/MEPS/h201.dta (2017 full-year consolidated)
# -----------------------------------------------------------------------------

# Install/load packages and set global options --------------------------------

# Install packages (if needed) -- only need to run once
install.packages("survey")
install.packages("dplyr")
install.packages("haven")

# Load packages (need to run every session)
library(survey)
library(dplyr)
library(haven)

# Set survey option for lonely psu
options(survey.lonely.psu="adjust")


# Load FYC file ---------------------------------------------------------------

FYC <- read_dta("C:/MEPS/h201.dta")


# Define variables ------------------------------------------------------------

# Reasons for difficulty receiving needed care

FYC <- FYC %>%
  mutate(
    # any delay / unable to receive needed care
    delay_MD  = (MDUNAB42 == 1 | MDDLAY42==1)*1,
    delay_DN  = (DNUNAB42 == 1 | DNDLAY42==1)*1,
    delay_PM  = (PMUNAB42 == 1 | PMDLAY42==1)*1,
    
    # Among people unable or delayed, how many...
    # ...couldn't afford
    afford_MD = (MDDLRS42 == 1 | MDUNRS42 == 1)*1,
    afford_DN = (DNDLRS42 == 1 | DNUNRS42 == 1)*1,
    afford_PM = (PMDLRS42 == 1 | PMUNRS42 == 1)*1,
    
    # ...had insurance problems
    insure_MD = (MDDLRS42 %in% c(2,3) | MDUNRS42 %in% c(2,3))*1,
    insure_DN = (DNDLRS42 %in% c(2,3) | DNUNRS42 %in% c(2,3))*1,
    insure_PM = (PMDLRS42 %in% c(2,3) | PMUNRS42 %in% c(2,3))*1,
    
    # ...other
    other_MD  = (MDDLRS42 > 3 | MDUNRS42 > 3)*1,
    other_DN  = (DNDLRS42 > 3 | DNUNRS42 > 3)*1,
    other_PM  = (PMDLRS42 > 3 | PMUNRS42 > 3)*1,
    
    delay_ANY  = (delay_MD  | delay_DN  | delay_PM)*1,
    afford_ANY = (afford_MD | afford_DN | afford_PM)*1,
    insure_ANY = (insure_MD | insure_DN | insure_PM)*1,
    other_ANY  = (other_MD  | other_DN  | other_PM)*1)


# Poverty status
FYC <- FYC %>%
  mutate(poverty = recode_factor(
    as.factor(POVCAT17),
    "1" = "Negative or poor",
    "2" = "Near-poor",
    "3" = "Low income",
    "4" = "Middle income",
    "5" = "High income"))

# QC new variables
FYC %>% count(delay_MD, MDUNAB42, MDDLAY42)
FYC %>% count(delay_DN, DNUNAB42, DNDLAY42)
FYC %>% count(delay_PM, PMUNAB42, PMDLAY42)
FYC %>% count(delay_ANY,  delay_MD,  delay_DN, delay_PM)
 # ...repeat for "couldn't afford", "insurance", and "other"

FYC %>% count(poverty, POVCAT17)


# Define survey design and calculate estimates --------------------------------

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT17F,
  data = FYC,
  nest = TRUE)

# Subset to persons eligible to receive the 'access to care' supplement 
#   and who experienced difficulty receiving needed care

sub_dsgn <- subset(FYCdsgn, ACCELI42==1 & delay_ANY==1)

# Reasons for difficulty receiving any needed care
svyby(~afford_ANY + insure_ANY + other_ANY, FUN = svytotal, by = ~poverty, design = sub_dsgn) # number
svyby(~afford_ANY + insure_ANY + other_ANY, FUN = svymean,  by = ~poverty, design = sub_dsgn) # percent

