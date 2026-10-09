# -----------------------------------------------------------------------------
# This program generates the following estimates on national health care for
# the U.S. civilian non-institutionalized population, 2018:
#  - Overall expenses (National totals)
#  - Percentage of persons with an expense
#  - Mean expense per person
#  - Mean/median expense per person with an expense:
#    - Mean expense per person with an expense
#    - Mean expense per person with an expense, by age group
#    - Median expense per person with an expense, by age group
#
# Input file:
#  - C:/MEPS/h209.dta (2018 Full-year file - Stata format)
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------

# Can skip this part if already installed (run in a terminal)
#   pip install svy==0.32.1 "polars>=2"   # for survey analysis, also installs polars

# Run this part each time you re-start Python
from pathlib import Path

import polars as pl  # for data manipulation
import svy  # for survey analysis and loading Stata (.dta) files

# This module facilitates file import (meps.py, in this folder)
from meps import read_meps

MEPS_DIR = Path("C:/MEPS")


# Read in data from FYC file --------------------------------------------------

# Option 1: use 'meps' module
fyc18 = read_meps(year=2018, type="FYC")  # 2018 FYC

# Option 2: Use Stata format (recommended for Data Year 2018 and later)
fyc18_opt2 = svy.read_stata(MEPS_DIR / "h209.dta")

# View data
print(fyc18.head())
print(fyc18_opt2.head())


# Keep only needed variables --------------------------------------------------
# - codebook: https://meps.ahrq.gov/mepsweb/data_stats/download_data_files_codebook.jsp?PUFId=H209

fyc18_sub = fyc18.select(
    "AGELAST", "TOTEXP18",
    "DUPERSID", "VARSTR", "VARPSU", "PERWT18F",  # needed for survey design
)

print(fyc18_sub.head())


# Add variables for persons with any expense and persons under 65 -------------

fyc18x = fyc18_sub.with_columns(
    has_exp=pl.col("TOTEXP18") > 0,  # persons with any expense
    age_cat=pl.when(pl.col("AGELAST") < 65).then(pl.lit("<65")).otherwise(pl.lit("65+")),  # persons under age 65
)

print(fyc18x.head())


# QC check on new variables

print(fyc18x.group_by("has_exp", "age_cat").len().sort("has_exp", "age_cat"))

print(
    fyc18x.group_by("has_exp")
    .agg(min=pl.col("TOTEXP18").min(), max=pl.col("TOTEXP18").max())
    .sort("has_exp")
)

print(
    fyc18x.group_by("age_cat")
    .agg(min=pl.col("AGELAST").min(), max=pl.col("AGELAST").max())
    .sort("age_cat")
)


# Define the survey design ----------------------------------------------------

mepsdsgn = svy.Sample(
    data=fyc18x,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT18F", singleton="center"),
)


# Calculate estimates ---------------------------------------------------------
#  - Overall expenses (National totals)
#  - Percentage of persons with an expense
#  - Mean expense per person
#  - Mean/median expense per person with an expense:
#    - Mean expense per person with an expense
#    - Mean expense per person with an expense, by age group
#    - Median expense per person with an expense, by age group

# Overall expenses (National totals)
print(mepsdsgn.estimation.total("TOTEXP18"))

# Percentage of persons with an expense
print(mepsdsgn.estimation.prop("has_exp"))

# Mean expense per person
print(mepsdsgn.estimation.mean("TOTEXP18"))


# Mean/median expense per person with an expense --------------------
# Subset to people with expense (the 'where' argument keeps the full design):

# Mean expense per person with an expense
print(mepsdsgn.estimation.mean("TOTEXP18", where=pl.col("has_exp")))

# Mean expense per person with an expense, by age category
print(mepsdsgn.estimation.mean("TOTEXP18", by="age_cat", where=pl.col("has_exp")))

# Median expense per person with an expense, by age category
print(mepsdsgn.estimation.median("TOTEXP18", by="age_cat", where=pl.col("has_exp")))
