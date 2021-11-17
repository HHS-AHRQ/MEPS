# -----------------------------------------------------------------------------
# Accessibility and quality of care: Quality of Care, 2016
#
# Self-administered questionnaire (SAQ): 
#  - Number/percent of Adults by ability to schedule a routine appointment
#  - By Insurance Coverage Status
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

# Ability to schedule a routine appt. (adults)
  FYC <- FYC %>%
    mutate(adult_routine = recode_factor(
      ADRTWW42, .default = "Missing", .missing = "Missing",
      "4" = "Always",
      "3" = "Usually",
      "2" = "Sometimes/Never",
      "1" = "Sometimes/Never",
      "-7" = "Don't know/Non-response",
      "-8" = "Don't know/Non-response",
      "-9" = "Don't know/Non-response",
      "-1" = "Inapplicable"))

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
    mutate(insurance = recode_factor(
      INSURC16, .default = "Missing", .missing = "Missing",
      "1" = "<65, Any private",
      "2" = "<65, Public only",
      "3" = "<65, Uninsured",
      "4" = "65+, Medicare only",
      "5" = "65+, Medicare and private",
      "6" = "65+, Medicare and other public",
      "7" = "65+, No medicare",
      "8" = "65+, No medicare"))

# QC new variables
  FYC %>% count(adult_routine, ADRTWW42)
  FYC %>% count(insurance, INSURC16)


# Define survey design and calculate estimates --------------------------------
#  - use SAQWT16F weight variable, since outcome variable comes from SAQ

  SAQdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~SAQWT16F,
    data = FYC,
    nest = TRUE)

  # Subset to adults who made an appointment
  sub_dsgn <- subset(SAQdsgn, ADRTCR42 == 1 & AGELAST >= 18)

# Ability to schedule a routine appointment (adults)
  svyby(~adult_routine, FUN = svytotal, by = ~insurance, design = sub_dsgn) # number
  svyby(~adult_routine, FUN = svymean,  by = ~insurance, design = sub_dsgn) # percent
