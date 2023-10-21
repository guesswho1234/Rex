#' Calculate NPV of annuity
#'
#' @param k numeric. annuity
#' @param q numeric. discounting factor
#' @param n integer. periods
#' @export
#' @return NPV
rbw <- function(k,q,n) {
	return(k*rbwf(q,n))
}
