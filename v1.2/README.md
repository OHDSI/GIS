To get this running:

1. Install [Docker](https://www.docker.com/get-started)
2. Create a file `postgres-passwd` in the root directory of the project
3. `docker-compose up`, wait for tiger data to be initialized

`docker-compose down` to stop.

`docker volume rm gis_pgdata` to delete the database (start all over with `docker-compose up`)
