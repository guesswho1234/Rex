#' An S4 class to represent an asset
#'
#' Used in some tasks to scramble stuff that you own. Challenge is always to calculate the NPV.
#'
#' @slot txt character. Verbal representation
#' @slot k0 numeric. NPV
#' @slot distractor numeric. Distractor, can be identical to k0
#'
#' @export
#'
#' @section Constructor:
#' \code{newAsset(type, ieff, nmax, kmax, n, k)}
#' type is:
#' \itemize{
#' \item 1: Zukuenftige Zahlung
#' \item 2: Rente, Start in t0 oder t1
#' \item 3: Zahlung in der Vergangenheit
#' \item 4: Rente in der Vergangenheit
#' \item 5: Ein Barwert
#' }
#' nmax integer. Maximale Laufzeit
#' kmax numeric. Maximaler NPV
#'
#' @section Methods:
#' \itemize{
#' \item \code{getAssetTxt(ass)} getter for ass@txt
#' \item \code{getVal(ass)} getter for ass@k0
#' \item \code{getDistractor(ass)} getter for ass@distractor
#'}
#'
#' @examples
#' newAsset(2, 0.05, 6, 100000)
#'
setClass(Class="Asset",
		representation(
				txt="character",
				k0="numeric",
				distractor="numeric"
		)
)

### Getter

setGeneric(name="getAssetTxt",def=function(object){standardGeneric("getAssetTxt")})
setMethod(f="getAssetTxt",signature="Asset",
		definition=function(object){return(object@txt)}
)

setGeneric(name="getVal",def=function(object){standardGeneric("getVal")})
setMethod(f="getVal",signature="Asset",
		definition=function(object){return(object@k0)}
)

setGeneric(name="getDistractor",def=function(object){standardGeneric("getDistractor")})
setMethod(f="getDistractor",signature="Asset",
		definition=function(object){return(object@distractor)}
)

newAsset <- function(type, ieff, nmax, kmax, n, k){
		tmp <- new(Class="Asset")
		if (kmax < 5000) {stop("AssetClass: kmax is set too low!")}
		if (nmax < 4) {stop("AssetClass: nmax is set too low!")}
		if(type == 1) {
			# zukünftige Zahlung, kein Distraktor
			if (missing(k)) k <- sample(1:round(kmax / 1000), 1) * 1000
			if (missing(n)) n <- sample(2:nmax, 1)
			tmp@k0 <- k / (1+ieff)^n
			tmp@distractor <- tmp@k0
			frame <- sample(c("Eine Lebensversicherung, die",
							"Ein Kapitalsparbuch, das",
							"Ein Festgeldkonto, das"),1)
			tmp@txt <- paste(frame, "Ihnen in", n, "Jahren", eform(k) , "Euro auszahlen wird.")
		}
		if(type == 2) {
			# Rente Zukunft
			lag <- sample(c(0,1),1) # t=0 oder t=1
			if (missing(k)) k <- sample(49:(kmax/100), 1) * 100
			if (missing(n)) n <- sample(3:nmax, 1)
			a <- floor(k / rbwf(1+ieff, n) / (1 + ieff)^(1 - lag) / 100) * 100
			tmp@k0 <- rbw(a,1+ieff,n) * (1 + ieff)^(1 - lag)
			tmp@distractor <- rbw(a,1+ieff,n) * (1 + ieff)^lag # Distraktor bzgl Zeitpunkt der ersten Zahlung
			frame1 <- paste("Eine Forderung gegen\\\"uber Ihrem Studienkollegen, die Ihnen in den kommenden	Jahren jeweils", eform(a), "Euro pro Jahr einbringen wird")
			frame2 <- paste("Die Zusage Ihrer Eltern, Sie in den kommenden Jahren jeweils mit", eform(a), "Euro pro Jahr zu unterst\\\"utzen")
			frame3 <- paste("Ein Gewinn aus einem Brieflos, der Ihnen in den kommenden Jahren eine Rentenzahlung von jeweils", eform(a), "Euro pro Jahr einbringen wird")
			tmp@txt <- paste(sample(c(frame1, frame2, frame3), 1), " (1. Zahlung in t=",
					lag, ", letzte Zahlung in t=", n - 1 + lag, ").", sep = "")
		}
		if(type == 3) {
			# vergangene Zahlung, kein Distraktor
			if (missing(n)) n <- sample(2:10, 1)
			if (missing(k)) k <- sample(1:floor(kmax / 100 / (1 + ieff)^n), 1) * 100
			tmp@k0 <- k * (1+ieff)^n
			tmp@distractor <- tmp@k0
			tmp@txt <- paste("Ein Sparbuch, auf das", sample(c("Sie", "Ihre Eltern", "Ihre Grosseltern"), 1),
					"vor", n, "Jahren", eform(k), "Euro eingezahlt haben.")
		}
		if(type == 4) {
			# Rente Vergangenheit
			if (missing(k)) k <- sample(49:(kmax/100), 1) * 100
			if (k < 20000) {nmax <- 10}
			if (missing(n)) n <- sample(3:max(nmax, 15), 1)
			a <- floor(k * ieff / ((1+ieff)^n-1) / 100) * 100
			tmp@k0 <- rbw(a,1+ieff,n) * (1+ieff)^n
			tmp@distractor <- rbw(a,1+ieff,n) * (1+ieff)^(n-1) # Distraktor bzgl Zeitpunkt der ersten Zahlung
			frame1 <- paste("Ein Sparbuch, das Ihre Mutter vor", n - 1 ,
					"Jahren f\\\"ur Sie angelegt hat und auf das Sie bis heute j\\\"ahrlich",
					eform(a), "Euro eingezahlt hat (1. Zahlung vor genau", n - 1,
					"Jahren, letzte Zahlung heute). Ihre Mutter zahlt in Zukunft nichts mehr auf dieses Sparbuch ein.")
			frame2 <- paste("Einen Sparvertrag, bei dem Sie in den vergangenen",
					"Jahren jeweils", eform(a), "Euro eingezahlt haben (1. Zahlung vor genau", n - 1,
					"Jahren, letzte Zahlung heute).")
			tmp@txt <- sample(c(frame1, frame2), 1)
		}
		if(type == 5) {
			# Barwert, kein Distraktor
			if (missing(k)) k <- sample(1:floor(kmax / 100), 1) * 100
			tmp@k0 <- k
			tmp@distractor <- tmp@k0
			frame1 <- paste("Ein Sparbuch, auf dem sich genau",	eform(k), "Euro befinden.")
			frame2 <- paste("Ein Aktiendepot im Wert von ", eform(k), "Euro das Sie sofort verkaufen.")
			frame3 <- paste("Barverm\\\"ogen im Wert von ", eform(k), "Euro.")
			tmp@txt <- sample(c(frame1, frame2, frame3), 1)
		}
		checkIfGreater(0, tmp@k0)
		checkIfGreater(0, tmp@distractor)
		return(tmp)
}
