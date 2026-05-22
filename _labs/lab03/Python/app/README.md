# Shiny for Python App (lab 3) 

## Set up

1. Determine Python

```bash
which python3
```

```bash
# check  Python version
python3 --version
```

2. Create virtual environment 

```bash
/usr/bin/python3 -m venv .env # using system Python because it has SSL
```

```bash
source .env/bin/activate  
```

3. Install libraries

```bash
pip install --upgrade pip
```

```bash
pip install shiny requests
```

4. Verify

```bash
python -c "import shiny; print('✅ Shiny installed:', shiny.__version__)"
```

```bash
python -c "import requests; print('✅ Requests installed:', requests.__version__)
```

## Launch

Launch API:

```bash
cd api/
```

```bash
# source .env/bin/activate # if not activated 
python3 mod-api.py
```

Run app:

```bash
shiny run app-api.py --host 127.0.0.1 --port 3000 --reload
```