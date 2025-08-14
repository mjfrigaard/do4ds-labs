# pkgs ----
library(vetiver)
library(pins)

# connect to model board ----
model_board <- pins::board_folder("../../../lab2/R/models/")

# read the pinned vetiver model ----
v <- vetiver::vetiver_pin_read(model_board, "penguin_model")

# turn model into API ----
# use plumber to create router and create API
app <- plumber::pr() |> vetiver::vetiver_api(v)

# start the API server ----
# this keeps running
app |> plumber::pr_run(port = 8080, host = "127.0.0.1")
