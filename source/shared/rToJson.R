rjs_vectorToJsonArray = function(vector){
  x = paste(vector, collapse=",")
  x = paste0(c("[", x, "]"), collapse="")
  return(x)
}

escapeSpecialCharacters = function(values){
  values = gsub("[\\]", "\\\\\\\\", values)
  values = gsub("\"", "\\\\\"", values)
  values = gsub(":", "\\:", values)
  values = gsub("\\n", " ", values)
  values = gsub("\\t", " ", values)
  values = paste0("\"", values, "\"")
  return(values)
}

escapeInlineMathHtml = function(values){
  values = gsub("[\\]", "\\\\\\\\", values)
  values = gsub("\"", "\\\\\"", values)
  values = gsub(":", "\\:", values)
  values = gsub("\\n", " ", values)
  values = gsub("\\t", " ", values)
  return(values)
}


rjs_vectorToJsonStringArray = function(vector){
  x = paste0("\"", vector, "\"")
  x = rjs_vectorToJsonArray(x)
  return(x)
}

rjs_keyValuePairsToJsonObject = function(keys, values, escapeValues=TRUE){
  if(length(escapeValues) < length(values))
    escapeValues = rep(escapeValues, length(values))
  
  values = sapply(seq_along(values), \(x){
    if(escapeValues[x]) {
      values[x] = escapeSpecialCharacters(values[x])
    }
      
    return(values[x])
  })

  keys = paste0("\"", keys, "\":")
  
  x = paste0(keys, values, collapse=", ")
  x = paste0("{", x, "}")
  
  return(x)
}
