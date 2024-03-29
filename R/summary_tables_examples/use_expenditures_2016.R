# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Use, expenditures, and population, 2016
#
# Expenditures by event type and source of payment (SOP)
#  - Total expenditures
#  - Mean expenditure per person
#  - Mean out-of-pocket (SLF) payment per person with an out-of-pocket expense
#
# Selected event types:
#  - Office-based medical visits (OBV)
#  - Office-based physician visits (OBD)
#  - Outpatient visits (OPT)
#  - Outpatient physician visits (OPV)
#
# Input file: C:/MEPS/h192.ssp (2016 full-year consolidated)
# -----------------------------------------------------------------------------

# Install/load packages and set global options --------------------------------

# Install packages (if needed) -- only need to run once
  install.packages("survey")
  install.packages("dplyr")
  install.packages("foreign")

# Load packages (need to run every session)
  library(survey)
  library(dplyr)
  library(foreign)

# Set survey option for lonely psu
  options(survey.lonely.psu="adjust")


# Load FYC file ---------------------------------------------------------------

  FYC <- read.xport("C:/MEPS/h192.ssp")

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
#  PTR = Private (PRV) + TRICARE (TRI)
#
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
    OPTSLF_p = OPVSLF16 + OPSSLF16, # out-of-pocket payments
    OPTMCR_p = OPVMCR16 + OPSMCR16, # Medicare
    OPTMCD_p = OPVMCD16 + OPSMCD16, # Medicaid
    OPTPTR_p = OPVPTR   + OPSPTR,   # private insurance (including TRICARE)
    OPTOTZ_p = OPVOTZ   + OPSOTZ    # other sources of payment
  )


# Define survey design -------------------------------------------------------- 

  FYCdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = FYC,
    nest = TRUE)
  
# Calculate estimates ---------------------------------------------------------
#
# Sources of payment (SOP) abbreviations:
#  - SLF: Out-of-pocket
#  - PTR: Private insurance, including TRICARE (PTR)
#  - MCR: Medicare 
#  - MCD: Medicaid
#  - OTZ: Other 
  
  
# Total expenditures, by event type and source of payment

  totals <-
    svytotal(~OBVSLF16 + OBVPTR + OBVMCR16 + OBVMCD16 + OBVOTZ +     # OB visits
               OBDSLF16 + OBDPTR + OBDMCR16 + OBDMCD16 + OBDOTZ +    # OB phys. visits
               OPTSLF16 + OPTPTR   + OPTMCR16 + OPTMCD16 + OPTOTZ +  # OP visits
               OPTSLF_p + OPTPTR_p + OPTMCR_p + OPTMCD_p + OPTOTZ_p, # OP phys. visits
             design = FYCdsgn)

  totals %>% as.data.frame()


# Mean expenditure per person, by event type and source of payment

  means <-
    svymean(~OBVSLF16 + OBVPTR + OBVMCR16 + OBVMCD16 + OBVOTZ +     # OB visits
              OBDSLF16 + OBDPTR + OBDMCR16 + OBDMCD16 + OBDOTZ +    # OB phys. visits
              OPTSLF16 + OPTPTR   + OPTMCR16 + OPTMCD16 + OPTOTZ +  # OP visits
              OPTSLF_p + OPTPTR_p + OPTMCR_p + OPTMCD_p + OPTOTZ_p, # OP phys. visits
            design = FYCdsgn)

  means %>% as.data.frame()


# Mean expenditure per person with expense
#  - Mean out-of-pocket expense per person with an out-of-pocket expense

  svymean(~OBVSLF16, design = subset(FYCdsgn, OBVSLF16 > 0)) # office-based visits
  svymean(~OBDSLF16, design = subset(FYCdsgn, OBDSLF16 > 0)) # office-based phys. visits

  svymean(~OPTSLF16, design = subset(FYCdsgn, OPTSLF16 > 0)) # OP visits
  svymean(~OPTSLF_p, design = subset(FYCdsgn, OPTSLF_p > 0)) # OP phys. visits
