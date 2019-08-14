# -----------------------------------------------------------------------------
# 
# PURPOSE: THIS PROGRAM GENERATES SELECTED ESTIMATES FOR A 2016 VERSION OF 
#          Purchases and Expenses for Narcotic analgesics or Narcotic analgesic combos
#           	
#  - TOTAL EXPENSE FOR Narcotic analgesics or Narcotic analgesic combos
# 
#  - TOTAL NUMBER OF PURCHASES OF Narcotic analgesics or Narcotic analgesic combos
# 
#  - AVERAGE TOTAL, OUT OF POCKET, AND THIRD PARTY PAYER EXPENSE FOR Narcotic 
#        analgesics or Narcotic analgesic combos PER PERSON WITH A 
#        Narcotic analgesics or Narcotic analgesic combos MEDICINE PURCHASE
# 
#   INPUT FILES:  (1) C:\MEPS\STATA\DATA\H192.ssp  (2016 FULL-YEAR CONSOLIDATED PUF)
#                 (2) C:\MEPS\STATA\DATA\H188A.ssp (2016 PRESCRIBED MEDICINES PUF)
#
# -----------------------------------------------------------------------------

# Install and load libraries
  
  # Can skip this part if already installed 
  install.packages("survey")
  install.packages("foreign")
  install.packages("dplyr")
  
  # Run this part each time you re-start R  
  library(survey)
  library(foreign)
  library(dplyr)

# Set options to deal with lonely psu 
options(survey.lonely.psu='adjust');


# Read in data 
h192  = read.xport("C:/MEPS/h192.ssp") # 2016 FYC
h188a = read.xport("C:/MEPS/h188a.ssp") # 2016 RX

# Identify Narcotic analgesics or Narcotic analgesic combos using therapeutic classification (tc) codes

narc = h188a %>%
  filter(TC1S1_1 %in% c(60, 191)) %>%
  select(DUPERSID, RXRECIDX, LINKIDX, TC1S1_1, RXXP16X, RXSF16X)

head(narc)
table(narc$TC1S1_1)

# Sum data to person-level

narc_pers = narc %>%
  group_by(DUPERSID) %>%
  summarise(tot = sum(RXXP16X),
            oop = sum(RXSF16X),
            n_purchase = n()) %>%
  mutate(third_payer = tot - oop,
         any_narc = 1)

head(narc_pers)

# Merge the person-level expenditures to the fy puf to get complete PSUs, Strata

fyc = h192 %>% select(DUPERSID, VARSTR, VARPSU, PERWT16F)

narc_fyc = full_join(narc_pers, fyc, by = "DUPERSID")

head(narc_fyc)


# Define the survey design  

mepsdsgn = svydesign(
  id = ~VARPSU, 
  strata = ~VARSTR, 
  weights = ~PERWT16F, 
  data = narc_fyc, 
  nest = TRUE)  

# Calculate estimates on expenditures and use

svymean(~n_purchase + tot + oop + third_payer, 
        design = subset(mepsdsgn, any_narc == 1))

svytotal(~n_purchase + tot + oop + third_payer, 
        design = subset(mepsdsgn, any_narc == 1))

