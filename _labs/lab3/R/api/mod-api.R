# pkgs
library(vetiver)
library(pins)

# connect to lab3 model board ----
model_board <- pins::board_folder("models/")

# read pinned vetiver model ----
v <- vetiver::vetiver_pin_read(model_board, "penguin_model")

# print model info ----
cat("\n=== Model Loaded Successfully ===\n")
cat("Model name:", v$model_name, "\n")
cat("Model class:", class(v$model), "\n")
cat("Prototype (expected input):\n")
print(v$prototype)
cat("Factor levels:\n")
cat("  species:", paste(levels(v$prototype$species), collapse = ", "), "\n")
cat("  sex:", paste(levels(v$prototype$sex), collapse = ", "), "\n")
cat("=================================\n\n")


# plumber ----
app <- plumber::pr() |> vetiver::vetiver_api(v) # create plumber API
app |> plumber::pr_run(port = 8080, host = "127.0.0.1") # run

