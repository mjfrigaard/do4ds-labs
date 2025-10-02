# pkgs ----
library(vetiver)
library(pins)

# create model
source("model.R")

# connect to model board ----
# the previous model is stored in "../../../lab2/R/models/"
# but we have a local version created from model.R
model_board <- pins::board_folder("models/")

# read pinned vetiver model ----
v <- vetiver::vetiver_pin_read(model_board, "penguin_model")

# turn model into API ----
# use plumber to create router and API
app <- plumber::pr() |> vetiver::vetiver_api(v)

# start vetiver API server ----
# this keeps running while app is launched 
app |> plumber::pr_run(port = 8080, host = "127.0.0.1")
