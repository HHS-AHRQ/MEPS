# -----------------------------------------------------------------------------
# This program includes a regression example for persons delaying medical care
# because of COVID, including:
#  - Percentage of people who delayed care
#  - Logistic regression: to identify demographic factors associated with
#    delayed care
#
# Input file:
#  - C:/MEPS/h224.dta (2020 Full-year file)
#
# -----------------------------------------------------------------------------

# Install and load packages ---------------------------------------------------
#
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

fyc20 = read_meps(year=2020, type="FYC")  # 2020 FYC

# # Alternative:
# fyc20 = svy.read_stata(MEPS_DIR / "h224.dta")  # 2020 FYC

# View data
print(fyc20.select("DUPERSID", "AGELAST", "SEX", "RACETHX", "INSCOV20", "REGION53", pl.col("^.*CVDLAY.*$")))



# Keep only needed variables --------------------------------------------------
fyc20_sub = fyc20.select(
    "DUPERSID", "VARPSU", "VARSTR", "PERWT20F",
    pl.col("^.*CVDLAY.*$"), "AGELAST", "SEX", "RACETHX", "INSCOV20", "REGION53",
)


# Create variables ------------------------------------------------------------
#  - Convert CVDLAY**53 from 1/2 to 0/1 (for logistic regression)
#  - Create 'subpop' to exclude people with Missing 'CVDLAY**'


fyc20x = fyc20_sub.with_columns(
    pl.col("CVDLAYCA53", "CVDLAYDN53", "CVDLAYPM53").cast(pl.Float64),
).with_columns(
    # Convert outcome from 1/2 to 0/1:
    covid_delay_CARE=pl.when(pl.col("CVDLAYCA53") == 1).then(1)
    .when(pl.col("CVDLAYCA53") == 2).then(0)
    .otherwise(pl.col("CVDLAYCA53")),

    covid_delay_DENTAL=pl.when(pl.col("CVDLAYDN53") == 1).then(1)
    .when(pl.col("CVDLAYDN53") == 2).then(0)
    .otherwise(pl.col("CVDLAYDN53")),

    covid_delay_PMED=pl.when(pl.col("CVDLAYPM53") == 1).then(1)
    .when(pl.col("CVDLAYPM53") == 2).then(0)
    .otherwise(pl.col("CVDLAYPM53")),


    # Create subpops to exclude Missings
    subpop_CARE=pl.col("CVDLAYCA53") >= 0,
    subpop_DENTAL=pl.col("CVDLAYDN53") >= 0,
    subpop_PMED=pl.col("CVDLAYPM53") >= 0,
)


# QC new variables
print(fyc20x.group_by("covid_delay_CARE", "CVDLAYCA53", "subpop_CARE").len().sort(pl.all()))
print(fyc20x.group_by("covid_delay_DENTAL", "CVDLAYDN53", "subpop_DENTAL").len().sort(pl.all()))
print(fyc20x.group_by("covid_delay_PMED", "CVDLAYPM53", "subpop_PMED").len().sort(pl.all()))


# Check variables in regression -----------------------------------------------

print(fyc20x.group_by("SEX").len().sort("SEX"))
# SEX:
#   1 = MALE
#   2 = FEMALE

print(fyc20x.group_by("RACETHX").len().sort("RACETHX"))
# RACETHX:
#   1 = HISPANIC
#   2 = NON-HISPANIC WHITE
#   3 = NON-HISPANIC BLACK
#   4 = NON-HISPANIC ASIAN
#   5 = NON-HISPANIC OTHER/MULTIPLE

print(fyc20x.group_by("INSCOV20").len().sort("INSCOV20"))
# INSCOV:
#   1 = ANY PRIVATE
#   2 = PUBLIC ONLY
#   3 = UNINSURED

print(fyc20x.group_by("REGION53").len().sort("REGION53"))
# REGION53:
#   1 = NORTHEAST
#   2 = MIDWEST
#   3 = SOUTH
#   4 = WEST


print(fyc20x["AGELAST"].describe())
# AGELAST: 0-85


# Define the survey design ----------------------------------------------------

meps_dsgn = svy.Sample(
    data=fyc20x,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT20F", singleton="center"),
)


# Calculate survey estimates ---------------------------------------------------
#  - Percentage of people delaying care
#  - Logistic regression: to identify demographic factors associated with
#    delayed care
# (the 'where' argument subsets to the subpop and keeps the full design)

# Percentage of people delaying care
print(meps_dsgn.estimation.mean("covid_delay_CARE", where=pl.col("subpop_CARE")))
print(meps_dsgn.estimation.mean("covid_delay_DENTAL", where=pl.col("subpop_DENTAL")))
print(meps_dsgn.estimation.mean("covid_delay_PMED", where=pl.col("subpop_PMED")))


# Logistic regression

# Delaying Medical Care
print(
    meps_dsgn.glm.fit(
        y="covid_delay_CARE",
        x=["AGELAST", Cat("SEX"), Cat("RACETHX"), Cat("INSCOV20"), Cat("REGION53")],
        family="binomial", where=pl.col("subpop_CARE"),
    )
)

# Delaying Dental Care
print(
    meps_dsgn.glm.fit(
        y="covid_delay_DENTAL",
        x=["AGELAST", Cat("SEX"), Cat("RACETHX"), Cat("INSCOV20"), Cat("REGION53")],
        family="binomial", where=pl.col("subpop_DENTAL"),
    )
)

# Delaying PMEDs
print(
    meps_dsgn.glm.fit(
        y="covid_delay_PMED",
        x=["AGELAST", Cat("SEX"), Cat("RACETHX"), Cat("INSCOV20"), Cat("REGION53")],
        family="binomial", where=pl.col("subpop_PMED"),
    )
)
