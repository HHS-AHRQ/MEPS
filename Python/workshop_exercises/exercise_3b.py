# -----------------------------------------------------------------------------
# DESCRIPTION:  THIS PROGRAM ILLUSTRATES HOW TO POOL MEPS LONGITUDINAL DATA
#  FILES FROM DIFFERENT PANELS
#
# THE EXAMPLE USED IS PANELS 17-19 POPULATION AGE 26-30 WHO ARE UNINSURED BUT
#  HAVE HIGH INCOME IN THE FIRST YEAR
#
# DATA FROM PANELS 17, 18, AND 19 ARE POOLED.
#
# INPUT FILES:  (1) C:/MEPS/H183.ssp (PANEL 19 LONGITUDINAL FILE)
#               (2) C:/MEPS/H172.ssp (PANEL 18 LONGITUDINAL FILE)
#               (3) C:/MEPS/H164.ssp (PANEL 17 LONGITUDINAL FILE)
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

varlist = ["DUPERSID", "INSCOVY1", "INSCOVY2",
           "LONGWT",   "VARSTR",   "VARPSU",
           "POVCATY1", "AGEY1X",   "PANEL"]

h183 = svy.read_sas(MEPS_DIR / "h183.ssp").select(varlist)  # Panel 19
h172 = svy.read_sas(MEPS_DIR / "h172.ssp").select(varlist)  # Panel 18
h164 = svy.read_sas(MEPS_DIR / "h164.ssp").select(varlist)  # Panel 17

# Stack longitudinal files and define pooled weight variable and subpop of interest
#  subpop = age 26-30, uninsured, high income

pool = pl.concat([h183, h172, h164]).with_columns(
    poolwt=pl.col("LONGWT") / 3,
    subpop=pl.col("AGEY1X").is_between(26, 30) & (pl.col("POVCATY1") == 5) & (pl.col("INSCOVY1") == 3),
)

print(pool.filter(pl.col("subpop")).describe())

print(pool.head())



# Define the survey design

mepsdsgn = svy.Sample(
    data=pool,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="poolwt", singleton="center"),
)


# INSURANCE STATUS IN THE SECOND YEAR FOR THOSE W/ AGE=26-30, UNINSURED WHOLE YEAR, AND HIGH INCOME IN THE FIRST YEAR'

print(mepsdsgn.estimation.prop("INSCOVY2", where=pl.col("subpop")))
