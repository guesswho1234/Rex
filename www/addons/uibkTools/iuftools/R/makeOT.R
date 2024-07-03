#' Wrapper for exams2openolat to create online test with 100 scramblings
#'
#' @param name character. Exam name
#' @param myexam list. Exam files to include
#' @export
makeOT <- function(name, myexam) {
	MAKEBSP <<- FALSE
	EXAMFLAG <<- TRUE
	whatToDo(exam_list = myexam)
	addExamHistory(exam_list = myexam, exam_name = name)
	exams2openolat(myexam, n = 100, name = name,
			eval = list(partial = FALSE, negative = FALSE),
			shufflesections = FALSE,
			dir = "output",
			edir = "Questions",
			qti="2.1",
			stitle = "Aufgabe", ititle = "Frage",
			navigation = "linear",
			solutionswitch = FALSE,
            maxattempts = 1000,
            cutvalue = 1000)
}
