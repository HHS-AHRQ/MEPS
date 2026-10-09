# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Accessibility and quality of care: Access to Care, 2017
#
# Reasons for difficulty receiving needed care
#  - Number/percent of people
#  - By poverty status
#
# Input file: C:/MEPS/h201.dta (2017 full-year consolidated)
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

FYC = svy.read_stata(MEPS_DIR / "h201.dta")


# Define variables ------------------------------------------------------------

# Reasons for difficulty receiving needed care

FYC = FYC.with_columns(
    # any delay / unable to receive needed care
    delay_MD=((pl.col("MDUNAB42") == 1) | (pl.col("MDDLAY42") == 1)).cast(int),
    delay_DN=((pl.col("DNUNAB42") == 1) | (pl.col("DNDLAY42") == 1)).cast(int),
    delay_PM=((pl.col("PMUNAB42") == 1) | (pl.col("PMDLAY42") == 1)).cast(int),

    # Among people unable or delayed, how many...
    # ...couldn't afford
    afford_MD=((pl.col("MDDLRS42") == 1) | (pl.col("MDUNRS42") == 1)).cast(int),
    afford_DN=((pl.col("DNDLRS42") == 1) | (pl.col("DNUNRS42") == 1)).cast(int),
    afford_PM=((pl.col("PMDLRS42") == 1) | (pl.col("PMUNRS42") == 1)).cast(int),

    # ...had insurance problems
    insure_MD=(pl.col("MDDLRS42").cast(int).is_in([2, 3]) | pl.col("MDUNRS42").cast(int).is_in([2, 3])).cast(int),
    insure_DN=(pl.col("DNDLRS42").cast(int).is_in([2, 3]) | pl.col("DNUNRS42").cast(int).is_in([2, 3])).cast(int),
    insure_PM=(pl.col("PMDLRS42").cast(int).is_in([2, 3]) | pl.col("PMUNRS42").cast(int).is_in([2, 3])).cast(int),

    # ...other
    other_MD=((pl.col("MDDLRS42") > 3) | (pl.col("MDUNRS42") > 3)).cast(int),
    other_DN=((pl.col("DNDLRS42") > 3) | (pl.col("DNUNRS42") > 3)).cast(int),
    other_PM=((pl.col("PMDLRS42") > 3) | (pl.col("PMUNRS42") > 3)).cast(int),
)

FYC = FYC.with_columns(
    delay_ANY=pl.max_horizontal("delay_MD", "delay_DN", "delay_PM"),
    afford_ANY=pl.max_horizontal("afford_MD", "afford_DN", "afford_PM"),
    insure_ANY=pl.max_horizontal("insure_MD", "insure_DN", "insure_PM"),
    other_ANY=pl.max_horizontal("other_MD", "other_DN", "other_PM"),
)


# Poverty status
poverty_labels = {
    1: "Negative or poor",
    2: "Near-poor",
    3: "Low income",
    4: "Middle income",
    5: "High income",
}

FYC = FYC.with_columns(
    poverty=pl.col("POVCAT17").replace_strict(
        poverty_labels, return_dtype=pl.Enum(list(poverty_labels.values()))
    )
)

# QC new variables
print(FYC.group_by("delay_MD", "MDUNAB42", "MDDLAY42").len().sort(pl.all()))
print(FYC.group_by("delay_DN", "DNUNAB42", "DNDLAY42").len().sort(pl.all()))
print(FYC.group_by("delay_PM", "PMUNAB42", "PMDLAY42").len().sort(pl.all()))
print(FYC.group_by("delay_ANY", "delay_MD", "delay_DN", "delay_PM").len().sort(pl.all()))
# ...repeat for "couldn't afford", "insurance", and "other"

print(FYC.group_by("poverty", "POVCAT17").len().sort(pl.all()))


# Define survey design and calculate estimates --------------------------------

FYCdsgn = svy.Sample(
    data=FYC,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT17F", singleton="center"),
)


# Subset to persons eligible to receive the 'access to care' supplement
#   and who experienced difficulty receiving needed care

sub = (pl.col("ACCELI42") == 1) & (pl.col("delay_ANY") == 1)

# Reasons for difficulty receiving any needed care, by poverty status
reasons = ["afford_ANY", "insure_ANY", "other_ANY"]

for est in FYCdsgn.estimation.total(reasons, by="poverty", where=sub):  # number
    print(est)

for est in FYCdsgn.estimation.mean(reasons, by="poverty", where=sub):  # percent
    print(est)
