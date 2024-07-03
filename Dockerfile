FROM rocker/shiny:4.2.2

RUN mkdir /rex
WORKDIR /rex

RUN set -eu \
        ;apt-get update  \
        ;apt-get install -y \
				libsodium-dev \
				libmagick++-dev \
				ghostscript \
                libpoppler-cpp-dev \
				texlive-full \
        ;apt-get -y autoremove \
        ;apt-get -y clean \
        ;rm -rf /var/lib/apt/lists/* \
        ;
	
RUN R -e "install.packages(c('shinyjs', 'shinyWidgets', 'shinycssloaders', 'xtable', 'tth', 'png', 'callr', 'pdftools', 'openssl', 'shinyauthr', 'sodium', 'magick'), dependencies=TRUE)"						 
RUN R -e "install.packages('exams', repos='http://R-Forge.R-project.org', type='source')"
RUN R -e "install.packages('qpdf', repos='http://cran.us.r-project.org')"

ARG imagemagic_config=/etc/ImageMagick-6/policy.xml
RUN if [ -f $imagemagic_config ] ; then sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/g' $imagemagic_config ; else echo did not see file $imagemagic_config ; fi

COPY . /rex

EXPOSE 3838

CMD Rscript app.R
