# Example 2: Re-producing estimates for Figure 1 of Stat brief #491

# Load packages and set options
install.packages("foreign")  # Only need to run these once
install.packages("survey")

library(foreign) # Run these every time you re-start R
library(survey)

options(survey.lonely.psu='adjust')

# Load MEPS data from internet
download.file("https://meps.ahrq.gov/mepsweb/data_files/pufs/h163ssp.zip", temp <- tempfile())
unzipped_file = unzip(temp)
h163 = read.xport(unzipped_file)
unlink(temp)  # Unlink to delete temporary file

# After downloading MEPS data define the survey object:
mepsdsgn <- svydesign(id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT13F,
    data = h163,
    nest = TRUE)

# To get ambulatory (OB+OP) and home health/other expenditures, add variables to the mepsdsgn object.
mepsdsgn <- update(mepsdsgn,
                   ambexp13 = OBVEXP13 + OPTEXP13 + ERTEXP13,
                   hhexp13  = HHAEXP13 + HHNEXP13 + VISEXP13 + OTHEXP13)

# Use svyratio to calculate percentage distribution of spending by type of service:
pct_TOS = svyratio(~IPTEXP13 + ambexp13 + RXEXP13 + DVTEXP13 + hhexp13,
                   denominator = ~TOTEXP13,
                   design = mepsdsgn)

# Now do the same thing by age group (<65, 65+), using the `subset` function.
pct_TOS_lt65 = svyratio(~IPTEXP13 + ambexp13 + RXEXP13 + DVTEXP13 + hhexp13,
                    denominator = ~TOTEXP13,
                    design = subset(mepsdsgn,AGELAST < 65))

pct_TOS_ge65 = svyratio(~IPTEXP13 + ambexp13 + RXEXP13 + DVTEXP13 + hhexp13,
                    denominator = ~TOTEXP13,
                    design = subset(mepsdsgn,AGELAST >= 65))

# Create output tables
pct_matrix = cbind(coef(pct_TOS),
                   coef(pct_TOS_lt65),
                   coef(pct_TOS_ge65))*100
print(pct_matrix)

# Clean it up:
rownames(pct_matrix) <- c("Hospital IP", "Ambulatory", "RX", "Dental", "HH and Other")
colnames(pct_matrix) <- c("Total","<65 years","65+ years")
print(pct_matrix)

# Optional: output table to .csv file
write.csv(pct_matrix,file = "C:/MEPS/figure1.csv")


## Graphics - barplot Example to recreate Figure 1
bp <- barplot(
  t(pct_matrix),        # 't' transposes the matrix, so the x-axis represents type of service
  beside=TRUE,          # make bars side-by-side, not stacked
  col   = c("blue","yellow","magenta"),   # change colors of bars
  ylab  = "Percentage", # change y-axis label
  legend=T)             # add a legend

text(x = bp, y = t(pct_matrix)+2,  # add text labels to end points of bars
     labels = round(t(pct_matrix)),
     xpd=T,col="blue",font=2)


## Graphics example with ggplot2:
install.packages("reshape2")
install.packages("ggplot2")

library(ggplot2)
library(reshape2)

long = melt(pct_matrix)  # convert matrix from wide to long format (long format is preferred by ggplot)

# define custom colors
my_blue <- rgb(0,115,189,maxColorValue = 255)
my_yellow <- rgb(255,197,0,maxColorValue = 255)
my_magenta <- rgb(99,16,99,maxColorValue=255)
my_darkblue <- rgb(0,0,173,maxColorValue = 255)

# create plot
ggplot(long,aes(x=Var1,y=value,fill=Var2)) +
  geom_bar(position = "dodge",stat="identity") +                 # make bars side-by-side
  scale_fill_manual(values = c(my_blue,my_yellow,my_magenta))+   # change colors of bars
  labs(y = "Percentage",x="") +                                  # change axis labels
  geom_text(aes(x=Var1,y=value,label=round(value)),              # add data labels to end of bars
            position = position_dodge(width = 0.9),vjust = -0.25,
            colour = my_darkblue, fontface = "bold")+
  theme_classic()+                        # change themes (background color, line colors, etc.)
  theme(legend.position="top",
        legend.title = element_blank(),
        axis.line.x = element_line(colour="black"),
        axis.line.y = element_line(colour="black"),
        text = element_text(colour=my_darkblue,
                            face="bold"))+
  scale_y_continuous(expand = c(0,0),limits=c(0,max(long$value)+2))
