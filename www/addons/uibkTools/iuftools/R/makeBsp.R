#' Wrapper for exams2openolat to create unscrambeled pool
#' Sets the global variable MAKEBSP to TRUE (to set seed in each exam) and creates 1 scrambling
#'
#' @param name character. Exam name
#' @param myexam list. Exam files to include
#' @export
makeBsp <- function(name, myexam) {
	MAKEBSP <<- TRUE
	EXAMFLAG <<- FALSE
	whatToDo(exam_list = myexam)
	set.seed(1)
	exams2openolat(myexam, n = 1, name = name,
			eval = list(partial = FALSE, negative = FALSE),
			dir = "output",
			edir = "Questions",
			qti="2.1",
			solutionswitch = TRUE,
			stitle = "Aufgabe", ititle = "Frage",
            maxattempts = 1000,
            cutvalue = 1000)
	MAKEBSP <- FALSE
}

#' Wrapper for exams2pdf
#' Sets the global variable MAKEBSP to TRUE (to set seed in each exam) and creates 1 scrambling
#'
#' @param name character. Exam name
#' @param myexams list. Exam files to include
#' @export
makeBspPDF <- function(name, myexams) {
  MAKEBSP <<- TRUE
  EXAMFLAG <<- FALSE
  exams2pdf(myexams, n = 1, name = name,
                 dir = "output",
                 edir = "Questions",
                 template = c("templates/plain_bsp.tex"),
                 header = list(
                   Chapter = gsub("_", "\\\\_", name)
                 ))
}

#' Wrapper for exams2html
#' Sets the global variable MAKEBSP to TRUE (to set seed in each exam) and creates 1 scrambling
#'
#' @param name character. Exam name
#' @param myexams list. Exam files to include
#' @export
makeBspHTML <- function(name, myexams) {
  	MAKEBSP <<- TRUE
  	EXAMFLAG <<- FALSE
	exams2html(myexams, n = 1, name = name,
            dir = "output",
            edir = "Questions",
            question = "<h4>Aufgabe</h4>",
            solution = "<h4>L&ouml;sung</h4>",
            template = c("templates/plain_bsp.html"),
            encoding = "utf8"
	)
}
