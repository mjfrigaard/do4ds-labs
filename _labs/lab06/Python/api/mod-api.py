# pkgs
import warnings
warnings.filterwarnings("ignore", message=".*urllib3 v2 only supports OpenSSL.*")

import os
os.environ['PINS_ALLOW_PICKLE_READ'] = '1'

import vetiver
import pins
import uvicorn
import pandas as pd

# load model from MODEL_PATH env var (default: local models/ for dev)
model_path = os.environ.get("MODEL_PATH", "models/")
model_board = pins.board_folder(model_path)

# read pinned model
sklearn_model = model_board.pin_read("penguin_model")
print(f":-] Successfully loaded model: {type(sklearn_model)}")

# check model for the features it expects
if hasattr(sklearn_model, 'feature_names_in_'):
    feature_names = sklearn_model.feature_names_in_
    print(f"Model expects features: {list(feature_names)}")
    
    # define prototype value logic
    def get_prototype_value(column_name):
        """Get appropriate default value for each column type"""
        if 'bill_length' in column_name:
            return 45.0  # realistic penguin bill length
        elif 'species_Gentoo' in column_name:
            return 1     # default to Gentoo species
        elif 'sex_male' in column_name:
            return 1     # default to male
        else:
            return 0     # default for other dummy variables
    
    # create prototype data directly
    prototype_data = pd.DataFrame({
        name: [get_prototype_value(name)] for name in feature_names
    })
    
else:
    # fallback when model doesn't have feature names
    print("Model doesn't have feature_names_in_, using estimated prototype")
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
# can run with:
# vetiver_api.run(port = 8080)

# actual FastAPI application
app = vetiver_api.app  

print(f"FastAPI app type: {type(app)}")

if __name__ == "__main__":
    print(":-] Starting Penguin Model API...")
    print(":-] API Documentation: http://127.0.0.1:8080/docs")
    print(":-] Health Check: http://127.0.0.1:8080/ping")
    print(":-] Model Info: http://127.0.0.1:8080/metadata")
    uvicorn.run(app, host="0.0.0.0", port=8080)
