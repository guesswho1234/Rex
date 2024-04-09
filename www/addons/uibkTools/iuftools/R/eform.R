#' Number to String.
#' This function converts a number to a string with . as thousand sep , as decimal sep and it rounds the number with a hand-made rounding funtion. It should make sure that float imprecision problems are mitigated
#' Thus, do not use eform(round(1235.55, 1), 1)! Let eform do rounding!
#'
#' @param n numeric. The number to convert
#' @param digits numeric. Number of digits, -1 for displaying all significant digits
#' @export
#' @return character. Representation of the number
#' @examples
#' eform(1235.55, 1)
#'
eform <- function(n, digits=-1) {
	if (is.list(n)) {
		for (res in 1:length(n)) {
			n[[res]] <- eform(n[[res]], digits)
		}
		return(n)
	}
	if (digits == -1) {
		return(formatC(n, format="fg", decimal.mark = "{,}", big.mark = "."))
	}
	# Noch ein Sicherheitsnetz fuer das Runden, sollte Warnung ausspucken wenn es ev. ein Problem gibt.
	for (res in 1:length(n)) {
		if (n[res]<0) q <- n[res] - 0.0000001
		else q <- n[res] + 0.0000001
		neu <- formatC(roundFloat(q, digits), format="f", decimal.mark = "{,}", big.mark = ".", digits=digits)
		alt <- formatC(roundFloat(n[res], digits), format="f", decimal.mark = "{,}", big.mark = ".", digits=digits)
		if (neu != alt) {
			precise <- sprintf("%.20f",n[res])
			warning(paste("Achtung, ev Rundungsproblem.", precise, "wird gerundet zu", alt))
		}
	}
	return(formatC(roundFloat(n, digits), format="f", decimal.mark = "{,}", big.mark = ".", digits=digits))
}

#' @keywords internal
roundFloat = function(x, n) {
  posneg = sign(x)
  z = abs(x)*10^n
  z = z + 0.5 + sqrt(.Machine$double.eps)
  z = trunc(z)
  z = z/10^n
  z*posneg
}
