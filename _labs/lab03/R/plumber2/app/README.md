# Penguin Mass Predictor App (plumber2)

Shiny application that predicts penguin body mass by calling the plumber2 API in `../api/`. The user selects bill length, species, and sex; the app sends those values to the API and displays the predicted mass in grams.

```
├── app-api.R    # Shiny app
└── app.Rproj
```

## Prerequisites

The API in `../api/` must be running before launching the app. See `../api/README.md` for setup. By default the app expects the API at `http://127.0.0.1:8080`.

Start the API:

```bash
Rscript ../api/plumber.R
```

Start the app:

```bash
Rscript -e "shiny::runApp('app-api.R')"
```

## Inputs

| Input | Type | Values |
|---|---|---|
| Bill Length (mm) | Slider | 30–60, step 1 |
| Sex | Select | `male`, `female` |
| Species | Select | `Adelie`, `Chinstrap`, `Gentoo` |

Sex values are already lowercase in the `selectInput` — no `tolower()` conversion needed before sending to the API.

## How the app calls the API

The `vals()` reactive builds a single-row data frame from the UI inputs and sends it as JSON to `POST /predict`.

```r
vals <- reactive({
  data.frame(
    bill_length_mm = input$bill_length,
    species = input$species,
    sex = input$sex
  )
})
```

The `pred()` reactive is bound to the Predict button and performs the request:

```r
pred <- reactive({
  response <- httr2::request(api_url) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(vals(), auto_unbox = TRUE) |>
    httr2::req_perform() |>
    httr2::resp_body_json()

  response$.pred[[1]]
}) |>
  bindEvent(input$predict, ignoreInit = TRUE)
```

`bindEvent(ignoreInit = TRUE)` means no prediction fires on startup — only on button click. `resp_body_json()` returns a list, so `[[1]]` extracts the scalar numeric value.

## Layout

The UI uses `bslib` components and the `"sketchy"` Bootswatch theme:

| Component | Purpose |
|---|---|
| `page_sidebar()` | Overall page layout |
| `sidebar()` | Holds the three inputs and Predict button |
| `layout_columns()` | Two-column output area (7/5 width split) |
| `card()` | Input echo (left) and predicted mass (right) |
| `value_box()` | Displays predicted grams with a graph icon |

## API endpoints used

| Method | Path | When |
|---|---|---|
| POST | `/predict` | On every "Predict" button click |

The full endpoint list (health checks, model info, batch prediction) is documented in `../api/README.md`.

## Request / response example

Request sent by the app:

```json
{"bill_length_mm": 45, "species": "Adelie", "sex": "male"}
```

Response from the API:

```json
{".pred": [4180.797]}
```

Displayed in the app as `4180.8 grams`.

## Error handling

The `pred()` reactive catches connection and timeout errors and surfaces them as `showNotification()` warnings rather than crashing the app:

| Error pattern | User message |
|---|---|
| `Connection refused` / `couldn't connect` | `API not available - is the server running on port 8080?` |
| `timeout` / `timed out` | `Request timed out - API may be overloaded` |
| Other | Truncated error message (first 50 chars) |
