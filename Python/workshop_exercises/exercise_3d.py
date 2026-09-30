# -----------------------------------------------------------------------------
# This program illustrates how to pool MEPS data files from different years. It
# highlights one example of a discontinuity that may be encountered when
# working with data from before and after the 2018 CAPI re-design.
#
# It also demonstrates use of the Pooled Variance file (h36u19) to pool data
# years before and after 2019.
#
#
# The program pools 2017, 2018, and 2019 data and calculates:
#  - Percentage of people with Joint Pain / Arthritis (JTPAIN**, ARTHDX)
#  - Average expenditures per person, by Joint Pain status (TOTEXP, TOTSLF)
#
# Notes:
#  - Variables with year-specific names must be renamed before combining files
#    (e.g. 'TOTEXP18' and 'TOTEXP18' renamed to 'totexp')
#
#  - When pooling data years before and after 2002 or 2019, the Pooled Variance
#    file (h36u19) must be used for correct variance estimation
#
#
# Input files:
#  - C:/MEPS/h216.dta (2019 Full-year file)
#  - C:/MEPS/h209.dta (2018 Full-year file)
#  - C:/MEPS/h201.dta (2017 Full-year file)
#  - C:/MEPS/h36u19.dta (Pooled Variance Linkage file)
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------

# Can skip this part if already installed (run in a terminal)
#   pip install svy   # for survey analysis, also installs polars


# Run this part each time you re-start Python
from pathlib import Path

import polars as pl  # for data manipulation
import polars.selectors as cs
import svy  # for survey analysis and loading Stata (.dta) files

# This module facilitates file import (meps.py, in this folder)
from meps import read_meps

MEPS_DIR = Path("C:/MEPS")


# Read in data ----------------------------------------------------------------
fyc19 = read_meps(year=2019, type="FYC")  # 2019 FYC
fyc18 = read_meps(year=2018, type="FYC")  # 2018 FYC
fyc17 = read_meps(year=2017, type="FYC")  # 2017 FYC

# >> Note: File name for linkage file will change every year!!
linkage = read_meps(file="h36u19")  # Pooled Linkage file


# # Alternative:
# fyc19 = svy.read_stata(MEPS_DIR / "h216.dta")  # 2019 FYC
# fyc18 = svy.read_stata(MEPS_DIR / "h209.dta")  # 2018 FYC
# fyc17 = svy.read_stata(MEPS_DIR / "h201.dta")  # 2017 FYC

# >> Note: File name for linkage file will change every year!!
# linkage = svy.read_stata(MEPS_DIR / "h36u19.dta")  # Pooled Linkage file



# View data -------------------------------------------------------------------
# JTPAIN** and ARTHDX values
#  -15 = Cannot be computed (2018 and later)
#   -9 = Not ascertained (pre-2018)
#   -8 = Don't know
#   -7 = Refused
#   -1 = Inapplicable
#    1 = Yes
#    2 = No


# Starting in 2018, most people that report Arthritis (ARTHDX = '1 Yes') have
#  JTPAIN31_M18 = '-1 Inapplicable' (due to new skip pattern)
print(fyc17.filter(pl.col("ARTHDX") == 1).group_by("ARTHDX", "JTPAIN31").len().sort(pl.all()))
print(fyc18.filter(pl.col("ARTHDX") == 1).group_by("ARTHDX", "JTPAIN31_M18").len().sort(pl.all()))
print(fyc19.filter(pl.col("ARTHDX") == 1).group_by("ARTHDX", "JTPAIN31_M18").len().sort(pl.all()))


# Create variables ------------------------------------------------------------
#  - any_jtpain = "1 YES" if JTPAIN** = 1 OR ARTHDX = 1
#  - any_jtpain = "Missing" if JTPAIN < 0 AND ARTHDX < 0

fyc19x = fyc19.with_columns(
    any_jtpain=pl.when((pl.col("JTPAIN31_M18") == 1) | (pl.col("ARTHDX") == 1)).then(pl.lit("1 Yes"))
    .when((pl.col("JTPAIN31_M18") < 0) & (pl.col("ARTHDX") < 0)).then(pl.lit("Missing"))
    .otherwise(pl.lit("2 No"))
)

fyc18x = fyc18.with_columns(
    any_jtpain=pl.when((pl.col("JTPAIN31_M18") == 1) | (pl.col("ARTHDX") == 1)).then(pl.lit("1 Yes"))
    .when((pl.col("JTPAIN31_M18") < 0) & (pl.col("ARTHDX") < 0)).then(pl.lit("Missing"))
    .otherwise(pl.lit("2 No"))
)

