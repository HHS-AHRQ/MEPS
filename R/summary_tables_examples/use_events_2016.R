# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Use, expenditures, and population, 2016
#
# Utilization and expenditures by event type and source of payment (SOP)
#  - Total number of events
#  - Mean expenditure per event, by source of payment
#  - Mean events per person, for office-based visits
#
# Selected event types:
#  - Office-based medical visits (OBV)
#  - Office-based physician visits (OBD)
#  - Outpatient visits (OPT)
#  - Outpatient physician visits (OPV)
#
# Input files:
#  - C:/MEPS/h192.ssp  (2016 full-year consolidated)
#  - C:/MEPS/h188f.ssp (2016 OP event file)
#  - C:/MEPS/h188g.ssp (2016 OB event file)
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


# Load datasets ---------------------------------------------------------------

# Load FYC file and keep only needed variables
  FYC <- read.xport("C:/MEPS/h192.ssp") %>%
    select(DUPERSID, PERWT16F, VARSTR, VARPSU)

# Load event files
  OP <- read.xport("C:/MEPS/h188f.ssp") # outpatient visits
  OB <- read.xport("C:/MEPS/h188g.ssp") # office-based medical visits

# Aggregate payment sources for each dataset ----------------------------------
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
#  PR = Private (PV) + TRICARE (TR)
#
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
    mutate(
      count = 1,        # add counter for total events
      domain = 1) %>%   # add domain to subset design after merging with FYC
    select(-VARSTR, -VARPSU, -PERWT16F) %>%  # remove to avoid merge conflicts
    full_join(FYC)

  OP_FYC <- OP %>%
    mutate(
      count = 1,        # add counter for total events
      domain = 1) %>%   # add domain to subset design after merging with FYC
    select(-VARSTR, -VARPSU, -PERWT16F) %>%  # remove to avoid merge conflicts
    full_join(FYC)


# Define survey designs -------------------------------------------------------
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

  
# Calculate estimates ---------------------------------------------------------
#
# Sources of payment (SOP) abbreviations:
#  - SF: Out-of-pocket
#  - PR: Private insurance, including TRICARE (PTR)
#  - MR: Medicare 
#  - MD: Medicaid
#  - OZ: Other 

# Subset to people in domain (defined previously)
  OB_dsgn = subset(OB_dsgn, domain == 1)
  OP_dsgn = subset(OP_dsgn, domain == 1)

# For 'physician visits' subset to people with SEEDOC = 1  
  OBdoc_dsgn = subset(OB_dsgn, SEEDOC == 1)
  OPdoc_dsgn = subset(OP_dsgn, SEEDOC == 1)


# Total number of events, by event type

  svytotal(~count, design = OB_dsgn)    # office-based (OB) visits
  svytotal(~count, design = OBdoc_dsgn) # office-based (OB) physician visits

  svytotal(~count, design = OP_dsgn)    # outpatient (OP) visits
  svytotal(~count, design = OPdoc_dsgn) # outpatient (OP) physician visits


# Mean expenditure per event, by event type and source of payment

  svymean(~OBSF16X + PR + OBMR16X + OBMD16X + OZ, design = OB_dsgn)    # OB visits
  svymean(~OBSF16X + PR + OBMR16X + OBMD16X + OZ, design = OBdoc_dsgn) # OB phys. visits

  svymean(~SF + PR + MR + MD + OZ, design = OP_dsgn)    # OP visits
  svymean(~SF + PR + MR + MD + OZ, design = OPdoc_dsgn) # OP phys. visits


# Mean events per person, office-based medical visits 

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
    svymean(~n_events,      design = pers_OB_dsgn) # office-based visits
    svymean(~n_phys_events, design = pers_OB_dsgn) # office-based phys. visits
