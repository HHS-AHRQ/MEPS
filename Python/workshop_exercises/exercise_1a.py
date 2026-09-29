# -----------------------------------------------------------------------------
# DESCRIPTION: THIS PROGRAM GENERATES THE FOLLOWING ESTIMATES ON
#               NATIONAL HEALTH CARE, 2016:
#
#             (1) OVERALL EXPENSES
#             (2) PERCENTAGE OF PERSONS WITH AN EXPENSE
#             (3) MEAN EXPENSE PER PERSON WITH AN EXPENSE
#
# INPUT FILE:  C:/MEPS/H192.ssp (2016 FULL-YEAR FILE)
# -----------------------------------------------------------------------------

# Install and load libraries

# Can skip this part if already installed (run in a terminal)
#   pip install svy

# Run this part each time you re-start Python
from pathlib import Path

import polars as pl
import svy
from svy_io import read_xpt

MEPS_DIR = Path("C:/MEPS")


# Read in data from 2016 consolidated data file (hc-192)
h192, _ = read_xpt(MEPS_DIR / "h192.ssp")

# Add variables for persons with any expense and persons under 65

h192 = h192.with_columns(
    has_exp=pl.col("TOTEXP16") > 0,  # persons with any expense
    age_cat=pl.when(pl.col("AGELAST") < 65).then(pl.lit("<65")).otherwise(pl.lit("65+")),  # persons under age 65
)

# QC check on new variables

print(
    h192.group_by("has_exp")
    .agg(min=pl.col("TOTEXP16").min(), max=pl.col("TOTEXP16").max())
    .sort("has_exp")
)

print(
    h192.group_by("age_cat")
    .agg(min=pl.col("AGELAST").min(), max=pl.col("AGELAST").max())
    .sort("age_cat")
)


# Define the survey design

mepsdsgn = svy.Sample(
    data=h192,
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F"),
)

# Set option to deal with lonely psu
mepsdsgn = mepsdsgn.singleton.center()

# Overall expenses
print(mepsdsgn.estimation.mean("TOTEXP16"))
print(mepsdsgn.estimation.total("TOTEXP16"))

# Percentage of persons with an expense
print(mepsdsgn.estimation.prop("has_exp"))

# Mean expense per person with an expense
print(mepsdsgn.estimation.mean("TOTEXP16", where=pl.col("has_exp")))

# Mean expense per person with an expense, by age category
print(mepsdsgn.estimation.mean("TOTEXP16", by="age_cat", where=pl.col("has_exp")))
