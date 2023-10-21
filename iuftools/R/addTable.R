#' Wrapper function for xtable
#' used for simple tables like bond characteristics
#' @param dat dataframe.
#' @param rotate logical.
#' @export
#' @return latex code with content of dataframe
addTable <- function(dat, rotate = TRUE, hafter = NULL) {
	for(i in 1:ncol(dat)){
		dat[,i] <- paste("\\quad", dat[,i], "\\quad")
	}
	colnames(dat) <- paste("\\quad", colnames(dat), "\\quad")
	if (rotate) return(print(xtable(t(dat), align=paste("l",paste(rep("c",nrow(dat)),
			collapse=""), sep="")),hline.after=hafter, include.colnames=FALSE,
			sanitize.text.function = identity, sanitize.colnames.function = identity, latex.environment=NULL))
	return(print(xtable(dat, align=paste("l",paste(rep("c",ncol(dat)),
			collapse=""), sep="")),hline.after=hafter, include.rownames=FALSE,
			sanitize.text.function = identity, sanitize.colnames.function = identity, latex.environment=NULL))
}
