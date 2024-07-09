log_ = function(content, sessionToken, append=TRUE){
  timestamp = Sys.time()
  
  if(sessionToken != "")
	write(paste0(timestamp, ": ", sessionToken, ": ", content), "log.txt", append = append) 
  else  
	write(paste0(timestamp, ": ", content), "log.txt", append = append) 
}

out_ = function(out){
  if(out != "")
    cat(out)
}

startWait = function(session){
  session$sendCustomMessage("wait", 0)
}

stopWait = function(session){
  removeRuntimeFiles(session)
  session$sendCustomMessage("wait", 1)
}

initProrgress = function(session){
  session$sendCustomMessage("progress", 0)
}

updateProrgress = function(session, increment){
  update = sprintf(paste0("%0", 3, "d"), round(increment, 0))
  
  session$sendCustomMessage("updateProgress", update)
}

finalizeProgress = function(session){
  session$sendCustomMessage("progress", 1)
}
