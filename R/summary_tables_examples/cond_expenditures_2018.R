# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Medical Conditions, 2018:
#  - Number of people with care
#  - Number of events
#  - Total expenditures
#  - Mean expenditure per person
#
# Note: Starting in 2016, conditions were converted from ICD-9 and CCS codes
#  to ICD-10 and CCSR codes 
#
# Input files:
# 	- C:/MEPS/h206a.dta (2018 RX event file)
# 	- C:/MEPS/h206d.dta (2018 IP event file)
# 	- C:/MEPS/h206e.dta (2018 ER event file)
# 	- C:/MEPS/h206f.dta (2018 OP event file)
# 	- C:/MEPS/h206g.dta (2018 OB event file)
# 	- C:/MEPS/h206h.dta (2018 HH event file)
# 	- C:/MEPS/h206if1.dta (2018 CLNK: Condition-event link file)
# 	- C:/MEPS/h207.dta    (2018 Conditions file)
# -----------------------------------------------------------------------------

# Install/load packages and set global options --------------------------------

# Install packages (if needed) -- only need to run once
  install.packages("survey")
  install.packages("dplyr")
  install.packages("haven")
  install.packages("readr")
  install.packages("tidyr")

# Load packages (need to run every session)
  library(survey)
  library(dplyr)
  library(haven)
  library(readr)
  library(tidyr)

# Set survey option for lonely psu
  options(survey.lonely.psu="adjust")


# Load datasets ---------------------------------------------------------------

# Load and stack event files
# - For RX, count number of fills per event
  RX <- read_dta("C:/MEPS/h206a.dta")
  RX <- RX %>%
    group_by(DUPERSID, LINKIDX, VARSTR, VARPSU, PERWT18F) %>%
    summarize(XPX = sum(RXXP18X), n_fills = n()) %>%
    ungroup %>%
    rename(EVNTIDX = LINKIDX)

  IP <- read_dta("C:/MEPS/h206d.dta") %>% rename(XPX = IPXP18X)
  ER <- read_dta("C:/MEPS/h206e.dta") %>% rename(XPX = ERXP18X)
  OP <- read_dta("C:/MEPS/h206f.dta") %>% rename(XPX = OPXP18X)
  OB <- read_dta("C:/MEPS/h206g.dta") %>% rename(XPX = OBXP18X)
  HH <- read_dta("C:/MEPS/h206h.dta") %>% rename(XPX = HHXP18X)

  stacked_events <-
    bind_rows(RX=RX, IP=IP, ER=ER, OP=OP, OB=OB, HH=HH, .id = "data") %>%
    select(data, EVNTIDX, DUPERSID, XPX, VARSTR, VARPSU, PERWT18F, n_fills) %>%
    mutate(n_events = pmax(n_fills, 1, na.rm = T))


# Load in event-condition linking file
  clink1 = read_dta("C:/MEPS/h206if1.dta") %>%
    select(DUPERSID, CONDIDX, EVNTIDX)

# Load in Conditions public use file
  cond_puf <- read_dta("C:/MEPS/h207.dta") %>%
    select(DUPERSID, CONDIDX, CCSR1X:CCSR3X)

  
# Load crosswalk for CCSR and collapsed conditions codes
  ccsr_url <- "https://raw.githubusercontent.com/HHS-AHRQ/MEPS/master/Quick_Reference_Guides/meps_ccsr_conditions.csv"
  
  condition_codes <- read_csv(ccsr_url, show_col_types = F) %>% 
    setNames(c("CCSR", "CCSR_desc", "Condition"))

# Merge datasets --------------------------------------------------------------

# Merge collapsed condition codes to COND PUF
#  - convert multiple CCSRs to separate lines (wide to long)
  cond <- cond_puf %>% 
    pivot_longer(CCSR1X:CCSR3X, names_to = "CCSRnum", values_to = "CCSR") %>% 
    filter(CCSR != "-1") %>%
    left_join(condition_codes, by = "CCSR")
  
# Merge conditions file with the conditions-event link file (CLNK)
  cond_clink <- full_join(cond, clink1, by = c("DUPERSID", "CONDIDX"))

# De-duplicate by event ID ('EVNTIDX') and collapsed code ('Condition')
  cond_clink <- cond_clink %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all = T)


# Merge conditions and event files --------------------------------------------

  all_events <-
    full_join(stacked_events, cond_clink, by = c("DUPERSID", "EVNTIDX"))

# Remove observations with missing 'Condition' or negative/missing expenditures
  all_events <- all_events %>% 
    filter(!is.na(Condition), XPX >= 0)


# Aggregate to person-level, by Condition -------------------------------------

  all_pers <- all_events %>%
    group_by(DUPERSID, VARSTR, VARPSU, Condition) %>%
    summarize(
      PERWTF  = mean(PERWT18F),
      pers_XP = sum(XPX),
      n_events = sum(n_events)) %>%
    ungroup %>%
    mutate(persons = 1)


# Define survey design and calculate estimates --------------------------------

  PERSdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWTF,
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
