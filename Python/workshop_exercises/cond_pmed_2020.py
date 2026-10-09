# -----------------------------------------------------------------------------
# This program shows how to link the MEPS-HC Medical Conditions file
# to the Prescribed Medicines (PMED/RX) file for data year 2020 to estimate:
#
# National totals:
#   - Total number of people w PMED purchase for hyperlipidemia (HL)
#   - Total PMED fills for HL
#   - Total PMED expenditures for HL
#
# Per-person averages among ppl with any PMED for hyperlipidemia (HL)
#   - Avg PMED fills for hyperlipidemia, by SEX and Poverty (POVCAT)
#   - Avg PMED exp for HL per person w/ HL fills, by SEX and Poverty (POVCAT)
#
# Input files:
#   - h220a.dta        (2020 Prescribed Medicines file)
#   - h222.dta         (2020 Conditions file)
#   - h220if1.dta      (2020 CLNK: Condition-Event Link file)
#   - h224.dta         (2020 Full-Year Consolidated file)
#
# Resources:
#   - CCSR codes:
#   https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv
#
#   - MEPS-HC Public Use Files:
#   https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp
#
#   - MEPS-HC online data tools:
#   https://datatools.ahrq.gov/meps-hc
#
# -----------------------------------------------------------------------------


# Install/load packages and set global options --------------------------------

# Can skip this part if already installed (run in a terminal)
#   pip install svy==0.32.1 "polars>=2"   # for survey analysis, also installs polars


# Load packages (run this part each time you re-start Python)
from pathlib import Path

import polars as pl  # for data manipulation
import svy  # for survey analysis and loading Stata (.dta) files

# This module facilitates file import (meps.py, in this folder)
from meps import read_meps

MEPS_DIR = Path("C:/MEPS")


# Load datasets ---------------------------------------------------------------
#  PMED/RX = Prescribed medicines file (record = rx fill or refill)
#  COND    = Medical conditions file (record = medical condition)
#  CLNK    = Conditions-event link file (crosswalk between conditions and
#             events, including PMED events)
#  FYC     = Full-year-consolidated file (record = MEPS sample person)


# Option 1 - load data files using read_meps from the meps module
#  >> For PMED file, rename LINKIDX to EVNTIDX to merge with Conditions

pmed20 = read_meps(year=2020, type="RX").rename({"LINKIDX": "EVNTIDX"})
cond20 = read_meps(year=2020, type="COND")
clnk20 = read_meps(year=2020, type="CLNK")
fyc20 = read_meps(year=2020, type="FYC")


# Option 2 - load Stata data files using read_stata from the svy package
#  >> Replace "C:/MEPS" in MEPS_DIR with the directory you saved the files to.

# pmed20 = svy.read_stata(MEPS_DIR / "h220a.dta").rename({"LINKIDX": "EVNTIDX"})
# cond20 = svy.read_stata(MEPS_DIR / "h222.dta")
# clnk20 = svy.read_stata(MEPS_DIR / "h220if1.dta")
# fyc20 = svy.read_stata(MEPS_DIR / "h224.dta")


# Keep only needed variables ------------------------------------------------

pmed20x = pmed20.select("DUPERSID", "RXRECIDX", "EVNTIDX", "RXDRGNAM", "RXXP20X")

cond20x = cond20.select("DUPERSID", "CONDIDX", "ICD10CDX", "CCSR1X", "CCSR2X", "CCSR3X")

fyc20x = fyc20.select("DUPERSID", "AGELAST", "SEX", "POVCAT20", "CHOLDX", "VARSTR", "VARPSU", "PERWT20F")



# Prepare data for estimation -------------------------------------------------

# Subset condition records to hyperlipidemia (any CCSR = "END010")

hl = cond20x.filter(
    (pl.col("CCSR1X") == "END010") | (pl.col("CCSR2X") == "END010") | (pl.col("CCSR3X") == "END010")
)

# QC
print(hl.group_by("ICD10CDX", "CCSR1X", "CCSR2X", "CCSR3X").len().sort(pl.all()))


# >> Note that the same person can have 'duplicate' hyperlipidemia conditions.
#    This can happen when the full ICD10s are different (e.g. E78.1 and E78.5)
#    but the collapsed 3-digit ICD10CDX is the same (E78)

# >> Example:
print(hl.filter(pl.col("DUPERSID") == "2320134102"))



# Merge hyperlipidemia conditions with PMED file, using CLNK as crosswalk -----

# 1. Merge COND with CLNK file
hl_clnk = hl.join(clnk20, on=["DUPERSID", "CONDIDX"], how="inner")

# >> View example person:
#   - same condition (CONDIDX), multiple events (EVNTIDX)
#   - same event (EVNTIDX), multiple conditions (CONDIDX)

print(hl_clnk.filter(pl.col("DUPERSID") == "2320134102"))



