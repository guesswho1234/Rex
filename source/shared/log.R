log_ = function(content, user="", sessionToken="", append=TRUE, dir=NULL){
  timestamp = Sys.time()
  file = "log.txt"
  file = ifelse(is.null(dir), file, file.path(dir, file))
  
  if(user != "" && sessionToken != "" )
    write(paste0(timestamp, ": ", user, ": ", sessionToken, ": ", content), file, append = append) 
  else  
    write(paste0(timestamp, ": ", content), file, append = append) 
}

debug_ = function(content, user="", sessionToken="", append=TRUE, dir=NULL){
  timestamp = Sys.time()
  file = "debug.txt"
  file = ifelse(is.null(dir), file, file.path(dir, file))
  
  if(user != "" && sessionToken != "" )
    write(paste0(timestamp, ": ", user, ": ", sessionToken, ": ", content), file, append = append) 
  else  
    write(paste0(timestamp, ": ", content), file, append = append) 
}
