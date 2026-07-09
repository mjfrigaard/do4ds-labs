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

``` python
from vetiver import VetiverModel, VetiverAPI
from pins import board_temp

v = VetiverModel(model, model_name='penguin_model', prototype_data=X)
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
    ('The hash of pin "penguin_model" has not changed. Your pin will not be stored.',)

## Write to S3 Board

Use the commands below to write the model to an S3 board. You will need
to set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment
variables in your terminal before running this code.

1.  Create a `.env` file in your project root:

``` {bash}
#| eval: false
#| code-fold: false 
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
```

2.  Install `python-dotenv`:

``` {bash}
#| eval: false
#| code-fold: false 
pip install python-dotenv
```

3.  Load it in your script:

``` python
from dotenv import load_dotenv
import os

load_dotenv()

access_key = os.getenv("AWS_ACCESS_KEY_ID")
secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
region = os.getenv("AWS_REGION")
```

4.  Add `.env` to `.gitignore`.