fyc17x = fyc17.with_columns(
    any_jtpain=pl.when((pl.col("JTPAIN31") == 1) | (pl.col("ARTHDX") == 1)).then(pl.lit("1 Yes"))
    .when((pl.col("JTPAIN31") < 0) & (pl.col("ARTHDX") < 0)).then(pl.lit("Missing"))
    .otherwise(pl.lit("2 No"))
)


# QC variables:
print(
    fyc19x.filter(pl.col("AGELAST") >= 18)
    .group_by("any_jtpain", "JTPAIN31_M18", "ARTHDX").len().sort(pl.all())
)

print(
    fyc18x.filter(pl.col("AGELAST") >= 18)
    .group_by("any_jtpain", "JTPAIN31_M18", "ARTHDX").len().sort(pl.all())
)

with pl.Config(tbl_rows=50):
    print(
        fyc17x.filter(pl.col("AGELAST") >= 18)
        .group_by("any_jtpain", "JTPAIN31", "ARTHDX").len().sort(pl.all())
    )



# Rename year-specific variables prior to combining ---------------------------

# (?i) makes the match case-insensitive, like R's matches(), so any_jtpain is kept
fyc19p = fyc19x.rename(
    {"PERWT19F": "perwt", "TOTSLF19": "totslf", "TOTEXP19": "totexp"}
).select(
    "DUPERSID", "PANEL", "VARSTR", "VARPSU", "AGELAST", "perwt", "totslf", "totexp", "ARTHDX", cs.matches("(?i)JTPAIN")
)

fyc18p = fyc18x.rename(
    {"PERWT18F": "perwt", "TOTSLF18": "totslf", "TOTEXP18": "totexp"}
).select(
    "DUPERSID", "PANEL", "VARSTR", "VARPSU", "AGELAST", "perwt", "totslf", "totexp", "ARTHDX", cs.matches("(?i)JTPAIN")
)

fyc17p = fyc17x.rename(
    {"PERWT17F": "perwt", "TOTSLF17": "totslf", "TOTEXP17": "totexp"}
).select(
    "DUPERSID", "PANEL", "VARSTR", "VARPSU", "AGELAST", "perwt", "totslf", "totexp", "ARTHDX", cs.matches("(?i)JTPAIN")
)


print(fyc19p.head())
print(fyc18p.head())
print(fyc17p.head())


# Stack data and define pooled weight variable and subpop of interest ---------
#  - Subpop: AGELAST >= 18 AND any_jtpain not missing

pool = pl.concat([fyc19p, fyc18p, fyc17p], how="diagonal").with_columns(
    # for poolwt, divide perwt by number of years (3):
    poolwt=pl.col("perwt") / 3,
    subpop=(pl.col("AGELAST") >= 18) & (pl.col("any_jtpain") != "Missing"),
)


# Merge the Pooled Linkage Variance file (since pooling 2019 data) ---
#  Notes:
#   - DUPERSIDs are recycled, so must join by DUPERSID AND PANEL
#   - File name will change every year!! (e.g. 'h36u20' once 2020 data is added)

print(pool.head())
print(linkage.head())


linkage_sub = linkage.select("DUPERSID", "PANEL", "STRA9619", "PSU9619")

pool_linked = pool.join(linkage_sub, on=["DUPERSID", "PANEL"], how="left")


# QC:
print(pool.group_by("PANEL").len().sort("PANEL"))
print(pool_linked.group_by("PANEL").len().sort("PANEL"))



# Define the survey design ----------------------------------------------------
#  - Use PSU9619 and STRA9619 variables, since pooling before and after 2019

pool_dsgn = svy.Sample(
    data=pool_linked,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="PSU9619", stratum="STRA9619", wgt="poolwt", singleton="center"),
)


# Calculate survey estimates ---------------------------------------------------
#  - Percentage of people with Joint Pain / Arthritis (any_jtpain)
#  - Average expenditures per person, by Joint Pain status (totexp, totslf)

# Percent with any joint pain (any_jtpain)
print(pool_dsgn.estimation.prop("any_jtpain", where=pl.col("subpop")))

# Avg. expenditures per person
for est in pool_dsgn.estimation.mean(["totslf", "totexp"], by="any_jtpain", where=pl.col("subpop")):
    print(est)
