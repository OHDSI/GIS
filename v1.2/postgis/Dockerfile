FROM postgis/postgis:13-3.1

RUN \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    postgis \
    unzip \
    wget \
  ; \
  rm -rf /var/lib/apt/lists/*;

COPY ./initdb-gis.sh /docker-entrypoint-initdb.d/11_gis.sh
