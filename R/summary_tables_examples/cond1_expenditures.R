# -----------------------------------------------------------------------------
# Medical Conditions, 2015
#
# Note: Starting in 2016, conditions were coded to ICD-10 codes (ICD-9 codes
#  were used from 1996-2015). CCS codes are not on the medical conditions PUFs
#  for 2016 or 2017
#
# Example R code to replicate the following estimates in the MEPS-HC summary
#  tables by medical condition:
#  - Number of people with care
#  - Number of events
#  - Total expenditures
#  - Mean expenditure per person
# -----------------------------------------------------------------------------

# Install/load packages and set global options --------------------------------

# Install packages (if needed) -- only need to run once
  install.packages("survey")
  install.packages("dplyr")
  install.packages("foreign")

# Load packages (need to run every session)
  library(survey)
  library(dplyr)
  library(foreign)

# Set survey option for lonely psu
  options(survey.lonely.psu="adjust")


# Load datasets ---------------------------------------------------------------

# Load and stack event files
# - For RX, count number of fills per event
  RX <- read.xport("C:/MEPS/h178a.ssp")
  RX <- RX %>%
    group_by(DUPERSID, LINKIDX, VARSTR, VARPSU, PERWT15F) %>%
    summarize(XPX = sum(RXXP15X), n_fills = n()) %>%
    ungroup %>%
    rename(EVNTIDX = LINKIDX)
  
  IP <- read.xport("C:/MEPS/h178d.ssp") %>% rename(XPX = IPXP15X)
  ER <- read.xport("C:/MEPS/h178e.ssp") %>% rename(XPX = ERXP15X)
  OP <- read.xport("C:/MEPS/h178f.ssp") %>% rename(XPX = OPXP15X)
  OB <- read.xport("C:/MEPS/h178g.ssp") %>% rename(XPX = OBXP15X)
  HH <- read.xport("C:/MEPS/h178h.ssp") %>% rename(XPX = HHXP15X)

  stacked_events <- 
    bind_rows(RX=RX, IP=IP, ER=ER, OP=OP, OB=OB, HH=HH, .id = "data") %>%
    select(data, EVNTIDX, DUPERSID, XPX, VARSTR, VARPSU, PERWT15F, n_fills) %>%
    mutate(n_events = pmax(n_fills, 1, na.rm = T))
  

# Load in event-condition linking file
  clink1 = read.xport("C:/MEPS/h178if1.ssp") %>%
    select(DUPERSID, CONDIDX, EVNTIDX)

# Load in conditions file
  conditions <- read.xport("C:/MEPS/h180.ssp") %>%
    select(DUPERSID, CONDIDX, CCCODEX)


# Merge datasets --------------------------------------------------------------

# Merge conditions file with the conditions-event link file (CLNK)
  cond_clink <- full_join(conditions, clink1, by = c("DUPERSID", "CONDIDX"))
  
