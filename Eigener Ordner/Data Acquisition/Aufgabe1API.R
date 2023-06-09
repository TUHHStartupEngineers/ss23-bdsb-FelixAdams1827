#Step 1 Packages laden

      library(httr)
      library(jsonlite)
      library(tidyverse)
      library(ggplot2)

#Step 2 Anfrage stellen
      
      resp <- GET("https://api.open-meteo.com/v1/forecast?latitude=53.55&longitude=9.99&hourly=windspeed_10m")

#Step 3 Daten für Windgeschwindigkeit auslesen

      windspeed10m <- rawToChar(resp$content) %>% fromJSON()
      
      time <- windspeed10m[["hourly"]][1]
      windspeed_10m <- windspeed10m[["hourly"]][2]
      
      Geschwindigkeitsdaten <- data.frame(time, windspeed_10m) %>% head(n = 40)
      
      
#Step 4 Visualisierung
      
      Geschwindigkeitsdaten %>%
        
      ggplot(aes(x = time, y = windspeed_10m)) +
      geom_col(fill = "#2DC6D6") + 

      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      theme(axis.text.y = element_text(angle = 45, hjust = 1)) +
        
      labs(
          title    = "Windgeschwindigkeiten in Hamburg",
          subtitle = "Stündlich gemessen vom 28.04.2023 0:00 Uhr bis 29.04.2023 15:00 Uhr",
          x = "Zeitpunkt der Messung",
          y = "Windgeschwindigkeit in km/h"
          )