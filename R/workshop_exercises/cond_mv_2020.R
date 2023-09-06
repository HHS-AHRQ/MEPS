#'-----------------------------------------------------------------------------
# Example code linking MEPS-HC Medical Conditions file to the Office-based
# medical visits file, data year 2020:
#   
# Event-level estimates:
#  - Number of office-based visits for mental health
#  - Total expenditures for office-based mental health treatment
#  - Mean expenditure per office-based mental health visit
# 
# Person-level estimates 
#  - Number of people with office-based mental health visits
#  - Percent of people with office-based mental health visits
#  - Mean expenditure per person for office-based mental health visits

# 
# Input files:
#  - h220g.sas7bdat   (2020 Office-based event file)
#  - h222.sas7bdat    (2020 Conditions file)
#  - h220if1.sas7bdat (2020 CLNK: Condition-event link file)
#  - h224.sas7bdat    (2020 Full-Year Consolidated file)
# 
# Resources:
#  - CCSR codes: 
#     https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv
# 
#  - MEPS-HC Public Use Files: 
#     https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp
# 
#  - MEPS-HC data tools: 
#     https://datatools.ahrq.gov/meps-hc
#'-----------------------------------------------------------------------------  


# Install/load packages and set global options --------------------------------

# For each package that you don't already have installed, un-comment
# and run.  Skip this step if all packages below are already installed.

# install.packages("dplyr")    # for data manipulation
# install.packages("tidyr")    # for more data manipulation
# install.packages("survey")   # for survey analysis
# install.packages("haven")    # for loading Stata (.dta) files
# install.packages("devtools") # for loading "MEPS" package from GitHub


# If MEPS package is not installed, un-comment and run to install
# >> OK if it doesn't work -- just use 'Option 2' for loading data 
#
# library(devtools)
# install_github("e-mitchell/meps_r_pkg/MEPS")


# Load libraries
library(dplyr)
library(tidyr)
library(survey)
library(haven)
library(MEPS)
  

# Set global options 

options(survey.lonely.psu="adjust") # survey option for lonely PSUs
options(dplyr.width = Inf) # so columns won't be truncated when printing
options(digits = 10) # so big numbers aren't defaulted to scientific notation



# Load datasets ---------------------------------------------------------------

# OB   = Office-based medical visits file (record = medical visit)
# COND = Medical conditions file (record = medical condition)
# CLNK = Conditions-event link file (crosswalk between conditions and events)
# FYC  = Full year consolidated file (record = MEPS sample person)


# Option 1 - load data files using read_MEPS from the MEPS package
ob20   = read_MEPS(year = 2020, type = "OB")
cond20 = read_MEPS(year = 2020, type = "COND")
clnk20 = read_MEPS(year = 2020, type = "CLNK")
fyc20  = read_MEPS(year = 2020, type = "FYC")


# Option 2 - load Stata data files using read_dta from the haven package 
#  First, download Stata (.dta) data sets from MEPS website:
#   -> https://meps.ahrq.gov > Data Files  

# Replace "C:/MEPS" below with the directory you saved the files to.

# ob20   <- read_dta("C:/MEPS/h220g.dta") 
# cond20 <- read_dta("C:/MEPS/h222.dta")
# clnk20 <- read_dta("C:/MEPS/h220if1.dta")
# fyc20  <- read_dta("C:/MEPS/h224.dta")


# Preview files (optional)
View(ob20)
View(cond20)
View(clnk20)


# Keep only needed variables --------------------------------------------------

#  Browse variables using MEPS-HC data tools variable explorer: 
#  -> http://datatools.ahrq.gov/meps-hc#varExp

ob20x   = ob20 %>% 
  select(PANEL, DUPERSID, EVNTIDX, EVENTRN, OBDATEYR, OBDATEMM, 
         TELEHEALTHFLAG, OBXP20X, PERWT20F, VARPSU, VARSTR)

