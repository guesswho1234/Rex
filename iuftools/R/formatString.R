#' Function that provices named string formatting
#'
#' @param fmt character. String containing variables
#' @param ... character. Replacements for variables
#' @export
#' @examples
#' formatString("The %{coffee}s costs %{price}s EUR.", coffee="cappuccino", price=2.8)
#' ## The cappuccino costs 2.8 EUR
formatString = function(fmt, ...) {
  args = list(...)
  argn = names(args)
  if(is.null(argn)) return(sprintf(fmt, ...))
  for(i in seq_along(args)) {
    if(argn[i] == "" | is.null(argn[i])) next;
    fmt = gsub(sprintf("%%{%s}", argn[i]), sprintf("%%%d$", i), fmt, fixed = TRUE)
  }
  do.call(sprintf, append(args, fmt, 0))
}
