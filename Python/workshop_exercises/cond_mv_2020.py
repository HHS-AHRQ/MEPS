# -----------------------------------------------------------------------------
# Example code linking MEPS-HC Medical Conditions file to the Office-based
# medical visits file, data year 2020:
#
# Event-level estimates:
#  - Number of office-based visits for mental health
#  - Total expenditures for office-based mental health treatment
#  - Mean expenditure per office-based mental health visit
#
# Person-level estimates
#  - Number of people with office-based mental health visits
#  - Percent of people with office-based mental health visits
#  - Mean expenditure per person for office-based mental health visits

#
# Input files:
#  - h220g.dta   (2020 Office-based event file)
#  - h222.dta    (2020 Conditions file)
#  - h220if1.dta (2020 CLNK: Condition-event link file)
#  - h224.dta    (2020 Full-Year Consolidated file)
#
# Resources:
#  - CCSR codes:
#     https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv
#
#  - MEPS-HC Public Use Files:
#     https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp
#
#  - MEPS-HC data tools:
#     https://datatools.ahrq.gov/meps-hc
# -----------------------------------------------------------------------------


# Install/load packages and set global options --------------------------------

# If packages are not already installed, run in a terminal:
#   pip install svy   # for survey analysis, also installs polars


# Load packages
from pathlib import Path

import polars as pl  # for data manipulation
import svy  # for survey analysis and loading Stata (.dta) files

# This module facilitates file import (meps.py, in this folder)
# >> OK if it doesn't work -- just use 'Option 2' for loading data
from meps import read_meps

MEPS_DIR = Path("C:/MEPS")


# Set global options

pl.Config.set_tbl_cols(-1)  # so columns won't be truncated when printing
pl.Config.set_fmt_float("full")  # so big numbers aren't defaulted to scientific notation



# Load datasets ---------------------------------------------------------------

# OB   = Office-based medical visits file (record = medical visit)
# COND = Medical conditions file (record = medical condition)
# CLNK = Conditions-event link file (crosswalk between conditions and events)
# FYC  = Full year consolidated file (record = MEPS sample person)


# Option 1 - load data files using read_meps from the meps module
ob20 = read_meps(year=2020, type="OB")
cond20 = read_meps(year=2020, type="COND")
clnk20 = read_meps(year=2020, type="CLNK")
fyc20 = read_meps(year=2020, type="FYC")


# Option 2 - load Stata data files using read_stata from the svy package
#  First, download Stata (.dta) data sets from MEPS website:
#   -> https://meps.ahrq.gov > Data Files

# Replace "C:/MEPS" in MEPS_DIR with the directory you saved the files to.

# ob20 = svy.read_stata(MEPS_DIR / "h220g.dta")
# cond20 = svy.read_stata(MEPS_DIR / "h222.dta")
# clnk20 = svy.read_stata(MEPS_DIR / "h220if1.dta")
# fyc20 = svy.read_stata(MEPS_DIR / "h224.dta")


# Preview files (optional)
print(ob20)
print(cond20)
print(clnk20)


# Keep only needed variables --------------------------------------------------

#  Browse variables using MEPS-HC data tools variable explorer:
#  -> http://datatools.ahrq.gov/meps-hc#varExp

ob20x = ob20.select(
    "PANEL", "DUPERSID", "EVNTIDX", "EVENTRN", "OBDATEYR", "OBDATEMM",
    "TELEHEALTHFLAG", "OBXP20X", "PERWT20F", "VARPSU", "VARSTR",
)

cond20x = cond20.select("DUPERSID", "CONDIDX", "ICD10CDX", "CCSR1X", "CCSR2X", "CCSR3X")

fyc20x = fyc20.select("DUPERSID", "PERWT20F", "VARSTR", "VARPSU")



# Filter COND file to only people with Mental Disorders -----------------------

mental_health = cond20x.with_columns(
    all_CCSR=pl.concat_str("CCSR1X", "CCSR2X", "CCSR3X", separator="_")
).filter(pl.col("all_CCSR").str.contains("MBD|FAC002|FAC007|NVS011|SYM008|SYM009"))

# view ICD10-CCSR combinations for mental health
with pl.Config(tbl_rows=100):
    print(mental_health.group_by("ICD10CDX", "CCSR1X", "CCSR2X", "CCSR3X").len().sort(pl.all()))


# Filter CLNK file to only office-based visits --------------------------------
#  EVENTYPE:
#   1 = "Office-based"
#   2 = "Outpatient"
#   3 = "Emergency room"
#   4 = "Inpatient stay"
#   7 = "Home health"
#   8 = "Prescribed medicine"

clnk_ob = clnk20.filter(pl.col("EVENTYPE") == 1)

# QC: should only have EVENTYPE = 1
print(clnk_ob.group_by("EVENTYPE").len())


# Merge datasets --------------------------------------------------------------

# Merge conditions file with the conditions-event link file (CLNK)
#  'inner' join only keeps records that are on both files

mh_clnk = mental_health.join(clnk_ob, on=["DUPERSID", "CONDIDX"], how="inner")


# Note that one condition can be treated in different events
#  (same CONDIDX, different EVNTIDX):
print(mh_clnk.filter(pl.col("CONDIDX") == "2320109103009"))


# Conversely, one visit can be for multiple conditions
#  (same EVNTIDX, different CONDIDX):
print(mh_clnk.filter(pl.col("EVNTIDX") == "2320051101205101"))



# De-duplicate by event ID ('EVNTIDX'), since someone can have multiple events
# for Mental Health. We don't want to count the same event twice.
mh_clnk_nodup = mh_clnk.select("DUPERSID", "EVNTIDX", "EVENTYPE").unique(maintain_order=True)




