FROM rocker/shiny

# ENV DEBIAN_FRONTEND noninteractive
# ENV WORKDIR="/usr/local/src/misp_modules"
# ENV VENV_DIR="/misp_modules"

RUN mkdir /rex
WORKDIR /rex

RUN set -eu \
        ;apt-get update  \
        ;apt-get install -y \
                # git \
                libpoppler-cpp-dev \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;rm -rf /var/lib/apt/lists/* \
        ;
	
RUN R -e "install.packages(c('shinyjs', 'shinyWidgets', 'shinycssloaders', 'xtable', 'tth', 'png', 'callr', 'qpdf', 'pdftools', 'openssl', 'tinytex', 'shinyauthr'), dependencies=TRUE)"						 
RUN R -e "install.packages('exams', repos='http://R-Forge.R-project.org')"
RUN R -e "tinytex::install_tinytex()"
RUN R -e "tinytex::tlmgr_install('babel-german')"

COPY . /rex
EXPOSE 8180

#RUN R -e "install.packages('./iuftools', repos=NULL, type='source')"

CMD Rscript app.R

# docker build --platform linux/x86_64 -t shiny-docker-rex .
# docker run -p 8180:8180 shiny-docker-rex

# find ID of your running container:
#docker ps

# create image (snapshot) from container filesystem
#docker commit 12345678904b5 mysnapshot

# explore this filesystem using bash (for example)
#docker run -t -i mysnapshot /bin/bash
#docker rmi mysnapshot