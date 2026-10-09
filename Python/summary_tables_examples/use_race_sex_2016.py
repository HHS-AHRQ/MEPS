# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Use, expenditures, and population, 2016
#
# Expenditures by race and sex
#  - Number of people
#  - Percent of population with an expense
#  - Total expenditures
#  - Mean expenditure per person
#  - Mean expenditure per person with expense
#  - Median expenditure per person with expense
#
# Input file: C:/MEPS/h192.ssp (2016 full-year consolidated)
# -----------------------------------------------------------------------------

# Install/load packages -------------------------------------------------------

# Install packages (if needed) -- only need to run once (in a terminal)
#   pip install svy==0.32.1 "polars>=2"

# Load packages (need to run every session)
from pathlib import Path

import polars as pl
import svy

MEPS_DIR = Path("C:/MEPS")


# Load FYC file ---------------------------------------------------------------

FYC = svy.read_sas(MEPS_DIR / "h192.ssp")


# Define variables ------------------------------------------------------------

# Race/ethnicity
#  - 1996-2002: race/ethnicity variable based on RACETHNX (see documentation)
#  - 2002-2011: race/ethnicity variable based on RACETHNX and RACEX:
#     hisp   = (RACETHNX == 1)
#     white  = (RACETHNX == 4) & (RACEX == 1)
#     black  = (RACETHNX == 2)
#     native = (RACETHNX >= 3) & RACEX in (3, 6)
#     asian  = (RACETHNX >= 3) & RACEX in (4, 5)

#  - For 2012 and later, use RACETHX and RACEV1X:
FYC = FYC.with_columns(
    hisp=pl.col("RACETHX") == 1,
    white=pl.col("RACETHX") == 2,
    black=pl.col("RACETHX") == 3,
    native=(pl.col("RACETHX") > 3) & pl.col("RACEV1X").cast(int).is_in([3, 6]),
    asian=(pl.col("RACETHX") > 3) & pl.col("RACEV1X").cast(int).is_in([4, 5]),
)

race_labels = {
    1: "Hispanic",
    2: "White",
    3: "Black",
    4: "Amer. Indian, AK Native, or mult. races",
    5: "Asian, Hawaiian, or Pacific Islander",
}

FYC = FYC.with_columns(
    race=(
        1 * pl.col("hisp") + 2 * pl.col("white") + 3 * pl.col("black")
        + 4 * pl.col("native") + 5 * pl.col("asian")
    ).replace_strict(race_labels, return_dtype=pl.Enum(list(race_labels.values())))
)

# Sex
sex_labels = {
    1: "Male",
    2: "Female",
}

FYC = FYC.with_columns(
    sex=pl.col("SEX").replace_strict(sex_labels, return_dtype=pl.Enum(list(sex_labels.values())))
)

# QC new variables
print(
    FYC.group_by("RACETHX", "RACEV1X", "hisp", "white", "black", "native", "asian", "race")
    .len()
    .sort(pl.all())
)
print(FYC.group_by("sex", "SEX").len().sort(pl.all()))


# Add subgroup variables ------------------------------------------------------

FYC = FYC.with_columns(
    persons=pl.lit(1),  # counter variable for population totals
    has_exp=(pl.col("TOTEXP16") > 0).cast(int),  # 1 if person has an expense
)

# QC new variables
print(
    FYC.group_by("persons", "has_exp")
    .agg(
        min_exp=pl.col("TOTEXP16").min(),
        mean_exp=pl.col("TOTEXP16").mean(),
        max_exp=pl.col("TOTEXP16").max(),
    )
    .sort("persons", "has_exp")
)


# Define survey design and calculate estimates --------------------------------

FYCdsgn = svy.Sample(
    data=FYC,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F", singleton="center"),
)


has_exp = pl.col("has_exp") == 1


# Number of people
print(FYCdsgn.estimation.total("persons", by=["sex", "race"]))

# Percent of population with an expense
print(FYCdsgn.estimation.mean("has_exp", by=["sex", "race"]))

# Total expenditures
print(FYCdsgn.estimation.total("TOTEXP16", by=["sex", "race"]))

# Mean expenditure per person
print(FYCdsgn.estimation.mean("TOTEXP16", by=["sex", "race"]))

# Mean expenditure per person with expense
print(FYCdsgn.estimation.mean("TOTEXP16", by=["sex", "race"], where=has_exp))

# Median expenditure per person with expense
#   Note: Estimates may vary in R, SAS, and Stata, due to different methods
#         of estimating survey quantiles
print(FYCdsgn.estimation.median("TOTEXP16", by=["sex", "race"], where=has_exp))
