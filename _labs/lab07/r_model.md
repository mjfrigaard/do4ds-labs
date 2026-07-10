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

    #> Replacing version '20260710T050819Z-09946' with '20260710T052330Z-09946'
    #> Writing to pin 'penguin_model'
    #> 
    #> Create a Model Card for your published model
    #> • Model Cards provide a framework for transparent, responsible reporting
    #> • Use the vetiver `.Rmd` template as a place to start

## Write to S3 Bucket

We’ll start by storing the necessary environment variables:

1.  Create a `.Renviron` file in your project root:

``` bash
touch .Renviron
```

2.  Place the environment variables in the `.Renviron` file.

``` bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
```

3.  Restart R session to load `.Renviron`.

4.  We can access variables using `Sys.getenv()` to confirm they are
    loaded correctly.

``` r
Sys.getenv("AWS_ACCESS_KEY_ID")
Sys.getenv("AWS_SECRET_ACCESS_KEY")
Sys.getenv("AWS_REGION")
```

5.  Add `.Renviron` to `.gitignore`

Now we’re ready to write the model data to the S3 bucket. You might need
the `paws.storage` package installed to write to the S3 board. Install
it with the following command:

``` r
# install.packages("paws.storage")
```

`pins::board_s3()` will create a connection to the S3 bucket using the
environment variables we set earlier.

``` r
s3_board <- pins::board_s3(
  bucket = "penguin-vetiver-model-data",
  prefix = "R/models/",
  region = Sys.getenv("AWS_REGION"),
  access_key = Sys.getenv("AWS_ACCESS_KEY_ID"),
  secret_access_key = Sys.getenv("AWS_SECRET_ACCESS_KEY")
)

vetiver::vetiver_pin_write(s3_board, v)
```

    #> Creating new version '20260710T052331Z-09946'
    #> Writing to pin 'penguin_model'

We can confirm this with the following commands:

``` r
pins::pin_list(s3_board)
```

    #> [1] "penguin_model"
