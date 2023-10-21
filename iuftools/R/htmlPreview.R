#' Wrapper function for exams2html
#'
#' @param questions character list. Questions
#' @param edir character. Directory with questions
#' @param template character. Template to use
#'
#' @export
htmlPreview = function(questions, edir="Questions", template="plain.html") {
  MAKEBSP <<- FALSE
  EXAMFLAG <<- FALSE
  if(.Platform$OS.type == "unix") {
    exams2html(questions,
                      encoding="UTF-8",
                      template=template,
                      converter="pandoc-mathjax",
                      mathjax=TRUE,
                      edir=edir,
                      dir = "output",
                      question="<h4>Aufgabe</h4>",
                      solution="<h4>L&ouml;sung</h4>"
    )
    file_path <- paste0(getwd(), "/output/plain1.html")
    system2("firefox", args = file_path)
  } else {
    return(exams2html(questions,
                      encoding="UTF-8",
                      template=template,
                      converter="pandoc-mathjax",
                      mathjax=TRUE,
                      edir=edir,
                      question="<h4>Aufgabe</h4>",
                      solution="<h4>L&ouml;sung</h4>"
    ))
  }
}
