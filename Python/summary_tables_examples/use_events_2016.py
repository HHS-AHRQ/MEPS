# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Use, expenditures, and population, 2016
#
# Utilization and expenditures by event type and source of payment (SOP)
#  - Total number of events
#  - Mean expenditure per event, by source of payment
#  - Mean events per person, for office-based visits
#
# Selected event types:
#  - Office-based medical visits (OBV)
#  - Office-based physician visits (OBD)
#  - Outpatient visits (OPT)
#  - Outpatient physician visits (OPV)
#
# Input files:
#  - C:/MEPS/h192.ssp  (2016 full-year consolidated)
#  - C:/MEPS/h188f.ssp (2016 OP event file)
#  - C:/MEPS/h188g.ssp (2016 OB event file)
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

# Load FYC file and keep only needed variables
FYC = svy.read_sas(MEPS_DIR / "h192.ssp")
FYC = FYC.select("DUPERSID", "PERWT16F", "VARSTR", "VARPSU")

# Load event files
OP = svy.read_sas(MEPS_DIR / "h188f.ssp")  # outpatient visits
OB = svy.read_sas(MEPS_DIR / "h188g.ssp")  # office-based medical visits

# Aggregate payment sources for each dataset ----------------------------------
#
#  Notes:
#   - For 1996-1999: TRICARE label is CHM (changed to TRI in 2000)
#
#   - For 1996-2006: combined facility + SBD variables for hospital-type events
#      are not on PUF
#
#   - Starting in 2019, 'Other public' (OPU) and 'Other private' (OPR) are
#      dropped from the files
#
#
#  PR = Private (PV) + TRICARE (TR)
#
#  OZ = other federal (OF)  + State/local (SL) + other private (OR) +
#        other public (OU)  + other unclassified sources (OT) +
#        worker's comp (WC) + Veteran's (VA)


OB = OB.with_columns(
    PR=pl.sum_horizontal("OBPV16X", "OBTR16X"),
    OZ=pl.sum_horizontal("OBOF16X", "OBSL16X", "OBVA16X", "OBOT16X", "OBOR16X", "OBOU16X", "OBWC16X"),
).filter(pl.col("OBXP16X") >= 0)  # Remove inapplicable events

OP = OP.with_columns(
    PR_fac=pl.sum_horizontal("OPFPV16X", "OPFTR16X"),
    PR_sbd=pl.sum_horizontal("OPDPV16X", "OPDTR16X"),

    OZ_fac=pl.sum_horizontal("OPFOF16X", "OPFSL16X", "OPFOR16X", "OPFOU16X", "OPFVA16X", "OPFOT16X", "OPFWC16X"),
    OZ_sbd=pl.sum_horizontal("OPDOF16X", "OPDSL16X", "OPDOR16X", "OPDOU16X", "OPDVA16X", "OPDOT16X", "OPDWC16X"),
).filter(pl.col("OPXP16X") >= 0)  # Remove inapplicable events


# Combine facility and SBD expenses for hospital-type events ------------------

OP = OP.with_columns(
    SF=pl.sum_horizontal("OPFSF16X", "OPDSF16X"),  # out-of-pocket payments
    MR=pl.sum_horizontal("OPFMR16X", "OPDMR16X"),  # Medicare
    MD=pl.sum_horizontal("OPFMD16X", "OPDMD16X"),  # Medicaid
    PR=pl.sum_horizontal("PR_fac", "PR_sbd"),  # private insurance (including TRICARE)
    OZ=pl.sum_horizontal("OZ_fac", "OZ_sbd"),  # other sources of payment
)


# Merge with FYC to retain all PSUs -------------------------------------------
OB_FYC = (
    OB.with_columns(
        count=pl.lit(1),  # add counter for total events
        domain=pl.lit(1),  # add domain to subset design after merging with FYC
    )
    .drop("VARSTR", "VARPSU", "PERWT16F")  # remove to avoid merge conflicts
    .join(FYC, on="DUPERSID", how="full", coalesce=True)
)

OP_FYC = (
    OP.with_columns(
        count=pl.lit(1),  # add counter for total events
        domain=pl.lit(1),  # add domain to subset design after merging with FYC
    )
    .drop("VARSTR", "VARPSU", "PERWT16F")  # remove to avoid merge conflicts
    .join(FYC, on="DUPERSID", how="full", coalesce=True)
)


# Define survey designs -------------------------------------------------------
OB_dsgn = svy.Sample(
    data=OB_FYC,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F", singleton="center"),
)

OP_dsgn = svy.Sample(
    data=OP_FYC,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F", singleton="center"),
)


# Calculate estimates ---------------------------------------------------------
#
# Sources of payment (SOP) abbreviations:
#  - SF: Out-of-pocket
#  - PR: Private insurance, including TRICARE (PTR)
#  - MR: Medicare
#  - MD: Medicaid
#  - OZ: Other

# Subset to people in domain (defined previously)
OB_sub = pl.col("domain") == 1
OP_sub = pl.col("domain") == 1

# For 'physician visits' subset to people with SEEDOC = 1
OBdoc_sub = OB_sub & (pl.col("SEEDOC") == 1)
OPdoc_sub = OP_sub & (pl.col("SEEDOC") == 1)


# Total number of events, by event type

print(OB_dsgn.estimation.total("count", where=OB_sub))  # office-based (OB) visits
print(OB_dsgn.estimation.total("count", where=OBdoc_sub))  # office-based (OB) physician visits

print(OP_dsgn.estimation.total("count", where=OP_sub))  # outpatient (OP) visits
print(OP_dsgn.estimation.total("count", where=OPdoc_sub))  # outpatient (OP) physician visits


# Mean expenditure per event, by event type and source of payment

for est in OB_dsgn.estimation.mean(["OBSF16X", "PR", "OBMR16X", "OBMD16X", "OZ"], where=OB_sub):  # OB visits
    print(est)
for est in OB_dsgn.estimation.mean(["OBSF16X", "PR", "OBMR16X", "OBMD16X", "OZ"], where=OBdoc_sub):  # OB phys. visits
    print(est)

for est in OP_dsgn.estimation.mean(["SF", "PR", "MR", "MD", "OZ"], where=OP_sub):  # OP visits
    print(est)
for est in OP_dsgn.estimation.mean(["SF", "PR", "MR", "MD", "OZ"], where=OPdoc_sub):  # OP phys. visits
    print(est)


# Mean events per person, office-based medical visits

# Aggregate to person level
pers_OB = OB_FYC.group_by("DUPERSID", "VARSTR", "VARPSU").agg(
    PERWT16F=pl.col("PERWT16F").mean(),
    n_events=pl.col("count").sum(),
    n_phys_events=(pl.col("count") * (pl.col("SEEDOC") == 1)).sum(),
)

# Define survey design
pers_OB_dsgn = svy.Sample(
    data=pers_OB,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT16F", singleton="center"),
)


# Mean events per person
print(pers_OB_dsgn.estimation.mean("n_events"))  # office-based visits
print(pers_OB_dsgn.estimation.mean("n_phys_events"))  # office-based phys. visits
