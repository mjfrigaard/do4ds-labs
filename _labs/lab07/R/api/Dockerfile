FROM rocker/r-ver:4.6.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    cmake \
    libsodium-dev \
    libx11-dev \
    pandoc \
    xz-utils \
    libuv1-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY .Rprofile .
COPY renv/activate.R renv/activate.R
COPY renv.lock .

RUN Rscript -e "renv::restore(prompt = FALSE)"

COPY plumber.R .

ENV MODEL_PATH=/data/model

EXPOSE 8080

CMD ["Rscript", "plumber.R"]