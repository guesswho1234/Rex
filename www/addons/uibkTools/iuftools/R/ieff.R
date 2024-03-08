#' calculate effective compounding factor
#'
#' @param i numeric. interest rate
#' @param m integer. interest periods per year. 0 for continous compounding
#' @export
ieff <- function(i,m) {
	if (m == 0) return(exp(i)-1)
	return((1+i/m)^m-1)
}
