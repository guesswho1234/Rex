# tell the buildpack to install the required packages:
# using the helper caches the installed packages between deployments afaik.
helpers.installPackages(
  "exams",
  "xtable",
  "tth",
  "png",
  "callr"
  #"pdftools",
  #"staplr"
)

#install packages causing problems
install.packages("pdftools", verbose = TRUE, INSTALL_opts="--no-test-load", include.only = c("pdf_info", "pdf_convert")) # test if it works when only necessary functions are usied
#install.packages("pdftools", verbose = TRUE, INSTALL_opts="--no-test-load") # test if disabling test-load solves the problem (does not)
#install.packages("staplr", verbose = TRUE)

# special case of installing iuftools from source
install.packages("./iuftools", repos = NULL, type="source")

# tinytex setup
tinytex::install_tinytex()