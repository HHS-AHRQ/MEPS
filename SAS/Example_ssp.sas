*** Create a SAS data set from a single SAS trasport file;
*** The SAS transport file(s) must be downloaded from the MEPS web site and 
    then unzipped before running this program;
LIBNAME sasdata 'C:\MEPS\Data';
FILENAME in1 'C:\MEPS\ssp\h181.ssp';
proc xcopy in = in1 out = sasdata IMPORT;
run;

*** Create SAS data sets from multiple SAS transport files
    using a modular macro;

%macro create (fn);
	LIBNAME sasdata "C:\MEPS\Data";
	 FILENAME in1 "C:\MEPS\ssp\&fn..ssp";
		proc xcopy in = in1 out = sasdata IMPORT;
		run;
%mend create;
%create (h181)  /* full-year consolidate file, 2015 */
%create (h180)  /* medical condition file, 2015 */
%create (h164)  /* longitudinal file, panel 17 (2012-13) */
%create (h172)  /* longitudinal file, panel 18 (2013-14) */
%create (h183)  /* longitudinal file, panel 19 (2014-15) */
%create (h178a) /* prescribed medicines file, 2015 */
%create (h178d) /* hospital inpatient hospital stays file, 2015 */
%create (h178e) /* emergency room visits file, 2015 */
%create (h178f) /* outpatient visits file, 2015 */
%create (h178g) /* office-based medical provider visits file, 2015 */
%create (h178h) /* home health file, 2015 */
%create (h178if1) /* condition-event CLNK file, 2015 */
%create (h178if2) /* prescription medicines RXLK file, 2015 */


