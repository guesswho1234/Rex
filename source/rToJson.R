rjs_vectorToJsonArray = function(vector){
  x = paste(vector, collapse=",")
  x = paste0(c("[", x, "]"), collapse="")
  return(x)
}

rjs_vectorToJsonStringArray = function(vector){
  x = paste0("\"", vector, "\"")
  x = rjs_vectorToJsonArray(x)
  return(x)
}

rjs_vectorToJsonNumericArray = function(vector, rounding=0){
  x = paste0(round(vector, round(rounding, 0)))
  x = rjs_vectorToJsonArray(x)
  return(x)
}

rjs_keyValuePairsToJsonObject = function(keys, values, escapeValues=TRUE){
  if(length(escapeValues) < length(values))
    escapeValues = rep(escapeValues, length(values))
  
  values = sapply(seq_along(values), \(x){
    if(escapeValues[x]) {
      values[x] = gsub("\"", "\\\\\"", values[x])
      values[x] = gsub(":", "\\:", values[x])
      values[x] = gsub("\\n", " ", values[x])
      values[x] = paste0("\"", values[x], "\"")
    }
      
    return(values[x])
  })

  keys = paste0("\"", keys, "\":")
  
  x = paste0(keys, values, collapse=", ")
  x = paste0("{", x, "}")
  
  return(x)
}
