/* autoexec for t005_meps_m3_merge_id
   Substitutes small mock MEPS 2005 files for the external
   LIBNAME CDATA 'C:\MEPS\DATA' that the original M3.sas reads:
     - CDATA_H97 : 2005 full-year consolidated (person-level)
     - CDATA_H96 : 2005 medical conditions (person-condition-level)
   Columns match the KEEP= lists in M3.sas. The DUPERSID / PANEL
   keys line up so the MERGE demonstrations work as intended. */
options obs=100;

/* HC-097: person-level full-year file */
data CDATA_H97;
  input DUID PID DUPERSID $ PANEL AGE05X SEX PERWT05F VARSTR VARPSU;
  datalines;
1001 101 10010101 9 34 1 9821.5 1 1
1002 101 10020101 9 7 2 11233.0 1 2
1003 101 10030101 9 52 2 8420.3 2 1
1004 101 10040101 9 71 1 4502.8 2 2
1005 101 10050101 9 19 1 10567.1 3 1
1006 101 10060101 9 66 2 5120.9 3 2
1007 101 10070101 9 3 1 12044.2 4 1
1008 101 10080101 9 41 2 8890.7 4 2
1009 101 10090101 9 58 1 6701.4 5 1
1010 101 10100101 9 12 2 11890.6 5 2
;
run;

/* HC-096: medical conditions file (multiple conditions per person) */
data CDATA_H96;
  input DUPERSID $ PANEL CONDN CONDIDX $ INJURY ICD9CODX $;
  datalines;
10010101 9 1 100101011 2 401
10010101 9 2 100101012 1 873
10030101 9 1 100301011 2 250
10040101 9 1 100401011 2 414
10040101 9 2 100401012 2 427
10060101 9 1 100601011 1 813
10080101 9 1 100801011 2 311
10090101 9 1 100901011 2 715
10090101 9 2 100901012 2 530
10100101 9 1 101001011 1 850
;
run;
