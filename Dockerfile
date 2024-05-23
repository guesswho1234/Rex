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
	
RUN R -e "install.packages(c('shinyjs', 'shinyWidgets', 'shinycssloaders', 'xtable', 'tth', 'png', 'callr', 'qpdf', 'pdftools', 'openssl', 'tinytex', 'shinyauthr', 'sodium'), dependencies=TRUE)"						 
RUN R -e "install.packages('exams', repos='http://R-Forge.R-project.org', type='source')"
RUN R -e "tinytex::install_tinytex()"
RUN R -e "tinytex::tlmgr_install('babel-german')"

COPY . /rex
EXPOSE 8180
CMD Rscript app.R

# build and run:
# docker build --platform linux/x86_64 -t shiny-docker-rex .
# docker run -p 8180:8180 shiny-docker-rex

# find ID of your running container:
# docker ps

# create image (snapshot) from container filesystem:
# docker commit <imageId> mysnapshot

# explore this filesystem using bash (for example):
# docker run -t -i mysnapshot /bin/bash
# docker rmi mysnapshot
