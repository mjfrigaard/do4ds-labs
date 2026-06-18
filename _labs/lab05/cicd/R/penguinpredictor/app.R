library(shiny)
library(bslib)
library(httr2)

pkgload::load_all(".", quiet = TRUE)

# API configuration
api_url  <- "http://127.0.0.1:8080/predict"
ping_url <- "http://127.0.0.1:8080/ping"

# Initialize logging
log_file_path <- setup_logging()
logger::log_info("Shiny for R application initialized")

ui <- page_fluid(
  div(
    strong("Session: "),
    textOutput(outputId = "session_display", inline = TRUE),
    style = paste0(
      "position: fixed; top: 10px; right: 10px; z-index: 1000;",
      " color: #333; background: #fff; padding: 5px;",
      " border-radius: 3px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"
    )
  ),
  h1("Penguin Mass Predictor"),
  layout_columns(
    card(
      card_header("Inputs"),
      sliderInput("bill_length", "Bill Length (mm)", min = 30, max = 60, value = 45, step = 0.1),
      selectInput("sex",     "Sex",     choices = c("Male", "Female")),
      selectInput("species", "Species", choices = c("Adelie", "Chinstrap", "Gentoo")),
      actionButton("predict", "Predict")
    ),
    card(
      card_header("Results"),
      h3("Input Values"),
      div(
        verbatimTextOutput("vals_out"),
        style = paste0(
          "font-family: 'Monaco', 'Courier New', monospace; font-size: 12px;",
          " background-color: #f8f9fa; padding: 10px; border-radius: 5px;",
          " max-height: 250px; overflow-y: auto; border: 1px solid #dee2e6;"
        )
      ),
      h3("Predicted Mass"),
      div(
        textOutput("pred_out"),
        style = paste0(
          "font-size: 24px; font-weight: bold; text-align: center;",
          " padding: 15px; color: #0066cc;"
        )
      )
    ),
    col_widths = c(4, 8)
  ),
  card(
    card_header("System Status"),
    card_body(
      layout_columns(
        div(
          h4("API Health Check:"),
          br(),
          textOutput("api_status"),
          br(),
          h4("Recent Logs:"),
          div(
            verbatimTextOutput("recent_logs_display"),
            style = paste0(
              "font-family: 'Monaco', 'Courier New', monospace; font-size: 12px;",
              " background-color: #f8f9fa; padding: 10px; border-radius: 2px;",
              " max-height: 250px; overflow-y: auto; border: 2px solid #dee2e6;"
            )
          ),
          p(
            "Last updated: ",
            textOutput("log_timestamp", inline = TRUE),
            style = "margin-top: 5px; color: #6c757d; font-size: 12px;"
          )
        ),
        col_widths = 12
      )
    )
  )
)

server <- function(input, output, session) {
  session_id <- paste0("r_", substr(session$token, 1, 8))
  logger::log_info("New session started - Session: {session_id}")

  onSessionEnded(function() {
    logger::log_info("Session ended - Session: {session_id}")
  })

  vals <- reactive({
    bill_length <- input$bill_length
    species     <- input$species
    sex         <- input$sex

    errors <- validate_inputs(bill_length, species, sex)
    for (err in errors) {
      logger::log_warn("Validation error - Session: {session_id} - {err}")
    }

    d <- encode_inputs(bill_length, species, sex)
    logger::log_debug("Input data prepared - Session: {session_id} - data: {jsonlite::toJSON(d, auto_unbox = TRUE)}")
    d
  })

  api_health_check <- reactive({
    tryCatch({
      start_time <- proc.time()[["elapsed"]]
      resp <- request(ping_url) |>
        req_timeout(5) |>
        req_error(is_error = \(r) FALSE) |>
        req_perform()
      response_time <- proc.time()[["elapsed"]] - start_time

      if (resp_status(resp) == 200L) {
        logger::log_info("API health check successful - Session: {session_id} - response_time: {round(response_time, 3)}s")
        paste0("API is running (ping: ", resp_body_string(resp), ") - ", round(response_time, 2), "s")
      } else {
        logger::log_warn("API ping failed - Session: {session_id} - status: {resp_status(resp)}")
        paste0("API ping failed: ", resp_status(resp))
      }
    }, error = function(e) {
      logger::log_error("API connection refused - Session: {session_id} - error: {e$message}")
      "Cannot connect to API - is it running on port 8080?"
    })
  })

  pred <- eventReactive(input$predict, {
    request_start  <- proc.time()[["elapsed"]]
    data_to_send   <- vals()

    logger::log_info("Starting prediction request - Session: {session_id} - request_data: {jsonlite::toJSON(data_to_send, auto_unbox = TRUE)}")

    tryCatch({
      resp <- request(api_url) |>
        req_body_json(list(data_to_send)) |>
        req_timeout(30) |>
        req_error(is_error = \(r) FALSE) |>
        req_perform()
      response_time <- proc.time()[["elapsed"]] - request_start

      if (resp_status(resp) == 200L) {
        prediction <- parse_prediction(resp_body_json(resp))
        logger::log_info("Prediction successful - Session: {session_id} - response_time: {round(response_time, 3)}s - prediction: {prediction}")
        if (response_time > 5) {
          logger::log_warn("Slow API response - Session: {session_id} - response_time: {round(response_time, 3)}s")
        }
        prediction
      } else {
        error_msg <- paste0("API Error ", resp_status(resp), ": ", resp_body_string(resp))
        logger::log_error("Prediction request failed - Session: {session_id} - status: {resp_status(resp)}")
        error_msg
      }
    }, error = function(e) {
      logger::log_error("Prediction error - Session: {session_id} - error: {e$message}")
      paste0("Error: ", e$message)
    })
  })

  log_file_content <- reactiveFileReader(
    intervalMillis = 1000,
    session        = session,
    filePath       = log_file_path,
    readFunc       = function(path) {
      tryCatch({
        lines <- readLines(path, warn = FALSE)
        list(lines = lines, last_modified = Sys.time(), total_lines = length(lines))
      }, error = function(e) {
        list(lines = character(0), last_modified = Sys.time(), total_lines = 0L)
      })
    }
  )

  output$session_display <- renderText(substr(session_id, 1, 8))

  output$vals_out <- renderPrint(vals())

  output$api_status <- renderText(api_health_check())

  output$pred_out <- renderText({
    result <- pred()
    if (is.numeric(result)) {
      paste0(round(result, 1), " grams")
    } else {
      as.character(result)
    }
  })

  output$recent_logs_display <- renderText({
    log_data <- log_file_content()
    lines    <- log_data$lines
    if (length(lines) > 0L) {
      paste(tail(lines, 10L), collapse = "\n")
    } else {
      "No logs available yet..."
    }
  })

  output$log_timestamp <- renderText({
    format(log_file_content()$last_modified, "%Y-%m-%d %H:%M:%S")
  })
}

logger::log_info("Shiny for R application created successfully")
shinyApp(ui, server)
