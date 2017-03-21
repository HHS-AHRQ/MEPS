The following is a quick-reference guide to compare common programming statements using SAS, STATA, and R to analyze MEPS expenditure data. Note that each language requires use of functions and methods specifically built to analyze survey data.

These examples are based on the 2011 Full-Year-Consolidated public use file (HC-147).

Description | SAS | STATA | R
------------|-----|-------|---
Full Population | PROC SURVEYMEANS DATA=FY;<br>STRATUM VARSTR;<br>CLUSTER VARPSU;<br>WEIGHT PERWT11F;<br>VAR TOTEXP11;<br>RUN; | svyset [pweight=perwt11f], <br>strata(varstr) psu(varpsu)<br>svy: mean totexp11 |library(survey)<br>mepsdsgn <- svydesign(<br>id=~VARPSU,<br>
strata=~VARSTR,<br>weights=~PERWT11F,<br>data=FY,<br>nest=TRUE)<br><br>svymean(~TOTEXP11, mepsdsgn)

Sub-population | PROC SURVEYMEANS DATA=FY;<br>STRATUM VARSTR;<br>CLUSTER VARPSU;<br>WEIGHT PERWT11F;<br>VAR TOTEXP11;<br>DOMAIN SEX;<br>RUN; |svy: mean totexp11,<br>
subpop(sex) | svymean(~TOTEXP11, subset(mepsdsgn,SEX==1))

Comparison between groups | PROC SURVEYREG DATA=FY;<br>STRATUM VARSTR;<br>CLUSTER VARPSU;<br>
WEIGHT PERWT11F;<br>CLASS SEX;<br>MODEL TOTEXP11=SEX/NOINT<br>SOLUTION VADJUST=NONE;<br>LSMEANS SEX/DIFF;<br>CONTRAST "Compare male vs.female" SEX 1 -1;<br>RUN; |
svy: mean totexp11, over(sex)<br>lincom [totexp11]1-[totexp11]2 | svyby(~TOTEXP11, ~SEX, mepsdsgn, svymean)<br>svyttest(TOTEXP11~SEX, mepsdsgn)<br>summary(svyglm(TOTEXP11~factor(SEX), mepsdsgn))