# Create collapsed condition code variable
  cond_clink <- cond_clink %>% mutate(
    
    ccnum = as.numeric(as.character(CCCODEX)), # factor -> numeric
    
    Condition = case_when(
      ccnum < 0                    ~ "",
      ccnum %in% 1:9               ~ "Infectious diseases",
      ccnum %in% 11:45             ~ "Cancer",
      ccnum %in% 46:47             ~ "Non-malignant neoplasm",
      ccnum == 48                  ~ "Thyroid disease",
      ccnum %in% 49:50             ~ "Diabetes mellitus",
      ccnum %in% c(51:52,54:58)    ~ "Other endocrine, nutritional & immune disorder",
      ccnum == 53                  ~ "Hyperlipidemia",
      ccnum == 59                  ~ "Anemia and other deficiencies",
      ccnum %in% 60:64             ~ "Hemorrhagic, coagulation, and disorders of White Blood cells",
      ccnum %in% c(65:75,650:670)  ~ "Mental disorders",
      ccnum %in% 76:78             ~ "CNS infection",
      ccnum %in% 79:81             ~ "Hereditary, degenerative and other nervous system disorders",
      ccnum == 82                  ~ "Paralysis",
      ccnum == 84                  ~ "Headache",
      ccnum == 83                  ~ "Epilepsy and convulsions",
      ccnum == 85                  ~ "Coma, brain damage",
      ccnum == 86                  ~ "Cataract",
      ccnum == 88                  ~ "Glaucoma",
      ccnum %in% c(87,89:91)       ~ "Other eye disorders",
      ccnum == 92                  ~ "Otitis media",
      ccnum %in% 93:95             ~ "Other CNS disorders",
      ccnum %in% 98:99             ~ "Hypertension",
      ccnum %in% c(96:97,100:108)  ~ "Heart disease",
      ccnum %in% 109:113           ~ "Cerebrovascular disease",
      ccnum %in% 114:121           ~ "Other circulatory conditions arteries, veins, and lymphatics",
      ccnum == 122                 ~ "Pneumonia",
      ccnum == 123                 ~ "Influenza",
      ccnum == 124                 ~ "Tonsillitis",
      ccnum %in% 125:126           ~ "Acute Bronchitis and URI",
      ccnum %in% 127:134           ~ "COPD, asthma",
      ccnum == 135                 ~ "Intestinal infection",
      ccnum == 136                 ~ "Disorders of teeth and jaws",
      ccnum == 137                 ~ "Disorders of mouth and esophagus",
      ccnum %in% 138:141           ~ "Disorders of the upper GI",
      ccnum == 142                 ~ "Appendicitis",
      ccnum == 143                 ~ "Hernias",
      ccnum %in% 144:148           ~ "Other stomach and intestinal disorders",
      ccnum %in% 153:155           ~ "Other GI",
      ccnum %in% 149:152           ~ "Gallbladder, pancreatic, and liver disease",
      ccnum %in% c(156:158,160:161)~ "Kidney Disease",
      ccnum == 159                 ~ "Urinary tract infections",
      ccnum %in% 162:163           ~ "Other urinary",
      ccnum %in% 164:166           ~ "Male genital disorders",
      ccnum == 167                 ~ "Non-malignant breast disease",
      ccnum %in% 168:176           ~ "Female genital disorders, and contraception",
      ccnum %in% 177:195           ~ "Complications of pregnancy and birth",
      ccnum %in% c(196,218)        ~ "Normal birth/live born",
      ccnum %in% 197:200           ~ "Skin disorders",
      ccnum %in% 201:204           ~ "Osteoarthritis and other non-traumatic joint disorders",
      ccnum == 205                 ~ "Back problems",
      ccnum %in% c(206:209,212)    ~ "Other bone and musculoskeletal disease",
      ccnum %in% 210:211           ~ "Systemic lupus and connective tissues disorders",
      ccnum %in% 213:217           ~ "Congenital anomalies",
      ccnum %in% 219:224           ~ "Perinatal Conditions",
      ccnum %in% c(225:236,239:240,244) ~ "Trauma-related disorders",
      ccnum %in% 237:238           ~ "Complications of surgery or device",
      ccnum %in% 241:243           ~ "Poisoning by medical and non-medical substances",
      ccnum == 259                 ~ "Residual Codes",
      ccnum %in% c(10,254:258)     ~ "Other care and screening",
      ccnum %in% 245:252           ~ "Symptoms",
      ccnum == 253                 ~ "Allergic reactions",
      TRUE                         ~ "Other"
    ))
  
  
# De-duplicate by event ID ('EVNTIDX') and collapsed code ('Condition')  
  
  cond_clink <- cond_clink %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all = T)
  
  
# Merge conditions and event files -------------------------------------------- 

  all_events <- 
    full_join(stacked_events, cond_clink, by = c("DUPERSID", "EVNTIDX")) 

# Remove observations with missing 'Condition' or negative/missing expenditures
  all_events <- all_events %>% filter(Condition != "", XPX >= 0)


# Aggregate to person-level, by Condition -------------------------------------

  all_pers <- all_events %>%
    group_by(DUPERSID, VARSTR, VARPSU, Condition) %>%
    summarize(
      PERWT15F = mean(PERWT15F),
      pers_XP = sum(XPX),
      n_events = sum(n_events)) %>%
    ungroup %>%
    mutate(persons = 1)


# Define survey design and calculate estimates --------------------------------

  PERSdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT15F,
    data = all_pers,
    nest = TRUE)


# Totals (people, events, expenditures)
  totals <- svyby(~persons + n_events + pers_XP,
                  by = ~Condition, FUN = svytotal, design = PERSdsgn)

  totals %>% select(persons, se.persons)   # Number of people with care
  totals %>% select(n_events, se.n_events) # Number of events
  totals %>% select(pers_XP, se.pers_XP)   # Total expenditures


# Mean expenditure per person with care
  means <- svyby(~pers_XP, by = ~Condition, FUN = svymean, design = PERSdsgn)

  means %>% select(pers_XP, se)