# 2. De-duplicate on EVNTIDX (so we don't 'double-count' events)
hl_clnk_distinct = hl_clnk.select(
    "PANEL", "DUPERSID", "EVNTIDX", "ICD10CDX", "CCSR1X", "EVENTYPE"
).unique(maintain_order=True)

# QC: should be 0 duplicate EVNTIDX
print((~hl_clnk_distinct["EVNTIDX"].is_first_distinct()).sum())

# >> View example person:
print(hl_clnk_distinct.filter(pl.col("DUPERSID") == "2320134102"))



# 3. Merge HL-CLNK with PMED file
hl_merged = hl_clnk_distinct.join(pmed20x, on=["DUPERSID", "EVNTIDX"], how="inner")


# >> View example person:
print(hl_merged.filter(pl.col("DUPERSID") == "2320134102"))


# QC: check that EVENTYPE = 8 PRESCRIBED MEDICINE for all rows
print(hl_merged.group_by("EVENTYPE").len())

# QC: View top PMEDS for hyperlipidemia
print(hl_merged.group_by("RXDRGNAM").len().sort("len", descending=True))



# Roll up to person-level data ------------------------------------------------
# >> For each person:
#    - n_hl_fills: number of unique fills for hyperlipidemia
#    - hl_drug_exp: sum of PMED expenditures for hyperlipidemia
#    - hl_pmed_flag: make a flag for people with a PMED purchase

drugs_by_pers = hl_merged.group_by("DUPERSID").agg(
    n_hl_fills=pl.col("RXRECIDX").n_unique(),
    hl_drug_exp=pl.col("RXXP20X").sum(),
).with_columns(hl_pmed_flag=pl.lit(1))


# >> View example person:
print(drugs_by_pers.filter(pl.col("DUPERSID") == "2320134102"))



# Merge onto FYC file ---------------------------------------------------------
#  >> Need to capture all Strata (VARSTR) and PSUs (VARPSU) for all MEPS sample
#     persons for correct variance estimation

fyc_hl_merged = fyc20x.join(drugs_by_pers, on="DUPERSID", how="full", coalesce=True).with_columns(
    pl.col("hl_pmed_flag").fill_null(0)
)


# QC: should have same number of rows as FYC file
print(fyc20x.height == fyc_hl_merged.height)

# QC: hl_pmed_flag counts should be equal to rows in drugs_by_pers
print(fyc_hl_merged.group_by("hl_pmed_flag").len().sort("hl_pmed_flag"))
print(drugs_by_pers.height)



# BONUS!! Compare people ever diagnosed with hyperlipidemia (CHOLDX == 1) with
# those that have hyperlipidemia PMED purchases

print(fyc_hl_merged.group_by("CHOLDX", "hl_pmed_flag").len().sort(pl.all()))  # -1's are mostly kids (age < 18)

print(
    fyc_hl_merged
    .filter(pl.col("CHOLDX") >= 0)
    .group_by("CHOLDX", "hl_pmed_flag").len().sort(pl.all())
)




# Define the survey design ----------------------------------------------------

meps_dsgn = svy.Sample(
    data=fyc_hl_merged,
    # lonely PSUs, also within a domain: R's options(survey.lonely.psu = 'adjust') and
    # options(survey.adjust.domain.lonely = TRUE)
    design=svy.Design(
        psu="VARPSU",
        stratum="VARSTR",
        wgt="PERWT20F",
        singleton=svy.Singleton("center", domains="apply"),
    ),
)


# Subset to people with HL PMED purchases (the 'where' argument keeps the full design)
hl_pmed_sub = pl.col("hl_pmed_flag") == 1


# Calculate estimates ---------------------------------------------------------

# >> National Totals:

for est in meps_dsgn.estimation.total(
    ["hl_pmed_flag",  # Total people w PMED purchase for HL
     "n_hl_fills",    # Total PMED fills for hyperlipidemia
     "hl_drug_exp"],  # Total PMED expenditures for hyperlipidemia
    where=hl_pmed_sub,
):
    print(est)


# >> Per-person average expenditures among people with at least
#    one PMED fill for hyperlipidemia (hl_pmed_flag = 1)

for est in meps_dsgn.estimation.mean(
    ["n_hl_fills",    # Avg PMED fills for hyperlipidemia
     "hl_drug_exp"],  # Avg PMED exp for HL per person w/ HL fills
    where=hl_pmed_sub,
):
    print(est)


# >> By SEX
#    1: MALE
#    2: FEMALE

for est in meps_dsgn.estimation.mean(
    ["n_hl_fills", "hl_drug_exp"], by="SEX", where=hl_pmed_sub
):
    print(est)


# >> By POVCAT
#    1: Poor/negative
#    2: Near poor
#    3: Low income
#    4: Middle income
#    5: High income

for est in meps_dsgn.estimation.mean(
    ["n_hl_fills", "hl_drug_exp"], by="POVCAT20", where=hl_pmed_sub
):
    print(est)
