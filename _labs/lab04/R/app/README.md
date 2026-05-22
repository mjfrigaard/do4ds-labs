# R Logging App (lab04)

This directory contains an R Shiny app to demonstrate logging from lab 4 of [DevOps for Data Science.](https://do4ds.com/chapters/sec1/1-4-monitor-log.html) 

## Running the API

To run the application, launch the api from lab 3 by navigating to `do4ds-labs/_labs/lab03/R/api/` and running `plumber.R`.

```r
source("do4ds-labs/_labs/lab03/R/api/plumber.R")
```

## Run the app

```r
install.packages('shiny')
shiny::runApp(appDir = ".")
```
