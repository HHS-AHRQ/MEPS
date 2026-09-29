# -----------------------------------------------------------------------------
# Functions to download MEPS public use files (PUFs) from the MEPS website and
# load them into Python. Based on the 'MEPS' R package:
#   https://github.com/e-mitchell/meps_r_pkg
#
# Examples:
#   from meps import read_meps
#
#   fyc18 = read_meps(year=2018, type="FYC")  # use year and file type
#   fyc18 = read_meps(file="h209")            # use file name
# -----------------------------------------------------------------------------

import tempfile
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

import polars as pl
import svy
from svy_io import read_xpt

FILE_NAMES_URL = "https://raw.githubusercontent.com/HHS-AHRQ/MEPS/master/Quick_Reference_Guides/meps_file_names.csv"
PUFS_URL = "https://meps.ahrq.gov/mepsweb/data_files/pufs"

TYPES = {
    "PIT": "PIT",
    "FYC": "FYC",
    "COND": "Conditions",
    "CONDITIONS": "Conditions",
    "RX": "PMED Events",
    "PMED": "PMED Events",
    "JOBS": "Jobs",
    "PRPL": "PRPL",
    "CLNK": "CLNK",
    "RXLK": "RXLK",
}

EVENT_LETTERS = {
    "DV": "b", "DN": "b",  # Dental visits
    "OM": "c",             # Other medical expenses
    "IP": "d", "HS": "d",  # Inpatient stays
    "ER": "e",             # Emergency room visits
    "OP": "f",             # Outpatient visits
    "OB": "g", "MV": "g",  # Office-based visits
    "HH": "h",             # Home health
}


def get_puf_name(year: int, type: str) -> str:
    """Look up MEPS file name (e.g. 'h209') by data year and file type."""
    type = type.upper()
    if type not in TYPES and type not in EVENT_LETTERS:
        raise ValueError(f"type must be one of: {', '.join([*TYPES, *EVENT_LETTERS])}")

    puf_names = pl.read_csv(FILE_NAMES_URL, infer_schema=False)
    row = puf_names.filter(pl.col("Year") == str(year))
    if row.is_empty():
        raise ValueError(f"year must be between {puf_names['Year'].min()} and {puf_names['Year'].max()}")

    if type in EVENT_LETTERS:
        return row["Events"].item().replace("*", EVENT_LETTERS[type])
    return row[TYPES[type]].item()


def dl_meps(file: str, ext: str = "dta", dir: str | Path | None = None) -> Path:
    """Download and unzip a MEPS file. Returns the location of the data file."""
    dir = Path(dir) if dir is not None else Path(tempfile.mkdtemp())

    # For CLNK and RXLK files (e.g. 'h209if1'), zip is stored under 'h209i'
    # For Pooled Linkage files (e.g. 'h36u19'), zip is stored under 'h036'
    folder = file.replace("f1", "").replace("f2", "")
    if file.startswith("h36"):
        folder = "h036"

    for url in (f"{PUFS_URL}/{file}{ext}.zip", f"{PUFS_URL}/{folder}/{file}{ext}.zip"):
        try:
            zip_file, _ = urllib.request.urlretrieve(url)
        except urllib.error.HTTPError:
            continue
        with zipfile.ZipFile(zip_file) as z:
            z.extractall(dir)
            return dir / z.namelist()[0]

    raise FileNotFoundError(f"Cannot find '{file}{ext}.zip' on the MEPS website")


def read_meps(file: str | None = None, *, year: int | None = None, type: str | None = None) -> pl.DataFrame:
    """Download a MEPS file and load it as a polars DataFrame.

    Stata (.dta) format is used if available (2017 and later, mostly),
    otherwise SAS transport (.ssp) format (1996-2016, mostly).
    """
    if file is None:
        file = get_puf_name(year, type)
    file = file.lower().split(".")[0]

    try:
        return svy.read_stata(dl_meps(file, ext="dta"))
    except FileNotFoundError:
        data, _ = read_xpt(dl_meps(file, ext="ssp"))
        return data
