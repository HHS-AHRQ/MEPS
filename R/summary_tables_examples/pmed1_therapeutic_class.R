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

  # Define therapeutic classes
  RX <- RX %>% mutate(
    TC1name = recode_factor(TC1,
       "-9" = "Not_ascertained",
       "-1" = "Inapplicable",
       "1"  = "Anti-infectives",
       "19" = "Antihyperlipidemic_agents",
       "20" = "Antineoplastics",
       "28" = "Biologicals",
       "40" = "Cardiovascular_agents",
       "57" = "Central_nervous_system_agents",
       "81" = "Coagulation_modifiers",
       "87" = "Gastrointestinal_agents",
       "97" = "Hormones/hormone_modifiers",
      "105" = "Miscellaneous_agents",
      "113" = "Genitourinary_tract_agents",
      "115" = "Nutritional_products",
      "122" = "Respiratory_agents",
      "133" = "Topical_agents",
      "218" = "Alternative_medicines",
      "242" = "Psychotherapeutic_agents",
      "254" = "Immunologic_agents",
      "358" = "Metabolic_agents"
    ))


# Aggregate to person-level ---------------------------------------------------

  TC1_pers <- RX %>%
    group_by(DUPERSID, VARSTR, VARPSU, TC1name) %>%
    summarise(
      PERWT16F = mean(PERWT16F),
      pers_RXXP = sum(RXXP16X),
      n_purchases = n()) %>%
    ungroup %>%
    mutate(persons = 1)


# Define survey design and calculate estimates --------------------------------

  TC1dsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = TC1_pers,
    nest = TRUE
  )

  totals <- svyby(~persons + n_purchases + pers_RXXP,
                  by = ~TC1name, FUN = svytotal, design = TC1dsgn)

  totals %>% select(persons, se.persons)         # Number of people with purchase
  totals %>% select(n_purchases, se.n_purchases) # Number of purchases
  totals %>% select(pers_RXXP, se.pers_RXXP)     # Total expenditures
