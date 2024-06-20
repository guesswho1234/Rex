FROM rocker/shiny:4.2.2

RUN mkdir /rex
WORKDIR /rex

RUN set -eu \
        ;apt-get update  \
        ;apt-get install -y \
				libsodium-dev \
                libpoppler-cpp-dev \
				texlive-full \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;rm -rf /var/lib/apt/lists/* \
        ;
	
RUN R -e "install.packages(c('shinyjs', 'shinyWidgets', 'shinycssloaders', 'xtable', 'tth', 'png', 'callr', 'qpdf', 'pdftools', 'openssl', 'shinyauthr', 'sodium'), dependencies=TRUE)"						 
RUN R -e "install.packages('exams', repos='http://R-Forge.R-project.org', type='source')"

COPY . /rex
EXPOSE 80
CMD Rscript app.R
