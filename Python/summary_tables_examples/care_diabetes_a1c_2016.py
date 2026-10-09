# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Accessibility and quality of care: Diabetes Care, 2016
#
# Diabetes care survey (DCS):
#  - Number/percent of adults with diabetes receiving hemoglobin A1c blood test
#  - By race/ethnicity
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

# Diabetes care: Hemoglobin A1c measurement
#  - DSA1C53 = 'Times tested for A1c in 2016' (96 = did not have test)
FYC = FYC.with_columns(
    diab_a1c=pl.when(pl.col("DSA1C53") == -1).then(pl.lit("Inapplicable"))
    .when(pl.col("DSA1C53") < 0).then(pl.lit("Don't know/Non-response"))
    .when(pl.col("DSA1C53") == 0).then(pl.lit("Did not have measurement"))
    .when(pl.col("DSA1C53") == 96).then(pl.lit("Did not have measurement"))
    .when((0 < pl.col("DSA1C53")) & (pl.col("DSA1C53") < 96)).then(pl.lit("Had measurement"))
    .otherwise(pl.lit("Missing"))
)

# Race/ethnicity
# 1996-2002: race/ethnicity variable based on RACETHNX (see documentation for details)
# 2002-2011: race/ethnicity variable based on RACETHNX and RACEX:
#   hisp   = (RACETHNX == 1)
#   white  = (RACETHNX == 4) & (RACEX == 1)
#   black  = (RACETHNX == 2)
#   native = (RACETHNX >= 3) & RACEX in (3, 6)
#   asian  = (RACETHNX >= 3) & RACEX in (4, 5)

# For 2012 and later, use RACETHX and RACEV1X:
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

# QC new variables
print(
    FYC.group_by("RACETHX", "RACEV1X", "hisp", "white", "black", "native", "asian", "race")
    .len()
    .sort(pl.all())
)
with pl.Config(tbl_rows=-1):
    print(FYC.group_by("diab_a1c", "DSA1C53").len().sort(pl.all()))


# Define survey design and calculate estimates --------------------------------
#  - use DIABW16F weight variable, since outcome variable comes from DCS

DIABdsgn = svy.Sample(
    data=FYC,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="DIABW16F", singleton="center"),
)


# Adults with diabetes with hemoglobin A1C measurement in 2016, by race
print(DIABdsgn.estimation.total("diab_a1c", by="race", as_factor=True))  # number
print(DIABdsgn.estimation.prop("diab_a1c", by="race"))  # percent
