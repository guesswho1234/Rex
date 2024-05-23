# install packages
helpers.installPackages(
  "shinyjs",
  "shinyWidgets",
  "shinycssloaders",
  "xtable",
  "tth",
  "png",
  "callr",
  "qpdf",
  "pdftools",
  "openssl",
  #"tinytex",
  "shinyauthr",
  "sodium"
)

# special install packages
install.packages("./iuftools", repos=NULL, type="source")
install.packages("exams", repos="http://R-Forge.R-project.org", type="source") # need new version for handling faulty scans properly

# tinytex setup
#tinytex::install_tinytex()
#tinytex::tlmgr_install("babel-german")
