# developed in r version 4.2.1

# STARTUP -----------------------------------------------------------------
rm(list = ls())
cat("\f")
gc()

# PACKAGES ----------------------------------------------------------------
library(shiny) # shiny_1.8.0
library(shinyjs) # shinyjs_2.1.0
library(shinyWidgets) # shinyWidgets_0.8.0
library(shinycssloaders) #shinycssloaders_1.0.0
library(exams) #exams_2.4-0
library(png) #png_0.1-8 
library(tth) #tth_4.12-0-1 
library(xtable) #xtable_1.8-4
library(iuftools) #iuftools_1.0.0
library(callr) # callr_3.7.3
library(pdftools) # pdftools_3.4.0
library(qpdf) # qpdf_1.3.2
library(openssl) # openssl_2.1.1

# library(shinyauthr)

# FUNCTIONS ----------------------------------------------------------------
getDir = function(session) {
  paste0(tempdir(), "/", session$token)
}

removeRuntimeFiles = function(session) {
  dir = getDir(session)
  
  temfiles = list.files(dir)
  filesToRemove = temfiles
  
  session$sendCustomMessage("debugMessage", dir)
  session$sendCustomMessage("debugMessage", filesToRemove)

  if(length(filesToRemove) > 0) {
    unlink(paste0(dir, "/", filesToRemove), recursive = TRUE)
  }
}

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
  
  if(type == 2) {
    code = ifelse(message$value$message %in% names(errorCodes), message$value$message, "E1000")
  }
  
  if(type == 1) {
    code = ifelse(message$value %in% names(errorCodes), message$value$message, "W1000")
  }
  
  code
}

myMessage = function(message) {
  type = getMessageType(message)
  
  if(type == 2) {
    if (message$value$message %in% names(errorCodes)) {
      message$value = getErrorCodeMessage(message$value$message)
    } else {
      message$value = getErrorCodeMessage("E1000")
    }
  }
  
  if(type == 1) {
    if (message$value %in% names(warningCodes)) {
      message$value = getWarningCodeMessage(message$value)
    } else {
      message$value = getWarningCodeMessage("W1000")
    }
  }
  
  message$value = gsub("\"", "'", message$value)
  message$value = gsub("[\r\n]", "<br>", trimws(message$value))
  message$value = gsub("[\r]", "",message$value)
  message$value = gsub("[\n]", "", message$value)
  

  messageSign = paste0('<span class="responseSign ', message$key, 'Sign">', messageSymbols[type + 1], '</span>')
  messageText = paste0('<span class="exerciseTryCatchText">', message$value , '</span>')
  messageObject = paste0('<span class="exerciseTryCatch ', message$key, '">', messageSign, messageText, '</span>')
  
  HTML(messageObject)
}

myActionButton = function(id, deText, enText, icon){
  tags$button(id = id, class = "btn btn-default action-button shiny-bound-input", type="button", myButtonStyle(deText, enText, icon))
}

myDownloadButton = function(id){
  tags$a(id = id, class = "btn btn-default shiny-download-link", href = "", 
         target = "_blank", type = "button", download = NA, NULL, myButtonStyle("Speichern", "Save", "fa-solid fa-download"))
}

myButtonStyle = function(deText, enText, icon) {
  icon = paste0('<span class="iconButton"><i class="', icon, '"></i></span>')
  text = paste0('<span class="textButton"><span lang="de">', deText, '</span><span lang="en">', enText, '</span></span>')
  
  return(tags$span(HTML(paste0(icon, text, collapse=""))))
}

collectWarnings = function(expr) {
  warnings = NULL
  wHandler = function(w) {
    warnings <<- c(warnings, list(w))
    invokeRestart("muffleWarning")
  }
  # origin = withCallingHandlers(expr, warning = wHandler)
  withCallingHandlers(expr, warning = wHandler)
  
  return(warnings)
}

prepareExerciseDownloadFiles = function(session, exercises){
  dir = getDir(session)
  
  exercises$exerciseNames = as.list(make.unique(unlist(exercises$exerciseNames), sep="_"))
  
  exerciseFiles = unlist(lapply(setNames(seq_along(exercises$exerciseNames), exercises$exerciseNames), function(i){
    file = paste0(dir, "/", exercises$exerciseNames[[i]], ".rnw")
    writeLines(text=gsub("\r\n", "\n", exercises$exerciseCodes[[i]]), con=file)

    return(file)
  }))
  
  return(list(exerciseFiles=exerciseFiles))
}

