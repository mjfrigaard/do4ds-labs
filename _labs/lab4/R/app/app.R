# pkgs ----
library(shiny)
library(bslib)
library(bsicons)
library(httr2)
library(logger)
library(jsonlite)

# configure logging ----
logger::log_threshold(level = "INFO")
logger::log_appender(appender = appender_tee(file = "shiny_app.log"))
logger::log_formatter(logger::formatter_glue_or_sprintf)

# session tracking ----
api_url <- "http://127.0.0.1:8080/predict"

ui <- page_sidebar(
  title = "Penguin Mass Predictor",
  theme = bs_theme(bootswatch = "sketchy"),
  
  # logging status indicator ----
  div(
    style = "position: fixed; top: 10px; right: 10px; z-index: 1000; color: #fff;",
    strong("Session", textOutput("log_status", inline = TRUE))
  ),
  
  sidebar = sidebar(
    sliderInput(
      inputId = "bill_length", 
      label = "Bill Length (mm)",
      min = 30, 
      max = 60, 
      value = 45, 
      step = 1
    ),
    selectInput(
      inputId = "sex", 
      label = "Sex", 
      choices = c("Male", "Female"), 
      selected = "Male"
    ),
    selectInput(
      inputId = "species",
      label = "Species",
      choices = c("Adelie", "Chinstrap", "Gentoo"),
      selected = "Adelie"
    ),
    actionButton(
      inputId = "predict", 
      label = "Predict", 
      class = "btn-primary"
    )
  ),
  
  # main content -----
  layout_columns(
    card(
      card_header("Penguin Parameters"),
      card_body(
        verbatimTextOutput(outputId = "vals")
      )
    ),
    card(
      card_header("Predicted Mass"),
      card_body(
        value_box(
          showcase_layout = "left center",
          title = "Grams",
          value = textOutput(outputId = "pred"),
          showcase = bs_icon("graph-up"),
          max_height = "200px",
          min_height = "200px"
        )
      )
    ),
    col_widths = c(6, 6),
    row_heights = c(3, 1)
  ),
  
  # system Status ----
  layout_columns(
    card(
      card_header("System Status"),
      card_body(
        h5("API Status:"),
        textOutput("api_health"),
        h5("Recent Logs:"),
        div(
          style = "font-family: 'Ubuntu Mono', monospace; font-size: 12px; background-color: #f8f9fa; padding: 10px; border-radius: 5px;",
          verbatimTextOutput("recent_logs", placeholder = TRUE)
        ),
        h6(
          "Last updated:", 
          textOutput("log_timestamp", inline = TRUE)
        ),
        style = "max-height: 350px; overflow-y: auto;"
      )
    ),
    col_widths = c(12),
    height = "300px" 
  )
)

