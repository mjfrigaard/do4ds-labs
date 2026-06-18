# penguin_predictor

A Shiny for Python application that predicts penguin body mass by sending requests to a vetiver model API. The package bundles the input validation, encoding, and response parsing logic needed to talk to that API, along with a logging helper and a Shiny UI that displays both predictions and live log output.

This package is the Python solution for Lab 05 of [DevOps for Data Science](https://do4ds.com/), which covers CI/CD workflows and automated testing.

---

## Project Structure

```
penguin_predictor/
├── .github/
│   └── workflows/
│       └── python-tests.yml   # GitHub Actions CI workflow
├── penguin_predictor/
│   ├── __init__.py            # Public API exports
│   ├── data.py                # Input validation, encoding, response parsing
│   └── logging_setup.py       # Logging configuration
├── tests/
│   ├── __init__.py
│   └── test_data.py           # pytest test suite
├── app.py                     # Shiny for Python application
├── pyproject.toml             # Build and dependency configuration
└── requirements.txt           # Pinned runtime dependencies
```

---

## Requirements

- Python 3.9 or higher
- A running vetiver model API at `http://127.0.0.1:8080`

Runtime dependencies (see `requirements.txt`):

```
requests==2.32.5
shiny==1.4.0
uvicorn==0.35.0
```

---

## Installation

Install the package in editable mode from the `penguin_predictor/` directory:

```bash
pip install -e .
```

To install with test dependencies:

```bash
pip install -e ".[test]"
```

---

## Running the App

Start the Shiny application with:

```bash
shiny run app.py
```

The app expects the vetiver API to be running and reachable at `http://127.0.0.1:8080`. The UI provides a bill length slider (30 to 60 mm), species selector (Adelie, Chinstrap, Gentoo), and sex selector (Male, Female). Clicking **Predict** sends a POST request to the `/predict` endpoint and displays the predicted body mass in grams.

A **System Status** card at the bottom of the page shows the result of a live `/ping` health check and the 10 most recent log lines, which refresh automatically as new entries are written.

---

## Package API

All four functions are importable directly from the top-level package:

```python
from penguin_predictor import encode_inputs, validate_inputs, parse_prediction, setup_logging
```

### `validate_inputs(bill_length, species, sex)`

Checks that the three inputs are within acceptable ranges before encoding. Returns a list of error message strings. An empty list means all inputs are valid.

```python
validate_inputs(45.0, "Adelie", "Male")    # []
validate_inputs(99.0, "Emperor", "Unknown") # three error messages
```

Valid ranges:
- `bill_length_mm`: 30.0 to 60.0 (inclusive)
- `species`: `"Adelie"`, `"Chinstrap"`, or `"Gentoo"`
- `sex`: `"Male"` or `"Female"`

### `encode_inputs(bill_length, species, sex)`

Transforms the UI inputs into the JSON payload format the vetiver API expects. Species and sex are dummy encoded as binary indicator columns, which matches the feature encoding used during model training.

```python
encode_inputs(45.0, "Chinstrap", "Female")
# [{"bill_length_mm": 45.0, "species_Chinstrap": 1, "species_Gentoo": 0, "sex_male": 0}]
```

### `parse_prediction(response_json)`

Extracts the predicted value from the API response dictionary. Handles both the vetiver `.pred` format and the legacy `predict` format. Raises `ValueError` if neither key is present.

```python
parse_prediction({".pred": [4180.8]})   # 4180.8
parse_prediction({"predict": [3750.0]}) # 3750.0
```

### `setup_logging(log_dir="logs", level=logging.INFO)`

Configures the root logger to write to both a file (`logs/shiny_app.log`) and the console. Creates the log directory if it does not exist. Returns the path to the log file as a string.

```python
from penguin_predictor import setup_logging
log_path = setup_logging()          # writes to logs/shiny_app.log
log_path = setup_logging("applogs") # writes to applogs/shiny_app.log
```

---

## Tests

Run the full test suite with:

```bash
pytest tests/ -v
```

The tests cover `encode_inputs`, `validate_inputs`, and `parse_prediction` and are located in `tests/test_data.py`. There are 21 test cases organized into three classes:

| Class | What it tests |
|---|---|
| `TestEncodeInputs` | Return shape, key names, binary encoding for all species/sex combinations |
| `TestValidateInputs` | Boundary values, invalid inputs, and error accumulation across multiple bad inputs |
| `TestParsePrediction` | Both response key formats, float coercion, key precedence, and unknown format errors |

---

## CI/CD Workflow

The `.github/workflows/python-tests.yml` workflow runs on any push to the `test` branch and on pull requests targeting `prod`. It installs the package and its test dependencies, then runs `pytest tests/ -v` on `ubuntu-latest` with Python 3.12.

```
push → test branch        →  CI runs tests
pull request → prod branch →  CI runs tests (gate before merge)
```

This branching strategy keeps untested code out of production: developers push to `test`, tests run automatically, and only passing branches can be merged into `prod`.

---

## Logging

The app generates structured log entries in `logs/shiny_app.log` using the format:

```
2025-01-15 14:32:01,234 - INFO - Prediction successful - Session: py_84312 - response_time: 0.142s - prediction: 4180.8
```

Each session gets a short ID (e.g., `py_84312`) that appears in every log line, making it straightforward to trace a single user's activity through the log file. The Shiny UI surfaces the 10 most recent lines directly in the browser so you can monitor activity without opening the log file manually.