cond20x = cond20 %>% 
  select(DUPERSID, CONDIDX, ICD10CDX, CCSR1X:CCSR3X)

fyc20x  = fyc20 %>% 
  select(DUPERSID, PERWT20F, VARSTR, VARPSU)



# Filter COND file to only people with Mental Disorders -----------------------

mental_health = cond20x %>% 
  unite("all_CCSR", CCSR1X:CCSR3X, remove = F) %>% 
  filter(grepl("MBD|FAC002|FAC007|NVS011|SYM008|SYM009", all_CCSR))

# view ICD10-CCSR combinations for mental health
mental_health %>% 
  count(ICD10CDX, CCSR1X, CCSR2X, CCSR3X) %>% 
  print(n = 100)


# Filter CLNK file to only office-based visits --------------------------------
#  EVENTYPE:
#   1 = "Office-based"
#   2 = "Outpatient" 
#   3 = "Emergency room"
#   4 = "Inpatient stay"
#   7 = "Home health"
#   8 = "Prescribed medicine"                                            

clnk_ob = clnk20 %>% 
  filter(EVENTYPE == 1)

# QC: should only have EVENTYPE = 1
clnk_ob %>% 
  count(EVENTYPE)


# Merge datasets --------------------------------------------------------------

# Merge conditions file with the conditions-event link file (CLNK)
#  'inner_join' only keeps records that are on both files

mh_clnk = inner_join(
  mental_health, clnk_ob,
  by = c("DUPERSID", "CONDIDX"))


# Note that one condition can be treated in different events
#  (same CONDIDX, different EVNTIDX):
mh_clnk %>% filter(CONDIDX == "2320109103009")


# Conversely, one visit can be for multiple conditions
#  (same EVNTIDX, different CONDIDX):
mh_clnk %>% filter(EVNTIDX == "2320051101205101")



# De-duplicate by event ID ('EVNTIDX'), since someone can have multiple events 
# for Mental Health. We don't want to count the same event twice.
mh_clnk_nodup = mh_clnk %>% 
  distinct(DUPERSID, EVNTIDX, EVENTYPE)




# Merge on event files --------------------------------------------------------
ob_mental_health = inner_join(ob20x, mh_clnk_nodup) %>% 
  # Add indicator variables for all visits to help with counting later:
  mutate(mh_ob_visit = 1)

# QC: should be EVENTYPE = 1 and mh_ob_visit = 1 for all rows
ob_mental_health %>% 
  count(EVENTYPE, mh_ob_visit) 


# DO NOT RUN ---------------------
#  Survey estimates? Not quite! Need to merge with FYC file first, to get 
#  complete Strata (VARSTR) and PSUs (VARPSU) for entire MEPS sample
#   
# THIS CODE IS INCLUDED AS AN EXAMPLE OF WHAT NOT TO DO
# THIS WILL GIVE WRONG SEs:
# 
# badDsgn = svydesign(
#   id = ~VARPSU,
#   strata = ~VARSTR,
#   weights = ~PERWT20F,
#   data = ob_mental_health,
#   nest = TRUE)
# 
# svytotal(~mh_ob_visit, design = badDsgn) # Number of visits
# svytotal(~OBXP20X,  design = badDsgn)    # Total exp.
# svymean(~OBXP20X,  design = badDsgn)     # Mean exp. per visit

# END DO NOT RUN -----------------




# Merge on FYC file for complete Strata, PSUs ---------------------------------

ob_mh_fyc = full_join(
  ob_mental_health %>% mutate(mh_ob = 1), 
  fyc20x %>% mutate(fyc = 1)) 


# QC
ob_mh_fyc %>% 
  count(mh_ob, mh_ob_visit, fyc)



# Event-level estimates -------------------------------------------------------
# - Number of office-based visits for mental health:       343,810,085 (SE: 22,252,863)
# - Total exp. for office-based mental health visits:  $60,209,392,314 (SE: 4,437,433,004)
# - Mean exp. per visit:                                       $175.12 (SE: 6.46)                     
   

