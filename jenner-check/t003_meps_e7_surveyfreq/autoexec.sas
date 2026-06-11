/* autoexec for t003_meps_e7_surveyfreq
   Substitutes a small mock MEPS 2005 full-year consolidated file (HC-097)
   for the external LIBNAME CDATA 'C:\MEPS\DATA' that the original E7.sas
   reads. Columns match the KEEP= list in E7.sas. Values span the age,
   race/ethnicity, education and colonoscopy-screening categories that
   E7's derived variables and SURVEYFREQ tables exercise. */
options obs=100;

data CDATA_H97;
  input DUPERSID $ VARSTR VARPSU AGE05X AGE53X AGE42X AGE31X
        RACEX HISPANX EDUCYR BOWEL53 WHNBWL53 PERWT05F;
  datalines;
30001 1 1 34 34 34 34 1 2 16 2 1 9821.5
30002 1 2 58 58 58 58 1 2 12 1 2 11233.0
30003 2 1 67 67 67 67 2 2 9 1 1 8420.3
30004 2 2 72 72 72 72 1 2 18 2 3 4502.8
30005 3 1 45 45 45 45 3 1 14 2 1 10567.1
30006 3 2 61 61 61 61 2 2 11 1 2 5120.9
30007 4 1 53 53 53 53 1 2 16 1 1 12044.2
30008 4 2 29 29 29 29 4 2 20 2 4 8890.7
30009 5 1 78 78 78 78 1 2 8 1 1 6701.4
30010 5 2 50 50 50 50 2 1 12 2 2 11890.6
30011 1 1 64 64 64 64 1 2 13 1 1 9450.0
30012 2 2 55 55 55 55 5 2 16 2 3 11002.3
30013 3 1 41 41 41 41 1 2 12 2 1 8233.8
30014 4 2 69 69 69 69 2 2 10 1 2 5980.2
30015 5 1 36 36 36 36 3 1 18 2 1 10880.5
30016 1 2 60 60 60 60 1 2 15 1 4 9120.6
30017 2 1 47 47 47 47 1 2 16 2 1 8675.9
30018 3 2 74 74 74 74 2 2 9 1 2 4011.6
30019 4 1 52 52 52 52 4 2 20 1 1 10210.7
30020 5 2 33 33 33 33 1 1 12 2 3 4890.3
;
run;
