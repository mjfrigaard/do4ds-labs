# Python Vetiver Model


This document demonstrates how to create a simple linear regression
model using the `palmerpenguins` dataset, and then turn it into a
`Vetiver` model for deployment using Python.

## Setup

In the **Terminal**, navigate to the `lab07` directory and run the
following commands to create a virtual environment and install
dependencies:

``` bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Then render this file:

``` bash
quarto render py_model.qmd
```

------------------------------------------------------------------------

``` python
from palmerpenguins import load_penguins
from pandas import get_dummies
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn import preprocessing
import duckdb
```

## Get Data

Load the data from the `palmerpenguins` package, and then create a
persistent table in `duckdb`.

``` python
penguins_data = load_penguins()
con = duckdb.connect('Python/my-db.duckdb')
con.execute("CREATE OR REPLACE TABLE penguins AS SELECT * FROM penguins_data")
df = con.execute("SELECT * FROM penguins").fetchdf().dropna()
con.close()
```

Preview the data frame and check how many rows were loaded from the SQL
query.

``` python
df.head(3)
```

<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }
&#10;    .dataframe tbody tr th {
        vertical-align: top;
    }
&#10;    .dataframe thead th {
        text-align: right;
    }
</style>

|  | species | island | bill_length_mm | bill_depth_mm | flipper_length_mm | body_mass_g | sex | year |
|----|----|----|----|----|----|----|----|----|
| 0 | Adelie | Torgersen | 39.1 | 18.7 | 181.0 | 3750.0 | male | 2007 |
| 1 | Adelie | Torgersen | 39.5 | 17.4 | 186.0 | 3800.0 | female | 2007 |
| 2 | Adelie | Torgersen | 40.3 | 18.0 | 195.0 | 3250.0 | female | 2007 |

</div>

## Define Model and Fit

Use `get_dummies` to convert categorical variables into dummy/indicator
variables, and then fit a linear regression model.

``` python
X = get_dummies(df[['bill_length_mm', 'species', 'sex']], drop_first = True)
y = df['body_mass_g']

model = LinearRegression().fit(X, y)
```

## Get some information

Print some of the model information, including the R^2 score, intercept,
columns, and coefficients.

``` python
print(f"R^2 {model.score(X,y)}")
print(f"Intercept {model.intercept_}")
print(f"Columns {X.columns}")
print(f"Coefficients {model.coef_}")
```

    R^2 0.8555368759537614
    Intercept 2169.2697209393996
    Columns Index(['bill_length_mm', 'species_Chinstrap', 'species_Gentoo', 'sex_male'], dtype='object')
    Coefficients [  32.53688677 -298.76553447 1094.86739145  547.36692408]

## Turn into Vetiver Model

We’re going to differentiate the model name here so we can easily
identify it later.

``` python
from vetiver import VetiverModel, VetiverAPI
from pins import board_temp

v = VetiverModel(model, model_name='penguin_lab07_model', prototype_data=X)
```

## Write to Local Board

``` python
from pins import board_folder
from vetiver import vetiver_pin_write

board = board_folder("Python/models", allow_pickle_read=True)
vetiver_pin_write(board, v)
```

    Model Cards provide a framework for transparent, responsible reporting. 
     Use the vetiver `.qmd` Quarto template as a place to start, 
     with vetiver.model_card()
    ('The hash of pin "penguin_lab07_model" has not changed. Your pin will not be stored.',)

## Write to S3

To write the model to an S3 board, set the `USE_S3` environment variable
and provide AWS credentials:

1.  Create a `.env` file in the project root:

``` bash
touch .env
```

2.  Add environment variables:

``` bash
USE_S3=true
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
```

3.  Add `.env` to your `.gitignore` file to avoid committing sensitive
    information.

4.  Load environment variables and write to the S3 board:

``` python
from dotenv import load_dotenv
import os
from pins import board_s3, board_folder
from vetiver import vetiver_pin_write

load_dotenv()

if os.getenv("USE_S3") == "true":
    board = board_s3(
        path="penguin-vetiver-model-data/Python/models",
        allow_pickle_read=True
    )
else:
    board = board_folder("Python/models", allow_pickle_read=True)

vetiver_pin_write(board, v)
```

    Model Cards provide a framework for transparent, responsible reporting. 
     Use the vetiver `.qmd` Quarto template as a place to start, 
     with vetiver.model_card()
    ('The hash of pin "penguin_lab07_model" has not changed. Your pin will not be stored.',)

Confirm the model was written:

``` python
print(board.pin_list())
```

    ['penguin_lab07_model', 'penguin_model']

## Pull from S3

To load a model from S3 in our API, we’ll use the same approach:

1.  Create the board using the same `USE_S3` environment variable that
    controls where it’s read from
2.  `USE_S3=true` means the credentials are automatically provided by
    the IAM role on EC2  
3.  The `MODEL_PATH` variable allows us to customize the local folder
    path for development/testing (optional here).

``` python
from dotenv import load_dotenv
import os
from pins import board_s3, board_folder

load_dotenv()

if os.getenv("USE_S3") == "true":
    board = board_s3(
        path="penguin-vetiver-model-data/Python/models",
        allow_pickle_read=True
    )
else:
    board = board_folder(os.getenv("MODEL_PATH", "Python/models"), allow_pickle_read=True)

# read the pinned model (returns the underlying sklearn model)
model = board.pin_read("penguin_lab07_model")

print(f"Model type: {type(model)}")
print(f"Model loaded successfully from {'S3' if os.getenv('USE_S3') == 'true' else 'local'}")
```

    Model type: <class 'sklearn.linear_model._base.LinearRegression'>
    Model loaded successfully from S3

`board.pin_read()` returns the underlying model object ready for
predictions or API serving!
