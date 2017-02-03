

### Update Design: To get ambulatory (OB+OP) and home health/other expenditures, we need to add variables to the **mepsdsgn** object.

mepsdsgn <- update(mepsdsgn, 
                   ambexp13 = OBVEXP13 + OPTEXP13 + ERTEXP13,
                   hhexp13  = HHAEXP13 + HHNEXP13 + VISEXP13 + OTHEXP13)

### svyratio: 

pct_TOS = svyratio(~IPTEXP13 + ambexp13 + RXEXP13 + DVTEXP13 + hhexp13, 
                   denominator = ~TOTEXP13, 
                   design = mepsdsgn)
print(pct_TOS)

## Ratio estimator: svyratio.survey.design2(~IPTEXP13 + ambexp13 + RXEXP13 + DVTEXP13 + 
##     hhexp13, denominator = ~TOTEXP13, design = mepsdsgn)
## Ratios=
##            TOTEXP13
## IPTEXP13 0.27911022
## ambexp13 0.37882294
## RXEXP13  0.21977145
## DVTEXP13 0.06556864
## hhexp13  0.05672677
## SEs=
##             TOTEXP13
## IPTEXP13 0.011717046
## ambexp13 0.008278700
## RXEXP13  0.007218369
## DVTEXP13 0.002462953
## hhexp13  0.003511954

# Now we can do the same thing by age group (&lt; 65, and 65+), using the `subset` function.

pct_TOS_lt65 = svyratio(~IPTEXP13 + ambexp13 + RXEXP13 + DVTEXP13 + hhexp13, 
                        denominator = ~TOTEXP13, 
                        design = subset(mepsdsgn,AGELAST < 65))

pct_TOS_ge65 = svyratio(~IPTEXP13 + ambexp13 + RXEXP13 + DVTEXP13 + hhexp13, 
                        denominator = ~TOTEXP13, 
                        design = subset(mepsdsgn,AGELAST >= 65))


# The `svyby` function can be used to calculate estimates for all levels of a subgroup. For instance, previously we calculated the percent distribution of expenditures by type of service separately for persons aged 65 and older and those under age 65, by using the `subset` function.

svyratio(~IPTEXP13+ambexp13, 
         denominator = ~TOTEXP13, 
         design = subset(mepsdsgn,AGELAST >= 65))

## Ratio estimator: svyratio.survey.design2(~IPTEXP13 + ambexp13, denominator = ~TOTEXP13, 
##     design = subset(mepsdsgn, AGELAST >= 65))
## Ratios=
##           TOTEXP13
## IPTEXP13 0.3238367
## ambexp13 0.3242236
## SEs=
##            TOTEXP13
## IPTEXP13 0.01611175
## ambexp13 0.01221816

# However, we can also get estimates for persons 65+ and &lt;65 simulataneously by using the `svyby` function. This function works with other svy functions (e.g. `svymean`, `svytotal`, `svyratio`) using the `FUN = ` option.

svyby(~IPTEXP13+ambexp13, 
      denominator = ~TOTEXP13, 
      by = ~(AGELAST >= 65),
      design = mepsdsgn,
      FUN = svyratio)

##       AGELAST >= 65 IPTEXP13/TOTEXP13 ambexp13/TOTEXP13
## FALSE         FALSE         0.2579555         0.4046473
## TRUE           TRUE         0.3238367         0.3242236
##       se.IPTEXP13/TOTEXP13 se.ambexp13/TOTEXP13
## FALSE           0.01485058           0.01013761
## TRUE            0.01611175           0.01221816




### Create output tables: Now we want to extract the coefficient estimates and combine them into a table. To do that, we can use the function `coef` to get the coefficients from the `svyratio` results, and then combine them into a matrix using `cbind`.


pct_matrix = cbind(coef(pct_TOS),
                   coef(pct_TOS_lt65),
                   coef(pct_TOS_ge65))*100
print(pct_matrix)
##                        [,1]      [,2]      [,3]
## IPTEXP13/TOTEXP13 27.911022 25.795551 32.383667
## ambexp13/TOTEXP13 37.882294 40.464733 32.422359
## RXEXP13/TOTEXP13  21.977145 21.540182 22.900994
## DVTEXP13/TOTEXP13  6.556864  7.848380  3.826269
## hhexp13/TOTEXP13   5.672677  4.351155  8.466711

# To clean it up a bit, we can change the row and column names:
  
rownames(pct_matrix) <- c("Hospital IP",
                          "Ambulatory",
                          "RX",
                          "Dental",
                          "HH and Other")

colnames(pct_matrix) = c("Total","<65 years","65+ years")

print(pct_matrix)

##                  Total <65 years 65+ years
## Hospital IP  27.911022 25.795551 32.383667
## Ambulatory   37.882294 40.464733 32.422359
## RX           21.977145 21.540182 22.900994
## Dental        6.556864  7.848380  3.826269
## HH and Other  5.672677  4.351155  8.466711


## Output table to .csv file: If we are happy with our table, now we can export it to a .csv file, to further manipulate, create graphics, or share.
write.csv(pct_matrix,file = "C:/MEPS/figure1.csv")


### Graphics - Barplot Example

# The default for the function `barplot` is to create a stacked bar plot if we give it a matrix, where each bar represents a column.

barplot(pct_matrix) 

# In order to switch the bar chart, so that the bars are type of service, not age group, we can use the transpose function `t` to pivot the matrix

print(t(pct_matrix))

##           Hospital IP Ambulatory       RX   Dental HH and Other
## Total        27.91102   37.88229 21.97714 6.556864     5.672677
## <65 years    25.79555   40.46473 21.54018 7.848380     4.351155
## 65+ years    32.38367   32.42236 22.90099 3.826269     8.466711

barplot(t(pct_matrix)) 



# To change the bars to be side by side, use the `'beside = TRUE'` option

barplot(t(pct_matrix), beside = TRUE) 

# We can also specify colors for the pars, add a label to the y-axis, add a legend, and add data labels on top of the bars.

bp <- barplot(t(pct_matrix),beside=TRUE,
              col = c("blue","yellow","magenta"),
              ylab = "Percentage",
              legend=T)

text(x = bp, y = t(pct_matrix)+2,
     labels = round(t(pct_matrix)),
     xpd=T,col="blue",font=2)



### Using GGplot2: 

install.packages("reshape2")
install.packages("ggplot2")

library(ggplot2)
library(reshape2)

long = melt(pct_matrix)

ggplot(data = long,mapping = aes(x=Var1,y=value,fill=Var2)) +
  geom_bar(position = "dodge",
           stat="identity") +
  scale_fill_manual(values = c(rgb(0,115,189,maxColorValue = 255),
                               rgb(255,197,0,maxColorValue = 255),
                               rgb(99,16,99,maxColorValue=255)))+
  labs(y = "Percentage",x="") + 
  geom_text(aes(x=Var1,y=value,label=round(value)),
            position = position_dodge(width = 0.9),vjust = -0.25,
            colour = rgb(0,0,173,maxColorValue = 255),
            fontface = "bold")+
  theme_classic()+
  theme(legend.position="top",
        legend.title = element_blank(),
        axis.line.x = element_line(colour="black"),
        axis.line.y = element_line(colour="black"),
        text = element_text(colour=rgb(0,0,173,maxColorValue = 255),
                            face="bold"))+
  scale_y_continuous(expand = c(0,0),limits=c(0,max(long$value)+2))
