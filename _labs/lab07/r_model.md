# R Vetiver Model


This document demonstrates how to create a simple linear regression
model using the `palmerpenguins` dataset, and then turn it into a
`Vetiver` model for deployment using R.

## Load Libraries

``` r
library(palmerpenguins)
library(duckdb)
library(DBI)
library(dplyr)
library(vetiver)
library(pins)
```

## Connect to DuckDB

``` r
con <- DBI::dbConnect(duckdb::duckdb(), "R/my-db.duckdb")

duckdb::duckdb_register(con, "penguins_raw", palmerpenguins::penguins)


DBI::dbExecute(
  con,
  "CREATE OR REPLACE TABLE penguins AS SELECT * FROM penguins_raw"
)
```

Line 3  
Register the `penguins` `data.frame` directly with `duckdb`

Lines 6,9  
Create persistent table in `duckdb`

<!-- -->

    #> [1] 344

## Get Data

``` r
df <- DBI::dbGetQuery(
  con,
  "SELECT bill_length_mm, species, sex, body_mass_g 
   FROM penguins 
   WHERE body_mass_g IS NOT NULL 
   AND bill_length_mm BETWEEN 30 AND 60
   AND sex IS NOT NULL
   AND species IS NOT NULL"
)

DBI::dbDisconnect(con)
```

Below we can see how many rows were loaded from the SQL query, and a
preview of the first three rows of the data frame.

``` r
nrow(df)
```

    #> [1] 333

``` r
head(df, 3)
```

    #>   bill_length_mm species    sex body_mass_g
    #> 1           39.1  Adelie   male        3750
    #> 2           39.5  Adelie female        3800
    #> 3           40.3  Adelie female        3250

## Define Model and Fit

``` r
model <- lm(body_mass_g ~ bill_length_mm + species + sex, data = df)
```

``` r
print(formula(model))
```

    #> body_mass_g ~ bill_length_mm + species + sex

``` r
print(coef(model))
```

    #>      (Intercept)   bill_length_mm speciesChinstrap    speciesGentoo 
    #>       2169.26972         32.53689       -298.76553       1094.86739 
    #>          sexmale 
    #>        547.36692

## Turn into Vetiver Model

``` r
v <- vetiver::vetiver_model(
  model,
  model_name = "penguin_model",
  description = "Linear model predicting penguin body mass from bill length, species, and sex",
  save_prototype = TRUE  
)
```

    #> Registered S3 method overwritten by 'butcher':
    #>   method                 from    
    #>   as.character.dev_topic generics

Check the prototype data that was saved with the model. This is the data
that will be used to validate new data when making predictions with the
model.

``` r
print(v$prototype)
```

    #> # A tibble: 0 × 3
    #> # ℹ 3 variables: bill_length_mm <dbl>, species <fct>, sex <fct>

## Write to Local Board

Write the model to a local board so that it can be used for deployment.
The model will be saved in the `R/models` directory.

``` r
model_board <- pins::board_folder("R/models")
vetiver::vetiver_pin_write(model_board, v)
```

    #> Replacing version '20260709T140004Z-09946' with '20260709T140946Z-09946'
    #> Writing to pin 'penguin_model'
    #> 
    #> Create a Model Card for your published model
    #> • Model Cards provide a framework for transparent, responsible reporting
    #> • Use the vetiver `.Rmd` template as a place to start
