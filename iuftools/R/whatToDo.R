#' Function to show all todos in a directory or an exam list
#'
#' @param dir character. Directory relative to working dir (must be iuf!)
#' @param exam_list list. Optional, can contain exam questions (only filenames)
#'
#' @export
#'
#' @examples
#' whatToDo()
#' whatToDo("Kapitalwert_01_S0_mc.Rnw")

whatToDo <- function(dir = "Questions", exam_list = NULL) {
  if (!dir.exists(dir)) stop(paste("Cannot find", dir, "in current working directory."))
  all_files <- paste0(dir, "/", list.files(path = dir, recursive = TRUE))
  for(file in all_files) {
    filename <- tail(strsplit(file, "/")[[1]], 1)
    if ((filename %in% exam_list) | (is.null(exam_list))) {
      allLines <- readLines(file)
      matches <- grep("todo", allLines, value=TRUE, ignore.case = TRUE)
      for (match in matches) {
        warning(paste("In", filename , match))
      }
    }
  }
}
