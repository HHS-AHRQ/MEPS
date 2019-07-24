# -----------------------------------------------------------------------------
# Prescribed drugs, 2016
#
# Purchases and expenditures by Multum therapeutic class name
#
# Example R code to replicate the following estimates in the MEPS-HC summary
#  tables by Multum therapeutic class:
#  - Number of people with purchase
#  - Total purchases
#  - Total expenditures
# -----------------------------------------------------------------------------

# Install/load packages and set global options --------------------------------

# Install packages (if needed) -- only need to run once
  install.packages("survey")
  install.packages("dplyr")
  install.packages("foreign")
  install.packages("devtools")

# Load packages (need to run every session)
  library(survey)
  library(dplyr)
  library(foreign)
  library(devtools)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

# Set survey option for lonely psu
  options(survey.lonely.psu="adjust")


# Load datasets ---------------------------------------------------------------
# For 1996-2013, need to merge RX event file with Multum Lexicon Addendum file
#  to get therapeutic class categories and generic drug names

# Load RX file
  RX <- read_MEPS(year = 2016, type = "RX")

# Merge with therapeutic class names and add counter variable
#  ('tc1_names' data comes pre-loaded with the MEPS R library)
  RX <- RX %>% left_join(tc1_names, by = "TC1")


# Aggregate to person-level ---------------------------------------------------

  TC1_pers <- RX %>%
    group_by(DUPERSID, VARSTR, VARPSU, TC1name) %>%
    summarise(
      PERWT16F = mean(PERWT16F),
      pers_RXXP = sum(RXXP16X),
      n_purchases = n()) %>%
    ungroup %>%
    mutate(person = 1)


# Define survey design and calculate estimates --------------------------------

  TC1dsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = TC1_pers,
    nest = TRUE
  )

# Number of people with purchase
  svyby(~person, by = ~TC1name, FUN = svytotal, design = TC1dsgn)

# Number of purchases
  svyby(~n_purchases, by = ~TC1name, FUN = svytotal, design = TC1dsgn)

# Total expenditures
  svyby(~pers_RXXP, by = ~TC1name, FUN = svytotal, design = TC1dsgn)
