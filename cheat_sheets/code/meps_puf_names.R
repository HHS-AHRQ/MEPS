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

get_pufs <- function(search,years=available_years,verbose = FALSE){
  file_year <- NULL
  for(year in years){ 
    if(verbose) cat("\nstarting year",year)
    url <- paste0("https://meps.ahrq.gov/mepsweb/data_stats/download_data_files_results.jsp?cboDataYear=",year,"&cboDataTypeY=",search,"&buttonYearandDataType=Search")
    page <- read_html(GET(url),as="text")
    results <- page %>% html_nodes("table")
    files <- results[results %>% html_attr("summary") == "PUF Search Results"] 
    file_info <- suppressWarnings(try(html_table(files,header=TRUE),silent=T))
    
    if(class(file_info)=="try-error") next
    file_info2 <- file_info[[1]] %>% 
      mutate(lookup_year = year,  # need this to separate longitudinal files
             url = url)
    file_year <- rbind(file_year,file_info2)
  }
  
  file_year %>% 
    select(`PUF no.`,Year,url,lookup_year) %>% 
    rename(file_name = `PUF no.`)
}

link_name <- function(data,name="file_name",url="url"){
  data %>% 
    mutate_(name=name,url=url) %>%
    mutate(linked_name = sprintf("[%s](%s)",name,url))
}


update_files <- function(){
  
# Look up all tables from MEPS site
  main_url <- "https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp"
  
  main_page  <- read_html(GET(main_url),as="text")
  
  available_years <- main_page %>% 
    html_nodes("select") %>% 
    html_nodes("option") %>% 
    html_text %>% as.numeric %>% na.omit
  
  FYC <- get_pufs("101%2CConsolidated+Data")
  Cond <- get_pufs("101%2CMedical+Conditions")
  Jobs <- get_pufs("101%2CJobs+File")
  PRP  <- get_pufs("101%2CPerson+Round+Plan")
  Long <- get_pufs("101%2CLongitudinal")
  Events <- get_pufs("2%2CHousehold+Event+File")
  PIT  <- get_pufs("3%2CHousehold+Point-in-Time+File")
    

  FYC2 <- FYC %>% link_name() %>% 
    select(Year,linked_name) %>%
    rename('Full Year Consolidated' = linked_name)
  
  Cond2 <- Cond %>% link_name() %>%
    select(Year, linked_name) %>%
    rename(Conditions = linked_name)
  
  Jobs2 <- Jobs %>% link_name() %>% 
    select(Year, linked_name) %>%
    rename(Jobs = linked_name)
  
  PIT2 <- PIT %>% link_name() %>% 
    select(Year, linked_name) %>%
    rename('Point in Time Files' = linked_name)
  
  # Remove aggregate years for person round plan  
  PRP$Year[PRP$Year=="1997-2000"] = 2000:1997
  PRP2 <- PRP %>% link_name() %>%
    mutate(Year = as.numeric(Year)) %>%
    select(Year, linked_name) %>%
    rename('Person Round Plan' = linked_name)
  
  # Change year on Longitudinal to be 'start year'
  Long2 <- Long %>%
    separate(Year,into='Year',sep="-",extra="drop") %>%
    mutate(Year = as.numeric(Year)) %>% 
    filter(Year==lookup_year) %>% unique %>%
    link_name() %>%
    select(Year, linked_name) %>%
    rename('Longitudinal' = linked_name)
  
  # For event files, collapse to one file name
  Events2 <- Events %>% 
    filter(nchar(Year)==4) %>%       # remove multum lexicon files
    mutate(file_name = gsub("[A-I]$","",file_name)) %>% unique %>%
    mutate(Year = as.numeric(Year)) %>%
    link_name() %>%
    select(Year, linked_name) %>%
    rename('Event Files' = linked_name)
  
 # Join files
    all_files <- join_all(list(PIT2,FYC2,Cond2,Jobs2,PRP2,Long2,Events2),by="Year")
  
 # Add panel information  
  
  n_panels = length(available_years)
  
  panel_data <- data.frame(Year=available_years) %>%
    arrange(available_years) %>%
    mutate(new_panel = 1:n_panels,
           old_panel = new_panel-1) %>%
    mutate(old_panel = replace(old_panel,old_panel==0,NA)) %>%
    select(Year, old_panel, new_panel) %>%
    rename('New panel' = new_panel,'Old panel' = old_panel)
  
  out <- full_join(panel_data,all_files,by="Year") 
  
  save(out,file="meps_puf_names.Rdata")
}

#update_files()

# Knit to markdown file

ezknit(file = "code/meps_puf_names.Rmd", out_dir = ".",keep_html = FALSE)

