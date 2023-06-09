# WEBSCRAPING ----

# 1.0 LIBRARIES ----

library(tidyverse) # Main Package - Loads dplyr, purrr, etc.
library(rvest)     # HTML Hacking & Web Scraping
library(xopen)     # Quickly opening URLs
library(jsonlite)  # converts JSON files to R objects
library(glue)      # concatenate strings
library(stringi)   # character string/text processing


##Scraping 1 - Get URLs for each of the product categories
# 1.1 COLLECT PRODUCT FAMILIES ----

url_home          <- "https://www.canyon.com/en-de"
xopen(url_home) # Open links directly from RStudio to inspect them

# Read in the HTML for the entire webpage
html_home         <- read_html(url_home)

# Web scrape the ids for the families
bike_family_tbl <- html_home %>%
  
  # Get the nodes for the families ...
  html_nodes(css = ".js-navigationDrawer__list--secondary") %>%
  # ...and extract the information of the id attribute
  html_attr('id') %>%
  
  # Remove the product families Gear and Outlet and Woman 
  # (because the female bikes are also listed with the others)
  discard(.p = ~stringr::str_detect(.x,"WMN|WOMEN|GEAR|OUTLET")) %>%
  
  # Convert vector to tibble
  enframe(name = "position", value = "family_class") %>%
  
  # Add a hashtag so we can get nodes of the categories by id (#)
  mutate(
    family_id = str_glue("#{family_class}")
  )

bike_family_tbl
## # A tibble: 5 x 3
##   position family_class                  family_id                     
##                                                        
##         1 js-navigationList-ROAD        #js-navigationList-ROAD       
##         2 js-navigationList-MOUNTAIN    #js-navigationList-MOUNTAIN   
##         3 js-navigationList-EBIKES      #js-navigationList-EBIKES     
##         4 js-navigationList-HYBRID-CITY #js-navigationList-HYBRID-CITY
##         5 js-navigationList-YOUNGHEROES #js-navigationList-YOUNGHEROES

# The updated page has now also ids for CFR and GRAVEL. You can either include or remove them.

##Scraping 2 - Get bike product category URLs
# 1.2 COLLECT PRODUCT CATEGORIES ----

# Combine all Ids to one string so that we will get all nodes at once
# (seperated by the OR operator ",")
family_id_css <- bike_family_tbl %>%
  pull(family_id) %>%
  stringr::str_c(collapse = ", ")
family_id_css
## "#js-navigationList-ROAD, #js-navigationList-MOUNTAIN, #js-navigationList-EBIKES, #js-navigationList-HYBRID-CITY, #js-navigationList-YOUNGHEROES"

# Extract the urls from the href attribute
bike_category_tbl <- html_home %>%
  
  # Select nodes by the ids
  html_nodes(css = family_id_css) %>%
  
  # Going further down the tree and select nodes by class
  # Selecting two classes makes it specific enough
  html_nodes(css = ".navigationListSecondary__listItem .js-ridestyles") %>%
  html_attr('href') %>%
  
  # Convert vector to tibble
  enframe(name = "position", value = "subdirectory") %>%
  
  # Add the domain, because we will get only the subdirectories
  mutate(
    url = glue("https://www.canyon.com{subdirectory}")
  ) %>%
  
  # Some categories are listed multiple times.
  # We only need unique values
  distinct(url)

bike_category_tbl
## # A tibble: 25 x 1
##    url                                                                    
##                                                                     
##  1 https://www.canyon.com/en-de/road-bikes/race-bikes/aeroad/             
##  2 https://www.canyon.com/en-de/road-bikes/endurance-bikes/endurace/      
##  3 https://www.canyon.com/en-de/e-bikes/e-road-bikes/endurace-on/         
##  4 https://www.canyon.com/en-de/road-bikes/gravel-bikes/grail/            
##  5 https://www.canyon.com/en-de/road-bikes/cyclocross-bikes/inflite/      
##  6 https://www.canyon.com/en-de/road-bikes/triathlon-bikes/speedmax/      
##  7 https://www.canyon.com/en-de/road-bikes/race-bikes/ultimate/           
##  8 https://www.canyon.com/en-de/mountain-bikes/fat-bikes/dude/            
##  9 https://www.canyon.com/en-de/mountain-bikes/cross-country-bikes/exceed/
## 10 https://www.canyon.com/en-de/mountain-bikes/trail-bikes/grand-canyon/  
## # … with 15 more rows

##Scraping 3 - Get URL for each individual bike of each product category. You might have to scroll down a bit (depending on the category).
# 2.0 COLLECT BIKE DATA ----

# 2.1 Get URL for each bike of the Product categories

# select first bike category url
bike_category_url <- bike_category_tbl$url[1]

# Alternatives for selecting values
# bike_category_url <- bike_category_tbl %$% url %>% .[1]
# bike_category_url <- bike_category_tbl %>% pull(url) %>% .[1]
# bike_category_url <- deframe(bike_category_tbl[1,])
# bike_category_url <- bike_category_tbl %>% first %>% first

xopen(bike_category_url)

# Get the URLs for the bikes of the first category
html_bike_category  <- read_html(bike_category_url)
bike_url_tbl        <- html_bike_category %>%
  
  # Get the 'a' nodes, which are hierarchally underneath 
  # the class productTile__contentWrapper
  html_nodes(css = ".productTile__contentWrapper > a") %>%
  html_attr("href") %>%
  
  # Remove the query parameters of the URL (everything after the '?')
  str_remove(pattern = "\\?.*") %>%
  
  # Convert vector to tibble
  enframe(name = "position", value = "url")

# 2.1.2 Extract the descriptions (since we have retrieved the data already)
bike_desc_tbl <- html_bike_category %>%
  
  # Get the nodes in the meta tag where the attribute itemprop equals description
  html_nodes('.productTile__productSummaryLeft > meta[itemprop="description"]') %>%
  
  # Extract the content of the attribute content
  html_attr("content") %>%
  
  # Convert vector to tibble
  enframe(name = "position", value = "description")