server <- function(input, output, session) {
  
  # log app startup ----
  observe({
    logger::log_info(
      "Shiny app started - Session: {session$token} - Host: {session$clientData$url_hostname}"
    )
  }, priority = 1000)
  
  # reactive file reader for log monitoring ----
  log_file_content <- reactiveFileReader(
    intervalMillis = 1000,
    session = session,
    filePath = "shiny_app.log",
    readFunc = function(filePath) {
      if (file.exists(filePath)) {
        lines <- readLines(filePath, warn = FALSE)
        mod_time <- file.mtime(filePath)
        
        list(
          lines = lines,
          last_mod = mod_time,
          total_lines = length(lines)
        )
      } else {
        list(
          lines = character(0),
          last_mod = Sys.time(),
          total_lines = 0
        )
      }
    }
  )
  
  # user interactions ----
  observe({
    logger::log_debug(
      "User input changed - Session: {session$token} - bill_length: {input$bill_length} - species: {input$species} - sex: {input$sex}"
    )
  }) |> 
    throttle(2000)  
  
  # reactive values ----
  vals <- reactive({
    bill_length <- input$bill_length
    species <- input$species
    sex <- input$sex
    
    # input validation ----
    if (bill_length < 30 || bill_length > 60) {
      logger::log_warn(
        "Bill length out of typical range - Session: {session$token} - bill_length: {bill_length}"
      )
    }
    
    if (is.null(species) || is.null(sex)) {
      logger::log_error(
        "Missing required inputs - Session: {session$token} - species_null: {is.null(species)} - sex_null: {is.null(sex)}"
      )
      return(NULL)
    }
    
    # prepare data ----
    data <- data.frame(
      bill_length_mm = bill_length,
      species = species,
      sex = tolower(sex)
    )
    
    logger::log_debug(
      "Input data prepared - Session: {session$token} - data: {jsonlite::toJSON(data, auto_unbox = TRUE)}"
    )
    
    return(data)
  })
  
  # api health check ----
  api_health <- reactive({
    tryCatch({
      logger::log_debug("Checking API health - Session: {session$token}")
      
      response <- httr2::request("http://127.0.0.1:8080/ping") |>
        httr2::req_timeout(5) |>
        httr2::req_perform()
      
      if (httr2::resp_status(response) == 200) {
        logger::log_info("API health check successful - Session: {session$token}")
        return("✅ API Online")
      } else {
        logger::log_warn(
          "API health check returned non-200 status - Session: {session$token} - status: {httr2::resp_status(response)}"
        )
        return("⚠️ API Issues")
      }
    }, error = function(e) {
      logger::log_error(
        "API health check failed - Session: {session$token} - error: {conditionMessage(e)}"
      )
      return("❌ API Offline")
    })
  })
  
  # prediction with logging ----
  pred <- reactive({
    request_start <- Sys.time()
    request_data <- vals()
    
    if (is.null(request_data)) {
      logger::log_error(
        "Cannot make prediction with invalid inputs - Session: {session$token}"
      )
      return("❌ Invalid inputs")
    }
    
    logger::log_info(
      "Starting prediction request - Session: {session$token} - request_data: {jsonlite::toJSON(request_data, auto_unbox = TRUE)}"
    )
    
    tryCatch({
      showNotification(
        "Predicting penguin mass...", 
        type = "default", 
        duration = 3
      )
      
      response <- httr2::request(api_url) |>
        httr2::req_method("POST") |>
        httr2::req_body_json(request_data, auto_unbox = FALSE) |>
        httr2::req_timeout(30) |>
        httr2::req_perform()
      
      response_time <- as.numeric(
        difftime(Sys.time(), request_start, units = "secs")
      )
      response_data <- httr2::resp_body_json(response)
      
      # Extract prediction - handle different response formats ----
      prediction_value <- if (is.list(response_data$.pred)) {
        # If .pred is a list, get first element
        as.numeric(response_data$.pred[[1]])
      } else {
        # If .pred is already numeric
        as.numeric(response_data$.pred[1])
      }
      
      logger::log_info(
        "Prediction successful - Session: {session$token} - response_time_sec: {round(response_time, 3)} - prediction: {prediction_value}"
      )
      
      # performance monitoring
      if (response_time > 5) {
        logger::log_warn(
          "Slow API response - Session: {session$token} - response_time_sec: {response_time}"
        )
      }
      
      showNotification(
        "✅ Prediction successful!", 
        type = "message", 
        duration = 3
      )
      
      return(prediction_value)
      
    }, error = function(e) {
      error_msg <- conditionMessage(e)
      response_time <- as.numeric(
        difftime(Sys.time(), request_start, units = "secs")
      )
      
      logger::log_error(
        "Prediction request failed - Session: {session$token} - error: {error_msg} - response_time_sec: {round(response_time, 3)}"
      )
      
      # classify error types ----
      if (grepl("Connection refused|couldn't connect", error_msg, ignore.case = TRUE)) {
        user_msg <- "API not available - is the server running on port 8080?"
        logger::log_error("API connection refused - Session: {session$token}")
      } else if (grepl("timeout|timed out", error_msg, ignore.case = TRUE)) {
        user_msg <- "Request timed out - API may be overloaded"
        logger::log_warn("API timeout occurred - Session: {session$token}")
      } else {
        user_msg <- paste("API Error:", substr(error_msg, 1, 50))
        logger::log_error(
          "Unknown API error - Session: {session$token} - error: {error_msg}"
        )
      }
      
      showNotification(
        paste("❌", user_msg), 
        type = "error", 
        duration = 5
      )
      return(paste("❌", user_msg))
    })
  }) |> 
    bindEvent(input$predict, ignoreInit = TRUE)
  
  # outputs ----
  output$pred <- renderText({
    prediction <- pred()
    
    if (is.numeric(prediction)) {
      result <- paste(round(prediction, 1), "grams")
      logger::log_info(
        "Displaying prediction to user - Session: {session$token} - display_value: {result}"
      )
      return(result)
    } else {
      logger::log_debug(
        "Displaying error message to user - Session: {session$token} - message: {prediction}"
      )
      return(as.character(prediction))
    }
  })
  
  output$vals <- renderPrint({
    data <- vals()
    if (!is.null(data)) {
      logger::log_debug("Displaying input values to user - Session: {session$token}")
      return(data)
    } else {
      return("Invalid inputs")
    }
  })
  
  output$api_health <- renderText({
    api_health()
  })
  
  output$log_status <- renderText({
    paste("Token:", substr(session$token, 1, 8))
  })
  
  output$recent_logs <- renderText({
    log_data <- log_file_content()
    
    if (length(log_data$lines) > 0) {
      recent_lines <- if (log_data$total_lines > 5) {
        tail(log_data$lines, 5)
      } else {
        log_data$lines
      }
      
      logger::log_debug(
        "Updating recent logs display - Session: {session$token} - showing {length(recent_lines)} lines"
      )
      
      paste(recent_lines, collapse = "\n")
    } else {
      "No logs available"
    }
  })
  
  output$log_timestamp <- renderText({
    log_data <- log_file_content()
    format(log_data$last_mod, "%Y-%m-%d %H:%M:%S")
  })
  
  # log session end ----
  session$onSessionEnded(function() {
    logger::log_info("User session ended - Session: {session$token}")
  })
}

# log app startup ----
logger::log_info(
  "Shiny application initialized - timestamp: {Sys.time()} - r_version: {R.version.string}"
)

shinyApp(ui = ui, server = server)