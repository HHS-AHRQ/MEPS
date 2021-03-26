# -----------------------------------------------------------------------------
# This program includes a regression example for persons receiving a flu shot
# in the last 12 months for the U.S. civilian non-institutionalized population, 
# including:
#  - Percentage of people with a flu shot
#  - Logistic regression: to identify demographic factors associated with
#    receiving a flu shot
#
# Input file: 
#  - C:/MEPS/h209.dat (2018 Full-year file)
#
# This program is available at:
# https://github.com/HHS-AHRQ/MEPS-workshop/tree/master/r_exercises
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------
# 
#   # Can skip this part if already installed
#   install.packages("survey")
#   install.packages("foreign")
#   install.packages("dplyr")
#   install.packages("devtools")
#   
#   # Run this part each time you re-start R
#   library(survey)
#   library(foreign)
#   library(dplyr)
#   library(devtools)
#   
#   # This package facilitates file import
#   install_github("e-mitchell/meps_r_pkg/MEPS") 
#   library(MEPS)

# Set options to deal with lonely psu
  options(survey.lonely.psu='adjust');


# Read in data from FYC file --------------------------------------------------
#  !! IMPORTANT -- must use ASCII (.dat) file for 2018 data !!

  fyc18 = read_MEPS(year = 2018, type = "FYC") # 2018 FYC

  # View data
  fyc18 %>% select(DUPERSID, ADFLST42, AGELAST, SEX, RACETHX, INSCOV18)

  fyc18 %>% 
    filter(SAQWT18F > 0) %>% 
    count(ADFLST42)
  
# Keep only needed variables --------------------------------------------------
  fyc18_sub <- fyc18 %>%
    select(DUPERSID, VARPSU, VARSTR,
           ADFLST42, AGELAST, SEX, RACETHX, INSCOV18, matches("SAQ"))
  
  
# Create variables ------------------------------------------------------------
#  - Convert ADFLST42 from 1/2 to 0/1 (for logistic regression)
#  - Create 'subpop' to exclude people with Missing 'ADFLST42'
  
 
  fyc18x <- fyc18_sub %>%
    mutate(
      
      # Convert outcome from 1/2 to 0/1:
      flu_shot = case_when(
        ADFLST42 == 1 ~ 1,
        ADFLST42 == 2 ~ 0,
        TRUE ~ ADFLST42),
      
      # Create subpop to exclude Missings
      subpop = (ADFLST42 >= 0))
  
  
  # QC new variable
  fyc18x %>% 
    # filter(SAQWT18F > 0) %>%
    count(flu_shot, ADFLST42, subpop)
  
  
# Check variables in regression -----------------------------------------------
  
  fyc18x %>% count(SEX)
  # SEX: 
  #   1 = MALE
  #   2 = FEMALE
  
  fyc18x %>% count(RACETHX)
  # RACETHX: 
  #   1 = HISPANIC
  #   2 = NON-HISPANIC WHITE
  #   3 = NON-HISPANIC BLACK
  #   4 = NON-HISPANIC ASIAN
  #   5 = NON-HISPANIC OTHER/MULTIPLE
  
  fyc18x %>% count(INSCOV18)
  # INSCOV:
  #   1 = ANY PRIVATE
  #   2 = PUBLIC ONLY
  #   3 = UNINSURED
  
  
  fyc18x %>% pull(AGELAST) %>% summary
  # AGELAST: 0-85

  
# Define the survey design ----------------------------------------------------
  
  saq_dsgn = svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~SAQWT18F,
    data = fyc18x,
    nest = TRUE)

  flu_dsgn = subset(saq_dsgn, subpop)

  
  # QC sub-design
  saq_dsgn$variables %>% count(flu_shot)
  flu_dsgn$variables %>% count(flu_shot)

  
# Calculate survey estimates ---------------------------------------------------
#  - Percentage of people with a flu shot
#  - Logistic regression: to identify demographic factors associated with
#    receiving a flu shot  

# Percentage of people with a flu shot
  svymean(~flu_shot, design = flu_dsgn)
  
# Logistic regression
# - specify 'family = quasibinomial' to get rid of warning messages
  
  svyglm(
    flu_shot ~ AGELAST + as.factor(SEX) + as.factor(RACETHX) + as.factor(INSCOV18), 
    design = flu_dsgn, family = quasibinomial) %>%  
    summary
  