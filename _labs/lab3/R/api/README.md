# R penguins model api

```
├── plumber.R                # main API file (vetiver + plumber)
├── mod-api.R                # original API (vetiver API)
├── model.R                  # model training script
├── models/                  # vetiver pin board
│   └── penguin_model
│       └── 20251004T054448Z-355a4
└── renv.lock               # dependency management
```

## mod-api.R

```r

```

## plumber.R

### handle_ping()

```bash
curl http://127.0.0.1:8080/ping
```

### handle_health()

```bash
curl http://127.0.0.1:8080/health
```

### handle_model_prototype()

```bash
curl http://127.0.0.1:8080/model-prototype
```