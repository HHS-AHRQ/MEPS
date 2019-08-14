# -----------------------------------------------------------------------------
# Accessibility and quality of care, 2016
#
# Children with dental care
#
# Example R code to replicate number and percentage of children with dental
#  care, by poverty status
# -----------------------------------------------------------------------------

# Install/load packages and set global options --------------------------------

# Install packages (if needed) -- only need to run once
  install.packages("survey")
  install.packages("dplyr")
  install.packages("foreign")

# Load packages (need to run every session)
  library(survey)
  library(dplyr)
  library(foreign)

# Set survey option for lonely psu
  options(survey.lonely.psu="adjust")


# Load FYC file ---------------------------------------------------------------

  FYC <- read.xport("C:/MEPS/h192.ssp")


# Define variables ------------------------------------------------------------

# Children receiving dental care
#  - For 1996-2007, AGELAST must be created from AGEyyX, AGE42X, AGE31X
  FYC <- FYC %>%
    mutate(
      child_2to17 = (1 < AGELAST & AGELAST < 18)*1,
      child_dental = ((DVTOT16 > 0) & (child_2to17 == 1))*1,
      child_dental = recode_factor(
        child_dental,
        "1" = "One or more dental visits",
        "0" = "No dental visits in past year"))

# Poverty status
#  - For 1996, use 'POVCAT' instead of 'POVCAT96'
  FYC <- FYC %>%
    mutate(poverty = recode_factor(
      POVCAT16,
      "1" = "Negative or poor",
      "2" = "Near-poor",
      "3" = "Low income",
      "4" = "Middle income",
      "5" = "High income"))


# Define survey design and calculate estimates --------------------------------

  FYCdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = FYC,
    nest = TRUE)

  children_2to17 = subset(FYCdsgn, child_2to17 == 1)

# Children with dental care, by poverty status
  svyby(~child_dental, FUN = svytotal, by = ~poverty, design = children_2to17) # number
  svyby(~child_dental, FUN = svymean,  by = ~poverty, design = children_2to17) # percent
