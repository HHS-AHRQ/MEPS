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

# Install/load packages -------------------------------------------------------

# Install packages (if needed) -- only need to run once (in a terminal)
#   pip install svy

# Load packages (need to run every session)
from pathlib import Path

import polars as pl
import svy

MEPS_DIR = Path("C:/MEPS")


# Load FYC file ---------------------------------------------------------------

FYC = svy.read_stata(MEPS_DIR / "h216.dta")

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


FYC = FYC.with_columns(
    # All event types
    TOTOTZ=pl.sum_horizontal("TOTOFD19", "TOTSTL19", "TOTOSR19", "TOTWCP19", "TOTVA19"),

    # Emergency room visits (facility + SBD expenses)
    ERTOTZ=pl.sum_horizontal("ERTOFD19", "ERTSTL19", "ERTOSR19", "ERTWCP19", "ERTVA19"),

    # Inpatient stays (facility + SBD expenses)
    IPTOTZ=pl.sum_horizontal("IPTOFD19", "IPTSTL19", "IPTOSR19", "IPTWCP19", "IPTVA19"),
)


# Define survey design --------------------------------------------------------

FYCdsgn = svy.Sample(
    data=FYC,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT19F", singleton="center"),
)


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
for est in FYCdsgn.estimation.mean(["TOTEXP19", "TOTSLF19", "TOTPTR19", "TOTMCR19", "TOTMCD19", "TOTOTZ"]):
    print(est)

# Emergency room visits
for est in FYCdsgn.estimation.mean(["ERTEXP19", "ERTSLF19", "ERTPTR19", "ERTMCR19", "ERTMCD19", "ERTOTZ"]):
    print(est)

# Inpatient stays
for est in FYCdsgn.estimation.mean(["IPTEXP19", "IPTSLF19", "IPTPTR19", "IPTMCR19", "IPTMCD19", "IPTOTZ"]):
    print(est)
