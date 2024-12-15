# developed in r version 4.2.2

# DOCKER_WORKER ------------------------------------------------------------------
DOCKER_WORKER = !file.exists("./app.R")

# STARTUP -----------------------------------------------------------------
if(DOCKER_WORKER){
  rm(list = ls())
  cat("\f")
  gc()
  DOCKER_WORKER = TRUE
}

# PACKAGES ----------------------------------------------------------------
library(exams) #exams_2.4-1
library(png) #png_0.1-8 
library(tth) #tth_4.12-0-1 
library(xtable) #xtable_1.8-4
library(openssl) # openssl_2.1.1
library(magick) # magick_2.7.4
library(callr) # callr_3.7.3

# SOURCE ------------------------------------------------------------------
source("./source/shared/log.R")

# FUNCTIONS ---------------------------------------------------------------
  # READ OUTPUT ---------------------------------------------------
  readOutput = function(){
    lapply(R_BG_STACK, function(bg_process){
      output = gsub("[\n]+", "\n", paste0(bg_process$process$read_output(), "\n"))
      
      if(output != "\n") {
        output = gsub("[\n]+", "\n", paste0(output, "\n"))
        cat(output, append = TRUE, file = bg_process$log)
      }
    })
  }

  # CHECK WORKER REQUESTS ---------------------------------------------------
  checkWorkerRequests = function(){
    readOutput()
    
    REQ_FILES_PATTERN = paste0(Reduce(c, lapply(REQ_FILES, \(x) paste0("(", x, ")"))), collapse="|")
    CHECK_REQ_FILES = list.files(paste0(tempdir(), "/../"), 
                                 pattern = REQ_FILES_PATTERN, 
                                 recursive = TRUE,
                                 full.names = TRUE)

    REQUESTS = c()
    
    if(length(CHECK_REQ_FILES)){
      COMPARE_TIME_NEW = Sys.time()
      REQUESTS = CHECK_REQ_FILES[which(sapply(CHECK_REQ_FILES, function(x){
        file.mtime(x) > COMPARE_TIME
      }))]

      COMPARE_TIME <<- COMPARE_TIME_NEW
    }

    if(length(REQUESTS) > 0) {
      PARSE_EXERCISE_REQUEST = REQUESTS[grepl("parseExercise", REQUESTS)]
      CREATE_EXAM_REQUEST = REQUESTS[grepl("createExam", REQUESTS)]
      EVALUATE_EXAM_SCANS_REQUEST = REQUESTS[grepl("evaluateExamScans", REQUESTS)]
      EVALUATE_EXAM_FINALIZE_REQUEST = REQUESTS[grepl("evaluateExamFinalize", REQUESTS)]
      
      if(length(PARSE_EXERCISE_REQUEST) > 0){
        lapply(PARSE_EXERCISE_REQUEST, function(x){
          log_(content="PARSE_EXERCISE_REQUEST", "WORKER", "WORKER")
          
          requestContent = readRDS(x)
          processFiles = getProcessFiles(requestContent$dir, "parseExercise")

          # if no response, consider polling outputs to keep alive
          R_BG_STACK <<- c(R_BG_STACK, list(list(log=processFiles$log, process=callr::r_bg(
            func = process_parseExerciseRequest,
            args = list(requestContent, processFiles$res, processFiles$fin, parseExercise, prepare_exerciseResponse),
            supervise = TRUE
          ))))
        })
      }
      
      if(length(CREATE_EXAM_REQUEST) > 0){
        lapply(CREATE_EXAM_REQUEST, function(x){
          log_(content="CREATE_EXAM_REQUEST", "WORKER", "WORKER")
          
          requestContent = readRDS(x)
          processFiles = getProcessFiles(requestContent$dir, "createExam")
          
          # if no response, consider polling outputs to keep alive
          R_BG_STACK <<- c(R_BG_STACK, list(list(log=processFiles$log, process=callr::r_bg(
            func = process_createExamRequest,
            args = list(requestContent, processFiles$res, processFiles$fin, createExam, prepare_createExamResponse),
            supervise = TRUE
          ))))
        })
      }
      
      if(length(EVALUATE_EXAM_SCANS_REQUEST) > 0){
        lapply(EVALUATE_EXAM_SCANS_REQUEST, function(x){
          log_(content="EVALUATE_EXAM_SCANS_REQUEST", "WORKER", "WORKER")
          
          requestContent = readRDS(x)
          processFiles = getProcessFiles(requestContent$dir, "evaluateExamScans")
          
          R_BG_STACK <<- c(R_BG_STACK, list(list(log=processFiles$log, process=callr::r_bg(
            func = process_evaluateExamScansRequest,
            args = list(requestContent, processFiles$res, processFiles$fin, evaluateExamScans, prepare_evaluateExamScansResponse),
            supervise = TRUE
          ))))
        })
      }
      
      if(length(EVALUATE_EXAM_FINALIZE_REQUEST) > 0){
        lapply(EVALUATE_EXAM_FINALIZE_REQUEST, function(x){
          log_(content="EVALUATE_EXAM_FINALIZE_REQUEST", "WORKER", "WORKER")
          
          requestContent = readRDS(EVALUATE_EXAM_FINALIZE_REQUEST[1])
          processFiles = getProcessFiles(requestContent$preparedEvaluation$fields$dir, "evaluateExamFinalize")
          
          R_BG_STACK <<- c(R_BG_STACK, list(list(log=processFiles$log, process=callr::r_bg(
            func = process_evaluateExamFinalizeRequest,
            args = list(requestContent, processFiles$res, processFiles$fin, evaluateExamFinalize, prepare_evaluateExamFinalizeResponse),
            supervise = TRUE
          ))))
        })
      }
    }
  }
  
  # GET FILENAMES ------------------------------------------------------------
  getProcessFiles = function(dir, fname){
    res = paste0(dir, "/", fname, "_res.txt")
    log = paste0(dir, "/", fname, "_log.txt") 
    fin = paste0(dir, "/", fname, "_fin.txt")
    
    return(list(res=res, log=log, fin=fin))
  }
  
	# PARSE EXERCISES -----------------------------------------------------
  process_parseExerciseRequest = function(requestContent, res, fin, parseExercise, prepare_exerciseResponse){
    source("./source/worker/tryCatch.R")
    source("./source/shared/rToJson.R")

    cat(paste0("Exercises to parse = ", length(requestContent$exercises), "\n"))
    
    lapply(seq_along(requestContent$exercises), \(x){
      data = c(list(dir=requestContent$dir), requestContent$exercises[[x]])
      parsedExercise = parseExercise(data)
      prepare_exerciseResponse(parsedExercise, res, append=x != 1)
    })
    
    file.create(fin)
	}

  parseExercise = function(data){
		 out = tryCatch({
		  warnings = collectWarnings({
  			cat("Preparing parameters.\n")
  		  
  		  file = paste0(data$dir, "/", data$file)  
  		  exerciseCode = readChar(file, file.info(file)$size)
  		  
  			splitBy = ";\n" # originally it is ";\r\n" but "\r\n" is replaced by "\n"
  			# unify line breaks
  			exerciseCode = gsub("\r\n", "\n", exerciseCode)
  			
  			# show all possible choices when viewing exercises (only relevant for editable exercises)
  			exerciseCode = sub("maxChoices=5", "maxChoices=NULL", exerciseCode)
  			
  			# remove image from question when viewing exercises (only relevant for editable exercises)
  			exerciseCode = sub("rnwTemplate_showFigure=TRUE", "rnwTemplate_showFigure=FALSE", exerciseCode)
  	  
  			# extract figure to display it in the respective field when viewing a exercise (only relevant for editable exercises)
  			figure = strsplit(exerciseCode, "rnwTemplate_figure=")[[1]][2]
  			figure = strsplit(figure, splitBy)[[1]][1]
  			
  			figure_split = strsplit(figure,",")[[1]]
  			figure = ""
  			
  			if(length(figure_split) == 3) {
  			  figure_name = sub("^[^\"]*\"([^\"]+)\".*", "\\1", figure_split[1])
  			  figure_fileExt = sub("^[^\"]*\"([^\"]+)\".*", "\\1", figure_split[2])
  			  figure_blob = sub("^[^\"]*\"([^\"]+)\".*", "\\1", figure_split[3])
  			  
  			  figure = list(name=figure_name, fileExt=figure_fileExt, blob=figure_blob)
  			}
  			
  			# extract raw question text
  			question_raw = strsplit(exerciseCode, "rnwTemplate_question=")[[1]][2]
  			question_raw = strsplit(question_raw, splitBy)[[1]][1]
  			question_raw = paste0(rev(rev(strsplit(question_raw, "")[[1]][-1])[-1]), collapse="") # trim
  			question_raw = gsub("\\\\", "\\", question_raw, fixed=TRUE)
  			
  			# extract raw choice texts
  			choices_raw = strsplit(exerciseCode, "rnwTemplate_choices=")[[1]][2]
  			choices_raw = strsplit(choices_raw, splitBy)[[1]][1]
  			choices_raw = strsplit(choices_raw, ",\"")[[1]]
  			choices_raw[1] = paste0(strsplit(choices_raw[1], "")[[1]][-c(1:3)], collapse="")
  			choices_raw[length(choices_raw)] = paste0(rev(rev(strsplit(choices_raw[length(choices_raw)], "")[[1]])[-1]), collapse="") #trim
  			choices_raw = Reduce(c, lapply(choices_raw, \(x) paste0(rev(rev(strsplit(x, "")[[1]])[-c(1)]), collapse=""))) # trim
  			
  			if(grepl("rnwTemplate_choices", exerciseCode) & length(choices_raw) < 2)
  			  stop("E1022")
  			
  			# extract raw solution note texts
  			solutionNotes_raw = strsplit(exerciseCode, "rnwTemplate_solutionNotes=")[[1]][2]
  			solutionNotes_raw = strsplit(solutionNotes_raw, splitBy)[[1]][1]
  			solutionNotes_raw = strsplit(solutionNotes_raw, ",\"")[[1]]
  			solutionNotes_raw[1] = paste0(strsplit(solutionNotes_raw[1], "")[[1]][-c(1:3)], collapse="")
  			solutionNotes_raw[length(solutionNotes_raw)] = paste0(rev(rev(strsplit(solutionNotes_raw[length(solutionNotes_raw)], "")[[1]])[-1]), collapse="") #trim
  			solutionNotes_raw = Reduce(c, lapply(solutionNotes_raw, \(x) paste0(rev(rev(strsplit(x, "")[[1]])[-c(1)]), collapse=""))) # trim
  			
  			seed = if(data$seed == "") NULL else data$seed
  			
  			writeLines(text=exerciseCode, con=file)
  			
  			exExtra = suppressWarnings(exams::extract_extra(readLines(con=file), markup="latex"))
  
  			cat("Parsing exercise.\n")
  			
  			html = exams::exams2html(file, dir = data$dir, seed = seed, base64 = TRUE)
  			
  			html$exam1$exercise1$question_raw = question_raw
  			html$exam1$exercise1$choices_raw = choices_raw
  			html$exam1$exercise1$solutionNotes_raw = solutionNotes_raw
  
  			if (!html$exam1$exercise1$metainfo$type %in% c("schoice", "mchoice")) {
  			  stop("E1005")
  			}
  			
  			if (length(html$exam1$exercise1$questionlist) < 2) {
  			  stop("E1006")
  			}
  			
  			if (any(duplicated(html$exam1$exercise1$questionlist))) {
  			  stop("E1007")
  			}
  	  
  			NULL
  		  })

		  key = "Success"
		  value = paste(unique(unlist(warnings)), collapse="<br>")
		  
		  if(value != "") {
  			key = "Warning"
  			value = "W1001"
		  }
	  
		  return(list(message=list(key=key, value=value), id=data$id, seed=seed, html=html, exExtra=exExtra, figure=figure))
		},
		error = function(e){
		  if(!grepl("E\\d{4}", e$message))
			  e$message = "E1001"
		  
		  return(list(message=list(key="Error", value=e), id=data$id, seed=NULL, html=NULL))
		},
		finally = {
		  cat("Parsing exercise completed.\n")
		})
	}

	prepare_exerciseResponse = function(result, res, append) {
	  with(result, {
	    messageType = getMessageType(message)
	    statusMessage = myMessage(message, "exercise")
	    statusCode = getMessageCode(message)
	    
	    write(id, file=res, ncolumns=1, sep="\n", append=append)
	    write(messageType, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(statusMessage, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(statusCode, file=res, ncolumns=1, sep="\n", append=TRUE)

	    if(!is.null(html)) {
	      author = html$exam1$exercise1$metainfo$author
	      
	      exExtra = exExtra[names(exExtra)!= "editable"]
	      exExtra = Reduce(c, lapply(names(exExtra), \(x){
	        x = rjs_keyValuePairsToJsonObject(x, rjs_vectorToJsonStringArray(exExtra[[x]]), escapeValues=FALSE)
	      }))
	      exExtra = rjs_vectorToJsonArray(exExtra)
	      
	      points = html$exam1$exercise1$metainfo$points
	      type = html$exam1$exercise1$metainfo$type
	      
	      tags = c()
	      
	      if(length(html$exam1$exercise1$metainfo$tags) > 0) { 
	        tags = trimws(html$exam1$exercise1$metainfo$tags, "both")
	        tags = rjs_vectorToJsonStringArray(tags)
	      }
	      
	      section = html$exam1$exercise1$metainfo$section
	      seed = seed
	      
	      question = paste0(html$exam1$exercise1$question, collapse="")
	      question_raw = paste0(html$exam1$exercise1$question_raw, collapse="")
	      figure = rjs_vectorToJsonStringArray(unlist(figure))
	      editable = ifelse(html$exam1$exercise1$metainfo$editable == 1, 1, 0)
	      choices = rjs_vectorToJsonStringArray(html$exam1$exercise1$questionlist)
	      choices_raw = rjs_vectorToJsonStringArray(html$exam1$exercise1$choices_raw)
	      solutions = rjs_vectorToJsonArray(tolower(as.character(html$exam1$exercise1$metainfo$solution)))
	      solutionNotes = rjs_vectorToJsonStringArray(as.character(html$exam1$exercise1$solutionlist))
	      solutionNotes_raw = rjs_vectorToJsonStringArray(html$exam1$exercise1$solutionNotes_raw)
	    } else {
	      author = NULL
	      exExtra = NULL
	      points = NULL
	      type = NULL
	      tags = NULL
	      section = NULL
	      seed = NULL
	      question = NULL
	      question_raw = NULL
	      figure = NULL
	      editable = NULL
	      choices = NULL
	      choices_raw = NULL
	      solutions = NULL
	      solutionNotes = NULL
	      solutionNotes_raw = NULL
	    }

	    write(author, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(exExtra, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(points, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(type, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(tags, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(section, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(seed, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(question, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(question_raw, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(figure, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(editable, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(choices, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(choices_raw, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(solutions, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(solutionNotes, file=res, ncolumns=1, sep="\n", append=TRUE)
	    write(solutionNotes_raw, file=res, ncolumns=1, sep="\n", append=TRUE)
	  })
	}
	# CREATE EXAM ---------------------------------------------------------
	process_createExamRequest = function(requestContent, res, fin, createExam, prepare_createExamResponse){
	  source("./source/worker/tryCatch.R")
	  source("./source/shared/rToJson.R")
	  
	  cat("Exams to create = 1\n")

	  createdExam = createExam(requestContent)
	  prepare_createExamResponse(createdExam, res)

	  file.create(fin)
	}
	
	createExam = function(data) {
		out = tryCatch({
		  warnings = collectWarnings({
		    cat("Preparing parameters.\n")

  			if(any(data$seedValueExam < data$seedMin))
  			  stop("E1008")
  			
  			if(any(data$seedValueExam > data$seedMax))
  			  stop("E1009")
  
  			if(length(data$exerciseFiles) < data$exerciseMin)
  			  stop("E1010")
  			
  			if(data$numberOfExercises < data$exerciseMin)
  			  stop("E1023")
  
  			if(length(data$exerciseFiles) > data$exerciseMax)
  			  stop("E1011")
  			
  			if(data$numberOfExercises > data$exerciseMax)
  			  stop("E1024")
  			
  			if(length(unique(data$exerciseTypes)) > 1)
  			  stop("E1019")
  			
  			if(!all(unique(data$exerciseTypes) %in% c("schoice", "mchoice")))
  			  stop("E1020")
  
  			uniqueBlocks = unique(data$blocks)
  			exercisesPerBlock = data$numberOfExercises / length(uniqueBlocks)
  			exercises = lapply(uniqueBlocks, function(x) data$exerciseFiles[data$blocks==x])
  			
  			seedList = matrix(1, nrow=data$numberOfExams, ncol=length(data$exerciseFiles))
  			seedList = seedList * as.numeric(paste0(if(is.na(data$seedValueExam)) NULL else data$seedValueExam, 1:data$numberOfExams))

  			points = if(!is.na(data$fixedPointsExamCreate)) data$fixedPointsExamCreate else NULL
  			reglength = if(!is.na(data$examRegLength)) data$examRegLength else 7
  			name = paste0(c("exam", data$seedValueExam, ""), collapse="_")
  
  			nsamp = NULL
  			if(!data$fixSequence) 
  			  nsamp = exercisesPerBlock
  			
  			if(data$fixSequence) 
  			  exercises = unlist(exercises)
  			
  			examFields = list(
  			  dir = data$dir,
  			  file = exercises,
  			  edir = data$edir,
  			  n = data$numberOfExams,
  			  nsamp = nsamp,
  			  name = name,
  			  language = data$examLanguage,
  			  title = data$examTitle,
  			  course = data$examCourse,
  			  institution = data$examInstitution,
  			  date = data$examDate,
  			  blank = data$numberOfBlanks,
  			  duplex = data$duplex,
  			  pages = data$additionalPdfFiles,
  			  points = points,
  			  showpoints = data$showPoints,
  			  seed = seedList,
  			  reglength = reglength,
  			  header = NULL,
  			  intro = c(data$examIntro), 
  			  replacement = data$replacement,
  			  samepage = data$samepage,
  			  newpage = data$newpage,
  			  logo = NULL
  			)
  			
  			# needed for pdf files (not for html files) - somehow exams needs it that way
  			fileIds = 1:data$numberOfExams
  			fileIdSizes = floor(log10(fileIds))
  			fileIdSizes = max(fileIdSizes) - fileIdSizes
  			fileIds = sapply(seq_along(fileIdSizes), function(x){
  			  paste0(paste0(rep("0", max(fileIdSizes))[0:fileIdSizes[x]], collapse=""), fileIds[x])
  			})
  			
  			examHtmlFiles = paste0(data$dir, "/", name, 1:data$numberOfExams, ".html")
  			examPdfFiles = paste0(data$dir, "/", name, fileIds, ".pdf")
  			examRdsFile = paste0(data$dir, "/", name, ".rds")
  			
  			# exam input field data
  			examInputFile = paste0(data$dir, "/input.txt")
  			
  			examInputTxt = Reduce(c, lapply(names(examFields)[!names(examFields) %in% c("edir", "header", "logo")], \(x){
  			  values = examFields[[x]] 
  			  
  			  if(x=="file")  
  				values = lapply(values, \(y) gsub(paste0(data$edir, "/"), "", y, fixed = TRUE))
  			  
  			  if(x=="pages")  
  				values = lapply(values, \(y) gsub(paste0(data$dir, "/"), "", y, fixed = TRUE))
  		 
  			  if(is.matrix(values)){
  				paste0(c(x, 
  						 paste0(apply(values, 1, \(y) paste0(paste0(y, collapse=";"), "\n")), collapse="")
  				), collapse="\n")
  			  } else {
  				paste0(c(x, 
  						 paste0(paste0(unlist(values), "\n"), collapse="")
  				), collapse="\n")
  			  }
  			}))
  
  			# write
  			writeLines(examInputTxt, examInputFile)
  
  			# prepared exam data
  			preparedExam = list(examFields=examFields, examFiles=list(examHtmlFiles=examHtmlFiles, pdfFiles=examPdfFiles, rdsFile=examRdsFile, examInputFile=examInputFile), sourceFiles=list(exerciseFiles=data$exerciseFiles, additionalPdfFiles=data$additionalPdfFiles))

  			cat("Creating exam.\n")

  			with(preparedExam$examFields, {
  			  # create exam html preview with solutions
  			  set.seed(1)
  			  exams::exams2html(file = file,
  								          edir = edir,
  								          n = n,
  								          nsamp = nsamp,
  								          name = name,
  								          dir = dir,
  								          seed = seed)
  	  
  			  # create exam
  			  set.seed(1)
  			  exams::exams2nops(file = file,
  								          edir = edir,
  								          n = n,
  								          nsamp = nsamp,
  								          name = name,
  								          dir = dir,
  								          language = language,
  								          title = title,
  								          course = course,
  								          institution = institution,
  								          date = date,
  								          blank = blank,
  								          duplex = duplex,
  								          pages = pages,
  								          points = points,
  								          showpoints = showpoints,
  								          seed = seed,
  								          encoding = "UTF-8",
  								          reglength = reglength,
  								          header = header,
  								          intro = intro,
  								          replacement = replacement,
  								          samepage = samepage,
  								          newpage = newpage,
  								          logo = NULL)
  			})
  	  
  		  NULL
		  })
		  
		  key = "Success"
		  value = paste(unique(unlist(warnings)), collapse="<br>")
		  
		  if(value != "") {
  			key = "Warning"
  			value = "W1002"
		  }
	  
		  return(list(message=list(key=key, value=value), files=list(sourceFiles=preparedExam$sourceFiles, examFiles=preparedExam$examFiles)))
		},
		error = function(e){
		  if(!grepl("E\\d{4}", e$message))
			  e$message = "E1002"
	  
		  return(list(message=list(key="Error", value=e), files=list()))
		},
		finally = {
		  cat("Creating exam completed.\n")
		})
	}

	prepare_createExamResponse = function(result, res) {
	  messageType = getMessageType(result$message)
	  message = myMessage(result$message, "modal")
	  response = unname(unlist(c(messageType, message, result$files, result$examFiles)))
	  
	  write(response, file=res, ncolumns=1, sep="\n")
	}
	
	# EVALUATE EXAM -------------------------------------------------------
    # EVALUATE EXAM SCANS -----------------------------------------------------
  	process_evaluateExamScansRequest = function(requestContent, res, fin, evaluateExamScans, prepare_evaluateExamScansResponse){
  	  source("./source/worker/tryCatch.R")
  	  source("./source/shared/rToJson.R")
  	  
  	  evaluatedScans = evaluateExamScans(requestContent)
  	  prepare_evaluateExamScansResponse(evaluatedScans, res)

  	  file.create(fin)
  	}
  
  	evaluateExamScans = function(data){
  		out = tryCatch({
  		  scans_reg_fullJoin = paste0(data$dir, "/scans_reg_fullJoinData.csv")
  
  		  warnings = collectWarnings({
  		  cat("Preparing parameters.\n")
  
  			if(length(data$scanFiles) < 1)
  			  stop("E1025")
  
  			if(is.null(data$registeredParticipantsFile))
  			  stop("E1026")
  
  			if(is.null(data$solutionFile))
  			  stop("E1027")
  
  			points = data$fixedPointsExamEvaluate
  			if(is.numeric(points) && points > 0) {
  			  points = rep(points, numExercises)
  			} else {
  			  points = NULL
  			}
  
  			mark = data$mark
  			labels = NULL
  
  			if(mark) {
  			  mark = data$marks
  			  labels = data$labels
  			  
  			  if(length(mark) != length(unique(mark)))
  			    stop("E1028")
  			  
  			  if(length(labels) != length(unique(labels)))
  			    stop("E1029")
  
  			  invalidGradingKeyItems = mark == "" | labels == ""
  
  			  mark = mark[!invalidGradingKeyItems][-1]
  
  			  labels = labels[!invalidGradingKeyItems]
  			}
  
  			cat("Preparing meta data.\n")
  
  			examExerciseMetaData = readRDS(data$solutionFile)
  			examName = data$examName
  			examIds = names(examExerciseMetaData)
  			numExercises = length(examExerciseMetaData[[1]])
  			numChoices = length(examExerciseMetaData[[1]][[1]]$questionlist)
  			
  			scanFileZipName = gsub("_+", "_", paste0(examName, "_nops_scan.zip"))
  			scanEvaluation = paste0(data$dir, "/", scanFileZipName)
  
  			preparedEvaluation = list(meta=list(examIds=examIds, examName=examName, numExercises=numExercises, numChoices=numChoices, totalPdfLength=data$totalPdfLength, totalPngLength=data$totalPngLength, scanFileZipName=scanFileZipName),
  			                          fields=list(dir=data$dir, edirName=data$edirName, cores=data$cores, rotate=data$rotate, points=points, regLength=data$regLength, partial=data$partial, negative=data$negative, rule=data$rule, mark=mark, labels=labels, language=data$language),
  			                          files=list(solution=data$solutionFile, registeredParticipants=data$registeredParticipantsFile, scans=data$scanFiles, scanEvaluation=scanEvaluation, scans_reg_fullJoin=scans_reg_fullJoin))
  			
  			with(preparedEvaluation, {
  			  if(length(files$scans) < 1)
  				  stop("E1012")
  
  			  if(length(files$registeredParticipants) != 1)
  				  stop("E1013")
  
  			  if(length(files$solution) != 1)
  				  stop("E1014")
  
  			  if(any(order(as.numeric(mark)) != seq_along(mark)))
  				  stop("E1017")
  
  			  if(any(as.numeric(mark) < 1) && any(as.numeric(mark) >= 1))
  				  stop("E1018")
  
  			  registeredParticipantData = read.csv2(files$registeredParticipants)
  
  			  if(ncol(registeredParticipantData) != 3)
  				  stop("E1015")
  
  			  if(!all(names(registeredParticipantData)[1:3] == c("registration", "name", "id")))
  				  stop("E1016")
  
  			  cat("Evaluating scans.\n")
  			  cat(paste0("Scans to convert = ", meta$totalPdfLength, "\n"))
  			  cat(paste0("Scans to process = ", meta$totalPdfLength + meta$totalPngLength, "\n"))
  
  			  scanData = exams::nops_scan(images=files$scans,
  							   file=meta$scanFileZipName,
  							   dir=fields$dir,
  							   rotate=fields$rotate,
  							   cores=fields$cores,
  							   verbose=TRUE)
  
  			  dummyFirstRow = paste0(rep(NA,51), collapse=" ")
  			  scanData = read.table(text=c(dummyFirstRow, scanData), sep=" ", fill=TRUE)
  			  scanData = scanData[-1,]
  
  			  names(scanData)[c(1:6)] = c("scan", "sheet", "scrambling", "type", "replacement", "registration")
  			  names(scanData)[-c(1:6)] = (7:ncol(scanData)) - 6
  
  			  # reduce columns using additional data from exam to know how many questions and answer per question existed
  			  scanData = scanData[,-which(grepl("^[[:digit:]]+$", names(scanData)))[-c(1:meta$numExercises)]] # remove unnecessary placeholders for unused questions
  			  scanData$numExercises = meta$numExercises
  			  scanData$numChoices = meta$numChoices
  
  			  # add scans as base64 to be displayed in browser
  			  scanFilesData = setNames(unzip(files$scanEvaluation, list=TRUE)[,1:2], c("scan", "size"))
  
  			  if(nrow(scanFilesData) > 1) {
    				scanData = merge(scanData, scanFilesData, by="scan")
    
    				scanData$blob = unlist(lapply(1:nrow(scanData), function(x) {
    				  blob = readBin(unz(files$scanEvaluation, scanData$scan[x], open="rb"), "raw", n=scanData$size[x])
    				  openssl::base64_encode(blob)
    				}))
  			  }
  
  			  # full outer join of scanData and registeredParticipantData
  			  scans_reg_fullJoinData = NULL
  			  
  			  if(data$dummyParticipants){
  			    scans_reg_fullJoinData = scanData
  			    scans_reg_fullJoinData$registration = registeredParticipantData$registration
  			    scans_reg_fullJoinData$name = registeredParticipantData$name
  			    scans_reg_fullJoinData$id = registeredParticipantData$id
  			  }
			    else{
			      scans_reg_fullJoinData = merge(scanData, registeredParticipantData, by="registration", all=TRUE)
  
    			  # in case of duplicates, set "XXXXXXX" as registration number and "NA" for name and id for every match following the first one
    			  dups = duplicated(scans_reg_fullJoinData$registration)
    			  scans_reg_fullJoinData$registration[dups] = "XXXXXXX"
    			  scans_reg_fullJoinData$name[dups] = "NA"
    			  scans_reg_fullJoinData$id[dups] = "NA"
    			  
    			  # set "XXXXXXX" as registration number for scans which were not matched with any of the registered participants
    			  scans_reg_fullJoinData$registration[is.na(scans_reg_fullJoinData$name) & is.na(scans_reg_fullJoinData$id)] = "XXXXXXX"
    			  
    			  # set "XXXXXXX" as registration number for scans which show "ERROR" in any field
    			  scans_reg_fullJoinData$registration[apply(scans_reg_fullJoinData, 1, function(x) any(x=="ERROR"))] = "XXXXXXX"
			    }
  			  
  			  # pad zeroes to registration numbers and answers
  			  scans_reg_fullJoinData$registration[scans_reg_fullJoinData$registration != "XXXXXXX"] = sprintf(paste0("%0", fields$regLength, "d"), as.numeric(scans_reg_fullJoinData$registration[scans_reg_fullJoinData$registration != "XXXXXXX"]))
  			  scans_reg_fullJoinData[,as.character(1:meta$numExercises)] = apply(scans_reg_fullJoinData[,as.character(1:meta$numExercises)], 2, function(x){
  			    x[is.na(x)] = 0
  			    x = sprintf(paste0("%0", data$maxChoices, "d"), as.numeric(x))
  			  })
  			  
  			  write.csv2(scans_reg_fullJoinData, file=scans_reg_fullJoin, row.names = FALSE)
  			})
  			
  			NULL
  		  })
  
  		  key = "Success"
  		  value = paste(unique(unlist(warnings)), collapse="<br>")
  		  if(value != "") {
  			key = "Warning"
  			value = "W1003"
  		  }
  
  		  return(list(message=list(key=key, value=value),
  					  preparedEvaluation=preparedEvaluation))
  		},
  		error = function(e){
  		  if(!grepl("E\\d{4}", e$message))
  			  e$message = "E1003"
  
  		  return(list(message=list(key="Error", value=e), scans_reg_fullJoin=NULL, examName=NULL, files=list(), data=list()))
  		},
  		finally = {
  		  cat("Evaluating Scans completed.\n")
  		})
  	}
  	
  	prepare_evaluateExamScansResponse = function(result, res) {
  	  messageType = getMessageType(result$message)
  	  message = myMessage(result$message, "modal")
  	  
  	  preparedEvaluationData = lapply(unlist(result$preparedEvaluation, recursive = FALSE) , function(x) paste0(unlist(x), collapse=";"))
  	  
  	  response = unname(unlist(c(messageType, message, result$scans_reg_fullJoin, preparedEvaluationData)))
  
  	  write(response, file=res, ncolumns=1, sep="\n")
  	}

    # EVALUATE EXAM FINALIZE --------------------------------------------------
  	process_evaluateExamFinalizeRequest = function(requestContent, res, fin, evaluateExamFinalize, prepare_evaluateExamFinalizeResponse){
  	  source("./source/worker/tryCatch.R")
  	  source("./source/shared/rToJson.R")
  	  
  	  cat("Exams to evaluate = 1\n")
  	  
  	  evaluatedFinalize = evaluateExamFinalize(requestContent)
  	  prepare_evaluateExamFinalizeResponse(evaluatedFinalize, res)

  	  file.create(fin)
  	}
    
  	evaluateExamFinalize = function(data){
  	  out = tryCatch({
  	    warnings = collectWarnings({
  	      # scanData
  	      cat("Updating scan data.\n")
  	      
  	      scanData = Reduce(c, lapply(data$proceedEvaluation$datenTxt, function(x) paste0(unlist(unname(x)), collapse=" ")))
  	      scanData = paste0(scanData, collapse="\n")
  	      
  	      if(scanData == "")
  	        stop("E1021")

  	      scanDatafile = paste0(data$preparedEvaluation$fields$dir, "/", "Daten.txt")
  	      writeLines(text=scanData, con=scanDatafile)
  	      
  	      # update *_nops_scan.zip file
  	      zip(data$preparedEvaluation$files$scanEvaluation, scanDatafile, flags='-r9Xj')
  	      
  	      # manage preparedEvaluation data to include in download
  	      cat("Preparing evaluation files.\n")
  	      data$preparedEvaluation$files = within(data$preparedEvaluation$files, rm(list=c("scans")))
  	      
  	      # file path and name settings
  	      nops_evaluation_fileNames = "evaluation.html"
  	      nops_evaluation_fileNamePrefix = gsub("_+", "_", paste0(data$preparedEvaluation$meta$examName, "_nops_eval"))
  	      data$preparedEvaluation$files$nops_evaluationCsv = paste0(data$preparedEvaluation$fields$dir, "/", nops_evaluation_fileNamePrefix, ".csv")
  	      data$preparedEvaluation$files$nops_evaluationZip = paste0(data$preparedEvaluation$fields$dir, "/", nops_evaluation_fileNamePrefix, ".zip")
  	      
  	      # additional files
  	      data$preparedEvaluation$files$nops_evalInputTxt = paste0(data$preparedEvaluation$fields$dir, "/input.txt")
  	      data$preparedEvaluation$files$nops_statisticsTxt = paste0(data$preparedEvaluation$fields$dir, "/statistics.txt")
  	      data$preparedEvaluation$evaluationStatistics = NULL
  	      
  	      cat("Evaluating exam.\n")
  	      
  	      with(data$preparedEvaluation, {
  	        # finalize evaluation
  	        exams::nops_eval(
  	          register = files$registeredParticipants,
  	          solutions = files$solution,
  	          scans = files$scanEvaluation,
  	          eval = exams::exams_eval(partial = fields$partial, negative = fields$negative, rule = fields$rule),
  	          points = fields$points,
  	          mark = fields$mark,
  	          labels = fields$labels,
  	          results = nops_evaluation_fileNamePrefix,
  	          dir = data$preparedEvaluation$fields$dir,
  	          file = nops_evaluation_fileNames,
  	          language = fields$language,
  	          interactive = FALSE
  	        )
  	        
  	        solutionData = readRDS(files$solution)
  	        evaluationData = read.csv2(files$nops_evaluationCsv)
  	        
  	        # pad zeroes to registration numbers and ids (if same as registrations numbers)
  	        if(all(evaluationData$id==evaluationData$registration))
  	          evaluationData$id = sprintf(paste0("%0", fields$regLength, "d"), as.numeric(evaluationData$id))
  	        
  	        evaluationData$registration = sprintf(paste0("%0", fields$regLength, "d"), as.numeric(evaluationData$registration))
  	        
  	        # add additional exercise columns
  	        exerciseTable = as.data.frame(Reduce(rbind, lapply(evaluationData$exam, \(exam) {
  	          exerciseNames = Reduce(cbind, lapply(solutionData[[as.character(exam)]], \(exercise) exercise$metainfo$file))
  	          if(all(grepl(paste0(fields$edirName, "_"), exerciseNames)))
  	            exerciseNames = sapply(strsplit(exerciseNames, paste0(fields$edirName, "_")), \(name) name[2])
  	          
  	          exerciseNames = matrix(exerciseNames, nrow=1)
  	          
  	          return(exerciseNames)
  	        })))
  	        
  	        names(exerciseTable) = paste0("exercise.", 1:ncol(exerciseTable))
  	        
  	        evaluationData = cbind(evaluationData, exerciseTable)
  	        
  	        # add max points column
  	        examMaxPoints = as.data.frame(Reduce(rbind, lapply(evaluationData$exam, \(exam) {
  	          examPoints = sum(as.numeric(sapply(solutionData[[as.character(exam)]], \(exercise) exercise$metainfo$points)))
  	          examPoints = matrix(examPoints, nrow=1)
  	          
  	          return(examPoints)
  	        })))
  	        
  	        names(examMaxPoints) = paste0("examMaxPoints")
  	        
  	        evaluationData = cbind(evaluationData, examMaxPoints)
  	        
  	        # pad zeros for answers and solutions
  	        evaluationData[paste("answer", 1:length(solutionData[[1]]), sep=".")] = sprintf(paste0("%0", 5, "d"), unlist(evaluationData[paste("answer", 1:length(solutionData[[1]]), sep=".")]))
  	        evaluationData[paste("solution", 1:length(solutionData[[1]]), sep=".")] = sprintf(paste0("%0", 5, "d"), unlist(evaluationData[paste("solution", 1:length(solutionData[[1]]), sep=".")]))
  	        
  	        # exam eval input field data
  	        examEvalFields = list(registeredParticipants = files$registeredParticipants,
  	                              solutions = files$solution,
  	                              scans = files$scanEvaluation,
  	                              partial = fields$partial,
  	                              negative = fields$negative,
  	                              rule = fields$rule,
  	                              points = fields$points,
  	                              mark = fields$mark,
  	                              labels = fields$labels,
  	                              language = fields$language)
  	        
  	        examEvalInputTxt = Reduce(c, lapply(names(examEvalFields), \(x){
  	          values = examEvalFields[[x]]
  	          
  	          if(x %in% c("registeredParticipants", "solutions", "scans"))
  	            values = lapply(values, \(y) gsub(paste0(fields$dir, "/"), "", y, fixed = TRUE))
  	          
  	          if(is.matrix(values)){
  	            paste0(c(x,
  	                     paste0(apply(values, 1, \(y) paste0(paste0(y, collapse=";"), "\n")), collapse="")
  	            ), collapse="\n")
  	          } else {
  	            paste0(c(x,
  	                     paste0(paste0(unlist(values), "\n"), collapse="")
  	            ), collapse="\n")
  	          }
  	        }))
  	        
  	        # statistics
  	        examMaxPoints = matrix(max(as.numeric(evaluationData$examMaxPoints)), dimnames=list("examMaxPoints", "value"))
  	        validExams = matrix(nrow(evaluationData), dimnames=list("validExams", "value"))
  	        
  	        exerciseNames = unique(unlist(evaluationData[,grepl("exercise.*", names(evaluationData))]))
  	        
  	        if(all(grepl(paste0(fields$edirName, "_"), exerciseNames)) )
  	          exerciseNames = sapply(strsplit(exerciseNames, paste0(fields$edirName, "_")), \(name) name[2])
  	        
  	        exercisePoints = Reduce(rbind, lapply(exerciseNames, \(exercise){
  	          summary(apply(evaluationData, 1, \(participant){
  	            
  	            if(!exercise %in% participant)
  	              return(NULL)
  	            
  	            as.numeric(participant[gsub("exercise", "check", names(evaluationData)[participant==exercise])])
  	          }))
  	        }))
  	        
  	        rownames(exercisePoints) = exerciseNames
  	        
  	        totalPoints = t(summary(as.numeric(evaluationData$points)))
  	        rownames(totalPoints) = "totalPoints"
  	        
  	        points = matrix(mean(as.numeric(evaluationData$points))/examMaxPoints)
  	        colnames(points) = c("mean")
  	        rownames(points) = "points"
  	        
  	        marks = matrix()
  	        
  	        if(fields$mark[1] != FALSE) {
  	          marks = table(factor(evaluationData$mark, fields$labels))
  	          marks = cbind(marks, marks/sum(marks), rev(cumsum(rev(marks)))/sum(marks))
  	          colnames(marks) = c("absolute", "relative", "relative cumulative")
  	          
  	          points = as.matrix(cbind(points, t(c(0, fields$mark))), nrow=1)
  	          colnames(points) = c("mean", fields$labels)
  	          rownames(points) = "points"
  	        }
  	        
  	        evaluationStatistics = list(
  	          points=points,
  	          examMaxPoints=examMaxPoints,
  	          validExams=validExams,
  	          exercisePoints=exercisePoints,
  	          totalPoints=totalPoints,
  	          marks=marks
  	        )
  	        
  	        evaluationStatisticsTxt = Reduce(c, lapply(names(evaluationStatistics), \(x){
  	          paste0(c(x,
  	                   paste0(c("name", colnames(evaluationStatistics[[x]])), collapse=";"),
  	                   paste0(rownames(evaluationStatistics[[x]]), ";", apply(evaluationStatistics[[x]], 1, \(y) paste0(paste0(y, collapse=";"), "\n")), collapse="")
  	          ), collapse="\n")
  	        }))
  	        
  	        # write
  	        writeLines(examEvalInputTxt, files$nops_evalInputTxt)
  	        writeLines(evaluationStatisticsTxt, files$nops_statisticsTxt)
  	        write.csv2(evaluationData, files$nops_evaluationCsv, row.names = FALSE)
  	      })
  	      
  	      NULL
  	    })
  	    key = "Success"
  	    value = paste(unique(unlist(warnings)), collapse="<br>")
  	    if(value != "") {
  	      key = "Warning"
  	      value = "W1004"
  	    }
  	    
  	    return(list(message=list(key=key, value=value),
  	                preparedEvaluation=data$preparedEvaluation))
  	  },
  	  error = function(e){
  	    if(!grepl("E\\d{4}", e$message))
  	      e$message = "E1004"
  	    
  	    return(list(message=list(key="Error", value=e), examName=NULL, files=list()))
  	  },
  	  finally = {
  	    cat("Evaluating exam completed.\n")
  	  })
  	}
  	
  	prepare_evaluateExamFinalizeResponse = function(result, res) {
  	  messageType = getMessageType(result$message)
  	  message = myMessage(result$message, "modal")
  	  
  	  preparedEvaluationData = lapply(unlist(result$preparedEvaluation, recursive = FALSE) , function(x) paste0(unlist(x), collapse=";"))
  	  
  	  response = unname(unlist(c(messageType, message, result$scans_reg_fullJoin, preparedEvaluationData)))

  	  write(response, file=res, ncolumns=1, sep="\n")
	  }


# PARAMETERS --------------------------------------------------------------
	# ADDONS ------------------------------------------------------------------
	addons_path = "./addons/"
	addons_path_www = "./www/addons/"
	addons = list.files(addons_path_www, recursive = TRUE) 
	addons = unique(Reduce(c, lapply(addons[grepl("/", addons)], \(x) strsplit(x, split="/")[[1]][1])))

	invisible(lapply(addons, \(addon) {
	  source(paste0(addons_path_www, addons, "/worker/", addons, "_worker.R"))
	}))
# WORKER ------------------------------------------------------------------
POLL_TIME = 1 / 100 # polling timeout in seconds
COMPARE_TIME = Sys.time() # time of comparison

# files to monitor for requests
REQ_FILES = c("parseExercise_req.rds", 
              "createExam_req.rds", 
              "evaluateExamScans_req.rds", 
              "evaluateExamFinalize_req.rds")

# background process stack
R_BG_STACK = list()

# periodic check loop for requests
if(DOCKER_WORKER){
  repeat {
    checkWorkerRequests()
    Sys.sleep(POLL_TIME)
  }
}
