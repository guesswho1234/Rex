#' Calculate annuity factor
#'
#' @param q numeric. discounting factor
#' @param n integer. periods
#' @export
rbwf <- function(q,n) {
	return((q^n-1)/((q-1)*q^n))
}
