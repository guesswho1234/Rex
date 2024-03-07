FROM rocker/shiny

RUN R -e "install.packages(c('shinyjs', 'shinyWidgets', 'shinycssloaders', 'xtable', 'tth', 'png', 'callr', 'qpdf', 'pdftools', 'openssl', 'tinytex', 'shinyauthr'))"						 
#RUN R -e "install.packages('./iuftools', repos=NULL, type='source')"
RUN R -e "install.packages('exams', repos='http://R-Forge.R-project.org')"
RUN R -e "tinytex::install_tinytex()"
RUN R -e "tinytex::tlmgr_install('babel-german')"

COPY [^.]*  app/
EXPOSE 8180
CMD Rscript app/app.R

# docker build --platform linux/x86_64 -t shiny-docker-rex .
# docker run -p 8180:8180 shiny-docker-rex