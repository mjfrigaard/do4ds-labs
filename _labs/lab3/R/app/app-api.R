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
      verbatimTextOutput("vals")
      )
    ),
    card(
      card_header("Predicted Mass"),
      card_body(
        value_box(
          showcase_layout = "left center",
          title = "Grams",
          value = textOutput("pred"),
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
      species_Chinstrap = as.numeric(input$species == "Chinstrap"),
      species_Gentoo = as.numeric(input$species == "Gentoo"),
      sex_male = as.numeric(input$sex == "Male")
    )
  })

  pred <- eventReactive(input$predict, {
      request_data <- vals()
      response <- httr2::request(api_url) |>
        httr2::req_method("POST") |>
        httr2::req_body_json(request_data, auto_unbox = FALSE) |>  
        httr2::req_perform() |>
        httr2::resp_body_json()
      
      response$.pred[1]
    }, ignoreInit = TRUE)

  output$pred <- renderText({
    round(pred(), 1)
  })
  
  output$vals <- renderPrint({
    vals()
    })
  
}

shinyApp(ui = ui, server = server)