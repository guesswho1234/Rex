#' An S4 class to represent a bond
#'
#'
#' @slot nom numeric. Nominale
#' @slot emk numeric. Emissionskurs
#' @slot i numeric. Kupon
#' @slot t numeric. Laufzeit
#' @slot typ character. valid is "serie", "zero", "float", "end"
#' @slot fee numeric. Nachschuessige Geb
#' @slot initfee numeric Einmalige Geb
#' @slot tilgung numeric vector. Tilgungsplan
#' @slot zinsen numeric vector. Zahlungsstrom Zinsen
#' @slot schuld numeric vector. Restschuld
#' @slot fees numeric vector. Zahlungsstrom Geb
#' @slot zahlungen numeric vector. Zahlungsstrom Summe
#'
#' @export
#'
#' @section Constructor:
#' \code{newAnleihe(nom=100, ...)}
#'
#' @section Methods:
#' \itemize{
#' \item \code{getAnTyp(an)} gives a string representation (e.g. "Zerobond")
#' \item \code{getAnTable(an)} returns a latex table with cash flows
#' \item \code{getAnKonditionen(an)} returns a latex table with all characteristics
#' \item \code{getAnWert(an, rlz, i)} returns the NPV based on maturity and interest rate
#' \item \code{getAnClean(an, rlz, i)} returns the fair clean price based on maturity and interest rate
#' \item \code{getAnDirty(an, rlz, i)} returns the fair dirty price based on maturity and interest rate
#' \item \code{getAnStueckzinsen(an, rlz, i)} returns the accrued interest based on maturity
#'}
#'
#' @examples
#' an <- newAnleihe(100, 0.05, 4) ## a standard bond from issuers perspective
#' an@zinsen ## returns c(0, -5, -5, -5, -5)
#' an@zahlungen ## returns c(100, -5, -5, -5, -105)
#' getAnWert(an, 2.75, 0.04) ## returns -103.7878 (issuers perspective!)
#'
setClass(Class="Anleihe",
		representation(
				nom="numeric",
				emk="numeric",
				i="numeric",
				t="numeric",
				typ="numeric",
				fee="numeric",
				initfee="numeric",
				tilgung="numeric",
				zinsen="numeric",
				schuld="numeric",
				fees="numeric",
				zahlungen="numeric"
		)
)

newAnleihe <- function(nom=100, i=0, t=1, typ="end", emk=1, fee=0, initfee=0) {
	tmp <- new(Class="Anleihe")
	tmp@nom <- nom
	tmp@emk <- emk
	tmp@i <- i
	tmp@t <- t
	if (typ == "serie") tmp@typ <- 1
	else if (typ == "zero") tmp@typ <- 2
	else if (typ == "float") tmp@typ <- 4
	else tmp@typ <- 3
	tmp@fee <- fee
	tmp@initfee <- initfee
	time <- c(0:t)
	if (tmp@typ == 1 || tmp@typ ==3) {
		tmp@tilgung <-
				if (tmp@typ == 1) c(0,rep(-nom/t, t))
				else c(rep(0, t), -nom)
		tmp@schuld <- nom - tmp@tilgung[1]
		for(j in 2:(length(tmp@tilgung))) {
			tmp@schuld[j] <- tmp@schuld[j-1]+tmp@tilgung[j]
		}
		tmp@zinsen <- c(0,(-tmp@schuld*tmp@i)[1:length(tmp@schuld)-1])
	}
	if (tmp@typ == 2) {
		tmp@tilgung <- c(rep(0, t), -nom)
		tmp@zinsen <- rep(0, t+1)
		tmp@schuld <- c(rep(nom, t), 0)
	}
	if (tmp@typ == 4) {
		tmp@tilgung <- c(rep(0, t), -nom)
		tmp@zinsen <- c(0, -tmp@nom*tmp@i, rep(NA, t-1))
		tmp@schuld <- c(rep(nom, t), 0)
	}
	if(initfee != 0) initfee <- -abs(initfee)
	if(fee != 0) fee <- -abs(fee)
	tmp@fees <- c(initfee, rep(fee, t))
	tmp@zahlungen <- c(nom*emk, rep(0,t))+tmp@zinsen+tmp@tilgung+tmp@fees
	return(tmp)
}

setGeneric(name="getAnTyp",def=function(tmp){standardGeneric("getAnTyp")})
setMethod(f="getAnTyp",signature="Anleihe",
		definition=function(tmp){
			if (tmp@typ == 1) return("Serienanleihe")
			if (tmp@typ == 2) return("Zerobond")
			return("endf\\\"allige Kuponanleihe")
		}
)