# Merge on event files --------------------------------------------------------
ob_mental_health = ob20x.join(mh_clnk_nodup, on=["DUPERSID", "EVNTIDX"], how="inner").with_columns(
    # Add indicator variables for all visits to help with counting later:
    mh_ob_visit=pl.lit(1)
)

# QC: should be EVENTYPE = 1 and mh_ob_visit = 1 for all rows
print(ob_mental_health.group_by("EVENTYPE", "mh_ob_visit").len())


# DO NOT RUN ---------------------
#  Survey estimates? Not quite! Need to merge with FYC file first, to get
#  complete Strata (VARSTR) and PSUs (VARPSU) for entire MEPS sample
#
# THIS CODE IS INCLUDED AS AN EXAMPLE OF WHAT NOT TO DO
# THIS WILL GIVE WRONG SEs:
#
# badDsgn = svy.Sample(
#     data=ob_mental_health,
#     design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT20F"),
# )
#
# print(badDsgn.estimation.total("mh_ob_visit"))  # Number of visits
# print(badDsgn.estimation.total("OBXP20X"))      # Total exp.
# print(badDsgn.estimation.mean("OBXP20X"))       # Mean exp. per visit

# END DO NOT RUN -----------------




# Merge on FYC file for complete Strata, PSUs ---------------------------------

ob_mh_fyc = ob_mental_health.with_columns(mh_ob=pl.lit(1)).join(
    fyc20x.with_columns(fyc=pl.lit(1)),
    on=["DUPERSID", "PERWT20F", "VARSTR", "VARPSU"],
    how="full",
    coalesce=True,
)


# QC
print(ob_mh_fyc.group_by("mh_ob", "mh_ob_visit", "fyc").len())



# Event-level estimates -------------------------------------------------------
# - Number of office-based visits for mental health:       343,810,085 (SE: 22,252,863)
# - Total exp. for office-based mental health visits:  $60,209,392,314 (SE: 4,437,433,004)
# - Mean exp. per visit:                                       $175.12 (SE: 6.46)


# Define survey design
evntDsgn = svy.Sample(
    data=ob_mh_fyc,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT20F", singleton="center"),
)


# Subset to mental health visits (the 'where' argument keeps the full design)
sub = pl.col("mh_ob") == 1

# Calculate survey estimates
print(evntDsgn.estimation.total("mh_ob_visit", where=sub))  # Number of visits
print(evntDsgn.estimation.total("OBXP20X", where=sub))  # Total exp.
print(evntDsgn.estimation.mean("OBXP20X", where=sub))  # Mean exp. per visit


# A note on Telehealth --------------------------------------------------------
#  - telehealth questions were added to the survey in Fall of 2020
#  - TELEHEALTHFLAG = -15 for events reported before telehealth questions
#  - Recommendation: imputation or sensitivity analysis

print(
    ob20.group_by("OBDATEMM", "TELEHEALTHFLAG").len()
    .sort(pl.all())
    .pivot(on="TELEHEALTHFLAG", index="OBDATEMM", values="len")
)


# Person-level estimates ------------------------------------------------------
#  - Number of people with office visit for MH:  29,816,984 (SE: 1,192,676)
#  - Percent of people with office visit for MH:      9.08% (SE: 0.29%)
#  - Mean exp per person for office visits for MH: $2019.30 (SE: 126.16)
#
#  - Number of visits (QC)       343,810,085 (SE: 22,252,863)
#  - Total exp. (QC)         $60,209,392,314 (SE: 4,437,433,004)


# Aggregate to person-level
pers_mh = ob_mh_fyc.group_by("DUPERSID", "VARSTR", "VARPSU", "PERWT20F").agg(
    persXP=pl.col("OBXP20X").sum(),
    pers_nevents=pl.col("mh_ob_visit").sum(),
    mh_ob_visit_pers=pl.col("mh_ob_visit").mean(),
    mh_ob_pers=pl.col("mh_ob").mean(),
).with_columns(
    # replace missings with 0s
    pl.col("pers_nevents", "mh_ob_pers", "mh_ob_visit_pers").fill_null(0)
)


# QC - Should have:

# - same number of records as fyc file
print(pers_mh.height == fyc20.height)

# - mh_pers and mh_ob_visit = 1   OR
# - mh_pers and mh_ob_visit = 0
print(pers_mh.group_by("mh_ob_pers", "mh_ob_visit_pers").len())

# - pers_nevents = 0 when mh or mh_ob_visit = 0
print(
    pers_mh
    .filter((pl.col("mh_ob_pers") == 0) | (pl.col("mh_ob_visit_pers") == 0))
    .group_by("pers_nevents").len()
)

# - view person with several events
print(ob_mh_fyc.filter(pl.col("DUPERSID") == "2320109103"))
print(pers_mh.filter(pl.col("DUPERSID") == "2320109103"))

# - view person with 0 events
print(ob_mh_fyc.filter(pl.col("DUPERSID") == "2320005101"))
print(pers_mh.filter(pl.col("DUPERSID") == "2320005101"))



# Define person-level survey design -----------------
persDsgn = svy.Sample(
    data=pers_mh,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT20F", singleton="center"),
)


# Define subset of people with office-based mental health visits
sub_OBMH = pl.col("mh_ob_pers") == 1



# Calculate survey estimates ------------------------
print(persDsgn.estimation.total("mh_ob_visit_pers"))  # Number of people
print(persDsgn.estimation.mean("mh_ob_visit_pers"))  # Percent of people
print(persDsgn.estimation.mean("persXP", where=sub_OBMH))  # Mean exp. per person for office-based mental health visits

# Duplicate event-level estimates for additional QC
print(persDsgn.estimation.total("pers_nevents", where=sub_OBMH))  # Number of visits
print(persDsgn.estimation.total("persXP", where=sub_OBMH))  # Total exp.
