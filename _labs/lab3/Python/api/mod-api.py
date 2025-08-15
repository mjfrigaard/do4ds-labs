# pkgs
import warnings
warnings.filterwarnings("ignore", message=".*urllib3 v2 only supports OpenSSL.*")

import os
os.environ['PINS_ALLOW_PICKLE_READ'] = '1'

import vetiver
import pins
import uvicorn
import pandas as pd

# connect to model board from lab2 
model_board = pins.board_folder("../../../lab2/model-vetiver/models/")

# read pinned model
sklearn_model = model_board.pin_read("penguin_model")
print(f":-] Successfully loaded model: {type(sklearn_model)}")

# check what features model expects
if hasattr(sklearn_model, 'feature_names_in_'):
    feature_names = sklearn_model.feature_names_in_
    print(f"Model expects features: {list(feature_names)}")
    
    # create prototype data using model's expected features
    prototype_data = pd.DataFrame({name: [0.0] for name in feature_names})
    
    # set reasonable defaults (based on penguin data)
    for col in prototype_data.columns:
        if 'bill_length' in col:
            prototype_data[col] = [45.0]
        elif 'species_Gentoo' in col:
            prototype_data[col] = [1]  # default Gentoo
        elif 'sex_male' in col:
            prototype_data[col] = [1]  # default male
            
else:
    print("Model doesn't have feature_names_in_, using estimated prototype")
    # original R model structure
    prototype_data = pd.DataFrame({
        "bill_length_mm": [45.0],
        "species_Chinstrap": [0],
        "species_Gentoo": [1], 
        "sex_male": [1]
    })

print("Prototype data shape:", prototype_data.shape)
print("Prototype columns:", list(prototype_data.columns))
print("Sample data:")
print(prototype_data)

# wrap as VetiverModel
v = vetiver.VetiverModel(
    model=sklearn_model, 
    model_name="penguin_model",
    prototype_data=prototype_data
)
print(f":-] Created VetiverModel: {type(v)}")

# create VetiverAPI and extract FastAPI app
vetiver_api = vetiver.VetiverAPI(v, check_prototype=True)

# actual FastAPI application
app = vetiver_api.app  # should be the FastAPI instance

print(f"FastAPI app type: {type(app)}")

if __name__ == "__main__":
    print(":-] Starting Penguin Model API...")
    print(":-] API Documentation: http://127.0.0.1:8080/docs")
    print(":-] Health Check: http://127.0.0.1:8080/ping")
    print(":-] Model Info: http://127.0.0.1:8080/metadata")
    uvicorn.run(app, host="127.0.0.1", port=8080)