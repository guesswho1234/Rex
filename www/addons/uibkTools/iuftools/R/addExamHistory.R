#' Function to add comment for questions that have been part of an exam
#'
#' @param exam_list list.
#' @param exam_name character. Name of the exam
#'
#' @export
#'
#' @examples
#' addExamHistory("Kapitalwert_01_S0_mc.Rnw", "just a test")

addExamHistory <- function(exam_list, exam_name) {
  dir <- "Questions"
  if (!dir.exists(dir)) stop(paste("Cannot find", dir, "in current working directory."))
  all_files <- paste0(dir, "/", list.files(path = dir, recursive = TRUE))
  for(file in all_files) {
    filename <- tail(strsplit(file, "/")[[1]], 1)
    if ((filename %in% exam_list) | (is.null(exam_list))) {
      allLines <- readLines(file)
      if (length(grep(exam_name, allLines)) == 0) {
        allLines <- append(allLines, paste("## ExamHistory:", exam_name), after = 1)
        writeLines(allLines, file)
      }
    }
  }
}
