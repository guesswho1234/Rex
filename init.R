# tell the buildpack to install the required packages:
# using the helper caches the installed packages between deployments afaik.
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

# special case of installing iuftools from source
install.packages("./iuftools", repos = NULL, type="source")

# tex setup
tinytex::install_tinytex()
tlmgr_install("babel")
