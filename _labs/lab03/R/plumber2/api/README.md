# Penguin Mass Predictor API (plumber2)

Plumber2 API that serves a linear regression model predicting penguin body mass from bill length, species, and sex. The model is trained in `model.R`, versioned with `vetiver`, and pinned locally to `models/`.

```
├── model.R            # train and pin the vetiver model
├── plumber.R          # full API with all endpoints
├── models/            # vetiver pin board
│   └── penguin_model
└── my-db.duckdb
```

## plumber2 vs plumber

| plumber | plumber2 |
|---|---|
| `plumber::pr()` | `plumber2::api()` |
| `pr_get()` / `pr_post()` | `api_get()` / `api_post()` |
| `pr_run()` | `api_run()` |
| `req$body` (raw JSON string) | `body` argument (auto-parsed list) |
| Docs at `/openapi` | Docs at `/__docs__/` |

Request bodies are parsed from JSON automatically — no `jsonlite::fromJSON()` needed in handlers.

## Model

`model.R` queries `my-db.duckdb` (Palmer Penguins data), trains a linear model, and pins a `vetiver` model object to `models/`.

```r
lm(body_mass_g ~ bill_length_mm + species + sex, data = df)
```

The `vetiver` prototype defines the expected input shape:

| Column | Type | Values |
|---|---|---|
| `bill_length_mm` | numeric | 30–60 |
| `species` | factor | `Adelie`, `Chinstrap`, `Gentoo` |
| `sex` | factor | `female`, `male` |

Run once before starting the API:

```bash
Rscript model.R
```

## plumber.R

Full API with health checks, model introspection, and three prediction endpoints. Handlers receive `body` (parsed JSON) and `response` (for setting status codes) as arguments.

Start:

```bash
Rscript plumber.R
```

Docs: http://127.0.0.1:8080/__docs__/

### Endpoints

#### Health

| Method | Path | Description |
|---|---|---|
| GET | `/ping` | Basic liveness check |
| GET | `/health` | Model name, version, R version |

```bash
curl http://127.0.0.1:8080/ping
```

```bash
curl http://127.0.0.1:8080/health
```

#### Model Info

| Method | Path | Description |
|---|---|---|
| GET | `/model-info` | Name, class, version |
| GET | `/model-prototype` | Expected column types and factor levels |
| GET | `/input-schema` | Field descriptions and valid values |

```bash
curl http://127.0.0.1:8080/model-info
```

```bash
curl http://127.0.0.1:8080/model-prototype
```

```bash
curl http://127.0.0.1:8080/input-schema
```

#### Predictions

| Method | Path | Description |
|---|---|---|
| POST | `/predict` | Single prediction |
| POST | `/predict-validated` | Prediction with input validation (400 on bad input) |
| POST | `/predict-batch` | Batch prediction (arrays) |

All endpoints accept `species` and `sex` as strings — `prep_pred_data()` converts them to factors internally. Single-prediction response is `{".pred": [<value>]}`.

Single prediction:

```bash
curl -X POST http://127.0.0.1:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"bill_length_mm": 45, "species": "Adelie", "sex": "male"}'
```

Prediction with validation:

```bash
curl -X POST http://127.0.0.1:8080/predict-validated \
  -H "Content-Type: application/json" \
  -d '{"bill_length_mm": 45, "species": "Adelie", "sex": "male"}'
```

Batch prediction:

```bash
curl -X POST http://127.0.0.1:8080/predict-batch \
  -H "Content-Type: application/json" \
  -d '{"bill_length_mm": [45, 39, 50], "species": ["Adelie", "Adelie", "Gentoo"], "sex": ["male", "female", "male"]}'
```

## How the Shiny app uses this API

The Shiny app in `../app/` calls `POST /predict` on this API. It sends a single-row JSON payload with `bill_length_mm` (numeric), `species` (string), and `sex` (lowercase string). The API returns `{".pred": [<grams>]}` and the app displays the value.

```
User input (UI)
    │
    ▼
vals() reactive — data.frame(bill_length_mm, species, sex)
    │
    ▼
httr2::req_body_json() → POST /predict → prep_pred_data() → predict(v, .)
    │
    ▼
response$.pred[[1]] → renderText → "4180.8 grams"
```

The app does **not** one-hot encode the categorical variables — the API handles factor conversion internally.
