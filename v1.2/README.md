To get this running:

1. Install/update latest [Docker](https://www.docker.com/get-started) and [docker-compose](https://docs.docker.com/compose/install/)
2. Create a file `postgres-passwd` (no extension) in the `postgis` directory of the project which contains
the text of the password you would like to set
3. Create a file `.env` in the root directory of the project to set `RSTUDIO_PASSWD` and `POSTGRES_PORT`
4. Build the loader image
  - `docker run --privileged -it --rm -v <absolute path to working directory>/loader/:/src lnl7/nix sh -c 'nix-build /src && cp result /src/'`
  - `docker load < loader/result`
5. `docker-compose up`

`docker-compose up --profile dev` to start the shiny / rstudio container as well

`docker-compose down` to stop.

`docker volume rm gis_pgdata` to delete the database (start all over with `docker-compose up`)

## Loading data
`docker exec -it -w /data/cdc-social-vulnerability-index-svi gis_loader sh load.sh`
