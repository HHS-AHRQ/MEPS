# -----------------------------------------------------------------------------
# This program shows how to link the MEPS-HC Medical Conditions file 
# to the Prescribed Medicines (PMED/RX) file for data year 2020 to estimate:
#
# National totals:
#   - Total number of people w PMED purchase for hyperlipidemia (HL)
#   - Total PMED fills for HL
#   - Total PMED expenditures for HL 
#
# Per-person averages among ppl with any PMED for hyperlipidemia (HL)
#   - Avg PMED fills for hyperlipidemia, by SEX and Poverty (POVCAT)
#   - Avg PMED exp for HL per person w/ HL fills, by SEX and Poverty (POVCAT)
# 
# Input files:
#   - h220a.dta        (2020 Prescribed Medicines file)
#   - h222.dta         (2020 Conditions file)
#   - h220if1.dta      (2020 CLNK: Condition-Event Link file)
#   - h224.dta         (2020 Full-Year Consolidated file)
# 
# Resources:
#   - CCSR codes: 
#   https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv
# 
#   - MEPS-HC Public Use Files: 
#   https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp
# 
#   - MEPS-HC online data tools: 
#   https://datatools.ahrq.gov/meps-hc
#
# -----------------------------------------------------------------------------


# Install/load packages and set global options --------------------------------

# Can skip this part if already installed
  install.packages("survey")   # for survey analysis
  install.packages("haven")    # for loading Stata (.dta) files
  install.packages("dplyr")    # for data manipulation
  install.packages("tidyr")    # for data manipulation
  install.packages("devtools") # for loading "MEPS" package from GitHub
  
  devtools::install_github("e-mitchell/meps_r_pkg/MEPS") # easier file import


# Load libraries (run this part each time you re-start R)
  library(survey)
  library(haven)
  library(dplyr)
  library(tidyr)
  library(MEPS)


# Set survey option for lonely PSUs
  options(survey.lonely.psu='adjust')
  options(survey.adjust.domain.lonely = TRUE)


# Load datasets ---------------------------------------------------------------
#  PMED/RX = Prescribed medicines file (record = rx fill or refill)
#  COND    = Medical conditions file (record = medical condition)
#  CLNK    = Conditions-event link file (crosswalk between conditions and 
#             events, including PMED events)
#  FYC     = Full-year-consolidated file (record = MEPS sample person)

  
# Option 1 - load data files using read_MEPS from the MEPS package
#  >> For PMED file, rename LINKIDX to EVNTIDX to merge with Conditions
    
  pmed20 <- read_MEPS(year = 2020, type = "RX") %>% rename(EVNTIDX=LINKIDX)
  cond20 <- read_MEPS(year = 2020, type = "COND")
  clnk20 <- read_MEPS(year = 2020, type = "CLNK")
  fyc20  <- read_MEPS(year = 2020, type = "FYC")
  

# Option 2 - load Stata data files using read_dta from the haven package 
#  >> Replace "C:/MEPS" below with the directory you saved the files to.

  # pmed20 <- read_dta("C:/MEPS/h220a.dta") %>% rename(EVNTIDX=LINKIDX)
  # cond20 <- read_dta("C:/MEPS/h222.dta")
  # clnk20 <- read_dta("C:/MEPS/h220if1.dta")
  # fyc20  <- read_dta("C:/MEPS/h224.dta")
  

# Keep only needed variables ------------------------------------------------

  pmed20x <- pmed20 %>% 
    select(DUPERSID, RXRECIDX, EVNTIDX, RXDRGNAM, RXXP20X)
  
  cond20x <- cond20 %>% 
    select(DUPERSID, CONDIDX, ICD10CDX, CCSR1X:CCSR3X)
  
  fyc20x  <- fyc20  %>% 
    select(DUPERSID, AGELAST, SEX, POVCAT20, CHOLDX, VARSTR, VARPSU, PERWT20F)
  


# Prepare data for estimation -------------------------------------------------

# Subset condition records to hyperlipidemia (any CCSR = "END010") 

  hl <- cond20x %>% 
    filter(CCSR1X == "END010" | CCSR2X == "END010" | CCSR3X == "END010")
  
  # QC
  hl %>% count(ICD10CDX, CCSR1X, CCSR2X, CCSR3X)
  
  
  # >> Note that the same person can have 'duplicate' hyperlipidemia conditions. 
  #    This can happen when the full ICD10s are different (e.g. E78.1 and E78.5) 
  #    but the collapsed 3-digit ICD10CDX is the same (E78)
  
  # >> Example:
  hl %>% filter(DUPERSID == '2320134102')

  

# Merge hyperlipidemia conditions with PMED file, using CLNK as crosswalk -----

