# Code extracted from r_model.qmd (run by .github/workflows/publish.yml)
library(palmerpenguins)
library(duckdb)
library(DBI)
library(dplyr)
library(vetiver)
library(pins)

con <- DBI::dbConnect(duckdb::duckdb(), "R/my-db.duckdb")

duckdb::duckdb_register(con, "penguins_raw", palmerpenguins::penguins)

DBI::dbExecute(
  con,
  "CREATE OR REPLACE TABLE penguins AS SELECT * FROM penguins_raw"
)

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

nrow(df)
head(df, 3)

model <- lm(body_mass_g ~ bill_length_mm + species + sex, data = df)

print(formula(model))
print(coef(model))

v <- vetiver::vetiver_model(
  model,
  model_name = "penguin_lab07_model",
  description = "Linear model predicting penguin body mass from bill length, species, and sex",
  save_prototype = TRUE  
)

print(v$prototype)

model_board <- pins::board_folder("R/models")
vetiver::vetiver_pin_write(model_board, v)

# install.packages("paws.storage")

if (Sys.getenv("USE_S3") == "true") {
  model_board <- pins::board_s3(
    bucket = "penguin-vetiver-model-data",
    prefix = "R/models/",
    region = Sys.getenv("AWS_REGION", "us-east-1")
  )
} else {
  model_board <- pins::board_folder("R/models")
}

vetiver::vetiver_pin_write(model_board, v)

pins::pin_list(model_board)

if (Sys.getenv("USE_S3") == "true") {
  model_board <- pins::board_s3(
    bucket = "penguin-vetiver-model-data",
    prefix = "R/models/",
    region = Sys.getenv("AWS_REGION", "us-east-1")
  )
} else {
  model_path <- Sys.getenv("MODEL_PATH", unset = "R/models")
  model_board <- pins::board_folder(model_path)
}

# read the pinned model
model <- vetiver::vetiver_pin_read(model_board, "penguin_lab07_model")

cat("Model type:", class(model$model)[1], "\n")
cat("Model loaded successfully from",
    if(Sys.getenv("USE_S3") == "true") "S3" else "local", "\n")

