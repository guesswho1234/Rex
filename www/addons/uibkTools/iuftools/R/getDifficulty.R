#' Function that translates difficulty levels [0;3] to points [1;3]
#' Used primarily in OLAT examples pool and Onlinetests. For written exams the points for each questions are provided separately.
#' @param diff integer. Between 0 and 3, is specified in each iuf exam question!
#' @export
#' @return integer. Points that OLAT assignes for correct answer of that question
#' @examples
#' usually at the bottom of an iuf question the metainformation uses getDifficulty(diff) to pass diff to specify points

getDifficulty <- function(diff) {
	# return(6)
	if (diff == 0) return(2)
	if (diff == 1) return(2)
	if (diff == 2) return(4)
	if (diff == 3) return(5)
	stop(paste("Error: difficulty must be between 0 and 3! Here it was ", diff))
}
