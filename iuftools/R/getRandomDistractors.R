#' Add a number of random distractors
#' drawn from a range vector while making sure that the random distractors do not coincide with existing choices in the exclude vector
#'
#' @param num_distractors integer. Number of distractors to produce
#' @param range numeric vector length 2. Range for distractors
#' @param digits integer.
#' @param exclude numeric vector.
#' @export
getRandomDistractors = function(num_distractors=4, range=c(0, 1), digits=2, exclude=c()) {
  random_distractors = c()
  sorted_range = sort(range)
  for (i in 1:num_distractors) {
    rept <- 0
    repeat {
      rept <- rept + 1
      candidate = round(runif(1, sorted_range[1], sorted_range[2]), digits=digits)
      if (!(candidate %in% c(exclude, random_distractors)))  {
        random_distractors = c(random_distractors, candidate)
        break
      }
      if (rept > 100) {
          stop("Could not find a random distractor within 100 attempts.")
      }
    }
  }
  return(random_distractors)
}