setGeneric(name="getAnTable",def=function(tmp){standardGeneric("getAnTable")})
setMethod(f="getAnTable",signature="Anleihe",
		definition=function(tmp){
			library(xtable)
			t <- c(0:tmp@t)
			df <- data.frame(t)
			df["Emission"] <- c(eform(tmp@nom*tmp@emk, 0), rep("", tmp@t))
			df["Tilgung"] <- eform(tmp@tilgung, 0)
			df["Zinsen"] <- eform(tmp@zinsen, 0)
			df["Sonst."] <- eform(tmp@fees, 0)
			df["Summe Zahlungen"] <- eform(tmp@zahlungen, 0)
			df["Restschuld"] <- eform(tmp@schuld, 0)
			return(print(xtable(df, align=paste("|l|",paste(rep("c|",ncol(df)),
													collapse=""), sep="")),hline.after=NULL, include.rownames=FALSE,
							sanitize.text.function = identity, sanitize.colnames.function = identity, latex.environment=NULL))

		}
)

setGeneric(name="getAnKonditionen",def=function(tmp){standardGeneric("getAnKonditionen")})
setMethod(f="getAnKonditionen",signature="Anleihe",
		definition=function(tmp){
			Nominale <- eform(tmp@nom, 0)
			tab <- data.frame(Nominale)
			tab["Kupon"] <- paste0("$", eform(tmp@i*100), "$ Prozent p.a.")
			tab["Laufzeit"] <- paste(tmp@t, "Jahre")
			if (tmp@emk != 0) tab["Emissionskurs"] <- paste(eform(tmp@emk*100), "Prozent")
			tab["Tilgungskurs"] <- "100 Prozent"
			tab["Tilgungsform"] <- getAnTyp(tmp)
			if (tmp@typ == 1) tab["Tilgungsform"] <- paste(tmp@t, "Serien")
			if (tmp@initfee > 0) tab["Emissionsgeb\\\"uhr"] <- eform(tmp@initfee, 0)
			if (tmp@fee > 0) tab["Sonstige Kosten pro Jahr"] <- eform(tmp@fee, 0)
			return(addTable(tab))
		}
)

setGeneric(name="getAnWert",def=function(tmp, rlz, i){standardGeneric("getAnWert")})
setMethod(f="getAnWert",signature="Anleihe",
		definition=function(tmp, rlz, i){
			if(missing(rlz)) rlz <- tmp@t
			veclen <- ceiling(rlz)
			t <- seq(rlz-veclen+1, rlz)
			if(length(i) == 1) i <- rep(i, veclen)
			if(length(i) != veclen) return(NULL)
			if(tmp@t < rlz) return(NULL)
			if (tmp@typ <= 3) {
				return(sum(tmp@zahlungen[(tmp@t-veclen+1):tmp@t+1]/(1+i)^t))
			}
			return(-tmp@nom*(1+tmp@i)/(1+i)^t[1])
		}
)

setGeneric(name="getAnClean",def=function(tmp, rlz, i){standardGeneric("getAnClean")})
setMethod(f="getAnClean",signature="Anleihe",
		definition=function(tmp, rlz, i){
			if(missing(rlz)) rlz <- tmp@t
			veclen <- ceiling(rlz)
			t <- seq(rlz-veclen+1, rlz)
			if(length(i) == 1) i <- rep(i, veclen)
			if(length(i) != veclen) return(NULL)
			if(tmp@t < rlz) return(NULL)
			if (tmp@typ <= 3) {
				return(sum(tmp@zahlungen[(tmp@t-veclen+1):tmp@t+1]/(1+i)^t)/-tmp@nom - tmp@i*(ceiling(rlz)-rlz))
			}
			return((1+tmp@i)/(1+i)^t[1] - tmp@i*(ceiling(rlz)-rlz))
		}
)

setGeneric(name="getAnDirty",def=function(tmp, rlz, i){standardGeneric("getAnDirty")})
setMethod(f="getAnDirty",signature="Anleihe",
		definition=function(tmp, rlz, i){
			if(missing(rlz)) rlz <- tmp@t
			veclen <- ceiling(rlz)
			t <- seq(rlz-veclen+1, rlz)
			if(length(i) == 1) i <- rep(i, veclen)
			if(length(i) != veclen) return(NULL)
			if(tmp@t < rlz) return(NULL)
			if (tmp@typ <= 3) {
				return(sum(tmp@zahlungen[(tmp@t-veclen+1):tmp@t+1]/(1+i)^t)/-tmp@nom)
			}
			return((1+tmp@i)/(1+i)^t[1])
		}
)

setGeneric(name="getAnStueckzinsen",def=function(tmp, rlz, i){standardGeneric("getAnStueckzinsen")})
setMethod(f="getAnStueckzinsen",signature="Anleihe",
		definition=function(tmp, rlz){
			return(tmp@i * -tmp@nom * (ceiling(rlz)-rlz))
		}
)