# 1. Merge COND with CLNK file
  hl_clnk = hl %>% 
    inner_join(clnk20, by = c("DUPERSID", "CONDIDX"))
  
  # >> View example person: 
  #   - same condition (CONDIDX), multiple events (EVNTIDX) 
  #   - same event (EVNTIDX), multiple conditions (CONDIDX)
  
  hl_clnk %>% filter(DUPERSID == '2320134102')

  
  
# 2. De-duplicate on EVNTIDX (so we don't 'double-count' events)
  hl_clnk_distinct = hl_clnk %>% 
    distinct(PANEL, DUPERSID, EVNTIDX, ICD10CDX, CCSR1X, EVENTYPE)
  
  # QC: should be 0 duplicate EVNTIDX
  hl_clnk_distinct %>% pull(EVNTIDX) %>% duplicated() %>% sum
  
  # >> View example person: 
  hl_clnk_distinct %>% filter(DUPERSID == '2320134102')

  
  
# 3. Merge HL-CLNK with PMED file
  hl_merged <- hl_clnk_distinct %>% 
    inner_join(pmed20x, by = c("DUPERSID", "EVNTIDX")) 
  
  
  # >> View example person: 
  hl_merged %>% filter(DUPERSID == '2320134102')
  
  
  # QC: check that EVENTYPE = 8 PRESCRIBED MEDICINE for all rows
    hl_merged %>% 
      count(EVENTYPE)
  
  # QC: View top PMEDS for hyperlipidemia
    hl_merged %>% 
        count(RXDRGNAM) %>% 
        arrange(-n)



# Roll up to person-level data ------------------------------------------------
# >> For each person:
#    - n_hl_fills: number of unique fills for hyperlipidemia
#    - hl_drug_exp: sum of PMED expenditures for hyperlipidemia
#    - hl_pmed_flag: make a flag for people with a PMED purchase 
  
  drugs_by_pers <- hl_merged %>% 
    group_by(DUPERSID) %>% 
    summarize(
      n_hl_fills = n_distinct(RXRECIDX),
      hl_drug_exp = sum(RXXP20X)) %>% 
    mutate(hl_pmed_flag = 1)
  

  # >> View example person: 
  drugs_by_pers %>% filter(DUPERSID == '2320134102')
  
  
  
# Merge onto FYC file ---------------------------------------------------------
#  >> Need to capture all Strata (VARSTR) and PSUs (VARPSU) for all MEPS sample 
#     persons for correct variance estimation

  fyc_hl_merged <- fyc20x %>% 
    full_join(drugs_by_pers, by="DUPERSID") %>% 
    replace_na(list(hl_pmed_flag = 0))
  

  # QC: should have same number of rows as FYC file
  nrow(fyc20x) == nrow(fyc_hl_merged)
  
  # QC: hl_pmed_flag counts should be equal to rows in drugs_by_pers
  fyc_hl_merged %>% count(hl_pmed_flag)
  nrow(drugs_by_pers)
   
  
  
# BONUS!! Compare people ever diagnosed with hyperlipidemia (CHOLDX == 1) with 
# those that have hyperlipidemia PMED purchases
    
  fyc_hl_merged %>% 
    count(CHOLDX, hl_pmed_flag)  # -1's are mostly kids (age < 18)
  
  fyc_hl_merged %>% 
    filter(CHOLDX >= 0) %>% 
    count(CHOLDX, hl_pmed_flag)
  
  

  
# Define the survey design ----------------------------------------------------

meps_dsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT20F,
  data = fyc_hl_merged,
  nest = TRUE) 

hl_pmed_dsgn = subset(meps_dsgn, hl_pmed_flag == 1)


# Calculate estimates ---------------------------------------------------------

# >> National Totals:

svytotal(~ hl_pmed_flag +    # Total people w PMED purchase for HL
           n_hl_fills +      # Total PMED fills for hyperlipidemia
           hl_drug_exp,      # Total PMED expenditures for hyperlipidemia
           design = hl_pmed_dsgn)

    
# >> Per-person average expenditures among people with at least 
#    one PMED fill for hyperlipidemia (hl_pmed_flag = 1)

svymean(~ n_hl_fills +   # Avg PMED fills for hyperlipidemia
          hl_drug_exp,   # Avg PMED exp for HL per person w/ HL fills
          design = hl_pmed_dsgn) 


# >> By SEX
#    1: MALE
#    2: FEMALE

svyby(~n_hl_fills + hl_drug_exp, 
      by = ~SEX, FUN = svymean, design = hl_pmed_dsgn) 


# >> By POVCAT
#    1: Poor/negative
#    2: Near poor
#    3: Low income
#    4: Middle income
#    5: High income

svyby(~n_hl_fills + hl_drug_exp, 
      by = ~POVCAT20, FUN = svymean, design = hl_pmed_dsgn) 


