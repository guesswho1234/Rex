# PARSE EXERCISES -----------------------------------------------------
examParseResponse = function(session, exerciseData, error) {
	with(exerciseData, {
	  id = as.numeric(id)

	  if(!error){
		session$sendCustomMessage("setExerciseAuthor", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, author)))
		session$sendCustomMessage("setExerciseExExtra", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, exExtra)))
		session$sendCustomMessage("setExercisePoints", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, points)))
		session$sendCustomMessage("setExerciseType", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, type)))
		session$sendCustomMessage("setExerciseTags", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, tags)))
		session$sendCustomMessage("setExerciseSection", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, section)))
		session$sendCustomMessage("setExerciseSeed", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, seed)))
		session$sendCustomMessage("setExerciseQuestion", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, question)))
		session$sendCustomMessage("setExerciseQuestionRaw", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, question_raw)))
		session$sendCustomMessage("setExerciseFigure", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, figure)))
		session$sendCustomMessage("setExerciseEditable", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, editable)))
		session$sendCustomMessage("setExerciseChoices", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, choices)))
		session$sendCustomMessage("setExerciseChoicesRaw", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, choices_raw)))
		session$sendCustomMessage("setExerciseSolutions", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, solutions)))
		session$sendCustomMessage("setExerciseSolutionNotes", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, solutionNotes)))
		session$sendCustomMessage("setExerciseSolutionNotesRaw", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, solutionNotes_raw)))
	  }

	  session$sendCustomMessage("setExerciseStatusMessage", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, statusMessage)))
	  session$sendCustomMessage("setExerciseStatusCode", rjs_keyValuePairsToJsonObject(c("id", "value"), c(id, statusCode)))
	})
}

# CREATE EXAM -------------------------------------------------------------
examCreationResponse = function(session, messageType, message, downloadable) {
	session$sendCustomMessage("changeTabTitle", messageType)

	showModal(modalDialog(
	  title = tags$span(HTML('<span lang="de">Prüfung erstellen</span><span lang="en">Create exam</span>')),
	  tags$span(id="responseMessage", HTML(message)),
	  footer = tagList(
		myActionButton("dismiss_examCreationResponse", "Schließen", "Close", "fa-solid fa-xmark"),
		if (downloadable)
		  myDownloadButton('downloadExamFiles')
	  )
	))
	session$sendCustomMessage("f_langDeEn", 1)
}
  
# EVALUATE EXAM -----------------------------------------------------------
evaluateExamScansResponse = function(session, result) {
	session$sendCustomMessage("changeTabTitle", result$messageType)

	showModal(modalDialog(
	  title = tags$span(HTML('<span lang="de">Scans überprüfen</span><span lang="en">Check scans</span>')),
	  tags$span(id="responseMessage", HTML(result$message)),
	  
	  if (!is.null(result$scans_reg_fullJoinData)) 
		tagList(
		  tags$div(id="scanStats"),
		  tags$div(id="inspectScan"),
		  tags$div(id="compareScanRegistrationDataTable", HTML('<div class="loadingCompareScanRegistrationDataTable"><span lang="de">BITTE WARTEN ...</span><span lang="en">PLEASE WAIT ...</span></div>')),
		),
	  
	  footer = tagList(
		myActionButton(id="dismiss_evaluateExamScansResponse", deText="Abbrechen", enText="Cancle", icon="fa-solid fa-xmark"),
		if (!is.null(result$scans_reg_fullJoinData)) 
		  myActionButton(id="proceedEval", deText="Weiter", enText="Proceed", icon="fa-solid fa-circle-right")
	  ),
	  size = "l"
	))

	session$sendCustomMessage("f_langDeEn", 1)

	# display scanData in modal
	if (!is.null(result$scans_reg_fullJoinData) && nrow(result$scans_reg_fullJoinData) > 0) {
	  session$sendCustomMessage("resetScanRegistrationData", 1)

	  init = 1
	  from = 1
	  to = nrow(result$scans_reg_fullJoinData)
	  step = 10
	  
	  repeat{
		chunk = from:min(from + step - 1, to)
		
		scans_reg_fullJoinData_json = rjs_vectorToJsonArray(
		  apply(result$scans_reg_fullJoinData[chunk,], 1, function(x) {
			rjs_keyValuePairsToJsonObject(names(result$scans_reg_fullJoinData), x)
		  })
		)
		
		session$sendCustomMessage("appendScanRegistrationData", scans_reg_fullJoinData_json)
		
		from = from + step
		
		if(from > to){
		  break
		}
	  }
	  
	  examIds_json = rjs_vectorToJsonStringArray(result$preparedEvaluation$meta$examIds)
	  
	  session$sendCustomMessage("setExanIds", examIds_json)
	  session$sendCustomMessage("finalizeScanRegistrationData", 1)
	} 

	# display scanData again after going back from "evaluateExamFinalizeResponse"
	if (!is.null(result$scans_reg_fullJoinData) && nrow(result$scans_reg_fullJoinData) == 0) {
	  session$sendCustomMessage("backTocompareScanRegistrationData", 1)
	}
}

evaluateExamFinalizeResponse = function(session, result) {
	session$sendCustomMessage("changeTabTitle", result$messageType)

	# evaluation statistics
	showModalStatistics = !is.null(result$preparedEvaluation$files$nops_evaluationCsv) && length(unlist(result$preparedEvaluation$files, recursive = TRUE)) > 0
	chartData = NULL

	if (showModalStatistics) {
	  chartData = list(ids = list("evaluationPointStatistics", "evaluationExerciseStatistics", "evaluationGradingStatistics"),
						 values = list(result$evaluationStatistics$points, result$evaluationStatistics$exercisePoints, result$evaluationStatistics$marks),
						 deCaptions = c("Punkte", "Aufgaben", "Noten"),
						 enCaptions = c("Points", "Exercises", "Marks"))
	  
	  evaluationStatistics_json = rjs_vectorToJsonArray(Reduce(c, lapply(seq_along(result$evaluationStatistics), \(x) {
		rjs_keyValuePairsToJsonObject(names(result$evaluationStatistics)[x],
									  rjs_vectorToJsonArray(Reduce(c, lapply(1:nrow(result$evaluationStatistics[[x]]), \(y) {
										rjs_keyValuePairsToJsonObject(colnames(result$evaluationStatistics[[x]]),
																	  result$evaluationStatistics[[x]][y,],
																	  c(TRUE, rep(FALSE, length(result$evaluationStatistics[[x]][y,]) - 1)))
									  }))), FALSE)
	  })))
	  
	  session$sendCustomMessage("evaluationStatistics", evaluationStatistics_json)
	}

	# show modal
	showModal(modalDialog(
	  title = tags$span(HTML('<span lang="de">Prüfung auswerten</span><span lang="en">Evaluate exam</span>')),
	  tags$span(id='responseMessage', HTML(result$message)),
	  if (showModalStatistics)
		myEvaluationCharts(chartData, result$evaluationStatistics$examMaxPoints$value, result$evaluationStatistics$validExams$value, result$preparedEvaluation$fields$mark),
	  footer = tagList(
		myActionButton("dismiss_evaluateExamFinalizeResponse", "Schließen", "Close", "fa-solid fa-xmark"),
		myActionButton("backTo_evaluateExamScansResponse", "Zurück", "Back", "fa-solid fa-arrow-left"),
		if (length(unlist(result$preparedEvaluation$files, recursive = TRUE)) > 0)
		  myDownloadButton('downloadEvaluationFiles')
	  )
	))
	session$sendCustomMessage("f_langDeEn", 1)
}
