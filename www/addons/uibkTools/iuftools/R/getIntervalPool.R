#' Get pool questions and solutions for intervals (possibly) containing the correct result
#'
#' @param correct_result numeric. The correct result is the reference point
#' @param max_dev numeric. Maximum positive and negative deviation of intervals from correct result
#' @param digits integer.
#' @export
#' @return list. List containing the question pool and solution pool
#' @examples
#' getIntervalPool(1000, 10, 2)
#'
getIntervalPool <- function(correct_result, max_dev = 0.2, digits = 2) {
  # Define how broad a single range can be
  broadness <- max_dev/sample(11:17, 1)
  # Sanity checks, make sure two intervals cannot overlap
  shift <- runif(1, -broadness/2, broadness/2)
  checkIfEqual(ceiling((correct_result + broadness/2 + shift)*10^digits)/10^digits, floor((correct_result + broadness + shift)*10^digits)/10^digits, prec = digits)
  # Start with correct result
  qpool <- paste0("Das Endergebnis liegt im Intervall [", eform(floor((correct_result-broadness/2 + shift)*10^digits)/10^digits, digits), "; ", eform(ceiling((correct_result + broadness/2 + shift)*10^digits)/10^digits, digits), "]")
  spool <- TRUE
  # Sample position of correct result
  correct_position <- sample(1:5, 1)
  if (correct_position > 1) {
    start_points <- seq(correct_result - 2*broadness + shift, correct_result- max_dev + shift, -broadness*1.5)
    start_Points_below <- sample(start_points, correct_position - 1)
    qpool <- c(qpool, paste0("Das Endergebnis liegt im Intervall [", eform(floor(start_Points_below*10^digits)/10^digits, digits), "; ", eform(ceiling((start_Points_below + broadness)*10^digits)/10^digits, digits), "]"))
    spool <- c(spool, rep(FALSE, length(start_Points_below)))
  }
  if (correct_position < 5) {
    start_points <- seq(correct_result + broadness + shift, correct_result + max_dev + shift - broadness, broadness*1.5)
    start_Points_above <- sample(start_points, 5 - correct_position)
    qpool <- c(qpool, paste0("Das Endergebnis liegt im Intervall [", eform(floor(start_Points_above*10^digits)/10^digits, digits), "; ", eform(ceiling((start_Points_above + broadness)*10^digits)/10^digits, digits), "]"))
    spool <- c(spool, rep(FALSE, length(start_Points_above)))
  }
  sel = sample(length(qpool), 4) # shufflt 4 Fragen aus dem pool
  # Fuegt keine der anderen Antworten... hinzu
  qpool[length(qpool)+1] = "Keine der anderen Antworten ist korrekt."
  spool[length(spool)+1] = sum(spool[sel]) == 0
  sel = sample(c(sel, length(qpool)), 5)
  questions <- qpool[sel]
  solutions <- spool[sel]
  return(list(questions, solutions))
}
