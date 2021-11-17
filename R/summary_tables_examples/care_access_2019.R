# -----------------------------------------------------------------------------
# Accessibility and quality of care: Access to Care, 2019
#
# Did not receive treatment because couldn't afford it
#  - Number/percent
#  - By Poverty Status
#
# Input file: C:/MEPS/h216.dta (2019 full-year consolidated)
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

FYC <- read_dta("C:/MEPS/h216.dta")


# Define variables ------------------------------------------------------------

# Didn't receive care because couldn't afford it 
FYC <- FYC %>%
  mutate(
    afford_MD = (AFRDCA42 == 1)*1, # medical care
    afford_DN = (AFRDDN42 == 1)*1, # dental care
    afford_PM = (AFRDPM42 == 1)*1, # prescription medicines
    afford_ANY = (afford_MD | afford_DN | afford_PM)*1) # any care

# Poverty status
FYC <- FYC %>%
  mutate(poverty = recode_factor(
    as.factor(POVCAT19),  
    "1" = "Negative or poor",
    "2" = "Near-poor",
    "3" = "Low income",
    "4" = "Middle income",
    "5" = "High income"))

# QC new variables
FYC %>% count(AFRDCA42, afford_MD)
FYC %>% count(AFRDDN42, afford_DN)
FYC %>% count(AFRDPM42, afford_PM)
FYC %>% count(afford_MD, afford_DN, afford_PM, afford_ANY)

FYC %>% count(poverty, POVCAT19)


# Define survey design and calculate estimates --------------------------------

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT19F,
  data = FYC,
  nest = TRUE)

# Subset to persons eligible to receive the 'access to care' supplement
sub_dsgn <- subset(FYCdsgn, ACCELI42==1)

# Did not receive treatment because of cost 
svyby(~afford_ANY + afford_MD + afford_DN + afford_PM, FUN = svytotal, by = ~poverty, design = sub_dsgn) # number
svyby(~afford_ANY + afford_MD + afford_DN + afford_PM, FUN = svymean,  by = ~poverty, design = sub_dsgn) # percent


