#' Wrapper for exams2openolat to create corona online final exam with 100 scramblings
#'
#' @param name character. Exam name
#' @param myexam list. Exam files to include
#' @export
makeSK <- function(name, myexam) {
	MAKEBSP <<- FALSE
	EXAMFLAG <<- TRUE
	whatToDo(exam_list = myexam)
	exams2openolat(myexam, n = 100, name = name,
			eval = list(partial = TRUE, negative = FALSE),
			shufflesections = TRUE,
			stitle = "Aufgabe", ititle = "Frage",
			dir = "output",
			edir = "Questions",
			qti="2.1",
			solutionswitch = FALSE, maxattempts = 1000, cutvalue = 1000)
}
