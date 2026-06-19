FROM python:3.11-slim

WORKDIR /app

COPY requirements-api.txt .
RUN pip install --no-cache-dir -r requirements-api.txt

COPY mod-api.py .

ENV MODEL_PATH=/data/model
ENV PINS_ALLOW_PICKLE_READ=1

EXPOSE 8080

CMD ["python3", "mod-api.py"]
