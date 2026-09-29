# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Health insurance, 2016:
#  - Number/percent of people
#  - By insurance coverage and age groups
#
# Input file: C:/MEPS/h192.ssp (2016 full-year consolidated)
# -----------------------------------------------------------------------------

# Install/load packages -------------------------------------------------------

# Install packages (if needed) -- only need to run once (in a terminal)
#   pip install svy

# Load packages (need to run every session)
from pathlib import Path

import polars as pl
import svy
from svy_io import read_xpt

MEPS_DIR = Path("C:/MEPS")

# Load FYC file ---------------------------------------------------------------

FYC, _ = read_xpt(MEPS_DIR / "h192.ssp")


# Define variables ------------------------------------------------------------

# Age groups
#  - For 1996-2007, AGELAST must be created from AGEyyX, AGE42X, AGE31X
FYC = FYC.with_columns(
    agegrps=pl.col("AGELAST").cut(
        [4.5, 17.5, 44.5, 64.5],
        labels=["Under 5", "5-17", "18-44", "45-64", "65+"],
    )
)

# Insurance coverage
#  - For 1996-2011, create INSURC from INSCOV and 'EV' variables
#     (for 1996, use 'EVER' vars):
#
#     public   = (MCDEV16 == 1) | (OPAEV16 == 1) | (OPBEV16 == 1)
#     medicare = (MCREV16 == 1)
#     private  = (INSCOV16 == 1)
#
#     mcr_priv = medicare &  private
#     mcr_pub  = medicare & ~private &  public
#     mcr_only = medicare & ~private & ~public
#     no_mcr   = ~medicare
#
#     ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr
#     INSURC16 = INSCOV16 if AGELAST < 65, otherwise ins_gt65

insurance_labels = {
    1: "<65, Any private",
    2: "<65, Public only",
    3: "<65, Uninsured",
    4: "65+, Medicare only",
    5: "65+, Medicare and private",
    6: "65+, Medicare and other public",
    7: "65+, No Medicare",
    8: "65+, No Medicare",
}

FYC = FYC.with_columns(
    insurance=pl.col("INSURC16").replace_strict(
        insurance_labels, return_dtype=pl.Enum(list(dict.fromkeys(insurance_labels.values())))
    )
)

# QC new variables
print(
    FYC.group_by("agegrps")
    .agg(
        min_age=pl.col("AGELAST").min(),
        max_age=pl.col("AGELAST").max(),
        n_ppl=pl.len(),
    )
    .sort("agegrps")
)

print(FYC.group_by("insurance", "INSURC16", "agegrps").len().sort(pl.all()))


# Define survey design and calculate estimates --------------------------------

FYCdsgn = svy.Sample(
    data=FYC,
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F"),
)

# Set survey option for lonely psu
FYCdsgn = FYCdsgn.singleton.center()

# Insurance coverage status by age groups
print(FYCdsgn.estimation.total("insurance", by="agegrps", as_factor=True))  # number
print(FYCdsgn.estimation.prop("insurance", by="agegrps"))  # percent
