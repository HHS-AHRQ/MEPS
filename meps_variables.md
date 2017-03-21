
### Utilization and Expenditure Variables

To complete the variable name in the following table, replace 'YY' with the two-digit code for year (e.g. '14' for data year 2014) and replace '**\*' with a particular source of payment category as identified in the '[Source of Payment Keys](#source-of-payment-keys)' table.


Health Service Category |Utilization Variable|Expenditure Variable
------------------------|--------------------|--------------------
<b>All Health Services</b>|--|TOT**\*YY
 | | 
<b>Office Based Visits</b>
Total Office Based Visits (Physician + Non-physician + Unknown)|OBTOTVYY|OBV**\*YY
&nbsp;&nbsp;&nbsp;Office Based Visits to Physicians|OBDRVYY|OBD**\*YY
&nbsp;&nbsp;&nbsp;Office Based Visits to Non-Physicians|OBOTHVYY|OBO**\*YY
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Visits to Chiropractors|OBCHIRYY|OBC**\*YY
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Nurse or Nurse Practitioner Visits|OBNURSYY|OBN**\*YY
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Visits to Optometrists|OBOPTOYY|OBE**\*YY
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Physician Assistant Visits|OBASSTYY|OBA**\*YY
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Office Based Physical or Occupational Therapist Visits|OBTHERYY|OBT**\*YY
 | | 
<b>Hospital Outpatient Visits</b>
Total Outpatient Visits (Physician + Non-physician + Unknown)|OPTOTVYY|--
&nbsp;&nbsp;&nbsp;Sum of Facility and SBD Expenses|--|OPT**\*YY
&nbsp;&nbsp;&nbsp;Facility Expense|--|OPF**\*YY
&nbsp;&nbsp;&nbsp;SBD Expense|--|OPD**\*YY
Outpatient Visits to Physicians|OPDRVYY|--
&nbsp;&nbsp;&nbsp;Facility Expense|--|OPV**\*YY
&nbsp;&nbsp;&nbsp;SBD Expense|--|OPS**\*YY
Outpatient Visits to Non-Physicians|OPOTHVYY|--
&nbsp;&nbsp;&nbsp;Facility Expense|--|OPO**\*YY
&nbsp;&nbsp;&nbsp;SBD Expense|--|OPP**\*YY
 | | 
<b>Office Based Plus Outpatient Visits</b>
Chiropractor Visits|AMCHIRYY|AMC**\*YY
Ambulatory Nurse/Practitioner Visits|AMNURSYY|AMN**\*YY
Ambulatory Optometrist Visits|AMOPTYY|AME**\*YY
Physician Assistant Visits|AMASSTYY|AMA**\*YY
Ambulatory PT/OT Therapy Visits|AMTHERYY|AMT**\*YY
 | | 
<b>Emergency Room Visits</b>
Total Emergency Room Visits|ERTOTYY|--
Sum of Facility and SBD Expenses|--|ERT**\*YY
&nbsp;&nbsp;&nbsp;Facility Expense|--|ERF**\*YY
&nbsp;&nbsp;&nbsp;SBD Expense|--|ERD**\*YY
 | | 
<b>Inpatient Hospital Stays (Including Zero Night Stays)</b>
Total Inpatient Stays (Including Zero Night Stays)|IPDISYY| IPNGTDYY|--
&nbsp;&nbsp;&nbsp;Sum of Facility and SBD Expenses|--|IPT**\*YY
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Facility Expense|--|IPF**\*YY
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SBD Expense|--|IPD**\*YY
Zero night Hospital Stays|IPZEROYY|--
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Facility Expense|--|ZIF**\*YY
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SBD Expense|--|ZID**\*YY
 | | 
<b>Prescription Medicines</b>
 Total Prescription Medicines|RXTOTYY|RX**\*YY
 | | 
<b>Dental Visits</b>
Total Dental Visits|DVTOTYY|DVT**\*YY
&nbsp;&nbsp;&nbsp;General Dental Visits|DVGENYY|DVG**\*YY
&nbsp;&nbsp;&nbsp;Orthodontist Visits|DVORTHYY|DVO**\*YY
 | | 
<b>Home Health Care</b>
Total Home Health Care|HHTOTDYY|--
&nbsp;&nbsp;&nbsp;Agency Sponsored|HHAGDYY|HHA**\*YY
&nbsp;&nbsp;&nbsp;Paid Independent Providers|HHINDDYY|HHN**\*YY
&nbsp;&nbsp;&nbsp;Informal|HHINFDYY|--
 | | 
<b>Other Medical Expenses</b>
Vision Aids|--|VIS**\*YY
Other Medical Supplies and Equipment|--|OTH**\*YY


### Source of Payment Keys

To complete variable name in the '[Utilization and Expenditure Variables](#utilization-and-expenditure-variables)' table, replace **\* with a particular source of payment category as identified in the following tables:

Source of Payment Category	| **\*
---------------------------|-----
Total payments (sum of all sources)	| EXP
Out of Pocket	| SLF
Medicare	| 	MCR
Medicaid	| 	MCD
Private Insurance		| PRV
Veterans Administration/CHAMPVA		| VA
TRICARE		| TRI
Other Federal Sources	| 	OFD
Other State and Local Sources		| STL
Workers Compensation		| WCP
Other Private	| 	OPR
Other Public		| OPU
Other Unclassified Sources		| OSR
Collapsed Source of Payment Category	| **\*
-------------------------------------|-----
Private and TRICARE |	PRT
Other Federal, Other State and Local,<br>Other Private, Other Public, and Other<br>Unclassified Sources  |	OTH
Total charges	 | TCH


