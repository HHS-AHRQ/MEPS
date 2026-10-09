# Example: Reproducing estimates for Figure 1 of Stat brief #491

# Load packages and set options
#   pip install svy==0.32.1 "polars>=2" matplotlib  # Only need to run these once (in a terminal)

import urllib.request  # Run these every time you re-start Python
import zipfile
from pathlib import Path

import matplotlib.pyplot as plt
import polars as pl
import svy

MEPS_DIR = Path("C:/MEPS")

# Load MEPS data from internet
zip_file, _ = urllib.request.urlretrieve("https://meps.ahrq.gov/mepsweb/data_files/pufs/h163ssp.zip")
with zipfile.ZipFile(zip_file) as z:
    unzipped_file = z.extract(z.namelist()[0])
h163 = svy.read_sas(unzipped_file)
Path(zip_file).unlink()  # Unlink to delete temporary file

# After downloading MEPS data define the survey object:
mepsdsgn = svy.Sample(
    data=h163,
    # lonely PSUs: R's options(survey.lonely.psu = 'adjust')
    design=svy.Design(psu="VARPSU", stratum="VARSTR", wgt="PERWT13F", singleton="center"),
)


# To get ambulatory (OB+OP) and home health/other expenditures, add variables to the mepsdsgn object.
mepsdsgn = mepsdsgn.wrangling.mutate({
    "ambexp13": pl.col("OBVEXP13") + pl.col("OPTEXP13") + pl.col("ERTEXP13"),
    "hhexp13": pl.col("HHAEXP13") + pl.col("HHNEXP13") + pl.col("VISEXP13") + pl.col("OTHEXP13"),
})

# Use ratio to calculate percentage distribution of spending by type of service:
pct_TOS = mepsdsgn.estimation.ratio(
    ["IPTEXP13", "ambexp13", "RXEXP13", "DVTEXP13", "hhexp13"],
    "TOTEXP13",
)

# Now do the same thing by age group (<65, 65+), using the `where` argument.
pct_TOS_lt65 = mepsdsgn.estimation.ratio(
    ["IPTEXP13", "ambexp13", "RXEXP13", "DVTEXP13", "hhexp13"],
    "TOTEXP13",
    where=pl.col("AGELAST") < 65,
)

pct_TOS_ge65 = mepsdsgn.estimation.ratio(
    ["IPTEXP13", "ambexp13", "RXEXP13", "DVTEXP13", "hhexp13"],
    "TOTEXP13",
    where=pl.col("AGELAST") >= 65,
)

# Create output tables
pct_matrix = pl.DataFrame({
    "y": pct_TOS.to_polars()["y"],
    "pct_TOS": pct_TOS.to_polars()["est"],
    "pct_TOS_lt65": pct_TOS_lt65.to_polars()["est"],
    "pct_TOS_ge65": pct_TOS_ge65.to_polars()["est"],
}).with_columns(pl.exclude("y") * 100)
print(pct_matrix)

# Clean it up:
pct_matrix = pct_matrix.with_columns(
    y=pl.Series(["Hospital IP", "Ambulatory", "RX", "Dental", "HH and Other"])
).rename({"y": "Type of service", "pct_TOS": "Total", "pct_TOS_lt65": "<65 years", "pct_TOS_ge65": "65+ years"})
print(pct_matrix)

# Optional: output table to .csv file
pct_matrix.write_csv(MEPS_DIR / "figure1.csv")


## Graphics example with matplotlib:

# define custom colors
my_blue = "#0073BD"  # rgb(0, 115, 189)
my_yellow = "#FFC500"  # rgb(255, 197, 0)
my_magenta = "#631063"  # rgb(99, 16, 99)
my_darkblue = "#0000AD"  # rgb(0, 0, 173)

# create plot
fig, ax = plt.subplots()
for i, (col, color) in enumerate(zip(["Total", "<65 years", "65+ years"], [my_blue, my_yellow, my_magenta])):
    bars = ax.bar([x + (i - 1) * 0.3 for x in range(5)], pct_matrix[col], width=0.3, color=color, label=col)  # make bars side-by-side
    ax.bar_label(bars, fmt="%.0f", color=my_darkblue, fontweight="bold")  # add data labels to end of bars

ax.set_xticks(range(5), pct_matrix["Type of service"])
ax.set_ylabel("Percentage", color=my_darkblue, fontweight="bold")  # change axis labels
ax.spines[["top", "right"]].set_visible(False)  # change themes (remove top and right lines)
ax.legend(loc="lower center", bbox_to_anchor=(0.5, 1), ncol=3, frameon=False)  # legend on top
plt.show()
