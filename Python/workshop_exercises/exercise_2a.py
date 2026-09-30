# -----------------------------------------------------------------------------
# PURPOSE: THIS PROGRAM GENERATES SELECTED ESTIMATES FOR A 2016 VERSION OF
#          Purchases and Expenses for Narcotic analgesics or Narcotic analgesic combos
#
#  - TOTAL EXPENSE FOR Narcotic analgesics or Narcotic analgesic combos
#
#  - TOTAL NUMBER OF PURCHASES OF Narcotic analgesics or Narcotic analgesic combos
#
#  - AVERAGE TOTAL, OUT OF POCKET, AND THIRD PARTY PAYER EXPENSE FOR Narcotic
#        analgesics or Narcotic analgesic combos PER PERSON WITH A
#        Narcotic analgesics or Narcotic analgesic combos MEDICINE PURCHASE
#
#   INPUT FILES:  (1) C:/MEPS/H192.ssp  (2016 FULL-YEAR CONSOLIDATED PUF)
#                 (2) C:/MEPS/H188A.ssp (2016 PRESCRIBED MEDICINES PUF)
#
# -----------------------------------------------------------------------------

# Install and load libraries

# Can skip this part if already installed (run in a terminal)
#   pip install svy

# Run this part each time you re-start Python
from pathlib import Path

import polars as pl
import svy

MEPS_DIR = Path("C:/MEPS")


# Read in data
h192 = svy.read_sas(MEPS_DIR / "h192.ssp")  # 2016 FYC
h188a = svy.read_sas(MEPS_DIR / "h188a.ssp")  # 2016 RX

# Identify Narcotic analgesics or Narcotic analgesic combos using therapeutic classification (tc) codes

narc = h188a.filter(pl.col("TC1S1_1").is_in([60, 191])).select(
    "DUPERSID", "RXRECIDX", "LINKIDX", "TC1S1_1", "RXXP16X", "RXSF16X"
)

print(narc.head())
print(narc["TC1S1_1"].value_counts().sort("TC1S1_1"))

# Sum data to person-level

narc_pers = (
    narc.group_by("DUPERSID")
    .agg(
        tot=pl.col("RXXP16X").sum(),
        oop=pl.col("RXSF16X").sum(),
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

fyc = h192.select("DUPERSID", "VARSTR", "VARPSU", "PERWT16F")

narc_fyc = narc_pers.join(fyc, on="DUPERSID", how="full", coalesce=True)

print(narc_fyc.head())


# Define the survey design

mepsdsgn = svy.Sample(
    data=narc_fyc,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F", singleton="center"),
)


# Calculate estimates on expenditures and use

for est in mepsdsgn.estimation.mean(
    ["n_purchase", "tot", "oop", "third_payer"], where=pl.col("any_narc") == 1
):
    print(est)

for est in mepsdsgn.estimation.total(
    ["n_purchase", "tot", "oop", "third_payer"], where=pl.col("any_narc") == 1
):
    print(est)
