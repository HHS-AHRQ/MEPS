# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Prescribed drugs, 2016
#
# Purchases and expenditures by generic drug name (RXDRGNAM)
#  - Number of people with purchase
#  - Total purchases
#  - Total expenditures
#
# Input file: C:/MEPS/h188a.ssp (2016 RX event file)
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


# Load datasets ---------------------------------------------------------------
# For 1996-2013, need to merge with RX Multum Lexicon Addendum files to get
#  therapeutic class categories and generic drug names

# Load RX file
  RX <- read.xport("C:/MEPS/h188a.ssp")

# Aggregate to person-level ---------------------------------------------------

  RX_pers <- RX %>%
    group_by(DUPERSID, VARSTR, VARPSU, RXDRGNAM) %>%
    summarise(
      PERWT16F = mean(PERWT16F),
      pers_RXXP = sum(RXXP16X),
      n_purchases = n()) %>%
    ungroup %>%
    mutate(persons = 1)


# Define survey design and calculate estimates --------------------------------

  RXdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = RX_pers,
    nest = TRUE
  )

  totals <- svyby(~persons + n_purchases + pers_RXXP,
                  by = ~RXDRGNAM, FUN = svytotal, design = RXdsgn)

  totals %>% select(persons, se.persons)         # Number of people with purchase
  totals %>% select(n_purchases, se.n_purchases) # Total purchases
  totals %>% select(pers_RXXP, se.pers_RXXP)     # Total expenditures
