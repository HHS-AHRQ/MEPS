# -----------------------------------------------------------------------------
# This program generates National Totals and Per-person Averages for Narcotic
# analgesics and Narcotic analgesic combos for the U.S. civilian
# non-institutionalized population, including:
#  - Number of purchases (fills)
#  - Total expenditures
#  - Out-of-pocket payments
#  - Third-party payments
#
# Input files:
#  - C:/MEPS/h209.dta  (2018 Full-year file)
#  - C:/MEPS/h206a.dta (2018 Prescribed medicines file)
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------

# Can skip this part if already installed (run in a terminal)
#   pip install svy   # for survey analysis, also installs polars

# Run this part each time you re-start Python
from pathlib import Path

import polars as pl  # for data manipulation
import svy  # for survey analysis and loading Stata (.dta) files

# This module facilitates file import (meps.py, in this folder)
from meps import read_meps

MEPS_DIR = Path("C:/MEPS")


# Read in data from FYC file --------------------------------------------------

fyc18 = read_meps(year=2018, type="FYC")  # 2018 FYC
rx18 = read_meps(year=2018, type="RX")  # 2018 RX

# # Alternative:
# fyc18 = svy.read_stata(MEPS_DIR / "h209.dta")   # 2018 FYC
# rx18  = svy.read_stata(MEPS_DIR / "h206a.dta")  # 2018 RX


# Keep only needed variables --------------------------------------------------

fyc18_sub = fyc18.select("DUPERSID", "VARSTR", "VARPSU", "PERWT18F")  # needed for survey design


# Identify Narcotic analgesics or Narcotic analgesic combos -------------------
#  Use therapeutic classification codes (TC1S1_1)
#
# DUPERSID: PERSON ID (DUID + PID)
# RXRECIDX: UNIQUE RX/PRESCRIBED MEDICINE IDENTIFIER
# LINKIDX:  ID FOR LINKAGE TO COND/OTH EVENT FILES
# TC1S1_1:  MULTUM THERAPEUT SUB-SUB-CLASS FOR TC1S1
#
# RXXP18X:  SUM OF PAYMENTS RXSF18X-RXOU18X(IMPUTED)
# RXSF18X:  AMOUNT PAID, SELF OR FAMILY (IMPUTED)


narc = rx18.filter(pl.col("TC1S1_1").is_in([60, 191])).select(
    "DUPERSID", "RXRECIDX", "LINKIDX", "TC1S1_1", "RXXP18X", "RXSF18X"
)

print(narc.head())
print(narc.group_by("TC1S1_1").len().sort("TC1S1_1"))

# Sum data to person-level ----------------------------------------------------

narc_pers = (
    narc.group_by("DUPERSID")
    .agg(
        tot=pl.col("RXXP18X").sum(),
        oop=pl.col("RXSF18X").sum(),
        n_purchase=pl.len(),
    )
    .sort("DUPERSID")
    .with_columns(
        third_payer=pl.col("tot") - pl.col("oop"),
        any_narc=pl.lit(1),
    )
)

print(narc_pers.head())


# Merge the person-level expenditures to the FY PUF to get complete PSUs, Strata

narc_fyc = narc_pers.join(fyc18_sub, on="DUPERSID", how="full", coalesce=True)

print(narc_fyc.head())

print(narc.height)
print(fyc18_sub.height)
print(narc_fyc.height)

print(narc_fyc.group_by("any_narc").len().sort("any_narc"))
print(narc_fyc.filter(pl.col("any_narc").is_null()))


# Define the survey design ----------------------------------------------------

mepsdsgn = svy.Sample(
    data=narc_fyc,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT18F", singleton="center"),
)


# Calculate estimates ---------------------------------------------------------
#  National totals and Per-person Averages for:
#   - Number of purchases (fills)  -- n_purchase
#   - Total expenditures           -- tot
#   - Out-of-pocket payments       -- oop
#   - Third-party payments         -- third_payer

# National totals
for est in mepsdsgn.estimation.total(
    ["n_purchase", "tot", "oop", "third_payer"], where=pl.col("any_narc") == 1
):
    print(est)


# Average per person
for est in mepsdsgn.estimation.mean(
    ["n_purchase", "tot", "oop", "third_payer"], where=pl.col("any_narc") == 1
):
    print(est)
