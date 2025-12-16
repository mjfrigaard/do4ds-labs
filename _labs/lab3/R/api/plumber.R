#  Penguin Mass Predictor API
# 
#  API for predicting penguin body mass from bill length, species, and sex
#  using a linear regression model deployed with vetiver.
# 
#  @apiTitle Penguin Mass Predictor API
#  
#  @apiDescription Predict penguin body mass using bill measurements and characteristics
#  
#  @apiVersion 1.0.0
#  
#  @apiContact list(name = "API Support", email = "support@example.com")
#  
#  @apiLicense list(name = "MIT")

# pkgs ----
library(vetiver)
library(pins)
library(plumber)
library(jsonlite)

# connect to model board ----
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

# HELPER FUNCTIONS ------------------------------

#' Prepare prediction data by converting types
#'
#' Converts incoming JSON data (strings) to the proper R types (factors)
#' that the linear model expects. Uses the prototype stored in the
#' vetiver model to get correct factor levels.
#'
#' @param input_data A data frame with columns: bill_length_mm, species, sex
#'
#' @return A data frame with proper types for model prediction
#'
#' @examples
#' prep_pred_data(data.frame(
#'   bill_length_mm = 45,
#'   species = "Adelie",
#'   sex = "male"
#' ))
#'
prep_pred_data <- function(input_data) {
  # get factor levels from the prototype
  species_levels <- levels(v$prototype$species)
  sex_levels <- levels(v$prototype$sex)
  
  data.frame(
    bill_length_mm = as.numeric(input_data$bill_length_mm),
    species = factor(input_data$species, levels = species_levels),
    sex = factor(input_data$sex, levels = sex_levels),
    stringsAsFactors = FALSE
  )
}

# HANDLERS --------------------------------------

#* Basic health check
#*
#* Simple endpoint to verify the API is running. Returns a minimal response
#* with status and timestamp.
#*
#* @get /ping
#* 
#* @serializer json
#* 
handle_ping <- function() {
  list(
    status = "alive", 
    timestamp = Sys.time()
  )
}

## handle_ping() examples ----
# Using curl:
# curl http://127.0.0.1:8080/ping
#
# Using httr2:
# request("http://127.0.0.1:8080/ping") |> req_perform()

#* Detailed health check
#*
#* Extended health check that includes model metadata, version information,
#* and R version. 
#*
#* @get /health
#* 
#* @serializer json
#* 
handle_health <- function() {
  list(
    status = "healthy",
    timestamp = Sys.time(),
    model_name = v$model_name,
    model_version = v$metadata$version,
    r_version = R.version.string
  )
}

## handle_health() examples ----
# Using curl:
# curl http://127.0.0.1:8080/health

#* Get model prototype information
#*
#* Returns the expected input format for the model, including data types
#* and factor levels. Useful for clients to understand what data to send.
#*
#* @get /model-prototype
#* @serializer json
handle_model_prototype <- function() {
  list(
    prototype = list(
      bill_length_mm = "numeric",
      species = list(
        type = "factor",
        levels = levels(v$prototype$species)
      ),
      sex = list(
        type = "factor", 
        levels = levels(v$prototype$sex)
      )
    ),
    model_class = class(v$model)
  )
}

## handle_model_prototype() examples ----
# Using curl:
# curl http://127.0.0.1:8080/model-prototype

#* Get model information and metadata
#*
#* Returns comprehensive information about the deployed model including
#* name, version, creation date, and required packages.
#*
#* @get /model-info
#* @serializer json
handle_model_info <- function() {
  list(
    model_name = v$model_name,
    model_class = class(v$model)[1],
    version = v$metadata$version,
    created = v$metadata$created,
    required_pkgs = v$metadata$required_pkgs,
    description = v$description %||% "No description available"
  )
}

## handle_model_info() examples ----
# Using curl:
# curl http://127.0.0.1:8080/model-info

