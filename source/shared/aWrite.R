write_atomic = function(content, target_file) {
  tmpfile <- paste0(target_file, ".tmp")
  
  if (grepl("\\.rds$", target_file, ignore.case = TRUE)) {
    saveRDS(content, tmpfile)
  } else {
    writeLines(as.character(content), tmpfile)
  }
  
  file.rename(tmpfile, target_file)
}
