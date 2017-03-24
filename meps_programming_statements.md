The following is a quick-reference guide to compare common programming statements using SAS, STATA, and R to analyze MEPS expenditure data. Note that each language requires use of functions and methods specifically built to analyze survey data.

These examples are based on the 2011 Full-Year-Consolidated public use file (HC-147).

<table>
<thead>
  <th>Description</th> <th>SAS</th> <th>Stata</th> <th>R</th>
</thead>
<tbody>
<tr>
  <td>Full<br>Population</td>
  <td>
  `proc surveymeans data=FYC;`<br>
  &nbsp;&nbsp;`stratum VARSTR;`<br>
  &nbsp;&nbsp;`cluster VARPSU;`<br>
  &nbsp;&nbsp;`weight PERWT11F;`<br>
  &nbsp;&nbsp;`var TOTEXP11;`<br>
  `run;`
  </td>
  <td>
  `svyset [pweight=perwt11f],` <br>
  `strata(varstr) psu(varpsu)`<br><br>
  `svy: mean totexp11`
  </td>
  <td>
  `library(survey)`<br>
  `mepsdsgn <- `<br>
  `svydesign(`
    &nbsp;&nbsp;`id=~VARPSU,`<br>
    &nbsp;&nbsp;`strata=~VARSTR,`<br>
    &nbsp;&nbsp;`weights=~PERWT11F,`<br>
    &nbsp;&nbsp;`data=FYC,`<br>
    &nbsp;&nbsp;`nest=TRUE)`<br><br>
    `svymean(~TOTEXP11, mepsdsgn)`
  </td>
</tr>
<tr>
  <td>
  Sub-population
  </td>
  <td>
   `proc surveymeans DATA=FYC;`<br>
   &nbsp;&nbsp;`stratum VARSTR;`<br>
   &nbsp;&nbsp;`cluster VARPSU;`<br>
   &nbsp;&nbsp;`weight PERWT11F;`<br>
   &nbsp;&nbsp;`var TOTEXP11;`<br>
   &nbsp;&nbsp;`domain SEX;`<br>
   `run;`
  </td>
  <td>
  `svy: mean totexp11,`<br>
  `subpop(sex)`
  </td>
  <td>
  `svymean(~TOTEXP11, subset(mepsdsgn,SEX==1))`
  </td>
</tr>
<tr>
  <td>
  Comparing<br>groups
  </td>
  <td>
  `proc surveyreg DATA=FYC;`<br>
  &nbsp;&nbsp;`stratum VARSTR;`<br>
  &nbsp;&nbsp;`cluster VARPSU;`<br>
  &nbsp;&nbsp;`weight PERWT11F;`<br>
  &nbsp;&nbsp;`class SEX;`<br>
  &nbsp;&nbsp;`model TOTEXP11=SEX/NOINT`<br>
  &nbsp;&nbsp;`solution VADJUST=NONE;`<br>
  &nbsp;&nbsp;`lsmeans SEX/DIFF;`<br>
  &nbsp;&nbsp;`contrast "Compare male vs.female" SEX 1 -1;`<br>
  `run;`
  </td>
  <td>
  `svy: mean totexp11, over(sex)`<br>
  `lincom [totexp11]1-[totexp11]2`
  </td>
  <td>
  `svyby(~TOTEXP11,~SEX, mepsdsgn, svymean)`<br>
  `svyttest(TOTEXP11~SEX, mepsdsgn)`<br>
  `summary(svyglm(TOTEXP11~factor(SEX), mepsdsgn))`
  </td>
</tr
</tbody>
</table>