#* Get input schema and example
#*
#* Returns documentation about the expected input fields, including
#* types, descriptions, valid values, and an example request.
#*
#* @get /input-schema
#* @serializer json
handle_input_schema <- function() {
  list(
    required_fields = list(
      bill_length_mm = list(
        type = "numeric",
        description = "Bill length in millimeters",
        range = c(30, 60)
      ),
      species = list(
        type = "string (converted to factor)",
        description = "Penguin species",
        valid_values = levels(v$prototype$species)
      ),
      sex = list(
        type = "string (converted to factor)",
        description = "Penguin sex",
        valid_values = levels(v$prototype$sex)
      )
    ),
    example = list(
      bill_length_mm = 45.5,
      species = "Gentoo",
      sex = "male"
    )
  )
}

## handle_input_schema() examples ----
# Using curl:
# curl http://127.0.0.1:8080/input-schema

#* Predict penguin body mass
#*
#* Main prediction endpoint that accepts penguin characteristics and returns
#* predicted body mass in grams. Supports both single predictions and batch
#* predictions (multiple penguins in one request).
#*
#* @post /predict
#* @serializer json
handle_predict <- function(req, res) {
  cat("\n=== /predict called ===\n")
  cat("Raw body:", req$postBody, "\n")
  
  result <- tryCatch({
    # parse JSON
    body <- jsonlite::fromJSON(req$postBody)
    cat("Parsed body:\n")
    print(body)
    
    # handle both single prediction and batch
    if (is.list(body) && !is.data.frame(body)) {
      body <- as.data.frame(body)
    }
    
    # prep data (convert strings to factors)
    pred_data <- prep_pred_data(body)
    cat("Prepared data:\n")
    print(pred_data)
    str(pred_data)
    
    # make prediction
    cat("Calling predict...\n")
    prediction <- predict(v, pred_data)
    cat("Prediction result:\n")
    print(prediction)
    cat("Prediction class:", class(prediction), "\n")
    
    # handle different return types from vetiver
    if (is.data.frame(prediction) && ".pred" %in% names(prediction)) {
      # vetiver format
      response <- list(.pred = prediction$.pred)
    } else if (is.numeric(prediction)) {
      # plain numeric vector 
      response <- list(.pred = as.numeric(prediction))
    } else {
      # fallback
      response <- list(.pred = as.numeric(prediction))
    }
    
    cat("Response:\n")
    print(response)
    cat("=== /predict complete ===\n\n")
    
    return(response)
    
  }, error = function(e) {
    cat("\n!!! ERROR !!!\n")
    cat("Error message:", conditionMessage(e), "\n")
    print(e)
    cat("!!! END ERROR !!!\n\n")
    
    res$status <- 500
    return(list(
      error = conditionMessage(e),
      timestamp = as.character(Sys.time())
    ))
  })
  
  return(result)
}

## handle_predict() examples ----
# Single prediction using curl:
# curl -X POST http://127.0.0.1:8080/predict \
#   -H "Content-Type: application/json" \
#   -d '{"bill_length_mm": 45, "species": "Adelie", "sex": "male"}'
#
# Batch prediction:
# curl -X POST http://127.0.0.1:8080/predict \
#   -H "Content-Type: application/json" \
#   -d '{"bill_length_mm": [45, 50], "species": ["Adelie", "Gentoo"], 
#        "sex": ["male", "female"]}'
#
# Using httr2:
# request("http://127.0.0.1:8080/predict") |>
#   req_body_json(list(
#     bill_length_mm = 45,
#     species = "Adelie",
#     sex = "male"
#   )) |>
#   req_perform() |>
#   resp_body_json()

