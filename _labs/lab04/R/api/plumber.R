# pkgs ----
library(vetiver)
library(pins)
library(plumber2)

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

# HELPER FUNCTION ------------------------------

prep_pred_data <- function(input_data) {
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

# in plumber2, POST handler signatures use:
#   body     - request body, already parsed from JSON (no jsonlite needed)
#   response - response object for setting status codes
# GET handlers need no special arguments unless using query params.

handle_ping <- function() {
  list(
    status = "alive",
    timestamp = Sys.time()
  )
}

handle_health <- function() {
  list(
    status = "healthy",
    timestamp = Sys.time(),
    model_name = v$model_name,
    model_version = v$metadata$version,
    r_version = R.version.string
  )
}

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

handle_predict <- function(body, response) {
  result <- tryCatch({

    if (is.list(body) && !is.data.frame(body)) {
      body <- as.data.frame(body)
    }

    pred_data <- prep_pred_data(body)
    prediction <- predict(v, pred_data)

    if (is.data.frame(prediction) && ".pred" %in% names(prediction)) {
      list(.pred = prediction$.pred)
    } else {
      list(.pred = as.numeric(prediction))
    }

  }, error = function(e) {
    response$status <- 500L
    list(
      error = conditionMessage(e),
      timestamp = as.character(Sys.time())
    )
  })

  return(result)
}

handle_predict_validated <- function(body, response) {
  result <- tryCatch({

    required_fields <- c("bill_length_mm", "species", "sex")
    missing_fields <- setdiff(required_fields, names(body))

    if (length(missing_fields) > 0) {
      response$status <- 400L
      return(list(
        error = "Missing required fields",
        missing = missing_fields,
        hint = "Required fields: bill_length_mm, species, sex"
      ))
    }

    valid_species <- levels(v$prototype$species)
    if (!body$species %in% valid_species) {
      response$status <- 400L
      return(list(
        error = "Invalid species",
        provided = body$species,
        valid_options = valid_species
      ))
    }

    valid_sex <- levels(v$prototype$sex)
    if (!body$sex %in% valid_sex) {
      response$status <- 400L
      return(list(
        error = "Invalid sex",
        provided = body$sex,
        valid_options = valid_sex
      ))
    }

    if (!is.numeric(body$bill_length_mm) ||
        body$bill_length_mm < 30 ||
        body$bill_length_mm > 60) {
      response$status <- 400L
      return(list(
        error = "bill_length_mm must be numeric between 30 and 60",
        provided = body$bill_length_mm,
        valid_range = c(30, 60)
      ))
    }

    pred_data <- prep_pred_data(body)
    prediction <- predict(v, pred_data)

    list(
      prediction = as.numeric(prediction),
      input = body,
      model_version = v$metadata$version,
      timestamp = Sys.time()
    )

  }, error = function(e) {
    response$status <- 500L
    list(
      error = conditionMessage(e),
      timestamp = as.character(Sys.time())
    )
  })

  return(result)
}

handle_predict_batch <- function(body, response) {
  result <- tryCatch({

    if (!is.data.frame(body)) {
      body <- as.data.frame(body)
    }

    pred_data <- prep_pred_data(body)
    predictions <- predict(v, pred_data)

    list(
      predictions = as.numeric(predictions),
      count = nrow(pred_data),
      timestamp = Sys.time()
    )

  }, error = function(e) {
    response$status <- 500L
    list(
      error = conditionMessage(e),
      timestamp = as.character(Sys.time())
    )
  })

  return(result)
}

# API SETUP -------------------------------------
# api() replaces pr(); api_get()/api_post() replace pr_get()/pr_post().
# JSON is the default serializer — no serializer argument needed.
# api_doc_add() sets the OpenAPI info block so Swagger UI can load the spec.

app <- plumber2::api() |>
  plumber2::api_doc_add(
    doc = plumber2::openapi(
      info = plumber2::openapi_info(
        title       = "Penguin Mass Predictor API",
        description = "Predict penguin body mass from bill length, species, and sex.",
        version     = "1.0.0"
      )
    ),
    overwrite = TRUE,
    subset    = "info"
  ) |>
  plumber2::api_get(path = "/ping",            handler = handle_ping) |>
  plumber2::api_get(path = "/health",          handler = handle_health) |>
  plumber2::api_get(path = "/model-prototype", handler = handle_model_prototype) |>
  plumber2::api_get(path = "/model-info",      handler = handle_model_info) |>
  plumber2::api_get(path = "/input-schema",    handler = handle_input_schema) |>
  plumber2::api_post(path = "/predict",            handler = handle_predict) |>
  plumber2::api_post(path = "/predict-validated",  handler = handle_predict_validated) |>
  plumber2::api_post(path = "/predict-batch",      handler = handle_predict_batch)

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

app |> plumber2::api_run(host = "127.0.0.1", port = 8080)
