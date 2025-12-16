# pkgs
library(vetiver)
library(pins)

# connect to model board
model_board <- pins::board_folder("../../../lab2/R/models/")

# read pinned vetiver model
v <- vetiver::vetiver_pin_read(model_board, "penguin_model")

# plumber ----
app <- plumber::pr() |> vetiver::vetiver_api(v) # create plumber API
app |> plumber::pr_run(port = 8080, host = "127.0.0.1") # run

# plumber2 ----
# app <- plumber2::api() |> vetiver::vetiver_api(v) # create plumber2 API
# app |> plumber2::api_run(port = 8080, host = "127.0.0.1") # run
