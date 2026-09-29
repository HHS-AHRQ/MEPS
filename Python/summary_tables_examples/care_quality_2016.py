# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Accessibility and quality of care: Quality of Care, 2016
#
# Self-administered questionnaire (SAQ):
#  - Number/percent of adults by ability to schedule a routine appointment
#  - By insurance coverage status
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

# Ability to schedule a routine appt. (adults)
routine_labels = {
    4: "Always",
    3: "Usually",
    2: "Sometimes/Never",
    1: "Sometimes/Never",
    -7: "Don't know/Non-response",
    -8: "Don't know/Non-response",
    -9: "Don't know/Non-response",
    -1: "Inapplicable",
}

FYC = FYC.with_columns(
    adult_routine=pl.col("ADRTWW42").replace_strict(
        routine_labels,
        default="Missing",
        return_dtype=pl.Enum([*dict.fromkeys(routine_labels.values()), "Missing"]),
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
    7: "65+, No medicare",
    8: "65+, No medicare",
}

FYC = FYC.with_columns(
    insurance=pl.col("INSURC16").replace_strict(
        insurance_labels,
        default="Missing",
        return_dtype=pl.Enum([*dict.fromkeys(insurance_labels.values()), "Missing"]),
    )
)

# QC new variables
print(FYC.group_by("adult_routine", "ADRTWW42").len().sort(pl.all()))
print(FYC.group_by("insurance", "INSURC16").len().sort(pl.all()))


# Define survey design and calculate estimates --------------------------------
#  - use SAQWT16F weight variable, since outcome variable comes from SAQ

SAQdsgn = svy.Sample(
    data=FYC,
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="SAQWT16F"),
)

# Set survey option for lonely psu
SAQdsgn = SAQdsgn.singleton.center()

# Subset to adults who made an appointment
sub = (pl.col("ADRTCR42") == 1) & (pl.col("AGELAST") >= 18)

# Ability to schedule a routine appointment (adults), by insurance coverage
print(SAQdsgn.estimation.total("adult_routine", by="insurance", where=sub, as_factor=True))  # number
print(SAQdsgn.estimation.prop("adult_routine", by="insurance", where=sub))  # percent
