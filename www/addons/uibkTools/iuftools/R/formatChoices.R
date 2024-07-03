#' Function to convert a raw_choices vector to a formatted choices vector
#'
#' @param raw_choices character list.
#' @param prefix character.
#' @param suffix character.
#' @param separator character.
#' @param digits integer. Number of digits for formatting
#' @export
formatChoices = function(raw_choices, prefix="", suffix="", separator=" ", digits=2) {
  choices = c()
  print(raw_choices)
  for (i in 1:length(raw_choices)) {
    context = "%{value}s"
    if (prefix != "") context = paste("%{prefix}s%{sep}s", context, sep="")
    if (suffix != "") context = paste(context, "%{sep}s%{suffix}s", sep="")
    choices[i] = formatString(context, prefix=prefix, value=eform(raw_choices[i], digits=prec), suffix=suffix, sep=separator)
  }
  return(choices)
}