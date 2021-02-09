To get this running:

1. Install [Docker](https://www.docker.com/get-started)
2. Create a file `postgres-passwd` (no extension) in the `postgis` directory of the project which contains
the text of the password you would like to set
3. Create a file `.env` in the root directory of the project to set `RSTUDIO_PASSWD` and `POSTGRES_PORT`
4. `docker-compose up`

`docker-compose up --profile dev` to start the shiny / rstudio container as well

`docker-compose down` to stop.

`docker volume rm gis_pgdata` to delete the database (start all over with `docker-compose up`)
