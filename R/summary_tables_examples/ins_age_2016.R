# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Health insurance, 2016:
#  - Number/percent of people
#  - By insurance coverage and age groups
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

  FYC <- read.xport("C:/MEPS/h192.ssp")s


# Define variables ------------------------------------------------------------

# Age groups
#  - For 1996-2007, AGELAST must be created from AGEyyX, AGE42X, AGE31X
  FYC <- FYC %>%
    mutate(agegrps = cut(AGELAST,
      breaks = c(-1, 4.5, 17.5, 44.5, 64.5, Inf),
      labels = c("Under 5","5-17","18-44","45-64","65+")))

# Insurance coverage
#  - For 1996-2011, create INSURC from INSCOV and 'EV' variables
#     (for 1996, use 'EVER' vars):
#
#     public   = (MCDEV16 == 1 | OPAEV16 == 1 | OPBEV16 == 1)
#     medicare = (MCREV16 == 1)
#     private  = (INSCOV16 == 1)
#
#     mcr_priv = (medicare &  private)
#     mcr_pub  = (medicare & !private & public)
#     mcr_only = (medicare & !private & !public)
#     no_mcr   = (!medicare),
#
#     ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr,
#     INSURC16 = ifelse(AGELAST < 65, INSCOV16, ins_gt65)

  FYC <- FYC %>%
    mutate(insurance = recode_factor(INSURC16,
      "1" = "<65, Any private",
      "2" = "<65, Public only",
      "3" = "<65, Uninsured",
      "4" = "65+, Medicare only",
      "5" = "65+, Medicare and private",
      "6" = "65+, Medicare and other public",
      "7" = "65+, No Medicare",
      "8" = "65+, No Medicare"))

# QC new variables
  FYC %>%
    group_by(agegrps) %>%
    summarize(
      min_age  = min(AGELAST),
      max_age  = max(AGELAST),
      n_ppl    = n())

  FYC %>% count(insurance, INSURC16, agegrps)


# Define survey design and calculate estimates --------------------------------

  FYCdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = FYC,
    nest = TRUE)

# Insurance coverage status by age groups
  svyby(~insurance, FUN = svytotal, by = ~agegrps, design = FYCdsgn) # number
  svyby(~insurance, FUN = svymean,  by = ~agegrps, design = FYCdsgn) # percent
