#' Calculate annuity factor for growing annuity
#'
#' @param i numeric. interest rate
#' @param q numeric. discounting factor
#' @param g numeric. growth rate
#' @param n integer. periods
#' @export
rbwfg <- function(i,n,g = 0, q = 1 + i) {
	return(((q)^n-(1+g)^n)/((q-1-g)*(q)^n))
}
