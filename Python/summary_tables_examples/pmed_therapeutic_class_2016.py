# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Prescribed drugs, 2016
#
# Purchases and expenditures by Multum therapeutic class name (TC1)
#  - Number of people with purchase
#  - Total purchases
#  - Total expenditures
#
# Input file: C:/MEPS/h188a.ssp (2016 RX event file)
# -----------------------------------------------------------------------------

# Install/load packages -------------------------------------------------------

# Install packages (if needed) -- only need to run once (in a terminal)
#   pip install svy==0.32.1 "polars>=2"

# Load packages (need to run every session)
from pathlib import Path

import polars as pl
import svy

MEPS_DIR = Path("C:/MEPS")


# Load datasets ---------------------------------------------------------------
# For 1996-2013, need to merge with RX Multum Lexicon Addendum files to get
#  therapeutic class categories and generic drug names

# Load RX file
RX = svy.read_sas(MEPS_DIR / "h188a.ssp")

# Define therapeutic classes
TC1_labels = {
    -9: "Not_ascertained",
    -1: "Inapplicable",
    1: "Anti-infectives",
    19: "Antihyperlipidemic_agents",
    20: "Antineoplastics",
    28: "Biologicals",
    40: "Cardiovascular_agents",
    57: "Central_nervous_system_agents",
    81: "Coagulation_modifiers",
    87: "Gastrointestinal_agents",
    97: "Hormones/hormone_modifiers",
    105: "Miscellaneous_agents",
    113: "Genitourinary_tract_agents",
    115: "Nutritional_products",
    122: "Respiratory_agents",
    133: "Topical_agents",
    218: "Alternative_medicines",
    242: "Psychotherapeutic_agents",
    254: "Immunologic_agents",
    358: "Metabolic_agents",
}

RX = RX.with_columns(
    TC1name=pl.col("TC1").replace_strict(
        TC1_labels, return_dtype=pl.Enum(list(TC1_labels.values()))
    )
)


# Aggregate to person-level ---------------------------------------------------

TC1_pers = (
    RX.group_by("DUPERSID", "VARSTR", "VARPSU", "TC1name")
    .agg(
        PERWT16F=pl.col("PERWT16F").mean(),
        pers_RXXP=pl.col("RXXP16X").sum(),
        n_purchases=pl.len(),
    )
    .with_columns(persons=pl.lit(1))
)


# Define survey design and calculate estimates --------------------------------

TC1dsgn = svy.Sample(
    data=TC1_pers,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F", singleton="center"),
)


totals = TC1dsgn.estimation.total(["persons", "n_purchases", "pers_RXXP"], by="TC1name")

print(totals[0])  # Number of people with purchase
print(totals[1])  # Total purchases
print(totals[2])  # Total expenditures
