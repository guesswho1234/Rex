FROM rocker/shiny:4.2.2

RUN mkdir /rex
WORKDIR /rex

# Create non-root user with specified UID/GID
ARG UID=1001
ARG GID=1001
RUN groupadd -g ${GID} rexuser && useradd -m -u ${UID} -g ${GID} -d /rex rexuser

RUN set -eu \
        ;apt-get update  \
        ;apt-get install -y \
				libsodium-dev \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;rm -rf /var/lib/apt/lists/* \
        ;
	
RUN R -e "install.packages(c('shinyjs', 'shinyWidgets', 'shinycssloaders', 'shinyauthr', 'sodium', 'RSQLite', 'DBI', 'httr'), dependencies=TRUE)"		
RUN R -e "install.packages('qpdf', repos='http://cran.us.r-project.org')"				 
RUN rm -rf /tmp/Rtmp*/

COPY ./app.R /rex/
COPY ./index.html /rex/
COPY ./app.html /rex/
COPY ./sso_config.csv /rex/
COPY ./www /tmp/www

# Copy addons directory excluding all "worker" subdirs
COPY ./www /tmp/www
RUN find /tmp/www/addons/ -mindepth 2 -maxdepth 2 -type d -name worker -exec rm -rf {} + && \
    mv /tmp/www /rex/www && \
    rm -rf /tmp/www
	
COPY ./source/main /rex/source/main
COPY ./source/shared /rex/source/shared

# Change ownership of everything to the non-root user
RUN chown -R rexuser:rexuser /rex

# Switch to non-root user
USER rexuser

EXPOSE 3838

CMD Rscript app.R
