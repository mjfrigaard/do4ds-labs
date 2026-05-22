# Penguin Mass Predictor App

Shiny application that predicts penguin body mass by calling the Plumber API in `../api/`. The user selects bill length, species, and sex; the app sends those values to the API and displays the predicted mass in grams.

```
├── app-api.R    # Shiny app
└── renv.lock
```

## Prerequisites

The API in `../api/` must be running before launching the app. See `../api/README.md` for setup. By default the app expects the API at `http://127.0.0.1:8080`.

Start the API:

```bash
Rscript -e "plumber::plumb(file='../api/plumber.R')\$run()"
```

Start the app:

```bash
Rscript -e "shiny::runApp('app-api.R')"
```

## Inputs

| Input | Type | Values |
|---|---|---|
| Bill Length (mm) | Slider | 30–60, step 1 |
| Sex | Select | `Male`, `Female` |
| Species | Select | `Adelie`, `Chinstrap`, `Gentoo` |

## How the app calls the API

The `vals()` reactive builds a single-row data frame from the UI inputs and sends it as JSON to `POST /predict`.

```r
vals <- reactive({
  data.frame(
    bill_length_mm = input$bill_length,
    species = input$species,
    sex = tolower(input$sex)   # API expects lowercase: "male" / "female"
  )
})
```

`sex` is lowercased because the UI displays `"Male"` / `"Female"` but the model's factor levels are `"male"` / `"female"`.

The `pred()` reactive performs the request and extracts the prediction:

```r
response <- httr2::request(api_url) |>
  httr2::req_method("POST") |>
  httr2::req_body_json(request_data, auto_unbox = FALSE) |>
  httr2::req_perform() |>
  httr2::resp_body_json()

response$.pred[[1]]   # [[1]] extracts numeric from the parsed list
```

`resp_body_json()` returns a list, so `[[1]]` (not `[1]`) is needed to get the scalar numeric value.

## API endpoints used

| Method | Path | When |
|---|---|---|
| POST | `/predict` | On every "Predict" button click |

The full endpoint list (health checks, model info, batch prediction) is documented in `../api/README.md`.

## Request / response example

Request sent by the app:

```json
[{"bill_length_mm": 45, "species": "Adelie", "sex": "male"}]
```

Response from the API:

```json
{".pred": [4180.797]}
```

Displayed in the app as `4180.8 grams`.
