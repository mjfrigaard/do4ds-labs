# R Model API (lab04)

To run the API (in `R/api/` folder):

1. Check R version

```bash
R --version
```

2. Restore the renv environment

```bash
Rscript -e "renv::restore()"
```

3. Run the model (optional):

If you need to retrain the model, run `model.R`. This queries the Palmer Penguins dataset from DuckDB, trains a linear model predicting body mass, and pins it to `models/` using vetiver.

```bash
Rscript model.R
```

4. Run the API:

```bash
Rscript plumber.R
```

View the API using the following URLs:

<http://127.0.0.1:8080/>

<http://127.0.0.1:8080/__docs__/>

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/ping` | Basic health check |
| GET | `/health` | Detailed health check with model info |
| GET | `/model-info` | Model metadata and version |
| GET | `/model-prototype` | Expected input format |
| GET | `/input-schema` | Input field documentation |
| POST | `/predict` | Single or batch prediction |
| POST | `/predict-validated` | Prediction with input validation |
| POST | `/predict-batch` | Batch predictions |

## Testing the API

Open these URLs in your browser:

- **Swagger UI**: http://127.0.0.1:8080/__docs__/
- **ReDoc**: http://127.0.0.1:8080/__docs__/?redoc=1
- **Health check**: http://127.0.0.1:8080/ping

Or test from the terminal (in a new terminal window):

```bash
curl http://127.0.0.1:8080/ping
```

```bash
curl http://127.0.0.1:8080/health
```

```bash
curl -X POST "http://127.0.0.1:8080/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "bill_length_mm": 45.5,
    "species": "Gentoo",
    "sex": "male"
  }'
```

```bash
curl -X POST "http://127.0.0.1:8080/predict-validated" \
  -H "Content-Type: application/json" \
  -d '{
    "bill_length_mm": 45.5,
    "species": "Gentoo",
    "sex": "male"
  }'
```

### Input fields

| Field | Type | Valid values |
|-------|------|--------------|
| `bill_length_mm` | numeric | 30 to 60 |
| `species` | string | `"Adelie"`, `"Chinstrap"`, `"Gentoo"` |
| `sex` | string | `"female"`, `"male"` |
