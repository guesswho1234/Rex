#'Names and formats a forward rate
#'
#' @param i numeric. Interest rate
#' @param n2 integer. End of period
#' @param n1 integer. Start of period
#' @param slash integer. Numer of backslashes for formatting
#' @export
fwform <- function(i, n2=1, n1=0, slash=2) {
	sh <- paste(replicate(slash, "\\"), collapse = "")
	txt <- paste(fwname(n2, n1, slash), "=",eform(i*100), sh, "%", sep="")
	return(txt)
}

#'Names a forward rate
#'
#' @param n2 integer. End of period
#' @param n1 integer. Start of period
#' @param slash integer. Numer of backslashes for formatting
fwname <- function(n2=1, n1=0, slash=2) {
	sh <- paste(replicate(slash, "\\"), collapse = "")
	if (n1 == 0) {
		txt <- paste("die Spotrate $", sh, "text{r}_",n2,"$", sep="")
	}
	else {
		txt <- paste("die Forwardrate $", sh, "text{r}_{",n1, n2,"}$", sep="")
	}
	return(txt)
}
