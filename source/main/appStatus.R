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
