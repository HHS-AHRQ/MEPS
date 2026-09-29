# -----------------------------------------------------------------------------
# DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS DATA FILES FROM
#  DIFFERENT YEARS THE EXAMPLE USED IS POPULATION AGE 26-30 WHO ARE UNINSURED
#  BUT HAVE HIGH INCOME DATA FROM 2015 AND 2016 ARE POOLED.
#
# VARIABLES WITH YEAR-SPECIFIC NAMES MUST BE RENAMED BEFORE COMBINING FILES:
#
# IN THIS PROGRAM THE INSURANCE COVERAGE VARIABLES 'INSCOV15' AND 'INSCOV16'
#  ARE RENAMED TO 'INSCOV'.
#
# SEE HC-036 (1996-2015 POOLED ESTIMATION FILE) FOR
#  INSTRUCTIONS ON POOOLING AND CONSIDERATIONS FOR VARIANCE
#  ESTIMATION FOR PRE-2002 DATA.
#
# INPUT FILES: (1) C:/MEPS/H192.ssp (2016 FULL-YEAR FILE)
#              (2) C:/MEPS/H181.ssp (2015 FULL-YEAR FILE)
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


# Read in data
h192, _ = read_xpt(MEPS_DIR / "h192.ssp")  # 2016 FYC
h181, _ = read_xpt(MEPS_DIR / "h181.ssp")  # 2015 FYC

# Rename year-specific variables prior to combining
h192x = h192.rename(
    {"INSCOV16": "inscov", "PERWT16F": "perwt", "POVCAT16": "povcat", "TOTSLF16": "totslf"}
).select("DUPERSID", "VARSTR", "VARPSU", "AGELAST", "inscov", "perwt", "povcat", "totslf")

h181x = h181.rename(
    {"INSCOV15": "inscov", "PERWT15F": "perwt", "POVCAT15": "povcat", "TOTSLF15": "totslf"}
).select("DUPERSID", "VARSTR", "VARPSU", "AGELAST", "inscov", "perwt", "povcat", "totslf")

# Stack data and define pooled weight variable and subpop of interest
#  subpop = age 26-30, uninsured, high income

pool = pl.concat([h192x, h181x]).with_columns(
    poolwt=pl.col("perwt") / 2,  # divide perwt by number of years (2)
    subpop=pl.col("AGELAST").is_between(26, 30) & (pl.col("povcat") == 5) & (pl.col("inscov") == 3),
)

# QC subpop

print(pool.filter(pl.col("subpop")).group_by("AGELAST", "povcat", "inscov").len().sort(pl.all()))


# Define the survey design

mepsdsgn = svy.Sample(
    data=pool,
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="poolwt"),
)

# Set option to deal with lonely psu
mepsdsgn = mepsdsgn.singleton.center()


# Weighted estimate on totslf for combined data w/age=26-30, uninsured whole year, and high income

print(mepsdsgn.estimation.mean("totslf", where=pl.col("subpop")))
