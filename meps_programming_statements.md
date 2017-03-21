The following is a quick-reference guide to compare common programming statements using SAS, STATA, and R to analyze MEPS expenditure data. Note that each language requires use of functions and methods specifically built to analyze survey data.

These examples are based on the 2011 Full-Year-Consolidated public use file (HC-147).

Description | SAS | STATA | R
------------|-----|-------|---
Full Population | proc surveymeans data=FYC;<br>stratum VARSTR;<br>cluster VARPSU;<br>weight PERWT11F;<br>var TOTEXP11;<br>run; | svyset [pweight=perwt11f], <br>strata(varstr) psu(varpsu)<br>svy: mean totexp11 |library(survey)<br>mepsdsgn <- svydesign(<br>&nbsp;&nbsp;id=~VARPSU,<br>&nbsp;&nbsp;strata=~VARSTR,<br>&nbsp;&nbsp;weights=~PERWT11F,<br>&nbsp;&nbsp;data=FY,<br>&nbsp;&nbsp;nest=TRUE)<br><br>svymean(~TOTEXP11, mepsdsgn)
Sub-population | proc surveymeans DATA=FY;<br>stratum VARSTR;<br>cluster VARPSU;<br>weight PERWT11F;<br>var TOTEXP11;<br>domain SEX;<br>run; |svy: mean totexp11,<br>subpop(sex) | svymean(~TOTEXP11, subset(mepsdsgn,SEX==1))
Comparison between groups | proc surveyreg DATA=FY;<br>stratum VARSTR;<br>cluster VARPSU;<br>weight PERWT11F;<br>class SEX;<br>model TOTEXP11=SEX/NOINT<br>solution VADJUST=NONE;<br>lsmeans SEX/DIFF;<br>contrast "Compare male vs.female" SEX 1 -1;<br>run; | svy: mean totexp11, over(sex)<br>lincom [totexp11]1-[totexp11]2 | svyby(~TOTEXP11, ~SEX, mepsdsgn, svymean)<br>svyttest(TOTEXP11~SEX, mepsdsgn)<br>summary(svyglm(TOTEXP11~factor(SEX), mepsdsgn))


