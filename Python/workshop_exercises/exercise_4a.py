# -----------------------------------------------------------------------------
# This program includes a regression example for persons receiving a flu shot
# in the last 12 months for the U.S. civilian non-institutionalized population,
# including:
#  - Percentage of people with a flu shot
#  - Logistic regression: to identify demographic factors associated with
#    receiving a flu shot
#
# Input file:
#  - C:/MEPS/h209.dta (2018 Full-year file)
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------

# Can skip this part if already installed (run in a terminal)
#   pip install svy   # for survey analysis, also installs polars

# Run this part each time you re-start Python
from pathlib import Path

import polars as pl  # for data manipulation
import svy  # for survey analysis and loading Stata (.dta) files
from svy import Cat  # for categorical variables in regression

# This module facilitates file import (meps.py, in this folder)
from meps import read_meps

MEPS_DIR = Path("C:/MEPS")


# Read in data from FYC file --------------------------------------------------

fyc18 = read_meps(year=2018, type="FYC")  # 2018 FYC

# # Alternative:
# fyc18 = svy.read_stata(MEPS_DIR / "h209.dta")  # 2018 FYC

# View data
print(fyc18.select("DUPERSID", "ADFLST42", "AGELAST", "SEX", "RACETHX", "INSCOV18"))

print(fyc18.filter(pl.col("SAQWT18F") > 0).group_by("ADFLST42").len().sort("ADFLST42"))

# Keep only needed variables --------------------------------------------------
fyc18_sub = fyc18.select(
    "DUPERSID", "VARPSU", "VARSTR",
    "ADFLST42", "AGELAST", "SEX", "RACETHX", "INSCOV18", pl.col("^.*SAQ.*$"),
)


# Create variables ------------------------------------------------------------
#  - Convert ADFLST42 from 1/2 to 0/1 (for logistic regression)
#  - Create 'subpop' to exclude people with Missing 'ADFLST42'

fyc18x = fyc18_sub.with_columns(
    # Convert outcome from 1/2 to 0/1:
    flu_shot=pl.when(pl.col("ADFLST42") == 1).then(1)
    .when(pl.col("ADFLST42") == 2).then(0)
    .otherwise(pl.col("ADFLST42")),

    # Create subpop to exclude Missings
    subpop=pl.col("ADFLST42") >= 0,
)


# QC new variable
print(
    fyc18x
    # .filter(pl.col("SAQWT18F") > 0)
    .group_by("flu_shot", "ADFLST42", "subpop").len().sort(pl.all())
)


# Check variables in regression -----------------------------------------------

print(fyc18x.group_by("SEX").len().sort("SEX"))
# SEX:
#   1 = MALE
#   2 = FEMALE

print(fyc18x.group_by("RACETHX").len().sort("RACETHX"))
# RACETHX:
#   1 = HISPANIC
#   2 = NON-HISPANIC WHITE
#   3 = NON-HISPANIC BLACK
#   4 = NON-HISPANIC ASIAN
#   5 = NON-HISPANIC OTHER/MULTIPLE

print(fyc18x.group_by("INSCOV18").len().sort("INSCOV18"))
# INSCOV:
#   1 = ANY PRIVATE
#   2 = PUBLIC ONLY
#   3 = UNINSURED


print(fyc18x["AGELAST"].describe())
# AGELAST: 0-85


# Define the survey design ----------------------------------------------------

saq_dsgn = svy.Sample(
    data=fyc18x,
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="SAQWT18F"),
)

# Set option to deal with lonely psu
saq_dsgn = saq_dsgn.singleton.center()

# Subset to people without missing flu shot (the 'where' argument keeps the full design)
flu_sub = pl.col("subpop")


# QC sub-design
print(saq_dsgn.data.group_by("flu_shot").len().sort("flu_shot"))
print(saq_dsgn.data.filter(flu_sub).group_by("flu_shot").len().sort("flu_shot"))


# Calculate survey estimates ---------------------------------------------------
#  - Percentage of people with a flu shot
#  - Logistic regression: to identify demographic factors associated with
#    receiving a flu shot

# Percentage of people with a flu shot
print(saq_dsgn.estimation.mean("flu_shot", where=flu_sub))

# Logistic regression

print(
    saq_dsgn.glm.fit(
        y="flu_shot",
        x=["AGELAST", Cat("SEX"), Cat("RACETHX"), Cat("INSCOV18")],
        family="binomial", where=flu_sub,
    )
)
