## Example 1: Re-producing estimates from MEPS summary table for 2013 data

# Load packages and set options

install.packages("foreign")  # Only need to run these once
install.packages("survey")

library(foreign) # Run these every time you re-start R
library(survey)

options(survey.lonely.psu='adjust')

# Load MEPS data from internet
download.file("https://meps.ahrq.gov/mepsweb/data_files/pufs/h163ssp.zip", temp <- tempfile())
unzipped_file = unzip(temp)
h163 = read.xport(unzipped_file)
unlink(temp)  # Unlink to delete temporary file

# After downloading MEPS data define the survey object:
mepsdsgn <- svydesign(id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT13F,
    data = h163,
    nest = TRUE)

# TOTAL POPULATION
# Standard errors are not applicable to population control totals, so we don't need to use a survey function here.
# The total population is equal to the sum of survey weights (PERWT13F).
sum(h163$PERWT13F)

# TOTAL EXPENSES
# Use the formula notation '~' with specified design object for survey functions
svytotal(~TOTEXP13,design = mepsdsgn)

# PERCENT WITH EXPENSE
# To calculate the percent of people with any expense, first update mepsdsgn with a new indicator variable for persons with an expense:
mepsdsgn <- update(mepsdsgn, any_expense = (TOTEXP13 > 0)*1)

# Then run the 'svymean' function
svymean(~any_expense,design = mepsdsgn)

# MEAN AND MEDIAN EXPENSE, PER PERSON
# To get expenses per person with an expense, use the 'subset' function to limit the dataset to persons that have an expense
# (i.e. any_expense == 1).
svymean(~TOTEXP13, design = subset(mepsdsgn,any_expense==1))
svyquantile(~TOTEXP13, design = subset(mepsdsgn,any_expense==1),quantiles = 0.5)

# DISTRIBUTION BY SOURCE OF PAYMENT
# For percent of total, use the `svyratio` function, and specify the numerator and denominator.
# Use a '+' sign to calculate estimates for multiple variables.
svyratio(~TOTSLF13 + TOTPTR13 + TOTMCR13 + TOTMCD13,
         denominator = ~TOTEXP13,
         design = mepsdsgn)

# Before estimating percentages for 'Other' insurance, we need to adjust this variable to match the online table:
# Other = VA + worker's comp + other sources.
mepsdsgn <- update(mepsdsgn, tototh13 = TOTVA13 + TOTWCP13 + TOTOTH13)
svyratio(~tototh13, denominator = ~TOTEXP13, design = mepsdsgn)
