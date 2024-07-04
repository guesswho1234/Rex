#' Create standfardized signature for a iuf exams question
#'
#' @param t character. The type of quest: "mc" (multiple choice), "mco" (multiple choice at least one correct), "sc" (single choice), "num" (one numeric result), "per" (one percent result), "pers" (several percent results), "perp" (percentage points), "perps" (several percentage points)
#' @param prec integer. The precision, i.e. number of digits to round
#' @param diff integer. Depreciated
#' @export
#' @return string with the complete signature
#' @examples
#' sig("mc", prec = 2)
sig <- function(t, prec = 0, diff = -1) {
	text=""
	mcFlag <- FALSE
	mcoFlag <- FALSE
	if (!missing(t)) {
		tmp <- buildSig(t[1], prec)
		if (t[1] == "mc") mcFlag <- TRUE
		if (t[1] == "mco") mcoFlag <- TRUE
		text <- paste(toupper(substring(tmp, 1,1)), substring(tmp, 2), sep="")
		if (length(t) > 1) {
			text <- paste(text, "und", buildSig(t[2], prec))
			if (t[2] == "mc") mcFlag <- TRUE
			if (t[2] == "mco") mcoFlag <- TRUE
		}
		text <- paste(text, ".", sep="")
		if (mcFlag) text <- paste(text, "Es k\\\\\"onnen keine, eine oder mehrere Aussagen richtig sein.")
		if (mcoFlag) text <- paste(text, "Es k\\\\\"onnen eine oder mehrere Aussagen richtig sein.")

	}
	return(text)
}

#' @keywords internal
buildSig <- function(text1, digits) {
	if (text1 == "num") text <- signature_num(digits)
	else if (text1 == "nums") text <- signature_num(digits, plural = TRUE)
	else if (text1 == "per") text <- signature_percent(digits)
	else if (text1 == "pers") text <- signature_percent(digits, plural = TRUE)
	else if (text1 == "perp") text <- signature_percent(digits, punkte = TRUE)
	else if (text1 == "perps") text <- signature_percent(digits, plural = TRUE, punkte = TRUE)
	else if (text1 == "mc") text <- "markieren Sie alle korrekten Aussagen"
	else if (text1 == "mco") text <- "markieren Sie alle korrekten Aussagen"
	else if (text1 == "sc") text <- "markieren Sie die korrekte Aussage"
	return(text)
}

#' @keywords internal
signature_num <- function(precision, diff = -1, plural = FALSE) {
	plu <- if(plural) "die Endergebnisse" else "das Endergebnis"
	wie <- if(precision == 0) "ganzzahlig" else paste("auf", numToText(precision), "Kommastelle")
	if (precision > 1) wie <- paste(wie, "n", sep="")
	text <- paste("runden Sie", plu, wie)
	if (diff >= 0) {text <- paste(text, signature_points(diff))}
	return(text)
}

#' @keywords internal
signature_percent <- function(precision, diff = -1, plural = FALSE, punkte = FALSE) {
	plu <- if(plural) "die Endergebnisse" else "das Endergebnis"
	pu <- if(punkte) "Prozentpunkten" else "Prozent"
	wie <- if (precision == 0) "ganze Zahlen" else paste(numToText(precision), "Kommastelle")
	if (precision > 1) wie <- paste(wie, "n", sep="")
	text <- paste("geben Sie", plu, "in", pu, "und auf", wie, "gerundet an")
	if (diff >= 0) {text <- paste(text, signature_points(diff))}
	return(text)
}

#' @keywords internal
numToText <- function(num) {
	txt <- c("eine", "zwei", "drei", "vier", "f\"unf", "sechs")
	return(txt[num])
}
