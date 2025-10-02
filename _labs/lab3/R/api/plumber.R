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
