#Step 1 Packages laden

library(vroom)
library(tidyverse)
library(dplyr)
library(httr)
library(jsonlite)

#Step 2 Daten importieren

col_types <- list(
  id = col_character(),
  type = col_character(),
  number = col_character(),
  country = col_character(),
  date = col_date("%Y-%m-%d"),
  abstract = col_character(),
  title = col_character(),
  kind = col_character(),
  num_claims = col_double(),
  filename = col_character(),
  withdrawn = col_double()
)

patent_tbl <- vroom(
  file       = "patent.tsv", 
  delim      = "\t", 
  col_types  = col_types,
  na         = c("", "NA", "NULL")
)

patent_assignee <- vroom(
  file = "patent_assignee.tsv",
  delim = "\t",
  na         = c("", "NA", "NULL")
)

assignee <- vroom(
  file = "assignee.tsv",
  delim = "\t",
  na         = c("", "NA", "NULL")
)

uspc <- vroom(
  file = "uspc.tsv",
  delim = "\t",
  col_types = list(
    patent_id = col_character()
  ),
  na         = c("", "NA", "NULL")
)

#Step 3 Kombinierte Tabellen erzeugen

data <- left_join(patent_tbl, patent_assignee, by = c("id" = "patent_id"))
data <- left_join(data, assignee, by = c("assignee_id" = "id")) 

#Step 4 Frage 1 Patent dominance
# The ten US companies with the most assigned/granted patents

dominance <- data %>% 
  select(organization, num_claims) %>% 
  group_by(organization) %>% 
  summarise(claims = sum(num_claims))
dominance_cleaned <- dominance[dominance$organization != 'NA',]

dominance_sorted <- dominance_cleaned[order(dominance_cleaned$claims,decreasing=TRUE),]

head(dominance_sorted, n=10)


#Step 5 Frage 2 Recent patent activity
# The ten US companies with the most new granted patents for August 2014

august_2014 <- data[format.Date(data$date, "%m")=="08" & !is.na(data$date),] %>% 
  select(organization, num_claims) %>% 
  group_by(organization) %>% 
  summarise(claims = sum(num_claims))

august_2014_cleaned <- august_2014[august_2014$organization != 'NA',]

august_2014_sorted <- august_2014_cleaned[order(august_2014_cleaned$claims,decreasing=TRUE),]

head(august_2014_sorted,n=10)

#Step 6 Frage 3 Innovation in tech 
# Top ten companies worldwide with most patents - top 5 USPTO tech main classes

inno <- left_join(assignee, patent_assignee, by = c("id" = "assignee_id"))
inno <- left_join(inno, uspc, by = c("patent_id" = "patent_id"))

inno_cleaned <- inno[!duplicated(inno$patent_id),]
inno_cleaned_new <- inno_cleaned[inno_cleaned$id != 'NA',]

#Create a filter
orgs <- head(dominance_sorted$organization, 10)

#Apply Filter
inno_orgs <- inno %>% 
  filter(organization %in% orgs) %>% 
  select(organization, mainclass_id) %>% 
  count(mainclass_id, sort = TRUE)

inno_orgs_final <- inno_orgs[-1,] %>% 
  head(n=5)

getMainId <- function(x){
  url <- sprintf('https://api.patentsview.org/uspc_mainclasses/query?q={"uspc_mainclass_id":%s}&f=["uspc_mainclass_title"]',x[1])
  resp <- GET(url)
  content <- rawToChar(resp$content) %>% 
    fromJSON()
  
  class <- content[["uspc_mainclasses"]][[1]]
  return(class)
}

names <- apply(inno_orgs_final,1,getMainId)

inno_orgs_final %>% 
  mutate(type = names) %>% 
  head(n=5)