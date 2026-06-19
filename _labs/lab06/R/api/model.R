# pkgs ----
library(palmerpenguins)
library(duckdb)
library(DBI)
library(dplyr)
library(vetiver)
library(pins)

# connect to duckdb ----
con <- DBI::dbConnect(duckdb::duckdb(), "my-db.duckdb")

# register the penguins data.frame directly with duckdb ----
duckdb::duckdb_register(con, "penguins_raw", palmerpenguins::penguins)

# create persistent table in duckdb ----
DBI::dbExecute(
  con,
  "CREATE OR REPLACE TABLE penguins AS SELECT * FROM penguins_raw"
)

# query and filter penguins data ----
df <- DBI::dbGetQuery(
  con,
  "SELECT bill_length_mm, species, sex, body_mass_g 
   FROM penguins 
   WHERE body_mass_g IS NOT NULL 
   AND bill_length_mm BETWEEN 30 AND 60
   AND sex IS NOT NULL
   AND species IS NOT NULL"
)

# disconnect from database
DBI::dbDisconnect(con)

cat("Loaded", nrow(df), "observations from DuckDB\n\n")

# train the model ----
# use the original categorical variables (i.e., let R handle the 
# dummy variable creation automatically)
model <- lm(body_mass_g ~ bill_length_mm + species + sex, data = df)

cat("\n=== Model Training Complete ===\n")
cat("Formula:\n")
print(formula(model))
cat("\nCoefficients:\n")
print(coef(model))
cat("===============================\n\n")

# create vetiver model ----
v <- vetiver::vetiver_model(
  model,
  model_name = "penguin_model",
  description = "Linear model predicting penguin body mass from bill length, species, and sex",
  # save the expected input format
  save_prototype = TRUE  
)

cat("Vetiver prototype (API will expect this format):\n")
print(v$prototype)
cat("\n")

# write model to board ----
model_board <- pins::board_folder("./models")
vetiver::vetiver_pin_write(model_board, v)

# print confirmation messages ----
cat("✓ Model trained and pinned successfully\n")
cat("  Model name:", v$model_name, "\n")
cat("  Version:", v$metadata$version, "\n")
cat("  Pin location: ./models/penguin_model\n")