# Python Model API (lab06)

To run API (in `Python/api/` folder):

1. Determine Python

```bash
# check  Python version
which python3
python3 --version
```

2. Create virtual environment 

```bash
# cd Python/api/ # run if not in directory 
/usr/bin/python3 -m venv .venv 
source .venv/bin/activate  
```

3. Install libraries

```bash
pip install -r requirements.txt
```

4. Run the model (optional): 

If you're running model.py, you'll also need `palmerpenguins` and `duckdb`.

```bash
pip install palmerpenguins
pip install duckdb
```

This will create a new model in `models/` (if something changed).

```bash
python3 model.py
```

5. Run the api:

```bash
python3 mod-api.py
```

View the API using the following URLS:

<http://127.0.0.1:8080/>

<http://127.0.0.1:8080/docs>

## Testing API

Open these URLs in your browser:

- **Interactive docs**: http://127.0.0.1:8080/docs
- **Health check**: http://127.0.0.1:8080/ping  
- **Model metadata**: http://127.0.0.1:8080/metadata

Or perform terminal testing (in a new terminal)

```bash
# Test health check
curl http://127.0.0.1:8080/ping

# Test prediction
curl -X POST "http://127.0.0.1:8080/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "bill_length_mm": 45.0,
    "species_Chinstrap": 0,
    "species_Gentoo": 1,
    "sex_male": 1
  }'
```

## Docker

Build the image (run from `Python/api/`):

```bash
docker build -t penguin-model-py .
```

Run the container, mounting the model directory from the host:

```bash
docker run --rm -d \
  -p 8080:8080 \
  --name penguin-model-py \
  -v "$(pwd)/models":/data/model \
  penguin-model-py
```

The `-v` flag mounts the local `models/` folder into the container at `/data/model`, which is where `MODEL_PATH` points by default. This keeps the model outside the image so it can be updated without a rebuild.

Test the running container:

```bash
curl http://localhost:8080/ping
```