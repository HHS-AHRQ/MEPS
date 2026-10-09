# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Prescribed drugs, 2016
#
# Purchases and expenditures by generic drug name (RXDRGNAM)
#  - Number of people with purchase
#  - Total purchases
#  - Total expenditures
#
# Input file: C:/MEPS/h188a.ssp (2016 RX event file)
# -----------------------------------------------------------------------------

# Install/load packages -------------------------------------------------------

# Install packages (if needed) -- only need to run once (in a terminal)
#   pip install svy==0.32.1 "polars>=2"

# Load packages (need to run every session)
from pathlib import Path

import polars as pl
import svy

MEPS_DIR = Path("C:/MEPS")


# Load datasets ---------------------------------------------------------------
# For 1996-2013, need to merge with RX Multum Lexicon Addendum files to get
#  therapeutic class categories and generic drug names

# Load RX file
RX = svy.read_sas(MEPS_DIR / "h188a.ssp")

# Aggregate to person-level ---------------------------------------------------

RX_pers = (
    RX.group_by("DUPERSID", "VARSTR", "VARPSU", "RXDRGNAM")
    .agg(
        PERWT16F=pl.col("PERWT16F").mean(),
        pers_RXXP=pl.col("RXXP16X").sum(),
        n_purchases=pl.len(),
    )
    .with_columns(persons=pl.lit(1))
)


# Define survey design and calculate estimates --------------------------------

RXdsgn = svy.Sample(
    data=RX_pers,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F", singleton="center"),
)


totals = RXdsgn.estimation.total(["persons", "n_purchases", "pers_RXXP"], by="RXDRGNAM")

print(totals[0])  # Number of people with purchase
print(totals[1])  # Total purchases
print(totals[2])  # Total expenditures
