# -----------------------------------------------------------------------------
# 
# DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS LONGITUDINAL DATA 
#  FILES FROM DIFFERENT PANELS
#
# THE EXAMPLE USED IS PANELS 17-19 POPULATION AGE 26-30 WHO ARE UNINSURED BUT 
#  HAVE HIGH INCOME IN THE FIRST YEAR
# 
# DATA FROM PANELS 17, 18, AND 19 ARE POOLED.
# 
# INPUT FILES:  (1) C:\MEPS\SAS\DATA\H183.ssp (PANEL 19 LONGITUDINAL FILE)
# 	            (2) C:\MEPS\SAS\DATA\H172.ssp (PANEL 18 LONGITUDINAL FILE)
# 	            (3) C:\MEPS\SAS\DATA\H164.ssp (PANEL 17 LONGITUDINAL FILE)
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

varlist = c("DUPERSID", "INSCOVY1", "INSCOVY2", 
            "LONGWT", "VARSTR", "VARPSU", 
            "POVCATY1", "AGEY1X", "PANEL")

h183 = read.xport("C:/MEPS/h183.ssp") %>% select(one_of(varlist)) # Panel 19
h172 = read.xport("C:/MEPS/h172.ssp") %>% select(one_of(varlist)) # Panel 18
h164 = read.xport("C:/MEPS/h164.ssp") %>% select(one_of(varlist)) # Panel 17

# Stack longitudinal files and define pooled weight variable and subpop of interest
#  subpop = age 26-30, uninsured, high income 

pool = bind_rows(h183, h172, h164) %>%
  mutate(poolwt = LONGWT / 3,
         subpop = (26 <= AGEY1X & AGEY1X <= 30 & POVCATY1 == 5 & INSCOVY1 == 3))

pool %>% 
  filter(subpop) %>%
  summary

head(pool)



# Define the survey design  

mepsdsgn = svydesign(
  id = ~VARPSU, 
  strata = ~VARSTR, 
  weights = ~poolwt, 
  data = pool, 
  nest = TRUE)  


# INSURANCE STATUS IN THE SECOND YEAR FOR THOSE W/ AGE=26-30, UNINSURED WHOLE YEAR, AND HIGH INCOME IN THE FIRST YEAR'

svymean(~as.factor(INSCOVY2), design = subset(mepsdsgn, subpop))
