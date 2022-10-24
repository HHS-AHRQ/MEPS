# -----------------------------------------------------------------------------
# This program includes a regression example for persons delaying medical care
# because of COVID, including:
#  - Percentage of people who delayed care
#  - Logistic regression: to identify demographic factors associated with
#    delayed care
#
# Input file: 
#  - C:/MEPS/h224.dta (2020 Full-year file)
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------
# 
# Can skip this part if already installed
# install.packages("survey")   # for survey analysis
# install.packages("foreign")  # for loading SAS transport (.ssp) files
# install.packages("haven")    # for loading Stata (.dta) files
# install.packages("dplyr")    # for data manipulation
# install.packages("devtools") # for loading "MEPS" package from GitHub
# 
# devtools::install_github("e-mitchell/meps_r_pkg/MEPS") # easier file import


# Run this part each time you re-start R
  library(survey)
  library(foreign)
  library(haven)
  library(dplyr)
  library(MEPS)


# Set options to deal with lonely psu
  options(survey.lonely.psu='adjust');


# Read in data from FYC file --------------------------------------------------

  fyc20 = read_MEPS(year = 2020, type = "FYC") # 2020 FYC

  # # Alternative:
  # fyc20 = read_dta("C:/MEPS/h224.dta") # 2020 FYC

  # View data
  fyc20 %>% 
    select(DUPERSID, AGELAST, SEX, RACETHX, INSCOV20, REGION53, matches("CVDLAY"))


  
# Keep only needed variables --------------------------------------------------
  fyc20_sub <- fyc20 %>%
    select(DUPERSID, VARPSU, VARSTR, PERWT20F,
           matches("CVDLAY"), AGELAST, SEX, RACETHX, INSCOV20, REGION53)
  
  
# Create variables ------------------------------------------------------------
#  - Convert CVDLAY**53 from 1/2 to 0/1 (for logistic regression)
#  - Create 'subpop' to exclude people with Missing 'CVDLAY**'
  
 
  fyc20x <- fyc20_sub %>% 
    mutate(
      
      CVDLAYCA53 = as.numeric(CVDLAYCA53),
      CVDLAYDN53 = as.numeric(CVDLAYDN53),
      CVDLAYPM53 = as.numeric(CVDLAYPM53),
      
      
      # Convert outcome from 1/2 to 0/1:
      covid_delay_CARE = case_when(
        CVDLAYCA53 == 1 ~ 1,
        CVDLAYCA53 == 2 ~ 0,
        TRUE ~ CVDLAYCA53),
      
      covid_delay_DENTAL = case_when(
        CVDLAYDN53 == 1 ~ 1,
        CVDLAYDN53 == 2 ~ 0,
        TRUE ~ CVDLAYDN53),
      
      covid_delay_PMED = case_when(
        CVDLAYPM53 == 1 ~ 1,
        CVDLAYPM53 == 2 ~ 0,
        TRUE ~ CVDLAYPM53),
      
      
      # Create subpops to exclude Missings
      subpop_CARE   = (CVDLAYCA53 >= 0),
      subpop_DENTAL = (CVDLAYDN53 >= 0),
      subpop_PMED   = (CVDLAYPM53 >= 0))
  
  
  # QC new variables
  fyc20x %>% count(covid_delay_CARE,   CVDLAYCA53, subpop_CARE)
  fyc20x %>% count(covid_delay_DENTAL, CVDLAYDN53, subpop_DENTAL)
  fyc20x %>% count(covid_delay_PMED,   CVDLAYPM53, subpop_PMED)
  
  
# Check variables in regression -----------------------------------------------
  
  fyc20x %>% count(SEX)
  # SEX: 
  #   1 = MALE
  #   2 = FEMALE
  
  fyc20x %>% count(RACETHX)
  # RACETHX: 
  #   1 = HISPANIC
  #   2 = NON-HISPANIC WHITE
  #   3 = NON-HISPANIC BLACK
  #   4 = NON-HISPANIC ASIAN
  #   5 = NON-HISPANIC OTHER/MULTIPLE
  
  fyc20x %>% count(INSCOV20)
  # INSCOV:
  #   1 = ANY PRIVATE
  #   2 = PUBLIC ONLY
  #   3 = UNINSURED
  
  fyc20x %>% count(REGION53)
  # REGION53:
  #   1 = NORTHEAST
  #   2 = MIDWEST
  #   3 = SOUTH
  #   4 = WEST
  
  
  fyc20x %>% pull(AGELAST) %>% summary
  # AGELAST: 0-85

  
# Define the survey design ----------------------------------------------------
  
  meps_dsgn = svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT20F,
    data = fyc20x,
    nest = TRUE)


  
# Calculate survey estimates ---------------------------------------------------
#  - Percentage of people delaying care
#  - Logistic regression: to identify demographic factors associated with
#    delayed care  

# Percentage of people delaying care
  svymean(~covid_delay_CARE,   design = subset(meps_dsgn, subpop_CARE))
  svymean(~covid_delay_DENTAL, design = subset(meps_dsgn, subpop_DENTAL))
  svymean(~covid_delay_PMED,   design = subset(meps_dsgn, subpop_PMED))
  
  
# Logistic regression
# - specify 'family = quasibinomial' to get rid of warning messages
  
  # Delaying Medical Care
  svyglm(
    covid_delay_CARE ~ AGELAST + as.factor(SEX) + as.factor(RACETHX) + 
      as.factor(INSCOV20) + as.factor(REGION53), 
    design = subset(meps_dsgn, subpop_CARE), family = quasibinomial) %>%  
    summary
  
  # Delaying Dental Care
  svyglm(
    covid_delay_DENTAL ~ AGELAST + as.factor(SEX) + as.factor(RACETHX) + 
      as.factor(INSCOV20) + as.factor(REGION53), 
    design = subset(meps_dsgn, subpop_DENTAL), family = quasibinomial) %>%  
    summary
  
  # Delaying PMEDs 
  svyglm(
    covid_delay_PMED ~ AGELAST + as.factor(SEX) + as.factor(RACETHX) + 
      as.factor(INSCOV20) + as.factor(REGION53), 
    design = subset(meps_dsgn, subpop_PMED), family = quasibinomial) %>%  
    summary
  
  
  
  
  