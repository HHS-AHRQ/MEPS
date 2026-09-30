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

# Install/load packages -------------------------------------------------------

# Install packages (if needed) -- only need to run once (in a terminal)
#   pip install svy

# Load packages (need to run every session)
from pathlib import Path

import polars as pl
import svy

MEPS_DIR = Path("C:/MEPS")


# Load FYC file ---------------------------------------------------------------

FYC = svy.read_sas(MEPS_DIR / "h192.ssp")

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


FYC = FYC.with_columns(
    # office-based visits
    OBVPTR=pl.sum_horizontal("OBVPRV16", "OBVTRI16"),
    OBVOTZ=pl.sum_horizontal("OBVOFD16", "OBVSTL16", "OBVOPR16", "OBVOPU16", "OBVOSR16", "OBVWCP16", "OBVVA16"),

    # office-based physician visits
    OBDPTR=pl.sum_horizontal("OBDPRV16", "OBDTRI16"),
    OBDOTZ=pl.sum_horizontal("OBDOFD16", "OBDSTL16", "OBDOPR16", "OBDOPU16", "OBDOSR16", "OBDWCP16", "OBDVA16"),

    # outpatient visits (facility + SBD expenses)
    #  - For 1996-2006: combined facility + SBD variables are not on PUF
    OPTPTR=pl.sum_horizontal("OPTPRV16", "OPTTRI16"),
    OPTOTZ=pl.sum_horizontal("OPTOFD16", "OPTSTL16", "OPTOPR16", "OPTOPU16", "OPTOSR16", "OPTWCP16", "OPTVA16"),

    # outpatient physician visits (facility expense)
    OPVPTR=pl.sum_horizontal("OPVPRV16", "OPVTRI16"),
    OPVOTZ=pl.sum_horizontal("OPVOFD16", "OPVSTL16", "OPVOPR16", "OPVOPU16", "OPVOSR16", "OPVWCP16", "OPVVA16"),

    # outpatient physician visits (SBD expense)
    OPSPTR=pl.sum_horizontal("OPSPRV16", "OPSTRI16"),
    OPSOTZ=pl.sum_horizontal("OPSOFD16", "OPSSTL16", "OPSOPR16", "OPSOPU16", "OPSOSR16", "OPSWCP16", "OPSVA16"),
)


# Combine facility and SBD expenses for hospital-type events ------------------
#  Note: for 1996-2006, also need to create OPT*** = OPF*** + OPD***

FYC = FYC.with_columns(
    OPTSLF_p=pl.sum_horizontal("OPVSLF16", "OPSSLF16"),  # out-of-pocket payments
    OPTMCR_p=pl.sum_horizontal("OPVMCR16", "OPSMCR16"),  # Medicare
    OPTMCD_p=pl.sum_horizontal("OPVMCD16", "OPSMCD16"),  # Medicaid
    OPTPTR_p=pl.sum_horizontal("OPVPTR", "OPSPTR"),  # private insurance (including TRICARE)
    OPTOTZ_p=pl.sum_horizontal("OPVOTZ", "OPSOTZ"),  # other sources of payment
)


# Define survey design --------------------------------------------------------

FYCdsgn = svy.Sample(
    data=FYC,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F", singleton="center"),
)


# Calculate estimates ---------------------------------------------------------
#
# Sources of payment (SOP) abbreviations:
#  - SLF: Out-of-pocket
#  - PTR: Private insurance, including TRICARE (PTR)
#  - MCR: Medicare
#  - MCD: Medicaid
#  - OTZ: Other

expenditures = [
    "OBVSLF16", "OBVPTR", "OBVMCR16", "OBVMCD16", "OBVOTZ",  # OB visits
    "OBDSLF16", "OBDPTR", "OBDMCR16", "OBDMCD16", "OBDOTZ",  # OB phys. visits
    "OPTSLF16", "OPTPTR", "OPTMCR16", "OPTMCD16", "OPTOTZ",  # OP visits
    "OPTSLF_p", "OPTPTR_p", "OPTMCR_p", "OPTMCD_p", "OPTOTZ_p",  # OP phys. visits
]


# Total expenditures, by event type and source of payment

totals = FYCdsgn.estimation.total(expenditures)

for est in totals:
    print(est)


# Mean expenditure per person, by event type and source of payment

means = FYCdsgn.estimation.mean(expenditures)

for est in means:
    print(est)


# Mean expenditure per person with expense
#  - Mean out-of-pocket expense per person with an out-of-pocket expense

print(FYCdsgn.estimation.mean("OBVSLF16", where=pl.col("OBVSLF16") > 0))  # office-based visits
print(FYCdsgn.estimation.mean("OBDSLF16", where=pl.col("OBDSLF16") > 0))  # office-based phys. visits

print(FYCdsgn.estimation.mean("OPTSLF16", where=pl.col("OPTSLF16") > 0))  # OP visits
print(FYCdsgn.estimation.mean("OPTSLF_p", where=pl.col("OPTSLF_p") > 0))  # OP phys. visits
