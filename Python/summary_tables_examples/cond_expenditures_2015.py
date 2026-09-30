# -----------------------------------------------------------------------------
# Example code to replicate estimates from the MEPS-HC Data Tools summary tables
#
# Medical Conditions, 2015:
#  - Number of people with care
#  - Number of events
#  - Total expenditures
#  - Mean expenditure per person
#
# Note: Starting in 2016, conditions were converted from ICD-9 and CCS codes
#  to ICD-10 and CCSR codes
#
# Input files:
# 	- C:/MEPS/h178a.ssp (2015 RX event file)
# 	- C:/MEPS/h178d.ssp (2015 IP event file)
# 	- C:/MEPS/h178e.ssp (2015 ER event file)
# 	- C:/MEPS/h178f.ssp (2015 OP event file)
# 	- C:/MEPS/h178g.ssp (2015 OB event file)
# 	- C:/MEPS/h178h.ssp (2015 HH event file)
# 	- C:/MEPS/h178if1.ssp (2015 CLNK: Condition-event link file)
# 	- C:/MEPS/h180.ssp    (2015 Conditions file)
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
RX = svy.read_sas(MEPS_DIR / "h178a.ssp")
RX = (
    RX.group_by("DUPERSID", "LINKIDX", "VARSTR", "VARPSU", "PERWT15F")
    .agg(XPX=pl.col("RXXP15X").sum(), n_fills=pl.len())
    .rename({"LINKIDX": "EVNTIDX"})
)

IP = svy.read_sas(MEPS_DIR / "h178d.ssp")
IP = IP.rename({"IPXP15X": "XPX"})
ER = svy.read_sas(MEPS_DIR / "h178e.ssp")
ER = ER.rename({"ERXP15X": "XPX"})
OP = svy.read_sas(MEPS_DIR / "h178f.ssp")
OP = OP.rename({"OPXP15X": "XPX"})
OB = svy.read_sas(MEPS_DIR / "h178g.ssp")
OB = OB.rename({"OBXP15X": "XPX"})
HH = svy.read_sas(MEPS_DIR / "h178h.ssp")
HH = HH.rename({"HHXP15X": "XPX"})

events = {"RX": RX, "IP": IP, "ER": ER, "OP": OP, "OB": OB, "HH": HH}

stacked_events = (
    pl.concat(
        [df.with_columns(data=pl.lit(name)) for name, df in events.items()],
        how="diagonal_relaxed",
    )
    .select("data", "EVNTIDX", "DUPERSID", "XPX", "VARSTR", "VARPSU", "PERWT15F", "n_fills")
    .with_columns(n_events=pl.max_horizontal("n_fills", 1))
)


# Load in event-condition linking file
clink1 = svy.read_sas(MEPS_DIR / "h178if1.ssp")
clink1 = clink1.select("DUPERSID", "CONDIDX", "EVNTIDX")

# Load in conditions file
conditions = svy.read_sas(MEPS_DIR / "h180.ssp")
conditions = conditions.select("DUPERSID", "CONDIDX", "CCCODEX")


# Merge datasets --------------------------------------------------------------

# Merge conditions file with the conditions-event link file (CLNK)
cond_clink = conditions.join(clink1, on=["DUPERSID", "CONDIDX"], how="full", coalesce=True)

# Create collapsed condition code variable
cond_clink = cond_clink.with_columns(
    ccnum=pl.col("CCCODEX").cast(pl.Int64),  # string -> numeric
)

cc = pl.col("ccnum")

