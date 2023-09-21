# Start from an official Python base image.
FROM solr

# copy the init script
COPY ./ohdsi-init-solr.sh /opt/solr-9.3.0/docker/scripts/ohdsi-init-solr.sh

# run init script
ENTRYPOINT ['/opt/solr-9.3.0/docker/scripts/ohdsi-init-solr.sh']