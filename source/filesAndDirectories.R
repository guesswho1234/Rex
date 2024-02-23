getDir = function(session) {
  paste0(tempdir(), "/", session$token)
}

removeRuntimeFiles = function(session) {
  dir = getDir(session)
  
  temfiles = list.files(dir)
  filesToRemove = temfiles
  
  if(length(filesToRemove) > 0) 
    unlink(paste0(dir, "/", filesToRemove), recursive = TRUE)
}
