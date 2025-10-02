# R penguins model api

```
├── api.R # API code
├── plumber.R # plumber API code
├── model.R # model code 
├── penguin_model.rds
├── model_features.rds
├── api.Rproj
├── models/ # model folder
│   └── penguin_model/
│       └── 20250924T152049Z-cca3d
├── my-db.duckdb # duckdb database
├── README.md
├── renv/ # pkgs 
└── renv.lock # depenencies 
```

The code below will create the `vetiver` model and a `plumber` API. 

## Model (`model.R`)

```r
# pkgs  ----
library(palmerpenguins)
library(dplyr)
library(duckdb)
library(fastDummies)

# load data and build model ----
penguins_data <- palmerpenguins::penguins
con <- DBI::dbConnect(duckdb::duckdb(), "my-db.duckdb")
duckdb::duckdb_register(con, "penguins_data", penguins_data)
DBI::dbExecute(con, "CREATE OR REPLACE TABLE penguins AS SELECT * FROM penguins_data")
df <- DBI::dbGetQuery(con, "SELECT * FROM penguins") |>
  na.omit()
# disconnect
DBI::dbDisconnect(con)
# model 
X <- df |>
  dplyr::select(bill_length_mm, species, sex) |>
  fastDummies::dummy_cols(select_columns = c("species", "sex"), remove_first_dummy = TRUE) |>
  dplyr::select(-species, -sex)
y <- df$body_mass_g
model <- lm(y ~ ., data = X)

# create vetiver model -----
v <- vetiver::vetiver_model(model, model_name = "penguin_model")

# write to board -----
model_board <- pins::board_folder("./models")
vetiver::vetiver_pin_write(model_board, v)

# Save model
saveRDS(model, "penguin_model.rds")
saveRDS(names(X), "model_features.rds")
```

## API (`api.R`)

```r
# pkgs ----
library(vetiver)
library(pins)

# create model
source("model.R")

# connect to model board ----
model_board <- pins::board_folder("models/")

# read pinned vetiver model ----
v <- vetiver::vetiver_pin_read(model_board, "penguin_model")

# turn model into API ----
app <- plumber::pr() |> vetiver::vetiver_api(v)

# start vetiver API server ----
app |> plumber::pr_run(port = 8080, host = "127.0.0.1")
```


## Plumber (`plumber.R`)

```r
# pkgs  ----
library(plumber)
library(vetiver)
library(pins)
library(plumber)
library(jsonlite)

# Load pre-trained model
model <- readRDS("penguin_model.rds")
model_features <- readRDS("model_features.rds")

#* @apiTitle Penguin Mass Predictor API
#* @apiDescription API for predicting penguin body mass
#* @apiVersion 1.0.0

#* Health check
#* @get /ping
function() {
  list(status = "healthy", timestamp = Sys.time())
}

#* Predict penguin mass
#* @param req The request object
#* @post /predict
function(req) {
  body <- jsonlite::fromJSON(req$postBody)
  
  # Handle single or batch predictions
  input_data <- if (!is.list(body) || is.null(names(body))) body else list(body)
  
  predictions <- lapply(input_data, function(single_input) {
    pred_df <- data.frame(
      bill_length_mm = as.numeric(single_input$bill_length_mm),
      species_Chinstrap = as.numeric(single_input$species_Chinstrap),
      species_Gentoo = as.numeric(single_input$species_Gentoo),
      sex_male = as.numeric(single_input$sex_male)
    )
    
    prediction <- predict(model, newdata = pred_df)
    return(as.numeric(prediction))
  })
  
  list(.pred = unlist(predictions))
}

# Create and run API
pr("api.R") |>
  pr_run(port = 8080, host = "127.0.0.1")
```
