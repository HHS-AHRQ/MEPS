# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Use, expenditures, and population, 2019
#
# Expenditures by event type and source of payment (SOP)
#  - Mean expenditure per person
#
# Selected event types:
#  - All event types (TOT)
#  - Emergency room visits (ERT)
#  - Inpatient stays (IPT)
#
# Input file: C:/MEPS/h216.dta (2019 full-year consolidated)
# -----------------------------------------------------------------------------

# Install/load packages and set global options --------------------------------

# Install packages (if needed) -- only need to run once
  install.packages("survey")
  install.packages("dplyr")
  install.packages("haven")

# Load packages (need to run every session)
  library(survey)
  library(dplyr)
  library(haven)

# Set survey option for lonely psu
  options(survey.lonely.psu="adjust")


# Load FYC file ---------------------------------------------------------------

  FYC <- read_dta("C:/MEPS/h216.dta")

# Aggregate payment sources ---------------------------------------------------
#
#  Notes:
#   - For 1996-1999: TRICARE label is CHM (changed to TRI in 2000)
#
#   - For 1996-2006: combined facility + SBD variables for hospital-type events
#      are not on PUF
#
#   - Starting in 2019, 'Other public' (OPU) and 'Other private' (OPR) are  
#      dropped from the files 
#
#
#  OTZ = other federal (OFD)  + State/local (STL) + 
#         other unclassified sources (OSR) +
#         worker's comp (WCP) + Veteran's (VA)


  FYC <- FYC %>% mutate(

  # All event types
    TOTOTZ = TOTOFD19 + TOTSTL19 + TOTOSR19 + TOTWCP19 + TOTVA19,
    
  # Emergency room visits (facility + SBD expenses)
    ERTOTZ = ERTOFD19 + ERTSTL19 + ERTOSR19 + ERTWCP19 + ERTVA19,

  # Inpatient stays (facility + SBD expenses)
    IPTOTZ = IPTOFD19 + IPTSTL19 + IPTOSR19 + IPTWCP19 + IPTVA19
  )


# Define survey design -------------------------------------------------------- 
  
  FYCdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT19F,
    data = FYC,
    nest = TRUE)

# Calculate estimates ---------------------------------------------------------
#
# Sources of payment (SOP) abbreviations:
#  - EXP: All sources
#  - SLF: Out-of-pocket
#  - PTR: Private insurance, including TRICARE (PTR)
#  - MCR: Medicare 
#  - MCD: Medicaid
#  - OTZ: Other 

  
# Mean expenditure per person, by source of payment

  # All event types
  svymean(~TOTEXP19 + TOTSLF19 + TOTPTR19 + TOTMCR19 + TOTMCD19 + TOTOTZ, design = FYCdsgn)
  
  # Emergency room visits
  svymean(~ERTEXP19 + ERTSLF19 + ERTPTR19 + ERTMCR19 + ERTMCD19 + ERTOTZ, design = FYCdsgn)
  
  # Inpatient stays
  svymean(~IPTEXP19 + IPTSLF19 + IPTPTR19 + IPTMCR19 + IPTMCD19 + IPTOTZ, design = FYCdsgn)
  
