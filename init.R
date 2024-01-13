# install packages
helpers.installPackages(
  "shinyjs",
  "shinyWidgets",
  "shinycssloaders",
  "exams",
  "xtable",
  "tth",
  "png",
  "callr",
  "qpdf",
  "pdftools",
  "openssl",
  "tinytex"
)

# install packages from source
install.packages("./iuftools", repos = NULL, type="source")

# tex setup
tinytex::install_tinytex()
tinytex::tlmgr_install("babel-german")
