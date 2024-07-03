#' Translates logical vector to German feedback
#'
#' @param eng logical vector.
#' @export
gersol <- function(eng) {
	sol <- character(length(eng))
	for (i in c(1:length(eng))) {
		if (eng[i]) sol[i] <- "Richtig"
		else sol[i] <- "Falsch"
	}
	return(sol)
}
