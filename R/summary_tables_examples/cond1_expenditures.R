# -----------------------------------------------------------------------------
# Medical Conditions, 2015
#
# Note: Starting in 2016, conditions were coded to ICD-10 codes (ICD-9 codes
#  were used from 1996-2015). CCS codes are not on the medical conditions PUFs
#  for 2016 or 2017
#
# Example R code to replicate the following estimates in the MEPS-HC summary
#  tables by medical condition:
#  - Number of people with care
#  - Number of events
#  - Total expenditures
#  - Mean expenditure per person
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

# Load and stack event files
  RX <- read_MEPS(year = 2015, type = "RX") %>% rename(EVNTIDX = LINKIDX)
  IP <- read_MEPS(year = 2015, type = "IP")
  ER <- read_MEPS(year = 2015, type = "ER")
  OP <- read_MEPS(year = 2015, type = "OP")
  OB <- read_MEPS(year = 2015, type = "OB")
  HH <- read_MEPS(year = 2015, type = "HH")

  stacked_events <- stack_events(RX, IP, ER, OP, OB, HH)


# Load in event-condition linking file
  clink1 = read_MEPS(year = 2015, type = "CLNK") %>%
    select(DUPERSID, CONDIDX, EVNTIDX)

# Load in conditions file
  conditions <- read_MEPS(year = 2015, type = "Conditions") %>%
    select(DUPERSID, CONDIDX, CCCODEX)


# Merge datasets --------------------------------------------------------------

# Merge collapsed condition codes onto conditions data set
#   ('condition_codes' data comes pre-loaded with the MEPS R library)

  conditions <- conditions %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes")

# Merge conditions data with the conditions-event link file (CLNK),
#  then de-duplicate by event ID ('EVNTIDX') and collapsed code ('Condition')

  cond_clink <-
    full_join(conditions, clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all = T)

# Merge events with linked conditions file and remove any observations with
#  missing 'Condition' or negative expenditures

  all_events <-
    full_join(stacked_events, cond_clink, by = c("DUPERSID", "EVNTIDX")) %>%
    filter(!is.na(Condition), XP15X >= 0)
  
  
# Aggregate to person-level, by Condition -------------------------------------

  all_pers <- all_events %>%
    group_by(DUPERSID, VARSTR, VARPSU, Condition) %>%
    summarize(
      PERWT15F = mean(PERWT15F),
      pers_XP = sum(XP15X),
      n_events = n()) %>%
    ungroup %>%
    mutate(persons = 1)


# Define survey design and calculate estimates --------------------------------

  PERSdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT15F,
    data = all_pers,
    nest = TRUE)


# Totals (people, events, expenditures)
  totals <- svyby(~persons + n_events + pers_XP, 
                  by = ~Condition, FUN = svytotal, design = PERSdsgn)

  totals %>% select(persons, se.persons)   # Number of people with care
  totals %>% select(n_events, se.n_events) # Number of events
  totals %>% select(pers_XP, se.pers_XP)   # Total expenditures

 
# Mean expenditure per person with care
  means <- svyby(~pers_XP, by = ~Condition, FUN = svymean, design = PERSdsgn)
  
  means %>% select(pers_XP, se)
