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
install.packages("pdftools", verbose = TRUE, INSTALL_opts=c("--no-test-load"))
library(pdftools)
#install.packages("staplr", verbose = TRUE)

# special case of installing iuftools from source
install.packages("./iuftools", repos = NULL, type="source")

# tinytex setup
tinytex::install_tinytex()