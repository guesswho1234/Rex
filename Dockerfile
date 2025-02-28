FROM rocker/shiny:4.2.2

RUN mkdir /rex
WORKDIR /rex

RUN set -eu \
        ;apt-get update  \
        ;apt-get install -y \
				libsodium-dev \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;rm -rf /var/lib/apt/lists/* \
        ;
	
RUN R -e "install.packages(c('shinyjs', 'shinyWidgets', 'shinycssloaders', 'shinyauthr', 'sodium', 'RSQLite', 'DBI'), dependencies=TRUE)"		
RUN R -e "install.packages('qpdf', repos='http://cran.us.r-project.org')"				 
RUN rm -rf /tmp/Rtmp*/

COPY ./app.R /rex/
COPY ./index.html /rex/
COPY ./app.html /rex/
# COPY --exclude=*/worker/* ./www /rex/www
COPY ./www /rex/www
COPY ./source/main /rex/source/main
COPY ./source/shared /rex/source/shared
COPY ./permission /rex/permission

EXPOSE 3838

CMD Rscript app.R
