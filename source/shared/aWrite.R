write_atomic = function(content, target_file, use_uuid=FALSE) {
  if(use_uuid){
    id = paste0(sample(c(0:9, letters), 8, replace = TRUE), collapse = "")
    target_file = strsplit(target_file, split="/")[[1]]
    
    if(length(target_file) > 1)
      target_file = paste0(paste0(target_file[1:(length(target_file) - 1)], collapse="/"), "/", id, "_", target_file[length(target_file)])
    else
      target_file = paste0(id, "_", target_file)
  }
  
  tmpfile = paste0(target_file, ".tmp")
  
  if (grepl("\\.rds$", target_file, ignore.case = TRUE)) {
    saveRDS(content, tmpfile)
  } else {
    writeLines(as.character(content), tmpfile)
  }
  
  file.rename(tmpfile, target_file)
}
