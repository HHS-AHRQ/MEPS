library(knitr)
library(rvest)
library(httr)
library(dplyr)
library(tidyr)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

set_config(config(ssl_verifypeer=0L))

join_all <- function(df_list,...){
  out <- df_list[[1]]
  for(df in df_list[-1]) out <- out %>% full_join(df,...)
  out
}

update_files <- function(){
  
# Look up all tables from MEPS site
  main_url <- "https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp"
  
  main_page  <- read_html(GET(main_url),as="text")
  
  available_years <- main_page %>% 
    html_nodes("select") %>% 
    html_nodes("option") %>% 
    html_text %>% as.numeric %>% na.omit
  
  search_list <- c("FYC" = "101%2CConsolidated+Data",
                   #"101%2CPopulation+Characteristics",
                   "Conditions"="101%2CMedical+Conditions",
                   "Jobs"="101%2CJobs+File",
                   "Person_Round_Plan"="101%2CPerson+Round+Plan",
                   "Longitudinal"="101%2CLongitudinal",
                   "Event_Files"="2%2CHousehold+Event+File",
                   "PIT"="3%2CHousehold+Point-in-Time+File")
  
  
  meps_url <- function(year,search)
    paste0("https://meps.ahrq.gov/mepsweb/data_stats/download_data_files_results.jsp?cboDataYear=",year,"&cboDataTypeY=",search,"&buttonYearandDataType=Search")
  
  file_list <- list()
  for(i in 1:length(search_list)){   
    file_year <- NULL
    for(year in available_years[-1]){ 
      url <- meps_url(year,search_list[i])
      page <- read_html(GET(url),as="text")
      results <- page %>% html_nodes("table")
      files <- results[results %>% html_attr("summary") == "PUF Search Results"] 
      file_info <- html_table(files,header=TRUE)[[1]]
      file_info$url <- url
      file_info$lookup_year <- year # need this to separate longitudinal files
      file_year <- rbind(file_year,file_info)
    }
    
    file_type <- names(search_list)[i]
    file_year <- file_year %>% select(`PUF no.`,Year,url,lookup_year) 
    names(file_year) <- c(file_type,"Year","url","lookup_year")
    file_list[[file_type]] <- file_year 
  }
  
  # For event files, collapse to one file name
    file_list[["Event_Files"]] <-
      file_list[["Event_Files"]] %>% 
      filter(nchar(Year)==4) %>%       # remove multum lexicon files
      mutate(Event_Files = gsub("[A-I]$","",Event_Files),
             Year = as.numeric(Year)) %>% unique
  
  # Change year on Longitudinal to be 'start year'
    file_list[["Longitudinal"]] <- 
      file_list[["Longitudinal"]] %>%
      separate(Year,into='Year',sep="-",extra="drop") %>%
      mutate(Year = as.numeric(Year)) %>% 
      filter(Year==lookup_year) %>% unique
    
  # Remove aggregate years for person round plan  
    PRP <- file_list[["Person_Round_Plan"]]
    PRP$Year[PRP$Year=="1997-2000"] = 2000:1997
    file_list[["Person_Round_Plan"]] <- PRP %>% mutate(Year = as.numeric(Year))
  
  # Remove lookup year   
    # for(i in 1:length(file_list)){
    #   
    #   l %>% mutate()
    # }
    
    
    ## i don't like it -- make some functions, then add linked url in function,
    #  then combine...
    
 
  all_files <- join_all(file_list,by="Year")
  
  n_panels = length(available_years)
  
  panel_data <- data.frame(Year=available_years) %>%
    arrange(available_years) %>%
    mutate(new_panel = 1:n_panels,
           old_panel = new_panel-1) %>%
    mutate(old_panel = replace(old_panel,old_panel==0,NA))
  
  out <- full_join(panel_data,all_files,by="Year") %>% 
    select(Year,new_panel,old_panel,PIT,FYC,Conditions,Event_Files,Jobs,Person_Round_Plan,Longitudinal)
  
  names(out) = c("Year","New Panel","Old Panel","Point in Time","Full Year Consolidated",
                 "Conditions","Event Files","Jobs","Person Round Plan","Longitudinal")
  save(out,file="meps_puf_names.Rdata")
}

