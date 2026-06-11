/* autoexec for t001_meps_e1_surveymeans_domain
   Substitutes a small mock MEPS 2001 full-year consolidated file (HC-060)
   for the external LIBNAME CMEPS V8 'C:\MEPS\DATA' that the original E1.sas
   reads. The columns match exactly the variables E1.sas keeps:
   TOTEXP01 SEX AGE01X AGE42X AGE31X PERWT01F VARPSU01 VARSTR01.
   All of E1's analysis logic (SURVEYMEANS DOMAIN, SURVEYREG, proportions,
   totals) runs unchanged against this stand-in. */
options obs=100;

/* Mock HC-060 person-level records. Realistic ranges:
   - person-level total expenditure (TOTEXP01)
   - SEX 1=male 2=female
   - age fields, with AGE01X primary
   - person weight, variance stratum, variance PSU. */
data CMEPS_H60;
  input TOTEXP01 SEX AGE01X AGE42X AGE31X PERWT01F VARPSU01 VARSTR01;
  datalines;
1240 1 34 34 34 9821.5 1 1
0 2 7 7 7 11233.0 2 1
582 2 52 52 52 8420.3 1 2
15630 1 71 71 71 4502.8 2 2
233 1 19 19 19 10567.1 1 3
4810 2 66 66 66 5120.9 2 3
0 1 3 -1 3 12044.2 1 4
920 2 41 41 41 8890.7 2 4
3375 1 58 58 58 6701.4 1 5
178 2 12 12 12 11890.6 2 5
24890 1 80 80 80 3201.7 1 6
640 2 27 27 27 9450.0 2 6
0 1 5 5 -1 11002.3 1 7
1290 2 49 49 49 8233.8 2 7
7720 1 63 63 63 5980.2 1 8
410 2 15 15 15 10880.5 2 8
2150 1 38 38 38 9120.6 2 1
0 2 9 9 9 11500.4 1 2
560 1 45 -1 45 8675.9 2 3
18420 2 74 74 74 4011.6 1 4
305 1 22 22 22 10210.7 2 5
5230 2 69 69 69 4890.3 1 6
0 1 1 1 1 12330.8 2 7
1180 2 55 55 55 7990.1 1 8
;
run;
