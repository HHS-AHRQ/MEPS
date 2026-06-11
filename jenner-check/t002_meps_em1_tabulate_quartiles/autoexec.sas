/* autoexec for t002_meps_em1_tabulate_quartiles
   Substitutes a small mock MEPS 2002 full-year population file (HC-062)
   for the external LIBNAME CMEPS V8 'C:\MEPS\DATA' that the original
   EM1.sas reads. Columns match the KEEP= list in EM1.sas. Every mock
   row is constructed to satisfy EM1's WHERE filter (employed current
   main job, reported wage/hours, valid perceived health status, age>24)
   so the quartile / TABULATE / SURVEYMEANS logic exercises real rows. */
options obs=100;

data CMEPS_H62;
  input DUPERSID $ PERWT02P VARSTR VARPSU EMPST42 SELFCM42 SELFCM31
        HRWG42X HRWG31X HOUR42 HOUR31 RTHLTH42 TEMPJB42 AGE42X;
  datalines;
20001 9821.5 1 1 1 2 2 12.50 12.50 40 40 1 2 34
20002 11233.0 1 2 1 2 2 8.25 8.25 35 35 2 2 41
20003 8420.3 2 1 2 2 2 25.00 25.00 45 45 1 2 52
20004 4502.8 2 2 1 2 2 60.00 60.00 50 50 3 2 47
20005 10567.1 3 1 1 2 2 9.10 9.10 38 38 4 2 29
20006 5120.9 3 2 2 2 2 15.75 15.75 40 40 2 2 60
20007 12044.2 4 1 1 2 2 18.40 18.40 42 42 1 2 38
20008 8890.7 4 2 1 2 2 7.80 7.80 30 30 5 2 26
20009 6701.4 5 1 2 2 2 31.20 31.20 48 48 2 2 55
20010 11890.6 5 2 1 2 2 10.50 10.50 36 36 3 2 33
20011 9450.0 1 1 1 2 2 14.00 14.00 40 40 2 2 44
20012 11002.3 2 2 2 2 2 22.60 22.60 44 44 1 2 49
20013 8233.8 3 1 1 2 2 6.90 6.90 28 28 4 2 27
20014 5980.2 4 2 1 2 2 45.00 45.00 50 50 2 2 58
20015 10880.5 5 1 2 2 2 11.30 11.30 39 39 3 2 36
20016 9120.6 1 2 1 2 2 19.75 19.75 41 41 1 2 42
;
run;
