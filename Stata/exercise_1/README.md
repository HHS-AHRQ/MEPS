# Stata Exercise 1

## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory (e.g. 'C:\MEPS\data'):

<b>Input Files</b>:  [H171 (2014 Full-year file)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)

Next, run the following code to convert the transport file (.ssp) to a Stata dataset (.dta) and save to a local directory (first create the target folder 'C:\MEPS\Stata\data' if needed):
``` stata
clear
import sasxport "C:\MEPS\data\h171.ssp"
save "C:\MEPS\Stata\data\h171.dta", replace
clear
```

## Summary
This exercise generates the following estimates on national health care expenses by type of service, 2014:

1. Percentage distribution of expenses by type of service
2. Percentage of persons with an expense, by type of service
3. Mean expense per person with an expense, by type of service

Defined service categories are:
- Hospital inpatient
- Ambulatory services: office-based & hospital outpatient visits
- Prescribed medicines
- Dental visits
- Emergency room
- Home health care (agency & non-agency) and other (total expenditures - above expenditure categories)

<b>Note</b>: expenses include both facility and physician expenses.

<b>Input File</b>:  H171.dta (2014 Full-year file)