#* Predict with input validation
#*
#* Enhanced prediction endpoint that validates all inputs before making
#* predictions. Returns detailed error messages if validation fails.
#* Checks for:
#* - Required fields present
#* - Valid species (Adelie, Chinstrap, or Gentoo)
#* - Valid sex (male or female)
#* - Bill length in valid range (30-60mm)
#*
#* @post /predict-validated
#* @serializer json
handle_predict_validated <- function(req, res) {
  cat("\n=== /predict-validated called ===\n")
  
  result <- tryCatch({
    body <- jsonlite::fromJSON(req$postBody)
    
    # validate required fields
    required_fields <- c("bill_length_mm", "species", "sex")
    missing_fields <- setdiff(required_fields, names(body))
    
    if (length(missing_fields) > 0) {
      res$status <- 400
      return(list(
        error = "Missing required fields",
        missing = missing_fields,
        hint = "Required fields: bill_length_mm, species, sex"
      ))
    }
    
    # validate species
    valid_species <- levels(v$prototype$species)
    if (!body$species %in% valid_species) {
      res$status <- 400
      return(list(
        error = "Invalid species",
        provided = body$species,
        valid_options = valid_species
      ))
    }
    
    # validate sex
    valid_sex <- levels(v$prototype$sex)
    if (!body$sex %in% valid_sex) {
      res$status <- 400
      return(list(
        error = "Invalid sex",
        provided = body$sex,
        valid_options = valid_sex
      ))
    }
    
    # validate bill_length_mm
    if (!is.numeric(body$bill_length_mm) || 
        body$bill_length_mm < 30 || 
        body$bill_length_mm > 60) {
      res$status <- 400
      return(list(
        error = "bill_length_mm must be numeric between 30 and 60",
        provided = body$bill_length_mm,
        valid_range = c(30, 60)
      ))
    }
    
    # prepare data
    pred_data <- prep_pred_data(body)
    
    # make prediction
    prediction <- predict(v, pred_data)
    
    list(
      prediction = as.numeric(prediction),
      input = body,
      model_version = v$metadata$version,
      timestamp = Sys.time()
    )
    
  }, error = function(e) {
    cat("Error:", conditionMessage(e), "\n")
    res$status <- 500
    return(list(
      error = conditionMessage(e),
      timestamp = as.character(Sys.time())
    ))
  })
  
  return(result)
}

## handle_predict_validated() examples ----
# Valid request using curl:
# curl -X POST http://127.0.0.1:8080/predict-validated \
#   -H "Content-Type: application/json" \
#   -d '{"bill_length_mm": 45, "species": "Adelie", "sex": "male"}'
#
# Invalid species (will return error):
# curl -X POST http://127.0.0.1:8080/predict-validated \
#   -H "Content-Type: application/json" \
#   -d '{"bill_length_mm": 45, "species": "Emperor", "sex": "male"}'

#* Batch predictions
#*
#* Predict body mass for multiple penguins in a single request.
#* Send arrays of values for each field. All arrays must have the same length.
#*
#* @post /predict-batch
#* @serializer json
handle_predict_batch <- function(req, res) {
  result <- tryCatch({
    body <- jsonlite::fromJSON(req$postBody)
    
    # ensure we have a data frame
    if (!is.data.frame(body)) {
      body <- as.data.frame(body)
    }
    
    # prepare data
    pred_data <- prep_pred_data(body)
    
    # make predictions
    predictions <- predict(v, pred_data)
    
    list(
      predictions = as.numeric(predictions),
      count = nrow(pred_data),
      timestamp = Sys.time()
    )
    
  }, error = function(e) {
    res$status <- 500
    return(list(
      error = conditionMessage(e),
      timestamp = as.character(Sys.time())
    ))
  })
  
  return(result)
}

## handle_predict_batch() examples ----
# Batch prediction using curl:
# curl -X POST http://127.0.0.1:8080/predict-batch \
#   -H "Content-Type: application/json" \
#   -d '{
#     "bill_length_mm": [45, 39, 50],
#     "species": ["Adelie", "Adelie", "Gentoo"],
#     "sex": ["male", "female", "male"]
#   }'
#
# Using httr2:
# request("http://127.0.0.1:8080/predict-batch") |>
#   req_body_json(list(
#     bill_length_mm = c(45, 39, 50),
#     species = c("Adelie", "Adelie", "Gentoo"),
#     sex = c("male", "female", "male")
#   )) |>
#   req_perform() |>
#   resp_body_json()

