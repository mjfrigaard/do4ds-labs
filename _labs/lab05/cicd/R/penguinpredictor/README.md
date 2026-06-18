# penguinpredictor

A Shiny for R application that predicts penguin body mass by sending requests to a vetiver model API. The package bundles the input validation, encoding, and response parsing logic needed to talk to that API, along with a logging helper and a Shiny UI that displays both predictions and live log output.

This package is the R solution for Lab 05 of [DevOps for Data Science](https://do4ds.com/), which covers CI/CD workflows and automated testing.

---

## Project Structure

```
penguinpredictor/
├── .github/
│   └── workflows/
│       └── r-tests.yml            # GitHub Actions CI workflow
├── R/
│   ├── data.R                     # Input validation, encoding, response parsing
│   └── logging_setup.R            # Logging configuration
├── tests/
│   └── testthat/
│       └── test-data.R            # testthat test suite
├── app.R                          # Shiny for R application
├── DESCRIPTION                    # Package metadata and dependencies
├── NAMESPACE                      # Exported functions
└── .Rbuildignore
```

---

## Requirements

- R 4.1 or higher
- A running vetiver model API at `http://127.0.0.1:8080`

Runtime dependencies (declared in `DESCRIPTION`):

| Package | Role |
|---------|------|
| `logger` | Structured logging with file and console output |
| `httr2` | HTTP requests to the vetiver API |
| `shiny` | Web application framework |
| `bslib` | Bootstrap-based UI layout components |
| `jsonlite` | JSON serialization for request payloads |
| `pkgload` | Load the package in development without installing |

---

## Installation

Install the package from inside the `penguinpredictor/` directory using `devtools`:

```r
devtools::install(".")
```

To load the package in development mode without installing (used by `app.R`):

```r
pkgload::load_all(".")
```

To install with test dependencies:

```r
devtools::install(".", dependencies = TRUE)
```

---

## Running the App

From inside the `penguinpredictor/` directory, launch the Shiny application with:

```r
shiny::runApp("app.R")
```

Or from the terminal:

```bash
Rscript -e "shiny::runApp('app.R')"
```

The app expects the vetiver API to be running and reachable at `http://127.0.0.1:8080`. The UI provides a bill length slider (30 to 60 mm), species selector (Adelie, Chinstrap, Gentoo), and sex selector (Male, Female). Clicking **Predict** sends a POST request to the `/predict` endpoint and displays the predicted body mass in grams.

A **System Status** card at the bottom of the page shows the result of a live `/ping` health check and the 10 most recent log lines, which refresh automatically every second as new entries are written.

---

## Package API

All four functions are exported from the package namespace:

```r
library(penguinpredictor)
# or in development:
pkgload::load_all(".")
```

### `validate_inputs(bill_length, species, sex)`

Checks that the three inputs are within acceptable ranges before encoding. Returns a character vector of error messages. An empty vector means all inputs are valid.

```r
validate_inputs(45.0, "Adelie", "Male")     # character(0)
validate_inputs(99.0, "Emperor", "Unknown") # three error messages
```

Valid ranges:

- `bill_length`: 30.0 to 60.0 (inclusive)
- `species`: `"Adelie"`, `"Chinstrap"`, or `"Gentoo"`
- `sex`: `"Male"` or `"Female"`

### `encode_inputs(bill_length, species, sex)`

Transforms the UI inputs into the named list format the vetiver API expects. Species and sex are dummy encoded as binary integer indicators, which matches the feature encoding used during model training.

```r
encode_inputs(45.0, "Chinstrap", "Female")
# $bill_length_mm
# [1] 45
# $species_Chinstrap
# [1] 1
# $species_Gentoo
# [1] 0
# $sex_male
# [1] 0
```

### `parse_prediction(response_json)`

Extracts the predicted value from the API response list. Handles both the vetiver `.pred` format and the legacy `predict` format. Raises an error if neither key is present.

```r
parse_prediction(list(.pred = list(4180.8)))    # 4180.8
parse_prediction(list(predict = list(3750.0)))  # 3750.0
```

### `setup_logging(log_dir = "logs", level = logger::INFO)`

Configures the `logger` package to write structured log entries to both a file (`logs/shiny_app.log`) and the console. Creates the log directory if it does not exist. Returns the path to the log file invisibly.

```r
log_path <- setup_logging()             # writes to logs/shiny_app.log
log_path <- setup_logging("applogs")    # writes to applogs/shiny_app.log
```

---

## Tests

Run the full test suite from inside the `penguinpredictor/` directory with:

```r
devtools::test(".")
```

Or using `testthat` directly:

```r
testthat::test_dir("tests/testthat", package = "penguinpredictor", load_package = "pkgload")
```

The tests cover `encode_inputs`, `validate_inputs`, and `parse_prediction` and are located in `tests/testthat/test-data.R`. There are 21 test cases:

| Group | What it tests |
|-------|---------------|
| `encode_inputs` | Return type, key names, numeric coercion, binary encoding for all species/sex combinations |
| `validate_inputs` | Boundary values, invalid inputs, and error accumulation across multiple bad inputs |
| `parse_prediction` | Both response key formats, numeric coercion, key precedence, and unknown format errors |

---

## CI/CD Workflow

The `.github/workflows/r-tests.yml` workflow runs on any push to the `test` branch and on pull requests targeting `prod`. It installs the package and its test dependencies via `r-lib/actions`, then runs the testthat suite on `ubuntu-latest` with R 4.4.

```
push → test branch →  CI runs tests
pull request → prod branch  →  CI runs tests (gate before merge)
```

This branching strategy keeps untested code out of production: developers push to `test`, tests run automatically, and only passing branches can be merged into `prod`.

> **Note:** GitHub Actions requires `.github/workflows/` to be at the root of the git repository. This project is designed so that `penguinpredictor/` is initialized as its own standalone git repository.

---

## Logging

The app generates structured log entries in `logs/shiny_app.log` using the format:

```
2025-01-15 14:32:01 - INFO - Prediction successful - Session: r_84aef12b - response_time: 0.142s - prediction: 4180.8
```

Each session gets a short ID derived from `session$token` (e.g., `r_84aef12b`) that appears in every log line, making it straightforward to trace a single user's activity through the log file. The Shiny UI surfaces the 10 most recent lines directly in the browser so you can monitor activity without opening the log file manually.
