# -----------------------------------------------------------------------------
# Use, expenditures, and population
#
# Utilization and expenditures by event type and source of payment (SOP)
#  based on event files
#
# Example R code to replicate the following estimates in the MEPS-HC summary
#  tables for selected event types:
#  - total number of events
#  - mean expenditure per event, by source of payment
#  - mean events per person, for office-based visits

# Selected event types:
#  - Office-based medical visits (OBV)
#  - Office-based physician visits (OBD)
#  - Outpatient visits (OPT)
#  - Outpatient physician visits (OPV)
#
# Sources of payment (SOPs):
#  - Out-of-pocket (SF)
#  - Medicare (MR)
#  - Medicaid (MD)
#  - Private insurance, including TRICARE (PR)
#  - Other (OZ)
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


# Load datasets ---------------------------------------------------------------

# Load FYC file and keep only needed variables
  FYC <- read_MEPS(year = 2016, type = "FYC") %>%
    select(DUPERSID, PERWT16F, VARSTR, VARPSU)

# Load event files
  OP <- read_MEPS(year = 2016, type = "OP") # outpatient visits
  OB <- read_MEPS(year = 2016, type = "OB") # office-based medical visits

# Aggregate payment sources for each dataset ----------------------------------
#  For 1996-1999: TRICARE label is CHM (changed to TRI in 2000)
#
#  PR = Private (PV) + TRICARE (TR)
#  OZ = other federal (OF)  + State/local (SL) + other private (OR) +
#        other public (OU)  + other unclassified sources (OT) +
#        worker's comp (WC) + Veteran's (VA)
  
  OB <- OB %>% 
    mutate(
      PR = OBPV16X + OBTR16X,
      OZ = OBOF16X + OBSL16X + OBVA16X + OBOT16X + OBOR16X + OBOU16X + OBWC16X
    ) %>% 
    filter(OBXP16X >= 0) # Remove inapplicable events 
  
  OP <- OP %>% 
    mutate(
      PR_fac = OPFPV16X + OPFTR16X,
      PR_sbd = OPDPV16X + OPDTR16X,
      
      OZ_fac = OPFOF16X + OPFSL16X + OPFOR16X + OPFOU16X + OPFVA16X + OPFOT16X + OPFWC16X,
      OZ_sbd = OPDOF16X + OPDSL16X + OPDOR16X + OPDOU16X + OPDVA16X + OPDOT16X + OPDWC16X
    ) %>% 
    filter(OPXP16X >= 0) # Remove inapplicable events


# Combine facility and SBD expenses for hospital-type events ------------------

  OP <- OP %>% mutate(
    SF = OPFSF16X + OPDSF16X, # out-of-pocket payments
    MR = OPFMR16X + OPDMR16X, # Medicare
    MD = OPFMD16X + OPDMD16X, # Medicaid
    PR = PR_fac + PR_sbd,     # private insurance (including TRICARE)
    OZ = OZ_fac + OZ_sbd      # other sources of payment
  )


# Merge with FYC to retain all PSUs -------------------------------------------
  OB_FYC <- OB %>% 
    mutate(count = 1) %>%                    # add counter for total events
    select(-VARSTR, -VARPSU, -PERWT16F) %>%  # remove to avoid merge conflicts
    full_join(FYC)
  
  OP_FYC <- OP %>% 
    mutate(count = 1) %>%                    # add counter for total events
    select(-VARSTR, -VARPSU, -PERWT16F) %>%  # remove to avoid merge conflicts
    full_join(FYC)
  
  
# Define survey design and calculate estimates --------------------------------
  OB_dsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = OB_FYC,
    nest = TRUE)
  
  OP_dsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT16F,
    data = OP_FYC,
    nest = TRUE)


# Total number of events

  svytotal(~count, design = subset(OB_dsgn, OBXP16X >= 0))               # office-based visits
  svytotal(~count, design = subset(OB_dsgn, OBXP16X >= 0 & SEEDOC == 1)) # office-based phys. visits

  svytotal(~count, design = subset(OP_dsgn, OPXP16X >= 0))               # OP visits
  svytotal(~count, design = subset(OP_dsgn, OPXP16X >= 0 & SEEDOC == 1)) # OP phys. visits


# Mean expenditure per event, by source of payment

  svymean(~OBSF16X + PR + OBMR16X + OBMD16X + OZ, design = subset(OB_dsgn, OBXP16X >= 0))
  svymean(~OBSF16X + PR + OBMR16X + OBMD16X + OZ, design = subset(OB_dsgn, OBXP16X >= 0 & SEEDOC == 1))

  svymean(~SF + PR + MR + MD + OZ, design = subset(OP_dsgn, OPXP16X >= 0))
  svymean(~SF + PR + MR + MD + OZ, design = subset(OP_dsgn, OPXP16X >= 0 & SEEDOC == 1))


# Mean events per person, office-based medical visits -------------------------

  # Aggregate to person level
    pers_OB <- OB_FYC %>%
      group_by(DUPERSID, VARSTR, VARPSU) %>%
      summarize(
        PERWT16F = mean(PERWT16F),
        n_events = sum(count, na.rm = T),
        n_phys_events = sum(count*(SEEDOC == 1), na.rm = T)) %>%
      ungroup

  # Define survey design
    pers_OB_dsgn <- svydesign(
      id = ~VARPSU,
      strata = ~VARSTR,
      weights = ~PERWT16F,
      data = pers_OB,
      nest = TRUE)

  # Mean events per person
    svymean(~n_events + n_phys_events, design = pers_OB_dsgn)

    