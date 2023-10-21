#' Assert function to make sure that two numbers are different.
#' If the two numbers are too similar, execution will stop with error
#' It will use catg and tnum (standard in each iuf question) in the error message to identify the problematic question
#'
#' @param k1 numeric.
#' @param k2 numeric.
#' @param prec integer. Presision to check
#' @export
#' @examples
#' checkIfEqual(1.1155, 1.1166, prec=2) ## will stop with error as rounding to 2 digits is identical
#' checkIfEqual(1.1155, 1.1166, prec=3) ## will pass though
checkIfEqual <- function(k1, k2, prec = 0) {
	if (round(k1*10^prec) == round(k2*10^prec)) {
		stop(paste("Sanity check for equality failed!", k1, "==", k2, "   Error "), 1)
	}
}
