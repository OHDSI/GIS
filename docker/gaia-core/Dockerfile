FROM ohdsi/broadsea-hades:4.2.1
LABEL maintainer="Tufts Medical Center <jared.houghtaling@tuftsmedicine.org>"
USER root

RUN Rscript -e 'remotes::install_github("OHDSI/GIS")'

#ENTRYPOINT ["/app/entrypoint.sh"]