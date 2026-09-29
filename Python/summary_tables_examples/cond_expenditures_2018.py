# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Medical Conditions, 2018:
#  - Number of people with care
#  - Number of events
#  - Total expenditures
#  - Mean expenditure per person
#
# Note: Starting in 2016, conditions were converted from ICD-9 and CCS codes
#  to ICD-10 and CCSR codes
#
# Input files:
# 	- C:/MEPS/h206a.dta (2018 RX event file)
# 	- C:/MEPS/h206d.dta (2018 IP event file)
# 	- C:/MEPS/h206e.dta (2018 ER event file)
# 	- C:/MEPS/h206f.dta (2018 OP event file)
# 	- C:/MEPS/h206g.dta (2018 OB event file)
# 	- C:/MEPS/h206h.dta (2018 HH event file)
# 	- C:/MEPS/h206if1.dta (2018 CLNK: Condition-event link file)
# 	- C:/MEPS/h207.dta    (2018 Conditions file)
# -----------------------------------------------------------------------------

# Install/load packages -------------------------------------------------------

# Install packages (if needed) -- only need to run once (in a terminal)
#   pip install svy

# Load packages (need to run every session)
from pathlib import Path

import polars as pl
import svy

MEPS_DIR = Path("C:/MEPS")


# Load datasets ---------------------------------------------------------------

# Load and stack event files
# - For RX, count number of fills per event
RX = svy.read_stata(MEPS_DIR / "h206a.dta")
RX = (
    RX.group_by("DUPERSID", "LINKIDX", "VARSTR", "VARPSU", "PERWT18F")
    .agg(XPX=pl.col("RXXP18X").sum(), n_fills=pl.len())
    .rename({"LINKIDX": "EVNTIDX"})
)

IP = svy.read_stata(MEPS_DIR / "h206d.dta").rename({"IPXP18X": "XPX"})
ER = svy.read_stata(MEPS_DIR / "h206e.dta").rename({"ERXP18X": "XPX"})
OP = svy.read_stata(MEPS_DIR / "h206f.dta").rename({"OPXP18X": "XPX"})
OB = svy.read_stata(MEPS_DIR / "h206g.dta").rename({"OBXP18X": "XPX"})
HH = svy.read_stata(MEPS_DIR / "h206h.dta").rename({"HHXP18X": "XPX"})

events = {"RX": RX, "IP": IP, "ER": ER, "OP": OP, "OB": OB, "HH": HH}

stacked_events = (
    pl.concat(
        [df.with_columns(data=pl.lit(name)) for name, df in events.items()],
        how="diagonal_relaxed",
    )
    .select("data", "EVNTIDX", "DUPERSID", "XPX", "VARSTR", "VARPSU", "PERWT18F", "n_fills")
    .with_columns(n_events=pl.max_horizontal("n_fills", 1))
)


# Load in event-condition linking file
clink1 = svy.read_stata(MEPS_DIR / "h206if1.dta").select("DUPERSID", "CONDIDX", "EVNTIDX")

# Load in Conditions public use file
cond_puf = svy.read_stata(MEPS_DIR / "h207.dta").select(
    "DUPERSID", "CONDIDX", "CCSR1X", "CCSR2X", "CCSR3X"
)


# Load crosswalk for CCSR and collapsed conditions codes
ccsr_url = "https://raw.githubusercontent.com/HHS-AHRQ/MEPS/master/Quick_Reference_Guides/meps_ccsr_conditions.csv"

condition_codes = pl.read_csv(ccsr_url, new_columns=["CCSR", "CCSR_desc", "Condition"])

# Merge datasets --------------------------------------------------------------

# Merge collapsed condition codes to COND PUF
#  - convert multiple CCSRs to separate lines (wide to long)
cond = (
    cond_puf.unpivot(
        on=["CCSR1X", "CCSR2X", "CCSR3X"],
        index=["DUPERSID", "CONDIDX"],
        variable_name="CCSRnum",
        value_name="CCSR",
    )
    .filter(pl.col("CCSR") != "-1")
    .join(condition_codes, on="CCSR", how="left")
)

# Merge conditions file with the conditions-event link file (CLNK)
cond_clink = cond.join(clink1, on=["DUPERSID", "CONDIDX"], how="full", coalesce=True)

# De-duplicate by event ID ('EVNTIDX') and collapsed code ('Condition')
cond_clink = cond_clink.unique(subset=["DUPERSID", "EVNTIDX", "Condition"], keep="first", maintain_order=True)


# Merge conditions and event files --------------------------------------------

all_events = stacked_events.join(cond_clink, on=["DUPERSID", "EVNTIDX"], how="full", coalesce=True)

# Remove observations with missing 'Condition' or negative/missing expenditures
all_events = all_events.filter(pl.col("Condition").is_not_null(), pl.col("XPX") >= 0)


# Aggregate to person-level, by Condition -------------------------------------

all_pers = (
    all_events.group_by("DUPERSID", "VARSTR", "VARPSU", "Condition")
    .agg(
        PERWTF=pl.col("PERWT18F").mean(),
        pers_XP=pl.col("XPX").sum(),
        n_events=pl.col("n_events").sum(),
    )
    .with_columns(persons=1)
)


# Define survey design and calculate estimates --------------------------------

PERSdsgn = svy.Sample(
    data=all_pers,
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWTF"),
)

# Set survey option for lonely psu
PERSdsgn = PERSdsgn.singleton.center()


# Totals (people, events, expenditures)
totals = PERSdsgn.estimation.total(["persons", "n_events", "pers_XP"], by="Condition")

print(totals[0])  # Number of people with care
print(totals[1])  # Number of events
print(totals[2])  # Total expenditures


# Mean expenditure per person with care
means = PERSdsgn.estimation.mean("pers_XP", by="Condition")

print(means)
