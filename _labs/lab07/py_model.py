# Code extracted from py_model.qmd (run by .github/workflows/publish.yml)
from palmerpenguins import load_penguins
from pandas import get_dummies
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn import preprocessing
import duckdb

penguins_data = load_penguins()
con = duckdb.connect('Python/my-db.duckdb')
con.execute("CREATE OR REPLACE TABLE penguins AS SELECT * FROM penguins_data")
df = con.execute("SELECT * FROM penguins").fetchdf().dropna()
con.close()

df.head(3)

X = get_dummies(df[['bill_length_mm', 'species', 'sex']], drop_first = True)
y = df['body_mass_g']

model = LinearRegression().fit(X, y)

print(f"R^2 {model.score(X,y)}")
print(f"Intercept {model.intercept_}")
print(f"Columns {X.columns}")
print(f"Coefficients {model.coef_}")

from vetiver import VetiverModel, VetiverAPI
from pins import board_temp

v = VetiverModel(model, model_name='penguin_lab07_model', prototype_data=X)

from pins import board_folder
from vetiver import vetiver_pin_write

board = board_folder("Python/models", allow_pickle_read=True)
vetiver_pin_write(board, v)

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

print(board.pin_list())

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

