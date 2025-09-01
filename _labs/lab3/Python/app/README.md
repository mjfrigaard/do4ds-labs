# Shiny for Python App (lab 3) 

## Set up

1. Determine Python

```bash
# check  Python version
which python3
python3 --version
```

2. Create virtual environment 

```bash
# cd Python/app/ # run if not in app directory 
/usr/bin/python3 -m venv .env # using system Python because it has SSL
source .env/bin/activate  
```

3. Install libraries

```bash
pip install --upgrade pip
pip install shiny requests
```

4. Verify

```bash
# verify install
python -c "import shiny; print('✅ Shiny installed:', shiny.__version__)"
python -c "import requests; print('✅ Requests installed:', requests.__version__)
```

Should show: 

```bash
# ✅ Shiny installed: 1.4.0
# ✅ Requests installed: 2.32.5
```

## Launch

Launch API:

```bash
cd api/
# source .env/bin/activate # if not activated 
python3 mod-api.py
```

Run app:

```bash
shiny run app-api.py --host 127.0.0.1 --port 3000 --reload
```