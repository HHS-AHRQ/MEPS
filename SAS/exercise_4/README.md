# SAS Exercise 4

## Loading the data
Use the following links to download the data .zip files, then unzip and save to a local directory. Create the folder 'C:\MEPS\data' on your hard drive if it is not there:

<b>Input Files</b>:
<br>[H171  (2014 Full year consolidated PUF)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)
<br>[H170 (2014 Condition PUF DATA)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h170ssp.zip)

Next, run the following code to convert the SAS transport file (.ssp) to a SAS dataset (.sas7bdat) and save to a local directory (first create the target folder 'C:\MEPS\SAS\data' if needed):
``` sas
LIBNAME SASdata 'C:\MEPS\SAS\data';

FILENAME in_h171 'C:\MEPS\data\h171.ssp';
FILENAME in_h170 'C:\MEPS\data\h170.ssp';

proc xcopy in = in_h171 out = SASdata IMPORT; run;
proc xcopy in = in_h170 out = SASdata IMPORT; run;
```
> <b>Note</b>: The target directory (e.g. 'C:\MEPS\SAS\data') must be different from the input directory (e.g. 'C:\MEPS\data'). If not, an error may occur.


## Summary
This exercise illustrates how to identify persons with a condition and calculate estimates on use and expenditures for persons with the condition.

The condition used in this exercise is diabetes (049 or 050)

Definition of 61 conditions based on the CCS code:

No. | Condition | CCS Codes
-------|------------- |-------------
1|Infectious diseases |1-9
2|  Cancer   | 11-45
3|  Non-malignant neoplasm  |46, 47
4|  Thyroid disease  |48
5|  Diabetes mellitus| 49,50
6|  Other endocrine, nutritional & immune disorder  |51, 52, 54 - 58
7|  Hyperlipidemia   |53
9|  Hemorrhagic, coagulation, and disorders of White Blood cells | 60-64
8|  Anemia and other deficiencies  |59
10| Mental disorders |650-670
11| CNS infection  |76-78
12| Hereditary, degenerative and other nervous system disorders  |79-81
13| Paralysis |82
14| Headache |84
15| Epilepsy and convulsions   |83
16| Coma, brain damage |85
17| Cataract|86
18| Glaucoma | 88
19| Other eye disorders  | 87, 89-91
20| Otitis media | 92
21| Other CNS disorders  | 93-95
22| Hypertension | 98,99
23| Heart disease| 96, 97, 100-108
24| Cerebrovascular disease| 109-113
25| Other circulatory conditions arteries, veins, and lymphatics| 114 -121
26| Pneumonia| 122
27| Influenza| 123
28| Tonsillitis  | 124
29| Acute Bronchitis and URI   | 125 , 126
30| COPD, asthma | 127-134
31| Intestinal infection | 135
32| Disorders of teeth and jaws| 136
33| Disorders of mouth and esophagus   | 137
34| Disorders of the upper GI  | 138-141
35| Appendicitis | 142
36| Hernias| 143
37| Other stomach and intestinal disorders   | 144- 148
38| Other GI | 153-155
39| Gallbladder, pancreatic, and liver disease   | 149-152
40| Kidney Disease   | 156-158, 160, 161
41| Urinary tract infections   | 159
42| Other urinary| 162,163
43| Male genital disorders | 164-166
44| Non-malignant breast disease   | 167
46| Complications of pregnancy and birth | 177-195
45| Female genital disorders, and contraception  | 168-176
47| Normal birth/live born | 196, 218
48| Skin disorders   | 197-200
49| Osteoarthritis and other non-traumatic joint disorders |201-204
50| Back problems| 205
51| Other bone and musculoskeletal  disease  | 206-209, 212
52| Systemic lupus and connective tissues disorders  | 210-211
53| Congenital anomalies | 213-217
54| Perinatal Conditions | 219-224
55| Trauma-related disorders   | 225-236, 239, 240, 244
56| Complications of surgery or device | 237, 238
57| Poisoning by medical and non-medical substances  | 241 - 243
58| Residual Codes   | 259
59| Other care and screening   | 10, 254-258
60| Symptoms | 245-252
61| Allergic reactions   | 253
