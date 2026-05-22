library(shiny)
library(bslib)
library(bsicons)
library(httr2)

api_url <- "http://127.0.0.1:8080/predict"

ui <- page_sidebar(
  title = "Penguin Mass Predictor",
  theme = bs_theme(bootswatch = "sketchy"),
  sidebar = sidebar(
    sliderInput(inputId = "bill_length", 
      label = "Bill Length (mm)",
      min = 30, 
      max = 60, 
      value = 45, 
      step = 1),
    selectInput(inputId = "sex", 
      label = "Sex", 
      choices = c("Male", "Female"), 
      selected = "Male"),
    selectInput(
      inputId = "species",
      label = "Species",
      choices = c("Adelie", "Chinstrap", "Gentoo"),
      selected = "Adelie"),
    actionButton(
      inputId = "predict", 
      label = "Predict", 
      class = "btn-primary")
  ),
  
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
          min_height = "200px",
        )
      )
    ),
    col_widths = c(7, 5)
  )
)

server <- function(input, output) {
  
  vals <- reactive({
    data.frame(
      bill_length_mm = input$bill_length,
      species = input$species,
      sex = tolower(input$sex)
    )
  })
  
  pred <- reactive({
    tryCatch({
      # loading notification
    showNotification("Predicting penguin mass...", 
                     type = "default", duration = 10)
        
    request_data <- vals()
      
    response <- httr2::request(api_url) |>
      httr2::req_method("POST") |>
      httr2::req_body_json(request_data, auto_unbox = FALSE) |>  
      httr2::req_perform() |>
      httr2::resp_body_json()
        
    # success notification
    showNotification("✅ Prediction successful!", 
                     type = "default", duration = 10)
        
    response$.pred[[1]]
        
    }, error = function(e) {
      error_msg <- conditionMessage(e)
      
      # error message
      if (grepl("Connection refused|couldn't connect", error_msg, ignore.case = TRUE)) {
        user_msg <- "API not available - is the server running on port 8080?"
      } else if (grepl("timeout|timed out", error_msg, ignore.case = TRUE)) {
        user_msg <- "Request timed out - API may be overloaded"
      } else {
        user_msg <- paste("API Error:", substr(error_msg, 1, 50))
      }
      
      # error notification
      showNotification(paste("❌", user_msg), type = "warn", duration = 10)
      
      # display error message
      paste("❌", user_msg)
      })
    }) |> 
    bindEvent(input$predict, ignoreInit = TRUE)

  output$pred <- renderText({
    prediction <- pred()
    
    # check for prediction 
    if (is.numeric(prediction)) {
      paste(round(prediction, 1), "grams")
    } else {
      # error message 
      prediction
    }
  })
  
  output$vals <- renderPrint({
    vals()
    })
  
}

shinyApp(ui = ui, server = server)