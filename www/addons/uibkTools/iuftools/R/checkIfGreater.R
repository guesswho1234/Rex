#' Assert function to make sure that second parameter is strictly greater than first parameter.
#' If not, execution will stop with error
#' It will use catg and tnum (standard in each iuf question) in the error message to identify the problematic question
#'
#' @param k1 numeric.
#' @param k2 numeric.
#' @param prec integer. Presision to check
#' @export
#' @examples
#' checkIfGreater(1.6, 1.5, prec=2) ## will stop with error as 2nd parameter is smaller
#' checkIfGreater(1.1155, 1.1166, prec=2) ## will stop with error as rounding to 2 digits is identical
#' checkIfGreater(1.1155, 1.1166, prec=3) ## will pass though
checkIfGreater <- function(k1, k2, prec = 0) {
	if (round(k1*10^prec) >= round(k2*10^prec)) {
		stop(paste("Sanity check for equality failed!", k1, ">=", k2))
	}
}
