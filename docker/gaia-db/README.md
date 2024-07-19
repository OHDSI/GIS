# Dockerized GAIA-DB

You can run this container directly with the following command:

```bash
sudo docker run --rm --env POSTGRES_PASSWORD=<YOUR PASSWORD> <IMAGE NAME>:latest
```

The image contains the PostGIS extension, the backbone schema with the catalog tables loaded, and a vocabulary schema
with