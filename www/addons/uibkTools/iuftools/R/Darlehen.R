#' An S4 class to represent a loan
#'
#'
#' @slot k0 numeric. Nominale
#' @slot i numeric. Darlehenszins
#' @slot t numeric. Laufzeit
#' @slot typ character. valid is "ann", "end", "const"
#' @slot fee numeric. Nachschuessige Geb
#' @slot initfee numeric Einmalige Geb
#' @slot freijahre integer.
#' @slot tilgung numeric vector. Tilgungsplan
#' @slot zinsen numeric vector. Zahlungsstrom Zinsen
#' @slot schuld numeric vector. Restschuld
#' @slot fees numeric vector. Zahlungsstrom Geb
#' @slot zahlungen numeric vector. Zahlungsstrom Summe
#'
#' @export
#'
#' @section Constructor:
#' \code{newDarlehen(typ="??", nom, i, t, ...)}
#'
#' @section Methods:
#' \itemize{
#' \item \code{getTyp(dar)} gives a string representation (e.g. "Zerobond")
#' \item \code{getTable(dar)} returns a latex table with cash flows
#' \item \code{getKonditionen(dar)} returns a latex table with all characteristics
#'}
#'
#' @examples
#' dar <- newDarlehen(typ="ann", 1000, 0.05, 4) ## Annuitaetendarlehen aus Sicht Schuldner
#' dar@zinsen ## returns c(0.00000, -50.00000, -38.39941, -26.21879, -13.42913)
#' dar@zahlungen ## returns c(1000.0000, -282.0118, -282.0118, -282.0118, -282.0118)
#'
setClass(Class="Darlehen",
		representation(
				k0="numeric",
				i="numeric",
				t="numeric",
				typ="numeric",
				fee="numeric",
				initfee="numeric",
				freijahre="numeric",
				tilgung="numeric",
				zinsen="numeric",
				schuld="numeric",
				fees="numeric",
				zahlungen="numeric"
		)
)

newDarlehen <- function(k0, i, t, typ="konst", fee=0, initfee=0, freijahre=0) {
	tmp <- new(Class="Darlehen")
	tmp@k0 <- k0
	tmp@i <- i
	tmp@t <- t
	if (typ == "ann") tmp@typ <- 2
	else if (typ == "end") tmp@typ <- 3
	else tmp@typ <- 1
	tmp@fee <- fee
	tmp@initfee <- initfee
	tmp@freijahre <- freijahre
	time <- c(0:t)
	if (tmp@typ == 1 || tmp@typ ==3) {
		tmp@tilgung <-
				if (tmp@typ == 1) c(rep(0, 1+freijahre),rep(-k0/(t-freijahre), (t-freijahre)))
				else c(rep(0, t), -k0)
		tmp@schuld <- k0 - tmp@tilgung[1]
		for(j in 2:(length(tmp@tilgung))) {
			tmp@schuld[j] <- tmp@schuld[j-1]+tmp@tilgung[j]
		}
		tmp@zinsen <- c(0,(-tmp@schuld*tmp@i)[1:length(tmp@schuld)-1])
	}
	if (tmp@typ == 2) {
		zs <- -c(0, rep(k0*i, freijahre), rep(k0/rbwf(1+i,t-freijahre), t-freijahre))
		tmp@schuld <- k0
		tmp@zinsen <- 0
		tmp@tilgung <- 0
		for (j in 2:(t+1)) {
			tmp@zinsen[j] <- -tmp@schuld[j-1]*i
			tmp@tilgung[j] <- zs[j]-tmp@zinsen[j]
			tmp@schuld[j] <- tmp@schuld[j-1]+tmp@tilgung[j]
		}
	}
	if(initfee != 0) initfee <- -abs(initfee)
	if(fee != 0) fee <- -abs(fee)
	tmp@fees <- c(initfee, rep(fee, t))
	tmp@zahlungen <- c(k0, rep(0,t))+tmp@zinsen+tmp@tilgung+tmp@fees
	return(tmp)
}

setGeneric(name="getTyp",def=function(tmp){standardGeneric("getTyp")})
setMethod(f="getTyp",signature="Darlehen",
		definition=function(tmp){
			if (tmp@typ == 1) return("konstante Tilgung")
			if (tmp@typ == 2) return("Annuit\\\"atentilgung")
			return("endf\\\"allige Tilgung")
		}
)

setGeneric(name="getTable",def=function(tmp){standardGeneric("getTable")})
setMethod(f="getTable",signature="Darlehen",
		definition=function(tmp){
			library(xtable)
			t <- c(0:tmp@t)
			df <- data.frame(t)
			df["Nominale"] <- c(eform(tmp@k0, 0), rep("", tmp@t))
			df["Tilgung"] <- eform(tmp@tilgung, 0)
			df["Zinsen"] <- eform(tmp@zinsen, 0)
			df["Sonst."] <- eform(tmp@fees, 0)
			df["Summe Zahlungen"] <- eform(tmp@zahlungen, 0)
			df["Schuldenstand"] <- eform(tmp@schuld, 0)
			return(print(xtable(df, align=paste("|l|",paste(rep("c|",ncol(df)),
													collapse=""), sep="")),hline.after=NULL, include.rownames=FALSE,
							sanitize.text.function = identity, sanitize.colnames.function = identity, latex.environment=NULL))

		}
)

setGeneric(name="getKonditionen",def=function(tmp){standardGeneric("getKonditionen")})
setMethod(f="getKonditionen",signature="Darlehen",
		definition=function(tmp){
			Darlehensbetrag <- paste0('$', eform(tmp@k0, 0), '$')
			tab <- data.frame(Darlehensbetrag)
			tab["Laufzeit"] <- paste0("$", tmp@t, "$ ", "Jahre")
			if (tmp@freijahre > 0) tab["Tilgungsfreie Jahre"] <- paste0("$", tmp@freijahre, "$")
			tab["Nominalzinssatz"] <- paste0("$", eform(tmp@i*100), "$ Prozent p.a.")
			tab["Tilgungsform"] <- getTyp(tmp)
			if (tmp@initfee > 0) tab["Einmalige Bearbeitungsgeb\\\"uhr in t=0"] <- paste0("$", eform(tmp@initfee, 0), "$")
			if (tmp@fee > 0) tab["J\\\"ahrliche Kontof\\\"uhrungsgeb\\\"uhr"] <- paste0("$", eform(tmp@fee, 0), "$")
			return(addTable(tab))
		}
)
