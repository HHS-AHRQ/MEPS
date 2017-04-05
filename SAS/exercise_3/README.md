# SAS Exercise 3
Use the following links to download the data .zip files (see ['Loading MEPS data'](../README.md#loading-meps-data) for instructions on loading the .ssp files into SAS):

<b>Input Files</b>:
[H171  (2014 Full year consolidated PUF)](https://meps.ahrq.gov/mepsweb/data_files/pufs/h171ssp.zip)

This program illustrates how to construct family level variables from person level data.

There are two definitions of family unit in MEPS:
1. **CPS Family**:  ID is DUID + CPSFAMID.  Corresponding weight is FAMWT14C.
2. **MEPS Family**: ID is DUID + FAMIDYR.   Corresponding weight is FAMWT14F.

The CPS family is used in this exercise.
