# -----------------------------------------------------------------------------
# DESCRIPTION: THIS PROGRAM GENERATES THE FOLLOWING ESTIMATES ON
#               NATIONAL HEALTH CARE, 2016:
#
#             (1) OVERALL EXPENSES
# 	          (2) PERCENTAGE OF PERSONS WITH AN EXPENSE
# 	          (3) MEAN EXPENSE PER PERSON WITH AN EXPENSE
#
# INPUT FILE:  C:/MEPS/H192.ssp (2016 FULL-YEAR FILE)
# -----------------------------------------------------------------------------

# Install and load libraries

  # Can skip this part if already installed
  install.packages("survey")
  install.packages("foreign")
  install.packages("dplyr")

  # Run this part each time you re-start R
  library(survey)
  library(foreign)
  library(dplyr)

# Set options to deal with lonely psu
  options(survey.lonely.psu='adjust');


# Read in data from 2016 consolidated data file (hc-192)
  h192 = read.xport("C:/MEPS/h192.ssp")

# Add variables for persons with any expense and persons under 65

  h192 = h192 %>%
    mutate(
      has_exp = (TOTEXP16 > 0), # persons with any expense
      age_cat = ifelse(AGELAST < 65, "<65", "65+")  # persons under age 65
    )

# QC check on new variables

  h192 %>%
    group_by(has_exp) %>%
    summarise(min = min(TOTEXP16), max = max(TOTEXP16))

  h192 %>%
    group_by(age_cat) %>%
    summarise(min = min(AGELAST), max = max(AGELAST))


# Define the survey design

  mepsdsgn = svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = h192,
    nest = TRUE)

# Overall expenses
svymean(~TOTEXP16, design = mepsdsgn)
svytotal(~TOTEXP16, design = mepsdsgn)

# Percentage of persons with an expense
svymean(~has_exp, design = mepsdsgn)

# Mean expense per person with an expense
svymean(~TOTEXP16, design = subset(mepsdsgn, has_exp))

# Mean expense per person with an expense, by age category
svyby(~TOTEXP16, by = ~age_cat, FUN = svymean, design = subset(mepsdsgn, has_exp))
