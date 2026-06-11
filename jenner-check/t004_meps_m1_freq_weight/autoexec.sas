/* autoexec for t004_meps_m1_freq_weight
   Substitutes a small mock MEPS 2005 full-year consolidated file (HC-097)
   for the external LIBNAME CDATA 'C:\MEPS\DATA' that the original M1.sas
   reads. M1 keeps only RACETHNX and PERWT05F, so the mock file carries
   those two variables across the race/ethnicity categories 1-4. */
options obs=100;

data CDATA_H97;
  input RACETHNX PERWT05F;
  datalines;
1 9821.5
1 11233.0
1 8420.3
2 4502.8
2 10567.1
3 5120.9
4 12044.2
1 8890.7
2 6701.4
3 11890.6
4 3201.7
1 9450.0
2 11002.3
1 8233.8
3 5980.2
4 10880.5
2 9120.6
1 11500.4
1 8675.9
2 4011.6
3 10210.7
4 4890.3
1 12330.8
2 7990.1
;
run;
