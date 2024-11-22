processLogFile = function(file, history){
	logData = c()
	output = c("")
	newHistory = length(logData)

	if(!is.na(file.mtime(file))){
	  logData = readLines(file, warn = FALSE)
	  
	  newHistory = length(logData)
	  diff = newHistory - history
	  
	  if(length(diff) > 0 && diff > 0){
		lapply(logData[(history + 1):newHistory], \(x){
		  output <<- paste0(c(output, x), collapse="\n")
		  out_(x)
		})
	  }
	}

	return(list(history=newHistory, out=output))
}

monitorProgressExerciseParse = function(session, out, data){
	data = within(data, {
	  progress = progress + sum(sapply(strsplit(out, split="\n"), function(x){
		if(length(x) == 0)
		  return(0)
		
		matchParsingExerciseCompleted = "Exercises to parse = "
		
		if(any(grepl(matchParsingExerciseCompleted, x)) && is.null(totalExercises))
		  totalExercises <<- as.numeric(gsub(matchParsingExerciseCompleted, "", x[which(grepl(matchParsingExerciseCompleted, x))]))
		
		if(is.null(totalExercises))
		  return(0)
		
		parses = sum(grepl("Parsing exercise completed.", x))

		parses / totalExercises * 100 
	  }), na.rm = TRUE) 
	  
	  if(progress - previousProgress > 1) {
		previousProgress = progress
		updateProrgress(session, progress)
	  }
	})

	return(data)
}

monitorProgressExamCreate = function(session, out, data){
	data = within(data, {

	  progress = progress + sum(sapply(strsplit(out, split="\n"), function(x){
		if(length(x) == 0)
		  return(0)
		
		matchCreatingExamCompleted = "Exams to create = "
		
		if(any(grepl(matchCreatingExamCompleted, x)) && is.null(totalExams))
		  totalExams <<- as.numeric(gsub(matchCreatingExamCompleted, "", x[which(grepl(matchCreatingExamCompleted, x))]))

		if(is.null(totalExams))
		  return(0)
		
		parses = sum(grepl("Creating exam completed.", x))

		parses / totalExams * 100 
	  }), na.rm = TRUE) 
	  
	  if(progress - previousProgress > 1) {
		previousProgress = progress
		updateProrgress(session, progress)
	  }
	})

	return(data)
}

monitorProgressExamScanEvaluation = function(session, out, data){
	data = within(data, {
	  progress = progress + sum(sapply(strsplit(out, split="\n"), function(x){
		if(length(x) == 0)
		  return(0)
		
		matchTotalPdfLength = "Scans to convert = "
		
		if(any(grepl(matchTotalPdfLength, x)) && is.null(totalPdfLength)) 
		  totalPdfLength <<- as.numeric(gsub(matchTotalPdfLength, "", x[which(grepl(matchTotalPdfLength, x))]))
		
		matchTotalPngLength = "Scans to process = "
		
		if(any(grepl(matchTotalPngLength, x)) && is.null(totalPngLength)) 
		  totalPngLength <<- as.numeric(gsub(matchTotalPngLength, "", x[which(grepl(matchTotalPngLength, x))]))

		if(is.null(totalPngLength) || is.null(totalPdfLength))
		  return(0)
		
		converts = sum(grepl("Converting PDF to PNG", x))
		reads = sum(grepl(".PNG:", x))
		adds = sum(grepl("adding:", x))
		
		(converts + reads + adds) / (totalPdfLength + totalPngLength * 2 + 1) * 100 
	  }), na.rm = TRUE) 
	  
	  if(progress - previousProgress > 1) {
		previousProgress = progress
		updateProrgress(session, progress)
	  }
	})

	return(data)
}

monitorProgressExamFinalizeEvaluation = function(session, out, data){
	data = within(data, {
	  
	  progress = progress + sum(sapply(strsplit(out, split="\n"), function(x){
		if(length(x) == 0)
		  return(0)
		
		matchEvaluatingExamCompleted = "Exams to evaluate = "
		
		if(any(grepl(matchEvaluatingExamCompleted, x)) && is.null(totalExams))
		  totalExams <<- as.numeric(gsub(matchEvaluatingExamCompleted, "", x[which(grepl(matchEvaluatingExamCompleted, x))]))
		
		if(is.null(totalExams))
		  return(0)
		
		parses = sum(grepl("Evaluating exam completed.", x))
		
		parses / totalExams * 100 
	  }), na.rm = TRUE) 
	  
	  if(progress - previousProgress > 1) {
		previousProgress = progress
		updateProrgress(session, progress)
	  }
	})

	return(data)
}
