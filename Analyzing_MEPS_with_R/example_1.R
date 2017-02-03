# Example 1: Re-producing estimates from MEPS summary table

# After downloading MEPS data (see 'loading_MEPS.R' for instructions to do so)
# define the survey object:

mepsdsgn <-
  svydesign(id = ~VARPSU, 
            strata = ~VARSTR, 
            weights = ~PERWT13F, 
            data = FYC2013, 
            nest=TRUE)  

## Total population: since the total population is equal to the sum of survey weights (PERWT13F), we don't need to use a survey function here, since standard errors are not applicable to population control totals.

sum(FYC2013$PERWT13F) 
##  [1] 315721982

## Total expenses: to use the `svytotal` function, we can use the '$' notation to indicate that we want to use dataset FYC2013 and variable TOTEXP13.

svytotal(FYC2013$TOTEXP13, design = mepsdsgn)  
##           total         SE
## [1,] 1.4005e+12 4.3378e+10

# Or we can use the formula notation '~', to tell R that we want to look in the design object `mepsdsgn` (in which we defined dataset FYC2013) to find the variable TOTEXP13.
svytotal(~TOTEXP13,design = mepsdsgn)  
##               total         SE
## TOTEXP13 1.4005e+12 4.3378e+10

## Percent with expense: To calculate the percent of people with any expense, first create a new indicator variable for persons with an expense.

FYC2013$any_expense = (FYC2013$TOTEXP13 > 0)*1

# Note that if we try to run `svymean`, we will get an error, since we added a variable to the data set after defining the survey design object, `mepsdsgn`. 
# First, we need to re-run the code defining `mepsdsgn` to include the dataset with the new variable. Then we can run the `svymean` function, since the `mepsdsgn` object now includes the version of the dataset that contains the new variable `any\_expense`.

mepsdsgn <- svydesign(id = ~VARPSU, 
    strata = ~VARSTR, 
    weights = ~PERWT13F, 
    data = FYC2013, 
    nest=TRUE)

svymean(~any_expense,design = mepsdsgn)                      
##                mean     SE
## any_expense 0.84398 0.0036

### Mean and median, per person with an expense: to get expenses per person with an expense, we want to limit the dataset to persons that have an expense (i.e. `any\_expense == 1`), using the `subset` function.

svymean(~TOTEXP13, design = subset(mepsdsgn,any_expense==1)) 
##          mean     SE
## TOTEXP13 5256 118.17

svyquantile(~TOTEXP13, design = subset(mepsdsgn,any_expense==1),quantiles = 0.5) 
##           0.5
## TOTEXP13 1389

## Distribution of expenses by source of payment: For percent of total, we need to use the `svyratio` function, and specify the numerator and denominator. First, we'll estimate the percent for out-of-pocket payments (`TOTSLF13`).
svyratio(~TOTSLF13, denominator = ~TOTEXP13, design = mepsdsgn)

## Ratio estimator: svyratio.survey.design2(~TOTSLF13, denominator = ~TOTEXP13, design = mepsdsgn)
## Ratios=
##           TOTEXP13
## TOTSLF13 0.1377617
## SEs=
##             TOTEXP13
## TOTSLF13 0.004395095

# We can also calculate percentages for multiple variables at one time, using a '+' sign in the formula notation.
svyratio(~TOTSLF13 + TOTPTR13 + TOTMCR13 + TOTMCD13, 
         denominator = ~TOTEXP13, 
         design = mepsdsgn)

## Ratio estimator: svyratio.survey.design2(~TOTSLF13 + TOTPTR13 + TOTMCR13 + TOTMCD13, 
##     denominator = ~TOTEXP13, design = mepsdsgn)
## Ratios=
##           TOTEXP13
## TOTSLF13 0.1377617
## TOTPTR13 0.4060437
## TOTMCR13 0.2530722
## TOTMCD13 0.1243487
## SEs=
##             TOTEXP13
## TOTSLF13 0.004395095
## TOTPTR13 0.011466596
## TOTMCR13 0.009134258
## TOTMCD13 0.007487569

# Before estimating percentages for 'Other' insurance, we need to adjust this variable to match the online table: Other = VA + worker's comp + other sources. Previously, we did this by adding new variables to the dataset FYC2013, and then re-defining the design object `mepsdsgn`. But, we can streamline this process by using the `update` function to make changes to `mepsdsgn` directly, without changing the dataset FYC2013.

mepsdsgn <- update(mepsdsgn, tototh13 = TOTVA13 + TOTWCP13 + TOTOTH13)
svyratio(~tototh13, denominator = ~TOTEXP13, design = mepsdsgn)

    ## Ratio estimator: svyratio.survey.design2(~tototh13, denominator = ~TOTEXP13, design = mepsdsgn)
    ## Ratios=
    ##            TOTEXP13
    ## tototh13 0.07877691
    ## SEs=
    ##             TOTEXP13
    ## tototh13 0.005148356

## END
