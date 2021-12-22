# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Use, expenditures, and population, 2016
#
# Expenditures by race and sex
#  - Number of people
#  - Percent of population with an expense
#  - Total expenditures
#  - Mean expenditure per person
#  - Mean expenditure per person with expense
#  - Median expenditure per person with expense
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

# Race/ethnicity
#  - 1996-2002: race/ethnicity variable based on RACETHNX (see documentation)
#  - 2002-2011: race/ethnicity variable based on RACETHNX and RACEX:
#     hisp   = (RACETHNX == 1),
#     white  = (RACETHNX == 4 & RACEX == 1),
#     black  = (RACETHNX == 2),
#     native = (RACETHNX >= 3 & RACEX %in% c(3,6)),
#     asian  = (RACETHNX >= 3 & RACEX %in% c(4,5)))

#  - For 2012 and later, use RACETHX and RACEV1X:
  FYC <- FYC %>%
    mutate(
      hisp   = (RACETHX == 1),
      white  = (RACETHX == 2),
      black  = (RACETHX == 3),
      native = (RACETHX > 3 & RACEV1X %in% c(3,6)),
      asian  = (RACETHX > 3 & RACEV1X %in% c(4,5)),

      race = 1*hisp + 2*white + 3*black + 4*native + 5*asian,
      race = recode_factor(race,
        "1" = "Hispanic",
        "2" = "White",
        "3" = "Black",
        "4" = "Amer. Indian, AK Native, or mult. races",
        "5" = "Asian, Hawaiian, or Pacific Islander"))

# Sex
  FYC <- FYC %>%
    mutate(
      sex = recode_factor(SEX,
        "1" = "Male",
        "2" = "Female"))

# QC new variables
  FYC %>% count(RACETHX, RACEV1X, hisp, white, black, native, asian, race)
  FYC %>% count(sex, SEX)


# Add subgroup variables ------------------------------------------------------

  FYC <- FYC %>%
    mutate(
      persons = 1,                # counter variable for population totals
      has_exp = (TOTEXP16 > 0)*1) # 1 if person has an expense

# QC new variables
  FYC %>%
    group_by(persons, has_exp) %>%
    summarize(
      min_exp  = min(TOTEXP16),
      mean_exp = mean(TOTEXP16),
      max_exp  = max(TOTEXP16))


# Define survey design and calculate estimates --------------------------------

  FYCdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = FYC,
    nest = TRUE)

  has_exp_dsgn <- subset(FYCdsgn, has_exp == 1)


# Number of people
  svyby(~persons, FUN = svytotal, by = ~sex + race, design = FYCdsgn)

# Percent of population with an expense
  svyby(~has_exp, FUN = svymean, by = ~sex + race, design = FYCdsgn)

# Total expenditures
  svyby(~persons, FUN = svytotal, by = ~sex + race, design = FYCdsgn)

# Mean expenditure per person
  svyby(~TOTEXP16, FUN = svymean, by = ~sex + race, design = FYCdsgn)

# Mean expenditure per person with expense
  svyby(~TOTEXP16, FUN = svymean, by = ~sex + race, design = has_exp_dsgn)

# Median expenditure per person with expense
#   Note: Estimates may vary in R, SAS, and Stata, due to different methods
#         of estimating survey quantiles
  svyby(~TOTEXP16, FUN = svyquantile, by = ~sex + race, design = has_exp_dsgn,
        quantiles = c(0.5), method = "constant")

  