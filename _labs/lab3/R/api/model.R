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
