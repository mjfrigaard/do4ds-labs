from palmerpenguins import load_penguins
from pandas import get_dummies
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn import preprocessing
import duckdb

penguins_data = load_penguins()
con = duckdb.connect('my-db.duckdb')
con.execute("CREATE OR REPLACE TABLE penguins AS SELECT * FROM penguins_data")
df = con.execute("SELECT * FROM penguins").fetchdf().dropna()
print(df.head(3))
con.close()

X = get_dummies(df[['bill_length_mm', 'species', 'sex']], drop_first = True)
y = df['body_mass_g']

model = LinearRegression().fit(X, y)

print(f"R^2 {model.score(X,y)}")
print(f"Intercept {model.intercept_}")
print(f"prototype_data {X}")
print(f"Columns {X.columns}")
print(f"Coefficients {model.coef_}")


from vetiver import VetiverModel
v = VetiverModel(model, model_name='penguin_model', prototype_data=X)

import os
from pins import board_folder
from vetiver import vetiver_pin_write

model_board = board_folder("./models", allow_pickle_read=True)
vetiver_pin_write(model_board, v)

from vetiver import VetiverAPI
app = VetiverAPI(v, check_prototype = True)