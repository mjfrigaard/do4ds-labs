library(shiny)
library(bslib)
library(bsicons)
library(httr2)

api_url <- "http://127.0.0.1:8080/predict"

ui <- page_sidebar(
  title = h4(strong("Penguin Mass Predictor "),code("plumber2")),
  theme = bs_theme(bootswatch = "sketchy"),
  sidebar = sidebar(
    sliderInput(
      inputId = "bill_length",
      label = "Bill Length (mm)",
      min = 30, max = 60, value = 45, step = 1
    ),
    selectInput(
      inputId = "sex",
      label = "Sex",
      choices = c("male", "female"),
      selected = "male"
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
  layout_columns(
    card(
      card_header("Penguin Parameters"),
      card_body(verbatimTextOutput(outputId = "vals"))
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
    col_widths = c(7, 5)
  )
)

server <- function(input, output, session) {

  # species and sex sent as strings; prep_pred_data() in the API converts them
  # to factors — no dummy variable encoding needed
  vals <- reactive({
    data.frame(
      bill_length_mm = input$bill_length,
      species = input$species,
      sex = input$sex
    )
  })

  pred <- reactive({
    tryCatch({
      showNotification("Predicting penguin mass...", type = "default", duration = 10)

      response <- httr2::request(api_url) |>
        httr2::req_method("POST") |>
        httr2::req_body_json(vals(), auto_unbox = TRUE) |>
        httr2::req_perform() |>
        httr2::resp_body_json()

      showNotification("Prediction successful!", type = "default", duration = 10)

      response$.pred[[1]]

    }, error = function(e) {
      error_msg <- conditionMessage(e)

      if (grepl("Connection refused|couldn't connect", error_msg, ignore.case = TRUE)) {
        user_msg <- "API not available - is the server running on port 8080?"
      } else if (grepl("timeout|timed out", error_msg, ignore.case = TRUE)) {
        user_msg <- "Request timed out - API may be overloaded"
      } else {
        user_msg <- paste("API Error:", substr(error_msg, 1, 50))
      }

      showNotification(paste("Error:", user_msg), type = "warn", duration = 10)
      paste("Error:", user_msg)
    })
  }) |>
    bindEvent(input$predict, ignoreInit = TRUE)

  output$pred <- renderText({
    p <- pred()
    if (is.numeric(p)) paste(round(p, 1), "grams") else p
  })

  output$vals <- renderPrint(vals())
}

shinyApp(ui = ui, server = server)
