# -----------------------------------------------------------------------------
# This program generates National Totals and Per-person Averages for Narcotic
# analgesics and Narcotic analgesic combos for the U.S. civilian 
# non-institutionalized population, including:
#  - Number of purchases (fills)  
#  - Total expenditures          
#  - Out-of-pocket payments       
#  - Third-party payments        
#
# Input files:
#  - C:/MEPS/h209.dta  (2018 Full-year file)
#  - C:/MEPS/h206a.dta (2018 Prescribed medicines file)
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------
# 
# # Can skip this part if already installed
# install.packages("survey")   # for survey analysis
# install.packages("foreign")  # for loading SAS transport (.ssp) files
# install.packages("haven")    # for loading Stata (.dta) files
# install.packages("dplyr")    # for data manipulation
# install.packages("devtools") # for loading "MEPS" package from GitHub
# 
# # Run this part each time you re-start R
# library(survey)
# library(foreign)
# library(haven)
# library(dplyr)
# library(devtools)
# 
# # This package facilitates file import
# install_github("e-mitchell/meps_r_pkg/MEPS") 
# library(MEPS)

# Set options to deal with lonely psu
options(survey.lonely.psu='adjust');

# Read in data from FYC file --------------------------------------------------

  fyc18 = read_MEPS(year = 2018, type = "FYC") # 2018 FYC
  rx18  = read_MEPS(year = 2018, type = "RX")  # 2018 RX
  
  # # Alternative:
  # fyc18 = read_dta("C:/MEPS/h209.dta")   # 2018 FYC
  # rx18  = read_dta("C:/MEPS/h206a.dta")  # 2018 RX
  

# Keep only needed variables --------------------------------------------------
  
  fyc18_sub = fyc18 %>%
    select(DUPERSID, VARSTR, VARPSU, PERWT18F) # needed for survey design
    

# Identify Narcotic analgesics or Narcotic analgesic combos -------------------
#  Use therapeutic classification codes (TC1S1_1)
#
# DUPERSID: PERSON ID (DUID + PID)
# RXRECIDX: UNIQUE RX/PRESCRIBED MEDICINE IDENTIFIER
# LINKIDX:  ID FOR LINKAGE TO COND/OTH EVENT FILES
# TC1S1_1:  MULTUM THERAPEUT SUB-SUB-CLASS FOR TC1S1
#
# RXXP18X:  SUM OF PAYMENTS RXSF18X-RXOU18X(IMPUTED)
# RXSF18X:  AMOUNT PAID, SELF OR FAMILY (IMPUTED)


  narc = rx18 %>%
    filter(TC1S1_1 %in% c(60, 191)) %>%
    select(DUPERSID, RXRECIDX, LINKIDX, TC1S1_1, RXXP18X, RXSF18X)
  
  head(narc)
  narc %>% count(TC1S1_1)

# Sum data to person-level ----------------------------------------------------

  narc_pers = narc %>%
    group_by(DUPERSID) %>%
    summarise(
      tot = sum(RXXP18X),
      oop = sum(RXSF18X),
      n_purchase = n()) %>%
    mutate(
      third_payer = tot - oop,
      any_narc = 1) 
  
  head(narc_pers)


# Merge the person-level expenditures to the FY PUF to get complete PSUs, Strata
  
  narc_fyc = full_join(narc_pers, fyc18_sub, by = "DUPERSID")
  
  head(narc_fyc)
  
  nrow(narc)
  nrow(fyc)
  nrow(narc_fyc)
  
  narc_fyc %>% count(any_narc)
  narc_fyc %>% filter(is.na(any_narc))



# Define the survey design ----------------------------------------------------
  
  mepsdsgn = svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT18F,
    data = narc_fyc,
    nest = TRUE)

# Calculate estimates ---------------------------------------------------------
#  National totals and Per-person Averages for:
#   - Number of purchases (fills)  -- n_purchase
#   - Total expenditures           -- tot
#   - Out-of-pocket payments       -- oop
#   - Third-party payments         -- third_payer
  
# National totals 
  svytotal(~n_purchase + tot + oop + third_payer, 
           design = subset(mepsdsgn, any_narc == 1))
  
  
# Average per person
  svymean(~n_purchase + tot + oop + third_payer,
          design = subset(mepsdsgn, any_narc == 1))


  