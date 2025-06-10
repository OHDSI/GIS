FROM ohdsi/broadsea-hades:4.2.1

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        libpq-dev \
        libudunits2-dev \
        libgdal-dev \
        libgeos-dev \
        libproj-dev

#ENV USER=ohdsi
#ENV GROUPNAME=$USER
#ENV UID=1001
#RUN useradd -u "$UID" $USER

# Temporary workaround for bug in sf -> https://forum.posit.co/t/sf-wont-install-for-anyone-on-posit-cloud/191242/2
RUN Rscript -e 'remotes::install_github(repo = "r-spatial/sf", ref = "93a25fd8e2f5c6af7c080f92141cb2b765a04a84")'

# Note that until the main package update is merged in the OHDSI org, we will need to reference the fixed code
# on the containerize branch
RUN Rscript -e 'remotes::install_github("OHDSI/GIS@containerize")'

# Outdated Andromeda package from Hades causes error
# "Error: 'isAndromedaTable' is not an exported object from 'namespace:Andromeda'"
# Broadsea HADES dockerhub package should be updated to use Andromeda v0.6.7
RUN Rscript -e 'install.packages("Andromeda")'

# This provides an API to gaiaCore, could be moved to the package DESCRIPTION
RUN Rscript -e 'install.packages("plumber")'
COPY ./docker/gaia-core/R /ohdsi-gis
WORKDIR /ohdsi-gis

# Add API service to supervisord
RUN echo "" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "[program:Rscript]" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "command=/usr/local/bin/Rscript /ohdsi-gis/gaia.R" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "stdout_logfile=/var/log/supervisor/%(program_name)s.log" >> /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
