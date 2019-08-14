# -----------------------------------------------------------------------------
# DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS DATA FILES FROM
#  DIFFERENT YEARS THE EXAMPLE USED IS POPULATION AGE 26-30 WHO ARE UNINSURED
#  BUT HAVE HIGH INCOME DATA FROM 2015 AND 2016 ARE POOLED.
#
# VARIABLES WITH YEAR-SPECIFIC NAMES MUST BE RENAMED BEFORE COMBINING FILES:
#
# IN THIS PROGRAM THE INSURANCE COVERAGE VARIABLES 'INSCOV15' AND 'INSCOV16'
#  ARE RENAMED TO 'INSCOV'.
#
# SEE HC-036 (1996-2015 POOLED ESTIMATION FILE) FOR
#  INSTRUCTIONS ON POOOLING AND CONSIDERATIONS FOR VARIANCE
#  ESTIMATION FOR PRE-2002 DATA.
#
# INPUT FILES: (1) C:/MEPS/H192.ssp (2016 FULL-YEAR FILE)
# 	           (2) C:/MEPS/H181.ssp (2015 FULL-YEAR FILE)
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


# Read in data
h192 = read.xport("C:/MEPS/h192.ssp") # 2016 FYC
h181 = read.xport("C:/MEPS/h181.ssp") # 2015 FYC

# Rename year-specific variables prior to combining
h192x = h192 %>%
  rename(inscov = INSCOV16,
         perwt  = PERWT16F,
         povcat = POVCAT16,
         totslf = TOTSLF16) %>%
  select(DUPERSID, VARSTR, VARPSU, AGELAST, inscov, perwt, povcat, totslf)

h181x = h181 %>%
  rename(inscov = INSCOV15,
         perwt  = PERWT15F,
         povcat = POVCAT15,
         totslf = TOTSLF15) %>%
  select(DUPERSID, VARSTR, VARPSU, AGELAST, inscov, perwt, povcat, totslf)

# Stack data and define pooled weight variable and subpop of interest
#  subpop = age 26-30, uninsured, high income

pool = bind_rows(h192x, h181x) %>%
  mutate(poolwt = perwt / 2, # divide perwt by number of years (2)
         subpop = (26 <= AGELAST & AGELAST <= 30 & povcat == 5 & inscov == 3))

# QC subpop

pool %>%
  filter(subpop) %>%
  group_by(AGELAST, povcat, inscov) %>%
  summarise(n())


# Define the survey design

mepsdsgn = svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~poolwt,
  data = pool,
  nest = TRUE)


# Weighted estimate on totslf for combined data w/age=26-30, uninsured whole year, and high income

svymean(~totslf, design = subset(mepsdsgn, subpop))