# Define survey design
evntDsgn = svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT20F,
  data = ob_mh_fyc,
  nest = TRUE) 

subDsgn = subset(evntDsgn, mh_ob == 1)

# Calculate survey estimates
svytotal(~mh_ob_visit, design = subDsgn) # Number of visits
svytotal(~OBXP20X,  design = subDsgn)    # Total exp.
svymean(~OBXP20X,  design = subDsgn)     # Mean exp. per visit


# A note on Telehealth --------------------------------------------------------
#  - telehealth questions were added to the survey in Fall of 2020           
#  - TELEHEALTHFLAG = -15 for events reported before telehealth questions    
#  - Recommendation: imputation or sensitivity analysis                      

ob20 %>% 
  count(OBDATEMM, TELEHEALTHFLAG) %>% 
  pivot_wider(names_from = TELEHEALTHFLAG, values_from = n)


# Person-level estimates ------------------------------------------------------
#  - Number of people with office visit for MH:  29,816,984 (SE: 1,192,676)
#  - Percent of people with office visit for MH:      9.08% (SE: 0.29%)
#  - Mean exp per person for office visits for MH: $2019.30 (SE: 126.16) 
#  
#  - Number of visits (QC)       343,810,085 (SE: 22,252,863)
#  - Total exp. (QC)         $60,209,392,314 (SE: 4,437,433,004)


# Aggregate to person-level 
pers_mh = ob_mh_fyc %>% 
  group_by(DUPERSID, VARSTR, VARPSU, PERWT20F) %>% 
  summarize(
    persXP           = sum(OBXP20X),
    pers_nevents     = sum(mh_ob_visit),
    mh_ob_visit_pers = mean(mh_ob_visit),
    mh_ob_pers       = mean(mh_ob)) %>% 
  
  # replace missings with 0s
  replace_na(
    list(pers_nevents = 0, mh_ob_pers = 0, mh_ob_visit_pers = 0))


# QC - Should have:

  # - same number of records as fyc file
  nrow(pers_mh) == nrow(fyc20)

  # - mh_pers and mh_ob_visit = 1   OR
  # - mh_pers and mh_ob_visit = 0 
  pers_mh %>% ungroup %>% 
    count(mh_ob_pers, mh_ob_visit_pers) 

  # - pers_nevents = 0 when mh or mh_ob_visit = 0
  pers_mh %>% 
    ungroup %>% 
    filter(mh_ob_pers == 0 | mh_ob_visit_pers == 0) %>% 
    count(pers_nevents)
  
  # - view person with several events
  # (use zap_labels to hide the value formats)
  ob_mh_fyc %>% filter(DUPERSID == "2320109103") %>% zap_labels
  pers_mh %>% filter(DUPERSID == "2320109103") %>% zap_labels
  
  # - view person with 0 events
  ob_mh_fyc %>% filter(DUPERSID == "2320005101") %>% zap_labels
  pers_mh %>% filter(DUPERSID == "2320005101") %>% zap_labels
  

  
# Define person-level survey design -----------------
persDsgn = svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT20F,
  data = pers_mh,
  nest = TRUE) 

# Define subset of people with office-based mental health visits
persDsgn_OBMH = subset(persDsgn, mh_ob_pers == 1)



# Calculate survey estimates ------------------------
svytotal(~mh_ob_visit_pers, design = persDsgn)  # Number of people
svymean(~mh_ob_visit_pers, design = persDsgn)   # Percent of people
svymean(~persXP, design = persDsgn_OBMH)        # Mean exp. per person for 
                                                #  office-based mental health visits

# Duplicate event-level estimates for additional QC
svytotal(~pers_nevents, design = persDsgn_OBMH) # Number of visits
svytotal(~persXP,       design = persDsgn_OBMH) # Total exp.



