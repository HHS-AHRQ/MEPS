# -----------------------------------------------------------------------------
# Use, expenditures, and population
#
# Expenditures by event type and source of payment (SOP)
#
# Example R code to replicate the following estimates in the MEPS-HC summary
#  tables, by source of payment (SOP), for selected event types:
#  - total expenditures
#  - mean expenditure per person
#  - mean out-of-pocket (SLF) payment per person with a SLF payment
#
# Selected event types:
#  - Office-based medical visits (OBV)
#  - Office-based physician visits (OBD)
#  - Outpatient visits (OPT)
#  - Outpatient physician visits (OPV)
#
# Sources of payment (SOPs):
#  - Out-of-pocket (SLF)
#  - Medicare (MCR)
#  - Medicaid (MCD)
#  - Private insurance, including TRICARE (PTR)
#  - Other (OTH)
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


# Load FYC file ---------------------------------------------------------------

  FYC <- read_MEPS(year = 2016, type = "FYC")

# Aggregate payment sources ---------------------------------------------------
#  PTR = Private (PRV) + TRICARE (TRI)
#  OTZ = other federal (OFD)  + State/local (STL) + other private (OPR) +
#         other public (OPU)  + other unclassified sources (OSR) +
#         worker's comp (WCP) + Veteran's (VA)

# Notes on source of payment categories:
#  1996-1999: TRICARE label is CHM (changed to TRI in 2000)

  FYC <- FYC %>% mutate(

  # office-based visits
    OBVPTR = OBVPRV16 + OBVTRI16,
    OBVOTZ = OBVOFD16 + OBVSTL16 + OBVOPR16 + OBVOPU16 + OBVOSR16 + OBVWCP16 + OBVVA16,

  # office-based physician visits
    OBDPTR = OBDPRV16 + OBDTRI16,
    OBDOTZ = OBDOFD16 + OBDSTL16 + OBDOPR16 + OBDOPU16 + OBDOSR16 + OBDWCP16 + OBDVA16,

  # outpatient visits (facility + SBD expenses)
  #  - For 1996-2006: combined facility + SBD variables are not on PUF
    OPTPTR = OPTPRV16 + OPTTRI16,
    OPTOTZ = OPTOFD16 + OPTSTL16 + OPTOPR16 + OPTOPU16 + OPTOSR16 + OPTWCP16 + OPTVA16,

  # outpatient physician visits (facility expense)
    OPVPTR = OPVPRV16 + OPVTRI16,
    OPVOTZ = OPVOFD16 + OPVSTL16 + OPVOPR16 + OPVOPU16 + OPVOSR16 + OPVWCP16 + OPVVA16,

  # outpatient physician visits (SBD expense)
    OPSPTR = OPSPRV16 + OPSTRI16,
    OPSOTZ = OPSOFD16 + OPSSTL16 + OPSOPR16 + OPSOPU16 + OPSOSR16 + OPSWCP16 + OPSVA16
  )


# Combine facility and SBD expenses for hospital-type events ------------------
#  Note: for 1996-2006, also need to create OPT*** = OPF*** + OPD***

  FYC <- FYC %>% mutate(
    OPTSLF_phys = OPVSLF16  + OPSSLF16, # out-of-pocket payments
    OPTMCR_phys = OPVMCR16  + OPSMCR16, # Medicare
    OPTMCD_phys = OPVMCD16  + OPSMCD16, # Medicaid
    OPTPTR_phys = OPVPTR    + OPSPTR,   # private insurance (including TRICARE)
    OPTOTZ_phys = OPVOTZ    + OPSOTZ    # other sources of payment
  )


# Define survey design and calculate estimates --------------------------------

  FYCdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = FYC,
    nest = TRUE)


# Total expenditures

  svytotal(~OBVSLF16 + OBVPTR + OBVMCR16 + OBVMCD16 + OBVOTZ, design = FYCdsgn) # office-based visits
  svytotal(~OBDSLF16 + OBDPTR + OBDMCR16 + OBDMCD16 + OBDOTZ, design = FYCdsgn) # office-based phys. visits

  svytotal(~OPTSLF16    + OPTPTR      + OPTMCR16    + OPTMCD16    + OPTOTZ,      design = FYCdsgn) # OP visits
  svytotal(~OPTSLF_phys + OPTPTR_phys + OPTMCR_phys + OPTMCD_phys + OPTOTZ_phys, design = FYCdsgn) # OP phys. visits


# Mean expenditure per person

  svymean(~OBVSLF16 + OBVPTR + OBVMCR16 + OBVMCD16 + OBVOTZ, design = FYCdsgn) # office-based visits
  svymean(~OBDSLF16 + OBDPTR + OBDMCR16 + OBDMCD16 + OBDOTZ, design = FYCdsgn) # office-based phys. visits

  svymean(~OPTSLF16    + OPTPTR      + OPTMCR16    + OPTMCD16    + OPTOTZ,      design = FYCdsgn) # OP visits
  svymean(~OPTSLF_phys + OPTPTR_phys + OPTMCR_phys + OPTMCD_phys + OPTOTZ_phys, design = FYCdsgn) # OP phys. visits


# Mean out-of-pocket expense per person with an out-of-pocket expense

  svymean(~OBVSLF16, design = subset(FYCdsgn, OBVSLF16 > 0)) # office-based visits
  svymean(~OBDSLF16, design = subset(FYCdsgn, OBDSLF16 > 0)) # office-based phys. visits

  svymean(~OPTSLF16,    design = subset(FYCdsgn, OPTSLF16 > 0))    # OP visits
  svymean(~OPTSLF_phys, design = subset(FYCdsgn, OPTSLF_phys > 0)) # OP phys. visits
