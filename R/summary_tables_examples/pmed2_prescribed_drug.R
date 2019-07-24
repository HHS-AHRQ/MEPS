# -----------------------------------------------------------------------------
# Prescribed drugs, 2016
#
# Purchases and expenditures by generic drug name
#
# Example R code to replicate the following estimates in the MEPS-HC summary
#  tables by generic drug name:
#  - Number of people with purchase
#  - Total purchases
#  - Total expenditures
#
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
# For 1996-2013, need to merge with RX Multum Lexicon Addendum files to get
#  therapeutic class categories and generic drug names

# Load RX file
  RX <- read_MEPS(year = 2016, type = "RX")


# Aggregate to person-level ---------------------------------------------------

  RX_pers <- RX %>%
    filter(RXNDC != "-9" & RXDRGNAM != "-9") %>%  # Remove missing drug names
    group_by(DUPERSID, VARSTR, VARPSU, RXDRGNAM) %>%
    summarise(
      PERWT16F = mean(PERWT16F),
      pers_RXXP = sum(RXXP16X),
      n_purchases = n()) %>%
    ungroup %>%
    mutate(person = 1)


# Define survey design and calculate estimates --------------------------------

  RXdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = RX_pers,
    nest = TRUE
  )

# Number of people with purchase
  svyby(~person, by = ~RXDRGNAM, FUN = svytotal, design = RXdsgn)

# Number of purchases
  svyby(~n_purchases, by = ~RXDRGNAM, FUN = svytotal, design = RXdsgn)

# Total expenditures
  svyby(~pers_RXXP, by = ~RXDRGNAM, FUN = svytotal, design = RXdsgn)
