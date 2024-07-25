# Dockerized GAIA-DB

You can run this container directly with the following command:

```bash
sudo docker run --rm --env POSTGRES_PASSWORD=<YOUR PASSWORD> <IMAGE NAME>:latest
```

This image is based on the [alpine flavored postgis](https://hub.docker.com/layers/postgis/postgis/16-3.4-alpine/images/sha256-5c31b8b83d9ea726ed109d2db7c16a3febe994e4c2d9ef888d3fc77fff7fd2c2?context=explore) base image. The [initialization script](https://github.com/TuftsCTSI/GIS/blob/containerize/docker/gaia-db/init.sql) for the database combines and modifies existing sql scripts used in both the [catalog initialization](https://github.com/TuftsCTSI/GIS/blob/containerize/inst/initialize.sql) (via the backbone schema) and the [vocabulary integration](https://github.com/TuftsCTSI/GIS/blob/containerize/vocabularies/easyload.sql).

Once deployed and auto-initialized, the containerized Postgres database includes:
- GIS Catalog (`backbone` schema)
- Constrained GIS vocabulary tables (`vocabulary` schema)
- postgis tools (native to image, `tiger` schema)