######################################################################################################################################
# R programming statements to read in MEPS Public Use Files
#
# Updated: 2/3/2017
#
# This file contains example programming statements in R for users who want to read in a MEPS public use file (PUF) and save the 
# dataset as an R file for easier access.  
#
# This code uses the 'foreign' package in R to read the SAS transport file (.xpt) that is provided with each PUF release. Two methods 
# of loading this data are given. The first requires the user to navigate to the website containing the MEPS dataset and manually 
# download the SAS transport file using either the .zip or .exe files. The second method uses the R function 'download.file' to 
# automatically download the file by pointing to its location on the website. 
#
# Any statistical analyses on MEPS data should be conducted using the 'survey' package in R, in order to calculate appropriate standard
# errors for estimates from a survey with a complex sample design. Example R code for analyzing MEPS data using the 'survey' package 
# can be found at https://meps.ahrq.gov/survey_comp/hc_samplecodes_se.shtml
#
# Users should be warned that the resulting R dataset does not preserve any SAS formats or variable labels. In addition, variable 
# types may be lost. For instance, a character variable on the SAS dataset could be read as a factor variable in the R dataset. 
# Users are encouraged to be diligent in confirming that variables are stored as the appropriate type before proceeding with analyses. 
######################################################################################################################################
# Install and load 'foreign' package to read SAS transport files  
    install.packages("foreign")  
    library(foreign)
  
## Option 1.  Read file from local computer
#    Step 1: Download and extract the SAS transport format zip file into "C:\MEPS\SASDATA"
#    Step 2: Use 'read.xport' function to load file

# Example: 2014 Full-Year Consolidated Data File (h171)
    meps_data = read.xport("C:/MEPS/SASDATA/h171.ssp")
   
## Option 2. Read file directly from website
#    Step 1: Use 'download.file' function to save zip file from MEPS website to temporary file 'temp'
#    Step 2: Use 'read.xport' and 'unzip' to unzip and load SAS transport data
    
# Example: 2014 Full-Year Consolidated Data File (h171)
   filename = "h171"    
   download.file(sprintf("https://meps.ahrq.gov/mepsweb/data_files/pufs/%sssp.zip",filename),temp <- tempfile())   
   meps_data = read.xport(unzip(temp))   
   unlink(temp)  ## Remove the temp file to free up memory
   

## Optional: Save data as .RData file for faster loading. Note that public use files are occassionally updated. Please see the MEPS
##  website to ensure that you have the latest version:
   save(meps_data,file = "C:/MEPS/SASDATA/h171.RData")
   
## Once the .Rdata is saved, it can be re-loaded in a new R session using the following code:
   load(file = "C:/MEPS/SASDATA/h171.RData")
