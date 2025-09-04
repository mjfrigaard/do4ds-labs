# Logging App (lab4)

This directory contains an R Shiny app to demonstrate logging from lab 4 of [DevOps for Data Science.](https://do4ds.com/chapters/sec1/1-4-monitor-log.html) 

## Running app

To run the application, the api from lab 3 must be running: 

```r
# nevigate to ~/projects/books/do4ds-labs/_labs/lab3/R/api/
# run mod-api.R
```

```r
# run the app
install.packages('shiny')
shiny::runApp(appDir = ".")
```