# install packages
helpers.installPackages(
  "shinyjs",
  "shinyWidgets",
  "shinycssloaders",
  # "exams",
  "xtable",
  "tth",
  "png",
  "callr",
  "qpdf",
  "pdftools",
  "openssl",
  "tinytex"
)

# special install packages
install.packages("./iuftools", repos=NULL, type="source")
install.packages("exams", repos="http://R-Forge.R-project.org")

# tex setup
tinytex::install_tinytex()
tinytex::tlmgr_install("babel-german")
