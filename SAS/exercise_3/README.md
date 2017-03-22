# SAS Exercise 3

This program illustrates how to construct family level variables from person level data.

There are two definitions of family unit in MEPS:
1. **CPS Family**:  ID is DUID + CPSFAMID.  Corresponding weight is FAMWT14C.
2. **MEPS Family**: ID is DUID + FAMIDYR.   Corresponding weight is FAMWT14F.

The CPS family is used in this exercise.

<b>Input File</b>:  H171.SAS7BDAT  (2014 Full year consolidated PUF)
