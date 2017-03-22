# Stata Exercise 7
This program illustrates how to construct insurance status variables from monthly insurance variables (see below) in the person level data.

Variable Name | Description
--------------|------------
TRImm14X |  Covered by TRICARE/CHAMPVA in mm (Ed)
MCRmm14  |  Covered by Medicare in mm
MCRmm14X | Covered by Medicare in mm (Ed)
MCDmm14  |  Covered by Medicaid or SCHIP in mm            
MCDmm14X |  Covered by Medicaid or SCHIP in mm  (Ed)
OPAmm14  |  Covered by Other Public A Ins in mm
OPBmm14  |  Covered by Other Public B Ins in mm
PUBmm14X |  Covered by Any Public Ins in mm (Ed)
PEGmm14  |  Covered by Empl Union Ins in mm
PDKmm14  |  Coverer by Priv Ins (Source Unknown) in mm
PNGmm14  |  Covered by Nongroup Ins in mm
POGmm14  |  Covered by Other Group Ins in mm
PRSmm14  |  Covered by Self-Emp Ins in mm
POUmm14  |  Covered by Holder Outside of RU in mm
PRImm14  |  Covered by Private Ins in mm                       

where mm = JA-DE  (January - December)   

**Input File**:  H171.dta (2014 FY PUF DATA)
