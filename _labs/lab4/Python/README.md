# Shiny for Python App Logging (lab 4) 

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
pip install logging
pip install -r requirements.txt
```

4. Verify

```bash
# verify install
python -c "import shiny; print('✅ Shiny installed:', shiny.__version__)"
python -c "import requests; print('✅ Requests installed:', requests.__version__)"
```

Should show: 

```bash
# ✅ Shiny installed: 1.4.0
# ✅ Requests installed: 2.32.5
```

## Launch

Launch API:

In a separate Terminal, launch the API by navigating to `do4ds-labs/_labs/lab3/Python/api/` and entering:

```bash
# source .env/bin/activate # if not activated 
python3 mod-api.py
```

Run app using: 

```bash
shiny run app-log.py --host 127.0.0.1 --port 3000 --reload
```

### Architecture 

```mermaid
%%{init: {'theme': 'neutral', 'look': 'handDrawn', 'themeVariables': { 'fontFamily': 'monospace'}}}%%

sequenceDiagram
    participant Main as App
    participant Setup as setup_logging()
    participant Logger as Logger
    participant FileReader as @reactive.file_reader

    Main->>Setup: Call setup_logging()
    Setup->>Setup: Configure logging system
    Setup-->>Main: Return str(log_file_path)
    
    Main->>Main: Store in log_file_path variable
    Main->>Logger: logging.info("App initialized")
    Logger->>Logger: Write to file & console
    
    Main->>FileReader: @reactive.file_reader(log_file_path)
    FileReader->>FileReader: Monitor file for changes
    FileReader-->>Main: Trigger UI updates when file changes
```