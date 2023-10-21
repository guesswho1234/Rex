#' Wrapper for exams2openolat to create scrambeled example pool with 20 scrambling
#'
#' @param name character. Exam name
#' @param myexam list. Exam files to include
#' @export
makeSt <- function(name, myexam) {
	MAKEBSP <<- FALSE
	EXAMFLAG <<- FALSE
	whatToDo(exam_list = myexam)
	exams2openolat(myexam, n = 20, name = name,
			eval = list(partial = FALSE, negative = FALSE),
			dir = "output",
			edir = "Questions",
			qti="2.1",
			stitle = "Aufgabe", ititle = "Frage",
			solutionswitch = TRUE,
            maxattempts = 1000,
            cutvalue = 1000)
}
