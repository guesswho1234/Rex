messageSymbols = c('<i class=\"fa-solid fa-circle-check\"></i>', '<i class=\"fa-solid fa-triangle-exclamation\"></i>', '<i class=\"fa-solid fa-circle-exclamation\"></i>')
  
errorCodes = read.csv2("tryCatch/errorCodes.csv")
errorCodes = setNames(apply(errorCodes[,-1], 1, FUN=as.list), errorCodes[,1])

warningCodes = read.csv2("tryCatch/warningCodes.csv")
warningCodes = setNames(apply(warningCodes[,-1], 1, FUN=as.list), warningCodes[,1])

getErrorCodeMessage = function(errorCode) {
  errorMessage = lapply(names(errorCodes[[errorCode]]), function(lang){
    paste0("<span lang=\"", lang, "\">", errorCodes[[errorCode]][[lang]], "</span>")  
  })
  errorMessage = paste0(errorMessage, collapse="")
  errorMessage = paste0("<span class=\"errorMessage\">", errorCode, ": ", errorMessage, "</span>", collapse="")
  
  errorMessage
}

getWarningCodeMessage = function(warningCode) {
  warningMessage = lapply(names(warningCodes[[warningCode]]), function(lang){
    paste0("<span lang=\"", lang, "\">", warningCodes[[warningCode]][[lang]], "</span>")  
  })
  warningMessage = paste0(warningMessage, collapse="")
  warningMessage = paste0("<span class=\"warningMessage\">", warningCode, ": ", warningMessage, "</span>", collapse="")
  
  warningMessage
}

getMessageType = function(message){
  which(message$key==c("Success", "Warning", "Error")) - 1
}

getMessageCode = function(message){
  type = getMessageType(message)
  code = 0
  
  if(type == 2) 
    code = strsplit(message$value$message, ":")[[1]][1]
  
  if(type == 1) 
    code = strsplit(message$value, ":")[[1]][1]
  
  code
}

myMessage = function(message, class) {
  type = getMessageType(message)
  
  if(type == 2) {
    if (message$value$message %in% names(errorCodes)) {
      message$value = getErrorCodeMessage(message$value$message)
    } else {
      message$value = ifelse(!grepl("E\\d{4}", message$value$message), paste0("W1000: ", message$value$message), message$value$message)
    }
  }
  
  if(type == 1) {
    if (message$value %in% names(warningCodes)) {
      message$value = getWarningCodeMessage(message$value)
    } else {
      message$value = ifelse(!grepl("W\\d{4}", message$value), paste0("W1000: ", message$value), message$value)
    }
  }
  
  message$value = gsub("\"", "'", message$value)
  message$value = gsub("[\r\n]", "<br>", trimws(message$value))
  message$value = gsub("[\r]", "",message$value)
  message$value = gsub("[\n]", "", message$value)
  
  messageSign = paste0('<span class="responseSign ', message$key, 'Sign">', messageSymbols[type + 1], '</span>')
  messageText = paste0('<span class="', paste0(class, 'TryCatchText'), ' tryCatchText">', message$value , '</span>')
  messageObject = paste0('<span class="', paste0(class, 'TryCatch'), ' tryCatch ', message$key, '">', messageSign, messageText, '</span>')
  
  HTML(messageObject)
}

collectWarnings = function(expr) {
  warnings = NULL
  wHandler = function(w) {
    warnings <<- c(warnings, list(w))
    invokeRestart("muffleWarning")
  }
  
  withCallingHandlers(expr, warning = wHandler)
  
  return(warnings)
}
