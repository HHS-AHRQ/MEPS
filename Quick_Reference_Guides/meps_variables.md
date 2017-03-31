The following tables provide a quick reference to identify the variable names for utilization and expenditure variables on the MEPS Full Year Consolidated (FYC) Public Use Files (PUFs). Note that not all of the listed variables are available on every FYC file. Data and corresponding documentation are available on [the MEPS website](https://meps.ahrq.gov/mepsweb/data_stats/download_data_files_results.jsp?cboDataYear=All&cboDataTypeY=1%2CHousehold+Full+Year+File&buttonYearandDataType=Search&cboPufNumber=All&SearchTitle=Consolidated+Data).


### Utilization and Expenditure Variables

To complete the variable name in the following table, replace 'yy' with the two-digit code for year (e.g. '14' for data year 2014) and replace '**\*' with a particular source of payment category as identified in the '[Source of Payment Keys](#source-of-payment-keys)' table.


Health Service Category |Utilization Variable|Expenditure Variable
------------------------|--------------------|--------------------
<b>All Health Services</b>|--|TOT\*\*\*yy
 | |
<b>Office Based Visits</b> ||
Total Office Based Visits (Physician + Non-physician + Unknown)|OBTOTVyy|OBV**\*yy
&nbsp;&nbsp;&nbsp;Office Based Visits to Physicians|OBDRVyy|OBD**\*yy
&nbsp;&nbsp;&nbsp;Office Based Visits to Non-Physicians|OBOTHVyy|OBO**\*yy
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Visits to Chiropractors|OBCHIRyy|OBC**\*yy
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Nurse or Nurse Practitioner Visits|OBNURSyy|OBN**\*yy
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Visits to Optometrists|OBOPTOyy|OBE**\*yy
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Physician Assistant Visits|OBASSTyy|OBA**\*yy
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Physical or Occupational Therapist Visits|OBTHERyy|OBT**\*yy
 | |
<b>Hospital Outpatient Visits</b> ||
Total Outpatient Visits (Physician + Non-physician + Unknown)|OPTOTVyy|--
&nbsp;&nbsp;&nbsp;Sum of Facility and SBD Expenses|--|OPT**\*yy
&nbsp;&nbsp;&nbsp;Facility Expense|--|OPF**\*yy
&nbsp;&nbsp;&nbsp;SBD Expense|--|OPD**\*yy
Outpatient Visits to Physicians|OPDRVyy|--
&nbsp;&nbsp;&nbsp;Facility Expense|--|OPV**\*yy
&nbsp;&nbsp;&nbsp;SBD Expense|--|OPS**\*yy
Outpatient Visits to Non-Physicians|OPOTHVyy|--
&nbsp;&nbsp;&nbsp;Facility Expense|--|OPO**\*yy
&nbsp;&nbsp;&nbsp;SBD Expense|--|OPP**\*yy
 | |
<b>Office Based Plus Outpatient Visits</b> ||
Chiropractor Visits|AMCHIRyy|AMC**\*yy
Ambulatory Nurse/Practitioner Visits|AMNURSyy|AMN**\*yy
Ambulatory Optometrist Visits|AMOPTyy|AME**\*yy
Physician Assistant Visits|AMASSTyy|AMA**\*yy
Ambulatory PT/OT Therapy Visits|AMTHERyy|AMT**\*yy
 | |
<b>Emergency Room Visits</b> ||
Total Emergency Room Visits|ERTOTyy|--
Sum of Facility and SBD Expenses|--|ERT**\*yy
&nbsp;&nbsp;&nbsp;Facility Expense|--|ERF**\*yy
&nbsp;&nbsp;&nbsp;SBD Expense|--|ERD**\*yy
 | |
<b>Inpatient Hospital Stays (Including Zero Night Stays)</b> ||
Total Inpatient Stays (Including Zero Night Stays)|IPDISyy| IPNGTDyy|--
&nbsp;&nbsp;&nbsp;Sum of Facility and SBD Expenses|--|IPT**\*yy
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Facility Expense|--|IPF**\*yy
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SBD Expense|--|IPD**\*yy
Zero night Hospital Stays|IPZEROyy|--
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Facility Expense|--|ZIF**\*yy
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SBD Expense|--|ZID**\*yy
 | |
<b>Prescription Medicines</b> ||
 Total Prescription Medicines|RXTOTyy|RX**\*yy
 | |
<b>Dental Visits</b> ||
Total Dental Visits|DVTOTyy|DVT**\*yy
&nbsp;&nbsp;&nbsp;General Dental Visits|DVGENyy|DVG**\*yy
&nbsp;&nbsp;&nbsp;Orthodontist Visits|DVORTHyy|DVO**\*yy
 | |
<b>Home Health Care</b> ||
Total Home Health Care|HHTOTDyy|--
&nbsp;&nbsp;&nbsp;Agency Sponsored|HHAGDyy|HHA**\*yy
&nbsp;&nbsp;&nbsp;Paid Independent Providers|HHINDDyy|HHN**\*yy
&nbsp;&nbsp;&nbsp;Informal|HHINFDyy|--
 | |
<b>Other Medical Expenses</b> ||
Vision Aids|--|VIS**\*yy
Other Medical Supplies and Equipment|--|OTH**\*yy


### Source of Payment Keys

To complete variable name in the '[Utilization and Expenditure Variables](#utilization-and-expenditure-variables)' table, replace **\* with a particular source of payment category as identified in the following tables:

Source of Payment Category	| \*\*\* | Source of Payment Category	| \*\*\*
---------------------------|-------|----------------------------|------
Total payments (sum of all sources)	| EXP | Other Federal Sources	| 	OFD
Out of Pocket	| SLF| Other State and Local Sources		| STL
Medicare	| 	MCR| Workers Compensation		| WCP
Medicaid	| 	MCD| Other Private	| 	OPR
Private Insurance		| PRV| Other Public		| OPU
Veterans Administration/CHAMPVA		| VA| Other Unclassified Sources		| OSR
TRICARE		| TRI ||



Collapsed Source of Payment Category	| **\*
-------------------------------------|-----
Private and TRICARE |	PRT
Other Federal, Other State and Local, Other Private, Other Public, and Other Unclassified Sources  |	OTH
Total charges	 | TCH
