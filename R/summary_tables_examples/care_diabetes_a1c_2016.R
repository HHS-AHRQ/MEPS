# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Accessibility and quality of care: Diabetes Care, 2016
#
# Diabetes care survey (DCS): 
#  - Number/percent of adults with diabetes receiving hemoglobin A1c blood test 
#  - By race/ethnicity
#
# Input file: C:/MEPS/h192.ssp (2016 full-year consolidated)
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

# Diabetes care: Hemoglobin A1c measurement
#  - DSA1C53 = 'Times tested for A1c in 2016' (96 = did not have test)
  FYC <- FYC %>%
    mutate(diab_a1c = case_when(
      DSA1C53 == -1 ~ "Inapplicable",
      DSA1C53 < 0   ~ "Don't know/Non-response",
      DSA1C53 == 0  ~ "Did not have measurement",
      DSA1C53 == 96 ~ "Did not have measurement",
      0 < DSA1C53 & DSA1C53 < 96 ~ "Had measurement",
      TRUE ~ "Missing"
    ))

# Race/ethnicity
# 1996-2002: race/ethnicity variable based on RACETHNX (see documentation for details)
# 2002-2011: race/ethnicity variable based on RACETHNX and RACEX:
#   hisp   = (RACETHNX == 1),
#   white  = (RACETHNX == 4 & RACEX == 1),
#   black  = (RACETHNX == 2),
#   native = (RACETHNX >= 3 & RACEX %in% c(3,6)),
#   asian  = (RACETHNX >= 3 & RACEX %in% c(4,5)))

# For 2012 and later, use RACETHX and RACEV1X:
  FYC <- FYC %>%
    mutate(
      hisp   = (RACETHX == 1),
      white  = (RACETHX == 2),
      black  = (RACETHX == 3),
      native = (RACETHX > 3 & RACEV1X %in% c(3,6)),
      asian  = (RACETHX > 3 & RACEV1X %in% c(4,5)))

  FYC <- FYC %>% mutate(
    race = 1*hisp + 2*white + 3*black + 4*native + 5*asian,
    race = recode_factor(
      race,
      "1" = "Hispanic",
      "2" = "White",
      "3" = "Black",
      "4" = "Amer. Indian, AK Native, or mult. races",
      "5" = "Asian, Hawaiian, or Pacific Islander"))

# QC new variables
  FYC %>% count(RACETHX, RACEV1X, hisp, white, black, native, asian, race)
  FYC %>% count(diab_a1c, DSA1C53) %>% as.data.frame


# Define survey design and calculate estimates --------------------------------
#  - use DIABW16F weight variable, since outcome variable comes from DCS

  DIABdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~DIABW16F,
    data = FYC,
    nest = TRUE)

# Adults with diabetes with hemoglobin A1C measurement in 2016, by race
  svyby(~diab_a1c, FUN = svytotal, by = ~race, design = DIABdsgn) # number
  svyby(~diab_a1c, FUN = svymean,  by = ~race, design = DIABdsgn) # percent