# API SETUP -------------------------------------
#' Create and configure Plumber API
#'
#' Sets up the API router with all endpoints, OpenAPI specification,
#' and serializers. This follows the Plumber 2.0 functional approach.
#'
app <- plumber::pr() |>
  # set OpenAPI specification
  plumber::pr_set_api_spec(function(spec) {
    spec$info$title <- "Penguin Mass Predictor API"
    spec$info$description <- "API for predicting penguin body mass using a linear regression model trained on the Palmer Penguins dataset. Deployed with vetiver for MLOps best practices."
    spec$info$version <- "1.0.0"
    spec$info$contact <- list(
      name = "API Support",
      email = "support@example.com"
    )
    spec$info$license <- list(
      name = "MIT",
      url = "https://opensource.org/licenses/MIT"
    )
    spec
  }) |>
  # GET endpoints - information retrieval
  plumber::pr_get(
    path = "/ping",
    handler = handle_ping,
    serializer = plumber::serializer_json(),
    tags = "Health"
  ) |>
  plumber::pr_get(
    path = "/health",
    handler = handle_health,
    serializer = plumber::serializer_json(),
    tags = "Health"
  ) |>
  plumber::pr_get(
    path = "/model-prototype",
    handler = handle_model_prototype,
    serializer = plumber::serializer_json(),
    tags = "Model Info"
  ) |>
  plumber::pr_get(
    path = "/model-info",
    handler = handle_model_info,
    serializer = plumber::serializer_json(),
    tags = "Model Info"
  ) |>
  plumber::pr_get(
    path = "/input-schema",
    handler = handle_input_schema,
    serializer = plumber::serializer_json(),
    tags = "Documentation"
  ) |>
  # POST endpoints - predictions
  plumber::pr_post(
    path = "/predict",
    handler = handle_predict,
    serializer = plumber::serializer_json(),
    tags = "Predictions"
  ) |>
  plumber::pr_post(
    path = "/predict-validated",
    handler = handle_predict_validated,
    serializer = plumber::serializer_json(),
    tags = "Predictions"
  ) |>
  plumber::pr_post(
    path = "/predict-batch",
    handler = handle_predict_batch,
    serializer = plumber::serializer_json(),
    tags = "Predictions"
  )

# RUN API ---------------------------------------
cat("\n╔════════════════════════════════════════════════════════╗\n")
cat("║  Penguin Mass Predictor API                            ║\n")
cat("╚════════════════════════════════════════════════════════╝\n\n")
cat("🚀 Starting API server on http://127.0.0.1:8080\n\n")
cat("📖 Documentation:\n")
cat("   Swagger UI: http://127.0.0.1:8080/__docs__/\n")
cat("   ReDoc:      http://127.0.0.1:8080/__docs__/?redoc=1\n\n")
cat("🔍 Available endpoints:\n")
cat("   Health Checks:\n")
cat("     GET  /ping               - Basic health check\n")
cat("     GET  /health             - Detailed health check\n\n")
cat("   Model Information:\n")
cat("     GET  /model-info         - Model metadata\n")
cat("     GET  /model-prototype    - Expected input format\n")
cat("     GET  /input-schema       - Input documentation\n\n")
cat("   Predictions:\n")
cat("     POST /predict            - Single/batch prediction\n")
cat("     POST /predict-validated  - Prediction with validation\n")
cat("     POST /predict-batch      - Batch predictions\n\n")
cat("📊 Model Information:\n")
cat("   Name:    ", v$model_name, "\n")
cat("   Version: ", v$metadata$version, "\n")
cat("   Type:    ", class(v$model)[1], "\n\n")
cat("✨ Ready to serve predictions!\n\n")

# start the server
app |> plumber::pr_run(port = 8080, host = "127.0.0.1")