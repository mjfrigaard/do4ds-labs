# Python Model API

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
/usr/bin/python3 -m venv .venv # using system Python because it has SSL
source .venv/bin/activate  
```

3. Install libraries

```bash
pip install -r requirements.txt
```

4. Run the api:

```bash
python3 mod-api.py
```

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