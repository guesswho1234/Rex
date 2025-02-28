log_ = function(content, user="", sessionToken="", append=TRUE){
  timestamp = Sys.time()
  
  if(user != "" && sessionToken != "" )
    write(paste0(timestamp, ": ", user, ": ", sessionToken, ": ", content), "log.txt", append = append) 
  else  
    write(paste0(timestamp, ": ", content), "log.txt", append = append) 
}

debug_ = function(content, user="", sessionToken="", append=TRUE){
  timestamp = Sys.time()
  
  if(user != "" && sessionToken != "" )
    write(paste0(timestamp, ": ", user, ": ", sessionToken, ": ", content), "debug.txt", append = append) 
  else  
    write(paste0(timestamp, ": ", content), "debug.txt", append = append) 
}