parseExercise = function(exercise, seed, collectWarnings, dir){
  out = tryCatch({
    warnings = collectWarnings({
      # show all possible choices when viewing exercises (only relevant for editable exercises)
      exercise$exerciseCode = sub("maxChoices = 5", "maxChoices = NULL", exercise$exerciseCode)
      
      # remove image from question when viewing exercises (only relevant for editable exercises)
      exercise$exerciseCode = sub("rnwTemplate_showFigure = TRUE", "rnwTemplate_showFigure = FALSE", exercise$exerciseCode)

      # extract figure to display it in the respective field when viewing a exercise (only relevant for editable exercises)
      figure = strsplit(exercise$exerciseCode, "rnwTemplate_figure=")[[1]][2]
      figure = strsplit(figure, "rnwTemplate_maxChoices")[[1]][1]
      
      figure_split = strsplit(figure,",")[[1]]
      figure = ""
      
      if(length(figure_split) == 3) {
        figure_name = sub("^[^\"]*\"([^\"]+)\".*", "\\1", figure_split[1])
        figure_fileExt = sub("^[^\"]*\"([^\"]+)\".*", "\\1", figure_split[2])
        figure_blob = sub("^[^\"]*\"([^\"]+)\".*", "\\1", figure_split[3])
        
        figure = list(name=figure_name, fileExt=figure_fileExt, blob=figure_blob)
      }
      
      seed = if(is.na(seed)) NULL else seed
      
      file = tempfile(fileext = ".Rnw")
      writeLines(text=gsub("\r\n", "\n", exercise$exerciseCode), con=file)

      htmlPreview = exams::exams2html(file, dir = dir, seed = seed, base64 = TRUE)
      
      if (htmlPreview$exam1$exercise1$metainfo$type != "mchoice") {
        stop("E1005")
      }
      
      if (length(htmlPreview$exam1$exercise1$questionlist) < 2) {
        stop("E1006")
      }
      
      if (any(duplicated(htmlPreview$exam1$exercise1$questionlist))) {
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

    return(list(message=list(key=key, value=value), id=exercise$exerciseID, seed=seed, html=htmlPreview, figure=figure))
  },
  error = function(e){
    if(!grepl("E\\d{4}", e$message)){
      e$message = "E1001"
    }
    
    return(list(message=list(key="Error", value=e), id=exercise$exerciseID, seed=NULL, html=NULL))
  })
  
  return(out)
}

loadExercise = function(session, id, seed, html, figure, message) {
  session$sendCustomMessage("setExerciseId", id)
  
  if(!is.null(html)) {
    examHistory = c() 
    authoredBy = c()
    tags = c()
    type = c()
    question = c()
    
    if(length(html$exam1$exercise1$metainfo$examHistory) > 0) {
      examHistory = trimws(strsplit(html$exam1$exercise1$metainfo$examHistory, ",")[[1]], "both")
      examHistory = rjs_vectorToJsonStringArray(examHistory)
    }
    
    if(length(html$exam1$exercise1$metainfo$authoredBy) > 0) {
      authoredBy = trimws(strsplit(html$exam1$exercise1$metainfo$authoredBy, ",")[[1]], "both") 
      authoredBy = rjs_vectorToJsonStringArray(authoredBy) 
    }
    
    if(length(html$exam1$exercise1$metainfo$tags) > 0) { 
      tags = trimws(strsplit(html$exam1$exercise1$metainfo$tags, ",")[[1]], "both")
      tags = rjs_vectorToJsonStringArray(tags)
    }
    
    precision = html$exam1$exercise1$metainfo$precision
    points = html$exam1$exercise1$points
    topic = html$exam1$exercise1$metainfo$topic
    type = html$exam1$exercise1$metainfo$type
    question = html$exam1$exercise1$question
    figure = rjs_vectorToJsonStringArray(unlist(figure))
    editable = ifelse(html$exam1$exercise1$metainfo$editable == 1, 1, 0)
    
    session$sendCustomMessage("setExerciseExamHistory", examHistory)
    session$sendCustomMessage("setExerciseAuthoredBy", authoredBy)
    session$sendCustomMessage("setExercisePrecision", precision)
    session$sendCustomMessage("setExercisePoints", points)
    session$sendCustomMessage("setExerciseTopic", topic)
    session$sendCustomMessage("setExerciseType", type)
    session$sendCustomMessage("setExerciseTags", tags)
    session$sendCustomMessage("setExerciseSeed", seed)
    session$sendCustomMessage("setExerciseQuestion", question)
    session$sendCustomMessage("setExerciseFigure", figure)
    session$sendCustomMessage("setExerciseEditable", editable)
    
    if(type == c("mchoice")) {
      session$sendCustomMessage("setExerciseChoices", rjs_vectorToJsonStringArray(html$exam1$exercise1$questionlist))
      session$sendCustomMessage("setExerciseResultMchoice", rjs_vectorToJsonArray(tolower(as.character(html$exam1$exercise1$metainfo$solution))))
    } 
    
    if(type == "num") {
      session$sendCustomMessage("setExerciseResultNumeric", result)
    }
  }

  session$sendCustomMessage("setExerciseMessage", myMessage(message))
  session$sendCustomMessage("setExerciseE", getMessageCode(message))
  session$sendCustomMessage("setExerciseId", -1)
}

prepareExam = function(session, exam, seed, input) {
  dir = getDir(session)
  
  exam$exerciseNames = as.list(make.unique(unlist(exam$exerciseNames), sep="_"))
  exerciseFiles = unlist(lapply(setNames(seq_along(exam$exerciseNames), exam$exerciseNames), function(i){
    file = paste0(dir, "/", exam$exerciseNames[[i]], ".rnw")
    writeLines(text=gsub("\r\n", "\n", exam$exerciseCodes[[i]]), con=file, sep="")

    return(file)
  }))
  
  numberOfExams = as.numeric(exam$numberOfExams)
  blocks = as.numeric(exam$blocks)
  uniqueBlocks = unique(blocks)
  numberOfExercises = as.numeric(exam$numberOfExercises)
  exercisesPerBlock = numberOfExercises / length(uniqueBlocks)
  exercises = lapply(uniqueBlocks, function(x) exerciseFiles[blocks==x])

  seedList = matrix(1, nrow=numberOfExams, ncol=length(exam$exerciseNames))
  seedList = seedList * as.numeric(paste0(if(is.na(exam$examSeed)) NULL else exam$examSeed, 1:numberOfExams))
  
  pages = NULL
  additionalPdfFiles = list()
  
  if(length(exam$additionalPdfNames) > 0) {
    exam$additionalPdfNames = as.list(make.unique(unlist(exam$additionalPdfNames), sep="_"))
    additionalPdfFiles = unlist(lapply(setNames(seq_along(exam$additionalPdfNames), exam$additionalPdfNames), function(i){
      file = paste0(dir, "/", exam$additionalPdfNames[[i]], ".pdf")
      raw = openssl::base64_decode(exam$additionalPdfFiles[[i]])
      writeBin(raw, con = file)
      
      return(file)
    }))
    
    pages = additionalPdfFiles
  }
  
  title = input$examTitle
  course = input$examCourse
  points = if(!is.na(input$fixedPointsExamCreate) && is.numeric(input$fixedPointsExamCreate)) input$fixedPointsExamCreate else NULL
  date = input$examDate
  name = paste0(c("exam", title, course, as.character(date), exam$examSeed, ""), collapse="_")
  
  examFields = list(
    file = exercises,
    fileBoundaries = c(exerciseMin, exerciseMax),
    n = numberOfExams,
    nsamp = exercisesPerBlock,
    name = name,
    language = input$examLanguage,
    title = title,
    course = course,
    institution = input$examInstitution,
    date = date,
    blank = input$numberOfBlanks,
    duplex = input$duplex,
    pages = pages,
    points = points,
    showpoints = input$showPoints,
    seed = seedList,
    seedBoundaries = c(seedMin, seedMax)
  )
  
  # needed for pdf files (not for html files) - somehow exams needs it that way
  fileIds = 1:exam$numberOfExams
  fileIdSizes = floor(log10(fileIds))
  fileIdSizes = max(fileIdSizes) - fileIdSizes
  fileIds = sapply(seq_along(fileIdSizes), function(x){
    paste0(paste0(rep("0", max(fileIdSizes))[0:fileIdSizes[x]], collapse=""), fileIds[x])
  })
  
  examHtmlFiles = paste0(dir, "/", name, 1:exam$numberOfExams, ".html")
  examPdfFiles = paste0(dir, "/", name, fileIds, ".pdf")
  examRdsFile = paste0(dir, "/", name, ".rds")

  return(list(examFields=examFields, examFiles=list(examHtmlFiles=examHtmlFiles, pdfFiles=examPdfFiles, rdsFile=examRdsFile), sourceFiles=list(exerciseFiles=exerciseFiles, additionalPdfFiles=additionalPdfFiles)))
}

createExam = function(preparedExam, collectWarnings, dir) {
  out = tryCatch({
    warnings = collectWarnings({
        with(preparedExam$examFields, {

          if(any(seed < seedBoundaries[1])){
            stop("E1008")
          }
          
          if(any(seed > seedBoundaries[2])){
            stop("E1009")
          }
          
          if(length(file) < fileBoundaries[1]){
            stop("E1010")
          }
          
          if(length(file) > fileBoundaries[2]){
            stop("E1011")
          }
          
          # create exam html preview with solutions
          exams::exams2html(file = file,
                            n = n,
                            nsamp = nsamp,
                            name = name,
                            dir = dir,
                            solution=TRUE,
                            seed = seed)
          
          # create exam
          exams::exams2nops(file = file,
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
                            seed = seed)
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
    if(!grepl("E\\d{4}", e$message)){
      e$message = "E1002"
    }
    
    return(list(message=list(key="Error", value=e), files=list()))
  })
  
  return(out)
}

examCreationResponse = function(session, message, downloadable) {
  showModal(modalDialog(
    title = tags$span(HTML('<span lang="de">Prüfung erstellen</span><span lang="en">Create exam</span>')),
    tags$span(id="responseMessage", myMessage(message)),
    footer = tagList(
      if (downloadable)
        myDownloadButton('downloadExamFiles'),
      myActionButton("dismiss_examCreationResponse", "Schließen", "Close", "fa-solid fa-xmark")
    )
  ))
  session$sendCustomMessage("f_langDeEn", 1)
}

prepareEvaluation = function(session, evaluation, rotate, input){
  dir = getDir(session)
  
  # exam
  evaluation$examSolutionsName = as.list(make.unique(unlist(evaluation$examSolutionsName), sep="_"))
  
  solutionFile = unlist(lapply(seq_along(evaluation$examSolutionsName), function(i){
    file = paste0(dir, "/", evaluation$examSolutionsName[[i]], ".rds")
    raw = openssl::base64_decode(evaluation$examSolutionsFile[[i]])
    writeBin(raw, con = file)

    return(file)
  }))
  examExerciseMetaData = readRDS(solutionFile)
  
  # registered participants
  evaluation$examRegisteredParticipantsnName = as.list(make.unique(unlist(evaluation$examRegisteredParticipantsnName), sep="_"))
  
  registeredParticipantsFile = unlist(lapply(seq_along(evaluation$examRegisteredParticipantsnName), function(i){
    file = paste0(dir, "/", evaluation$examRegisteredParticipantsnName[[i]], ".csv")
    writeLines(text=gsub("\r\n", "\n", evaluation$examRegisteredParticipantsnFile[[i]]), con=file)

    return(file)
  }))
  
  # process scans to end up with only png files at the end
  pngFiles = NULL
  pdfFiles = NULL
  convertedPngFiles = NULL
  
  if(length(evaluation$examScanPdfNames) > 0){
    evaluation$examScanPdfNames = as.list(make.unique(unlist(evaluation$examScanPdfNames), sep="_"))
    pdfFiles = lapply(setNames(seq_along(evaluation$examScanPdfNames), evaluation$examScanPdfNames), function(i){
      file = paste0(dir, "/", evaluation$examScanPdfNames[[i]], ".pdf")
      raw = openssl::base64_decode(evaluation$examScanPdfFiles[[i]])
  
      if(rotate){
        file = gsub(".pdf", "_.pdf", file)
        writeBin(raw, con = file)
        output = paste0(dir, "/", evaluation$examScanPdfNames[[i]], ".pdf")
        numberOfPages = qpdf::pdf_length(file)
        qpdf::pdf_rotate_pages(input=file, output=output, pages=1:numberOfPages, angle=ifelse(rotate, 180, 0))
  
        file = output
      } else {
        writeBin(raw, con = file)
      }
      
      
      return(file)
    })
    
    convertedPngFiles = unlist(lapply(seq_along(pdfFiles), function(i){
      numberOfPages = qpdf::pdf_length(pdfFiles[[i]])
      
      filenames = sapply(1:numberOfPages, function(page){
        paste0(dir, "/", names(pdfFiles)[i], "_scan", page, ".png")
      })
      
      convertedFiles = pdftools::pdf_convert(pdf=pdfFiles[[i]], filenames=filenames, pages=NULL, format='png', dpi=300, antialias=TRUE, verbose=FALSE)
    }))
  }
  
  if(length(evaluation$examScanPngNames) > 0){
    namesToConsider = c(sub("(.*\\/)([^.]+)(\\.[[:alnum:]]+$)", "\\2", convertedPngFiles), unlist(evaluation$examScanPngNames))
    namesToConsider_idx = (length(namesToConsider)-length(evaluation$examScanPngNames) + 1):length(namesToConsider)

    evaluation$examScanPngNames = as.list(make.unique(namesToConsider, sep="_"))[namesToConsider_idx]
    pngFiles = unlist(lapply(seq_along(evaluation$examScanPngNames), function(i){
      file = paste0(dir, "/", evaluation$examScanPngNames[[i]], ".png")
      raw = openssl::base64_decode(evaluation$examScanPngFiles[[i]])
      writeBin(raw, con = file)
      
      return(file)
    }))
  }
  
  scanFiles = c(convertedPngFiles, pngFiles)

  # meta data
  examName = evaluation$examSolutionsName[[1]]
  numExercises = length(examExerciseMetaData[[1]])
  numChoices = length(examExerciseMetaData[[1]][[1]]$questionlist)
  
  # additional settings
  points = input$fixedPointsExamEvaluate
  if(is.numeric(points) && points > 0) {
    points = rep(points, numExercises)
  } else {
    points = NULL
  }
  
  partial = input$partialPoints
  negative = input$negativePoints
  rule = input$rule
  
  mark = c(input$markThreshold1,
           input$markThreshold2,
           input$markThreshold3,
           input$markThreshold4,
           input$markThreshold5)
  labels = c(input$markLabel1,
             input$markLabe12,
             input$markLabel3,
             input$markLabel4,
             input$markLabel5)
  
  if(any(labels=="")){
    labels = NULL
  }

  language = input$evaluationLanguage

  return(list(meta=list(examName=examName, numExercises=numExercises, numChoices=numChoices),
              fields=list(points=points, partial=partial, negative=negative, rule=rule, mark=mark, labels=labels, language=language), 
              files=list(solution=solutionFile, registeredParticipants=registeredParticipantsFile, scans=scanFiles)))
}

evaluateExamScans = function(preparedEvaluation, collectWarnings, dir){
  out = tryCatch({
    scans_reg_fullJoinData = NULL

    warnings = collectWarnings({
      with(preparedEvaluation, {
        if(length(files$scans) < 1){
          stop("E1012")
        }
        
        if(length(files$registeredParticipants) != 1){
          stop("E1013")
        }
        
        if(length(files$solution) != 1){
          stop("E1014")
        }

        # process scans
        scanData = exams::nops_scan(images=files$scans,
                                    file="test",
                                    dir=dir)
        
        scanData = exams::nops_scan(images=files$scans,
                         file=FALSE,
                         dir=dir)
        scanData = as.data.frame(matrix(Reduce(rbind, lapply(scanData, function(x) strsplit(x, " ")[[1]])), nrow=length(scanData)))
        names(scanData)[c(1:6)] = c("scan", "sheet", "scrambling", "type", "replacement", "registration")
        names(scanData)[-c(1:6)] = (7:ncol(scanData)) - 6
        
        # midify using additional data from exam to know how many questions and answer per question existed
        scanData = scanData[,-which(grepl("^[[:digit:]]+$", names(scanData)))[-c(1:meta$numExercises)]] # remove unnecessary placeholders for unused questions
        scanData$numExercises = meta$numExercises
        scanData$numChoices = meta$numChoices
        
        # add scans as base64 to be displayed in browser
        scanData$blob = lapply(scanData$scan, function(x) {
          file = paste0(dir, "/", x)
          blob = readBin(file, "raw", n=file.info(file)$size)
          openssl::base64_encode(blob)
        })

        # read registered participants
        registeredParticipantData = read.csv2(files$registeredParticipants)
        
        # full outer join of scanData and registeredParticipantData
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
        
        scans_reg_fullJoinData <<- scans_reg_fullJoinData
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
                scans_reg_fullJoinData=scans_reg_fullJoinData, 
                preparedEvaluation=preparedEvaluation))
  },
  error = function(e){
    if(!grepl("E\\d{4}", e$message)){
      e$message = "E1003"
    }
    
    return(list(message=list(key="Error", value=e), scans_reg_fullJoinData=NULL, examName=NULL, files=list(), data=list()))
  })
  
  return(out)
}

evaluateExamScansResponse = function(session, message, scans_reg_fullJoinData) {
  showModal(modalDialog(
    title = tags$span(HTML('<span lang="de">Scans überprüfen</span><span lang="en">Check scans</span>')),
    tags$span(id="responseMessage", myMessage(message)),
    tags$div(id="compareScanRegistrationDataTable"),
    tags$div(id="inspectScan"),
    footer = tagList(
      myActionButton("dismiss_evaluateExamScansResponse", "Abbrechen", "Cancle", "fa-solid fa-xmark"),
      if (!is.null(scans_reg_fullJoinData) && nrow(scans_reg_fullJoinData) > 0) 
        myActionButton("proceedEval", "Weiter", "Proceed", "fa-solid fa-circle-right"),
    ),
    size = "l"
  ))
  session$sendCustomMessage("f_langDeEn", 1)
  
  # display scanData in modal
  if (!is.null(scans_reg_fullJoinData) && nrow(scans_reg_fullJoinData) > 0) {
    scans_reg_fullJoinData_json = rjs_vectorToJsonArray(
      apply(scans_reg_fullJoinData, 1, function(x) {
        rjs_keyValuePairsToJsonObject(names(scans_reg_fullJoinData), x)
      })
    )
    
    session$sendCustomMessage("compareScanRegistrationData", scans_reg_fullJoinData_json)
  }
}

evaluateExamFinalize = function(preparedEvaluation, collectWarnings, dir){
  out = tryCatch({
    # file path and name settings
    nops_evaluation_fileNames = "evaluation.html"
    nops_evaluation_fileNamePrefix = paste0(preparedEvaluation$meta$examName, "_nops_eval")
    preparedEvaluation$files$nops_evaluationCsv = paste0(dir, "/", nops_evaluation_fileNamePrefix, ".csv")
    preparedEvaluation$files$nops_evaluationZip = paste0(dir, "/", nops_evaluation_fileNamePrefix, ".zip")

    warnings = collectWarnings({
      with(preparedEvaluation, {
        # finalize evaluation
        exams::nops_eval(
          register = files$registeredParticipants,
          solutions = files$solution,
          scans = files$scanEvaluation,
          eval = exams::exams_eval(partial = fields$partial, negative = fields$negative, rule = fields$rule),
          points = fields$points,
          mark = fields$mark,
          labels = fields$abels,
          results = nops_evaluation_fileNamePrefix,
          dir = dir,
          file = nops_evaluation_fileNames,
          language = fields$language,
          interactive = TRUE
        )
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
                preparedEvaluation=preparedEvaluation))
  },
  error = function(e){
    if(!grepl("E\\d{4}", e$message)){
      e$message = "E1004"
    }
    
    return(list(message=list(key="Error", value=e), examName=NULL, files=list()))
  })

  return(out)
}

evaluateExamFinalizeResponse = function(session, message, downloadable) {
  showModal(modalDialog(
    title = tags$span(HTML('<span lang="de">Prüfung auswerten</span><span lang="en">Evaluate exam</span>')),
    tags$span(id='responseMessage', myMessage(message)),
    footer = tagList(
      if (downloadable)
        myDownloadButton('downloadEvaluationFiles'),
      # actionButton("dismiss_evaluateExamFinalizeResponse", label = "OK")
      myActionButton("dismiss_evaluateExamFinalizeResponse", "Schließen", "Close", "fa-solid fa-xmark")
    )
  ))
  session$sendCustomMessage("f_langDeEn", 1)
}

startWait = function(session){
  session$sendCustomMessage("wait", 0)
}

stopWait = function(session){
  removeRuntimeFiles(session)
  session$sendCustomMessage("wait", 1)
}

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

rjs_keyValuePairsToJsonObject = function(keys, values){
  values = gsub("\"", "\\\\\"", values)
  values = gsub(":", "\\:", values)
  values = gsub("\\n", " ", values)

  x = paste0("\"", keys, "\":")
  y = paste0("\"", gsub(":", "\\:", values), "\"")
  x = paste0(x, y, collapse=", ")
  x = paste0("{", x, "}")
  return(x)
}

# PARAMETERS --------------------------------------------------------------
exerciseMin = 1
exerciseMax = 45
seedMin = 1
seedMax = 999999999999
initSeed = 1
numberOfExerciseBlocks = 1
maxNumberOfExamExercises = 0
languages = c("en",
              "de")
# languages = c("en",
#               "hr",
#               "da",
#               "nl",
#               "fi",
#               "fr",
#               "de",
#               "hu",
#               "it",
#               "ja",
#               "ko",
#               "no",
#               "pt",
#               "ro",
#               "ru",
#               "sr",
#               "sk",
#               "sl",
#               "es",
#               "tr")
rules = list("- 1/max(nwrong, 2)"="false2", "- 1/nwrong"="false", "- 1/ncorrect"="true", "- 1"="all", "- 0"="none")
messageSymbols = c('<i class=\"fa-solid fa-circle-check\"></i>', '<i class=\"fa-solid fa-triangle-exclamation\"></i>', '<i class=\"fa-solid fa-circle-exclamation\"></i>')

errorCodes = read.csv("errorCodes.csv")
errorCodes = setNames(apply(errorCodes[,-1], 1, FUN=as.list), errorCodes[,1])

warningCodes = read.csv("warningCodes.csv")
warningCodes = setNames(apply(warningCodes[,-1], 1, FUN=as.list), warningCodes[,1])

# dataframe that holds usernames, passwords and other user data
# user_base <- tibble::tibble(
#   user = c("user1", "user2"),
#   password = sapply(c("pass1", "pass2"), sodium::password_store),
#   permissions = c("admin", "standard"),
#   name = c("User One", "User Two")
# )

# UI -----------------------------------------------------------------
ui = fluidPage(
  shinyjs::useShinyjs(),
  
  # DEBUG
  textOutput("debug"),
  
  # AUTH 
  # div(class = "pull-right", shinyauthr::logoutUI(id = "logout")),
  # shinyauthr::loginUI(id = "login"),
  
  # TEMPLATE
  htmlTemplate(
    filename = "main.html",
    # EXERCISES 
    textInput_seedValueExercises = textInput("seedValueExercises", label = NULL, value = initSeed),
    button_downloadExercises = myDownloadButton('downloadExercises'),
    button_downloadExercise = myDownloadButton('downloadExercise'),
  
    # EXAM CREATE
    textInput_seedValueExam = textInput("seedValueExam", label = NULL, value = initSeed),
    textInput_numberOfExams = textInput("numberOfExams", label = NULL, value = 1),
    textInput_numberOfExercises = textInput("numberOfExercises", label = NULL, value = 0),
    selectInput_examLanguage = selectInput("examLanguage", label = NULL, choices = languages, selected = NULL, multiple = FALSE),
    textInput_examTitle = textInput("examTitle", label = NULL, value = NULL),
    textInput_examCourse = textInput("examCourse", label = NULL, value = NULL),
    textInput_examInstitution = textInput("examInstitution", label = NULL, value = NULL),
    dateInput_examDate = dateInput("examDate", label = NULL, value = NULL, format = "yyyy-mm-dd"),
    textInput_numberOfBlanks = textInput("numberOfBlanks", label = NULL, value = 0),
    textInput_fixedPointsExamCreate = textInput("fixedPointsExamCreate", label = NULL, value = NULL),
    checkboxInput_showPoints = checkboxInput("showPoints", label = NULL, value = NULL),
    checkboxInput_duplex = checkboxInput("duplex", label = NULL, value = NULL),

    # EXAM EVALUATE
    textInput_fixedPointsExamEvaluate = textInput("fixedPointsExamEvaluate", label = NULL, value = NULL),
    checkboxInput_partialPoints = checkboxInput("partialPoints", label = NULL, value = NULL),
    checkboxInput_negativePoints = checkboxInput("negativePoints", label = NULL, value = NULL),
    selectInput_rule = selectInput("rule", label = NULL, choices = rules, selected = NULL, multiple = FALSE),
  
    textInput_markThreshold1 = textInput("markThreshold1", label = NULL, value = 0),
    textInput_markThreshold2 = textInput("markThreshold2", label = NULL, value = 0.5),
    textInput_markThreshold3 = textInput("markThreshold3", label = NULL, value = 0.6),
    textInput_markThreshold4 = textInput("markThreshold4", label = NULL, value = 0.75),
    textInput_markThreshold5 = textInput("markThreshold5", label = NULL, value = 0.85),
    
    textInput_markLabel1 = textInput("markLabel1", label = NULL, value = NULL),
    textInput_markLabe12 = textInput("markLabe12", label = NULL, value = NULL),
    textInput_markLabel3 = textInput("markLabel3", label = NULL, value = NULL),
    textInput_markLabel4 = textInput("markLabel4", label = NULL, value = NULL),
    textInput_markLabel5 = textInput("markLabel5", label = NULL, value = NULL),
  
    selectInput_evaluationLanguage = selectInput("evaluationLanguage", label = NULL, choices = languages, selected = NULL, multiple = FALSE),
    checkboxInput_rotateScans = checkboxInput("rotateScans", label = NULL, value = NULL)
  )
)
  
# SERVER -----------------------------------------------------------------
server = function(input, output, session) {
  # AUTH --------------------------------------------------------------------
  # credentials <- shinyauthr::loginServer(
  #   id = "login",
  #   data = user_base,
  #   user_col = user,
  #   pwd_col = password,
  #   sodium_hashed = TRUE,
  #   log_out = reactive(logout_init())
  # )
  # 
  # # Logout to hide
  # logout_init <- shinyauthr::logoutServer(
  #   id = "logout",
  #   active = reactive(credentials()$user_auth)
  # )
  
  # req(credentials()$user_auth) #TODO: use this as requirement
  
  # STARTUP -------------------------------------------------------------
  dir.create(getDir(session))
  removeRuntimeFiles(session)

  initSeed <<- as.numeric(gsub("-", "", Sys.Date()))

  session$sendCustomMessage("debugMessage", session$token)
  session$sendCustomMessage("debugMessage", tempdir())
  session$sendCustomMessage("debugMessage", list.files(tempdir()))

  # CLEANUP -------------------------------------------------------------
  onStop(function() {
    unlink(getDir(session), recursive = TRUE)
  })
  
  # HEARTBEAT -------------------------------------------------------------
  initialState = TRUE

  observe({
    invalidateLater(1000 * 5, session)
    if(!initialState) {
      session$sendCustomMessage("heartbeat", 1)
    }
    initialState <<- FALSE
  })

  # EXPORT SINGLE EXERCISE ------------------------------------------------------
  output$downloadExercise = downloadHandler(
    filename = function() {
      paste0(isolate(input$exerciseToDownload$exerciseName), ".rnw")
    },
    content = function(fname) {
      writeLines(text=gsub("\r\n", "\n", isolate(input$exerciseToDownload$exerciseCode)), con=fname)
      removeRuntimeFiles(session)
    },
    contentType = "text/rnw",
  )

  # EXPORT ALL EXERCISES ------------------------------------------------------
  output$downloadExercises = downloadHandler(
    filename = "exercises.zip",
    content = function(fname) {
      result = prepareExerciseDownloadFiles(session, isolate(input$exercisesToDownload))
      exerciseFiles = unlist(result$exerciseFiles, recursive = TRUE)

      zip(zipfile=fname, files=exerciseFiles, flags='-r9XjFS')
      removeRuntimeFiles(session)
    },
    contentType = "application/zip",
  )

  # PARSE EXERCISES -------------------------------------------------------------
  # TODO: (sync, prepare function) send list of exercises with javascript exerciseID and exerciseCode;
  # (sync, prepare function) store all files in temp;
  # (a sync, parse function) parse all exercises ans store results as one list and add to exerciseID;
  # (sync, send values to frontend and load into dom)
  exerciseParsing = eventReactive(input$parseExercise, {
    startWait(session)

    x = callr::r_bg(
      func = parseExercise,
      args = list(isolate(input$parseExercise), isolate(input$seedValueExercises), collectWarnings, getDir(session)),
      supervise = TRUE
      # env = c(callr::rcmd_safe_env(), MAKEBSP = FALSE)
    )

    # x$wait() makes it a sync exercise again - not what we want, but for now lets do this
    # in the future maybe send exercises to parse as batch from javascript
    # then async parse all exercises with one "long" wait screen
    # fill fields sync by looping through reponses (list of reponses, one for each exercise parsed)
    x$wait()

    return(x)
  })

  observe({
    if (exerciseParsing()$is_alive()) {
      invalidateLater(millis = 10, session = session)
    } else {
      result = exerciseParsing()$get_result()
      loadExercise(session, result$id, result$seed, result$html, result$figure, result$message)
      stopWait(session)
    }
  })

  # CREATE EXAM -------------------------------------------------------------
  # exam seed change
  examFiles = reactiveVal()

  examCreation = eventReactive(input$createExam, {
    startWait(session)

    preparedExam = prepareExam(session, isolate(input$createExam), isolate(input$seedValueExercises), isolate(input))

    x = callr::r_bg(
      func = createExam,
      args = list(preparedExam, collectWarnings, getDir(session)),
      supervise = TRUE
    )

    return(x)
  })

  observe({
    if (examCreation()$is_alive()) {
      invalidateLater(millis = 100, session = session)
    } else {
      result = examCreation()$get_result()
      examFiles(unlist(result$files, recursive = TRUE))
      
      print(examFiles())

      examCreationResponse(session, result$message, length(isolate(examFiles())) > 0)
    }
  })

  output$downloadExamFiles = downloadHandler(
    filename = paste0(paste0(c("exam", input$examTitle,
                               input$examCourse,
                               as.character(input$examDate),
                               input$seedValueExercises), collapse="_"), ".zip"),
    content = function(fname) {
      zip(zipfile=fname, files=isolate(examFiles()), flags='-r9XjFS')
    },
    contentType = "application/zip"
  )

  # modal close
  observeEvent(input$dismiss_examCreationResponse, {
    removeModal()
    stopWait(session)
  })

  # EVALUATE EXAM -------------------------------------------------------------
  examEvaluationData = reactiveVal()

  # evaluate scans - trigger
  examScanEvaluation = eventReactive(input$evaluateExam, {
    startWait(session)

    # save input data in reactive value
    examEvaluationData(prepareEvaluation(session, isolate(input$evaluateExam), isolate(input$rotateScans), isolate(input)))

    # background exercise
    x = callr::r_bg(
      func = evaluateExamScans,
      args = list(isolate(examEvaluationData()), collectWarnings, getDir(session)),
      supervise = TRUE
    )

    return(x)
  })

  # evaluate scans - callback
  observe({
    if (examScanEvaluation()$is_alive()) {
      invalidateLater(millis = 100, session = session)
    } else {
      result = examScanEvaluation()$get_result()

      # save result in reactive value
      examEvaluationData(result$preparedEvaluation)

      # open modal
      evaluateExamScansResponse(session,
                       result$message,
                       result$scans_reg_fullJoinData)
    }
  })

  # finalizing evaluation - trigger
  examFinalizeEvaluation = eventReactive(input$proceedEvaluation, {
    dir = getDir(session)
    removeModal()
    preparedEvaluation = isolate(examEvaluationData())

    # process scanData
    scanData = Reduce(c, lapply(input$proceedEvaluation, function(x) paste0(unlist(unname(x)), collapse=" ")))
    scanData = paste0(scanData, collapse="\n")

    # write scanData
    scanDatafile = paste0(dir, "/", "Daten.txt")
    writeLines(text=scanData, con=scanDatafile)

    # create *_nops_scan.zip file needed for exams::nops_eval
    zipFile = paste0(dir, "/", preparedEvaluation$meta$examName, "_nops_scan.zip")
    zip(zipFile, c(preparedEvaluation$files$scans, scanDatafile), flags='-r9XjFS')

    # manage preparedEvaluation data
    preparedEvaluation$files$scanEvaluation = zipFile
    preparedEvaluation$files = within(preparedEvaluation$files, rm(list=c("scans")))
    examEvaluationData(preparedEvaluation)

    # background exercise
    x = callr::r_bg(
      func = evaluateExamFinalize,
      args = list(isolate(examEvaluationData()), collectWarnings, dir),
      supervise = TRUE
    )

    return(x)
  })

  # finalizing evaluation - callback
  observe({
    if (examFinalizeEvaluation()$is_alive()) {
      invalidateLater(millis = 100, session = session)
    } else {
      result = examFinalizeEvaluation()$get_result()

      # save result in reactive value
      examEvaluationData(result$preparedEvaluation)

      # open modal
      evaluateExamFinalizeResponse(session, result$message, length(unlist(result$preparedEvaluation$files, recursive = TRUE)) > 0)
    }
  })

  # finalizing evaluation - download
  output$downloadEvaluationFiles = downloadHandler(
    filename = paste0(gsub("exam", "evaluation", isolate(examEvaluationData()$meta$examName)), ".zip"),
    content = function(fname) {
      zip(zipfile=fname, files=unlist(isolate(examEvaluationData()$files), recursive = TRUE), flags='-r9XjFS')
    },
    contentType = "application/zip"
  )

  # modal close
  observeEvent(input$dismiss_evaluateExamScansResponse, {
    removeModal()
    stopWait(session)
  })

  observeEvent(input$dismiss_evaluateExamFinalizeResponse, {
    removeModal()
    stopWait(session)
  })
}

# RUN APP -----------------------------------------------------------------
shinyApp(ui, server)