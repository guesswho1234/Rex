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

pattern="PDF" \/>/<policy domain="coder" #rights="read|write" pattern="PDF" \/>/g' $imagemagic_config ; else echo did not see file $imagemagic_config ; fi

RUN rm -rf /tmp/Rtmp*/

COPY ./app.R /rex/
COPY ./index.html /rex/
COPY ./app.html /rex/
COPY ./www /rex/www
COPY ./source/main /rex/source/main
COPY ./source/shared /rex/source/shared
COPY ./permission /rex/permission

EXPOSE 3838

CMD Rscript app.R