cond_clink = cond_clink.with_columns(
    Condition=pl.when(cc < 0).then(pl.lit(""))
    .when(cc.is_between(1, 9)).then(pl.lit("Infectious diseases"))
    .when(cc.is_between(11, 45)).then(pl.lit("Cancer"))
    .when(cc.is_between(46, 47)).then(pl.lit("Non-malignant neoplasm"))
    .when(cc == 48).then(pl.lit("Thyroid disease"))
    .when(cc.is_between(49, 50)).then(pl.lit("Diabetes mellitus"))
    .when(cc.is_between(51, 52) | cc.is_between(54, 58)).then(pl.lit("Other endocrine, nutritional & immune disorder"))
    .when(cc == 53).then(pl.lit("Hyperlipidemia"))
    .when(cc == 59).then(pl.lit("Anemia and other deficiencies"))
    .when(cc.is_between(60, 64)).then(pl.lit("Hemorrhagic, coagulation, and disorders of White Blood cells"))
    .when(cc.is_between(65, 75) | cc.is_between(650, 670)).then(pl.lit("Mental disorders"))
    .when(cc.is_between(76, 78)).then(pl.lit("CNS infection"))
    .when(cc.is_between(79, 81)).then(pl.lit("Hereditary, degenerative and other nervous system disorders"))
    .when(cc == 82).then(pl.lit("Paralysis"))
    .when(cc == 84).then(pl.lit("Headache"))
    .when(cc == 83).then(pl.lit("Epilepsy and convulsions"))
    .when(cc == 85).then(pl.lit("Coma, brain damage"))
    .when(cc == 86).then(pl.lit("Cataract"))
    .when(cc == 88).then(pl.lit("Glaucoma"))
    .when(cc.is_in([87, 89, 90, 91])).then(pl.lit("Other eye disorders"))
    .when(cc == 92).then(pl.lit("Otitis media"))
    .when(cc.is_between(93, 95)).then(pl.lit("Other CNS disorders"))
    .when(cc.is_between(98, 99)).then(pl.lit("Hypertension"))
    .when(cc.is_between(96, 97) | cc.is_between(100, 108)).then(pl.lit("Heart disease"))
    .when(cc.is_between(109, 113)).then(pl.lit("Cerebrovascular disease"))
    .when(cc.is_between(114, 121)).then(pl.lit("Other circulatory conditions arteries, veins, and lymphatics"))
    .when(cc == 122).then(pl.lit("Pneumonia"))
    .when(cc == 123).then(pl.lit("Influenza"))
    .when(cc == 124).then(pl.lit("Tonsillitis"))
    .when(cc.is_between(125, 126)).then(pl.lit("Acute Bronchitis and URI"))
    .when(cc.is_between(127, 134)).then(pl.lit("COPD, asthma"))
    .when(cc == 135).then(pl.lit("Intestinal infection"))
    .when(cc == 136).then(pl.lit("Disorders of teeth and jaws"))
    .when(cc == 137).then(pl.lit("Disorders of mouth and esophagus"))
    .when(cc.is_between(138, 141)).then(pl.lit("Disorders of the upper GI"))
    .when(cc == 142).then(pl.lit("Appendicitis"))
    .when(cc == 143).then(pl.lit("Hernias"))
    .when(cc.is_between(144, 148)).then(pl.lit("Other stomach and intestinal disorders"))
    .when(cc.is_between(153, 155)).then(pl.lit("Other GI"))
    .when(cc.is_between(149, 152)).then(pl.lit("Gallbladder, pancreatic, and liver disease"))
    .when(cc.is_between(156, 158) | cc.is_between(160, 161)).then(pl.lit("Kidney Disease"))
    .when(cc == 159).then(pl.lit("Urinary tract infections"))
    .when(cc.is_between(162, 163)).then(pl.lit("Other urinary"))
    .when(cc.is_between(164, 166)).then(pl.lit("Male genital disorders"))
    .when(cc == 167).then(pl.lit("Non-malignant breast disease"))
    .when(cc.is_between(168, 176)).then(pl.lit("Female genital disorders, and contraception"))
    .when(cc.is_between(177, 195)).then(pl.lit("Complications of pregnancy and birth"))
    .when(cc.is_in([196, 218])).then(pl.lit("Normal birth/live born"))
    .when(cc.is_between(197, 200)).then(pl.lit("Skin disorders"))
    .when(cc.is_between(201, 204)).then(pl.lit("Osteoarthritis and other non-traumatic joint disorders"))
    .when(cc == 205).then(pl.lit("Back problems"))
    .when(cc.is_between(206, 209) | (cc == 212)).then(pl.lit("Other bone and musculoskeletal disease"))
    .when(cc.is_between(210, 211)).then(pl.lit("Systemic lupus and connective tissues disorders"))
    .when(cc.is_between(213, 217)).then(pl.lit("Congenital anomalies"))
    .when(cc.is_between(219, 224)).then(pl.lit("Perinatal Conditions"))
    .when(cc.is_between(225, 236) | cc.is_between(239, 240) | (cc == 244)).then(pl.lit("Trauma-related disorders"))
    .when(cc.is_between(237, 238)).then(pl.lit("Complications of surgery or device"))
    .when(cc.is_between(241, 243)).then(pl.lit("Poisoning by medical and non-medical substances"))
    .when(cc == 259).then(pl.lit("Residual Codes"))
    .when((cc == 10) | cc.is_between(254, 258)).then(pl.lit("Other care and screening"))
    .when(cc.is_between(245, 252)).then(pl.lit("Symptoms"))
    .when(cc == 253).then(pl.lit("Allergic reactions"))
    .otherwise(pl.lit("Other"))
)


# De-duplicate by event ID ('EVNTIDX') and collapsed code ('Condition')

cond_clink = cond_clink.unique(subset=["DUPERSID", "EVNTIDX", "Condition"], keep="first", maintain_order=True)


# Merge conditions and event files --------------------------------------------

all_events = stacked_events.join(cond_clink, on=["DUPERSID", "EVNTIDX"], how="full", coalesce=True)

# Remove observations with missing 'Condition' or negative/missing expenditures
all_events = all_events.filter(pl.col("Condition") != "", pl.col("XPX") >= 0)


# Aggregate to person-level, by Condition -------------------------------------

all_pers = (
    all_events.group_by("DUPERSID", "VARSTR", "VARPSU", "Condition")
    .agg(
        PERWT15F=pl.col("PERWT15F").mean(),
        pers_XP=pl.col("XPX").sum(),
        n_events=pl.col("n_events").sum(),
    )
    .with_columns(persons=1)
)


# Define survey design and calculate estimates --------------------------------

PERSdsgn = svy.Sample(
    data=all_pers,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT15F", singleton="center"),
)


# Totals (people, events, expenditures)
totals = PERSdsgn.estimation.total(["persons", "n_events", "pers_XP"], by="Condition")

print(totals[0])  # Number of people with care
print(totals[1])  # Number of events
print(totals[2])  # Total expenditures


# Mean expenditure per person with care
means = PERSdsgn.estimation.mean("pers_XP", by="Condition")

print(means)
