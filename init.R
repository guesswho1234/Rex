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
  "openssl"
)

# special case of installing iuftools from source
install.packages("./iuftools", repos = NULL, type="source")

# tinytex setup
tinytex::install_tinytex()
# alternative to use installed tex distribution
# options(exams_tex = "tools")
