# R Logging App (lab4)

This directory contains an R Shiny app to demonstrate logging from lab 4 of [DevOps for Data Science.](https://do4ds.com/chapters/sec1/1-4-monitor-log.html) 

## Running the app

To run the application, launch the api from lab 3 by navigating to `do4ds-labs/_labs/lab3/R/api/` and running `mod-api.R`.

```r
source("do4ds-labs/_labs/lab3/R/api/api.R")
```

run the app:

```r
install.packages('shiny')
shiny::runApp(appDir = ".")
```