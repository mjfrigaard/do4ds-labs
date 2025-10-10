# pkgs
library(vetiver)
library(pins)

# connect to model board
model_board <- pins::board_folder("../../../lab2/R/models/")

# read pinned vetiver model
v <- vetiver::vetiver_pin_read(model_board, "penguin_model")

# use plumber/vetiver to create router/create API
app <- plumber::pr() |> vetiver::vetiver_api(v)

# run the api
app |> plumber::pr_run(port = 8080, host = "127.0.0.1")
