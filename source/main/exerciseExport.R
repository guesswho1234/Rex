prepareExerciseDownloadFiles = function(session, exercises){
  dir = getDir(session)
  
  exercises$exerciseNames = as.list(make.unique(unlist(exercises$exerciseNames), sep="_"))
  
  exerciseFiles = unlist(lapply(setNames(seq_along(exercises$exerciseNames), exercises$exerciseNames), function(i){
    file = paste0(dir, "/", exercises$exerciseNames[[i]], ".", exercises$exerciseExts[[i]])
    code = gsub("\r\n", "\n", exercises$exerciseCodes[[i]])
    writeLines(text=code, con=file)
    
    return(file)
  }))
  
  return(list(exerciseFiles=exerciseFiles))
}
