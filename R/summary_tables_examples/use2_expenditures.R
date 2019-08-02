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
#  For 1996-1999: TRICARE label is CHM (changed to TRI in 2000)
#
#  PTR = Private (PRV) + TRICARE (TRI) 
#  OTZ = other federal (OFD)  + State/local (STL) + other private (OPR) +
#         other public (OPU)  + other unclassified sources (OSR) +
#         worker's comp (WCP) + Veteran's (VA)

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
    OPTSLF_p = OPVSLF16  + OPSSLF16, # out-of-pocket payments
    OPTMCR_p = OPVMCR16  + OPSMCR16, # Medicare
    OPTMCD_p = OPVMCD16  + OPSMCD16, # Medicaid
    OPTPTR_p = OPVPTR    + OPSPTR,   # private insurance (including TRICARE)
    OPTOTZ_p = OPVOTZ    + OPSOTZ    # other sources of payment
  )


# Define survey design and calculate estimates --------------------------------

  FYCdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = FYC,
    nest = TRUE)


# Total expenditures
  
  totals <- 
    svytotal(~OBVSLF16 + OBVPTR + OBVMCR16 + OBVMCD16 + OBVOTZ +     # OB visits
               OBDSLF16 + OBDPTR + OBDMCR16 + OBDMCD16 + OBDOTZ +    # OB phys. 
               OPTSLF16 + OPTPTR   + OPTMCR16 + OPTMCD16 + OPTOTZ +  # OP visits
               OPTSLF_p + OPTPTR_p + OPTMCR_p + OPTMCD_p + OPTOTZ_p, # OP phys. visits
             design = FYCdsgn) 

  totals %>% as.data.frame()
  
  
# Mean expenditure per person

  means <- 
    svymean(~OBVSLF16 + OBVPTR + OBVMCR16 + OBVMCD16 + OBVOTZ +     # OB visits
              OBDSLF16 + OBDPTR + OBDMCR16 + OBDMCD16 + OBDOTZ +    # OB phys. 
              OPTSLF16 + OPTPTR   + OPTMCR16 + OPTMCD16 + OPTOTZ +  # OP visits
              OPTSLF_p + OPTPTR_p + OPTMCR_p + OPTMCD_p + OPTOTZ_p, # OP phys. visits
            design = FYCdsgn) 
  
  means %>% as.data.frame()


# Mean out-of-pocket expense per person with an out-of-pocket expense

  svymean(~OBVSLF16, design = subset(FYCdsgn, OBVSLF16 > 0)) # office-based visits
  svymean(~OBDSLF16, design = subset(FYCdsgn, OBDSLF16 > 0)) # office-based phys. visits

  svymean(~OPTSLF16, design = subset(FYCdsgn, OPTSLF16 > 0)) # OP visits
  svymean(~OPTSLF_p, design = subset(FYCdsgn, OPTSLF_p > 0)) # OP phys. visits
