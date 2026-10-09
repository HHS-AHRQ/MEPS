# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Accessibility and quality of care: Access to Care, 2019
#
# Did not receive treatment because couldn't afford it
#  - Number/percent of people
#  - By poverty status
#
# Input file: C:/MEPS/h216.dta (2019 full-year consolidated)
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

FYC = svy.read_stata(MEPS_DIR / "h216.dta")


# Define variables ------------------------------------------------------------

# Didn't receive care because couldn't afford it
FYC = FYC.with_columns(
    afford_MD=(pl.col("AFRDCA42") == 1).cast(int),  # medical care
    afford_DN=(pl.col("AFRDDN42") == 1).cast(int),  # dental care
    afford_PM=(pl.col("AFRDPM42") == 1).cast(int),  # prescription medicines
)

FYC = FYC.with_columns(
    afford_ANY=pl.max_horizontal("afford_MD", "afford_DN", "afford_PM"),  # any care
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
    poverty=pl.col("POVCAT19").replace_strict(
        poverty_labels, return_dtype=pl.Enum(list(poverty_labels.values()))
    )
)

# QC new variables
print(FYC.group_by("AFRDCA42", "afford_MD").len().sort(pl.all()))
print(FYC.group_by("AFRDDN42", "afford_DN").len().sort(pl.all()))
print(FYC.group_by("AFRDPM42", "afford_PM").len().sort(pl.all()))
print(FYC.group_by("afford_MD", "afford_DN", "afford_PM", "afford_ANY").len().sort(pl.all()))

print(FYC.group_by("poverty", "POVCAT19").len().sort(pl.all()))


# Define survey design and calculate estimates --------------------------------

FYCdsgn = svy.Sample(
    data=FYC,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT19F", singleton="center"),
)


# Subset to persons eligible to receive the 'access to care' supplement
sub = pl.col("ACCELI42") == 1

# Did not receive treatment because couldn't afford it, by poverty status
afford = ["afford_ANY", "afford_MD", "afford_DN", "afford_PM"]

for est in FYCdsgn.estimation.total(afford, by="poverty", where=sub):  # number
    print(est)

for est in FYCdsgn.estimation.mean(afford, by="poverty", where=sub):  # percent
    print(est)
