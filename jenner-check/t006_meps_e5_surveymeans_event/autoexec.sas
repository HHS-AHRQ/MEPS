/* autoexec for t006_meps_e5_surveymeans_event
   Substitutes two small mock MEPS 2001 event files for the external
   LIBNAME CMEPS V8 'C:\MEPS\DATA' that the original E5.sas reads:
     - CMEPS_H59D : inpatient hospital stays (var IPFXP01X)
     - CMEPS_H59G : office-based medical provider visits (var OBXP01X)
   Columns match the KEEP= lists in E5.sas exactly. */
options obs=100;

/* HC-059D: 2001 inpatient hospital stays (event-level) */
data CMEPS_H59D;
  input DUPERSID $ IPFXP01X PERWT01F VARSTR01 VARPSU01;
  datalines;
10001011 8420 9821.5 1 1
10001011 15630 9821.5 1 2
10002021 4210 11233.0 1 1
10003031 28900 8420.3 2 1
10004041 6750 4502.8 2 2
10005051 3120 10567.1 1 1
10006061 11450 5120.9 1 2
10007071 990 12044.2 2 1
10008081 19870 8890.7 2 2
10009091 5230 6701.4 1 1
;
run;

/* HC-059G: 2001 office-based medical provider visits (event-level) */
data CMEPS_H59G;
  input DUPERSID $ OBXP01X PERWT01F VARSTR01 VARPSU01;
  datalines;
10001011 120 9821.5 1 1
10001011 85 9821.5 1 2
10002021 240 11233.0 1 1
10003031 60 8420.3 2 1
10004041 310 4502.8 2 2
10005051 145 10567.1 1 1
10006061 78 5120.9 1 2
10007071 420 12044.2 2 1
10008081 95 8890.7 2 2
10009091 205 6701.4 1 1
10001011 50 9821.5 1 1
10002021 175 11233.0 1 2
;
run;
