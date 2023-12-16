# tell the buildpack to install the required packages:
# using the helper caches the installed packages between deployments afaik.
helpers.installPackages(
  "exams",
  "xtable",
  "tth",
  "callr",
  "staplr"
)

# special case of installing iuftools from source
install.packages("./iuftools", repos = NULL, type="source")

# tinytex setup
tinytex::install_tinytex()