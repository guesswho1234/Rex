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

# FUNCTIONS ----------------------------------------------------------------
removeRuntimeFiles = function() {
  temfiles = list.files(dir)
  filesToRemove = temfiles[!(temfiles %in% keep)]

  if(length(filesToRemove) > 0) {
    unlink(paste0(dir, "/", filesToRemove), recursive = TRUE)
  }
}

getMessageType = function(message){
  which(message$key==c("Success", "Warning", "Error")) - 1
}

myMessage = function(message) {
  type = getMessageType(message)
  
  if(type == 2) {
    message$value = message$value$message
  }
  
  message$value = gsub("\"", "'", message$value)
  message$value = gsub("[\r\n]", "<br>", trimws(message$value))
  message$value = gsub("[\r]", "",message$value)
  message$value = gsub("[\n]", "", message$value)
  

  messageSign = paste0('<span class="responseSign ', message$key, 'Sign">', messageSymbols[type + 1], '</span>')
  messageText = paste0('<span class="taskTryCatchText">', message$value , '</span>')
  messageObject = paste0('<span class="taskTryCatch ', message$key, '">', messageSign, messageText, '</span>')
  
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

prepareExportAllTasks = function(tasks){
  taskFiles = unlist(lapply(setNames(seq_along(tasks$taskNames), tasks$taskNames), function(i){
    file = tempfile(pattern = paste0(tasks$taskNames[[i]], "_"), tmpdir = dir, fileext = ".rnw")
    writeLines(text = gsub("\r\n", "\n", tasks$taskCodes[[i]]), con = file)

    return(file)
  }))
  
  return(list(taskFiles=taskFiles))
}

parseExercise = function(task, seed, collectWarnings, dir){
  out = tryCatch({
    warnings = collectWarnings({
      # show all possible choices when viewing tasks (only relevant for editable tasks)
      task$taskCode = sub("maxChoices = 5", "maxChoices = NULL", task$taskCode)
      
      # remove image from question when viewing tasks (only relevant for editable tasks)
      task$taskCode = sub("rnwTemplate_showFigure = TRUE", "rnwTemplate_showFigure = FALSE", task$taskCode)

      # extract figure to display it in the respective field when viewing a task (only relevant for editable tasks)
      figure = strsplit(task$taskCode, "rnwTemplate_figure=")[[1]][2]
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
      writeLines(text = gsub("\r\n", "\n", task$taskCode), con = file)

      htmlTask = exams::exams2html(file, dir = dir, seed = seed, base64 = TRUE)
      
      if (htmlTask$exam1$exercise1$metainfo$type != "mchoice") {
        stop("Question type is not 'mchoice'.")
      }

      NULL
    })
    key = "Success"
    value = paste(unique(unlist(warnings)), collapse="<br>")
    if(value != "") key = "Warning"

    return(list(message=list(key=key, value=value), id=task$taskID, seed=seed, html=htmlTask, figure=figure))
  },
  error = function(e){
    return(list(message=list(key="Error", value=e), id=task$taskID, seed=NULL, html=NULL))
  })
  
  return(out)
}

loadExercise = function(id, seed, html, figure, message, session) {
  session$sendCustomMessage("setTaskId", id)
  
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
    
    session$sendCustomMessage("setTaskExamHistory", examHistory)
    session$sendCustomMessage("setTaskAuthoredBy", authoredBy)
    session$sendCustomMessage("setTaskPrecision", precision)
    session$sendCustomMessage("setTaskPoints", points)
    session$sendCustomMessage("setTaskTopic", topic)
    session$sendCustomMessage("setTaskType", type)
    session$sendCustomMessage("setTaskTags", tags)
    session$sendCustomMessage("setTaskSeed", seed)
    session$sendCustomMessage("setTaskQuestion", question)
    session$sendCustomMessage("setTaskFigure", figure)
    session$sendCustomMessage("setTaskEditable", editable)
    
    if(type == c("mchoice")) {
      session$sendCustomMessage("setTaskChoices", rjs_vectorToJsonStringArray(html$exam1$exercise1$questionlist))
      session$sendCustomMessage("setTaskResultMchoice", rjs_vectorToJsonArray(tolower(as.character(html$exam1$exercise1$metainfo$solution))))
    } 
    
    if(type == "num") {
      session$sendCustomMessage("setTaskResultNumeric", result)
    }
  }

  session$sendCustomMessage("setTaskMessage", myMessage(message))
  session$sendCustomMessage("setTaskE", getMessageType(message))
  session$sendCustomMessage("setTaskId", -1)
}

prepareExam = function(exam, seed, input) {
  taskFiles = unlist(lapply(setNames(seq_along(exam$taskNames), exam$taskNames), function(i){
    file = tempfile(pattern = paste0(exam$taskNames[[i]], "_"), tmpdir = dir, fileext = ".rnw")
    writeLines(text = gsub("\r\n", "\n", exam$taskCodes[[i]]), con = file, sep="")

    return(file)
  }))
  
  additionalPdfFiles = unlist(lapply(setNames(seq_along(exam$additionalPdfNames), exam$additionalPdfNames), function(i){
    file = tempfile(pattern = paste0(exam$additionalPdfNames[[i]], "_"), tmpdir = dir, fileext = ".pdf")
    raw = openssl::base64_decode(exam$additionalPdfFiles[[i]])
    writeBin(raw, con = file)

    return(file)
  }))

  numberOfExams = as.numeric(exam$numberOfExams)
  blocks = as.numeric(exam$blocks)
  uniqueBlocks = unique(blocks)
  numberOfTasks = as.numeric(exam$numberOfTasks)
  tasksPerBlock = numberOfTasks / length(uniqueBlocks)
  tasks = lapply(uniqueBlocks, function(x) taskFiles[blocks==x])

  seedList = matrix(1, nrow=numberOfExams, ncol=length(exam$taskNames))
  seedList = seedList * as.numeric(paste0(if(is.na(exam$examSeed)) NULL else exam$examSeed, 1:numberOfExams))
  
  pages = NULL
  
  if(length(additionalPdfFiles) > 0) {
    pages = additionalPdfFiles
  }
  
  title = input$examTitle
  course = input$examCourse
  points = if(!is.na(input$numberOfFixedPoints) && is.numeric(input$numberOfFixedPoints)) input$numberOfFixedPoints else NULL
  date = input$examDate
  name = paste0(c("exam", title, course, as.character(date), exam$examSeed, ""), collapse="_")
  
  examFields = list(
    file = tasks,
    fileBoundaries = c(1, 45),
    n = numberOfExams,
    nsamp = tasksPerBlock,
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
  
  examHtmlFiles = paste0(dir, "/", name, 1:exam$numberOfExams, ".html")
  examPdfFiles = paste0(dir, "/", name, 1:exam$numberOfExams, ".pdf")
  examRdsFile = paste0(dir, "/", name, ".rds")

  return(list(examFields=examFields, examFiles=list(examHtmlFiles=examHtmlFiles, pdfFiles=examPdfFiles, rdsFile=examRdsFile), sourceFiles=list(taskFiles=taskFiles, additionalPdfFiles=additionalPdfFiles)))
}

createExam = function(preparedExam, collectWarnings, dir) {
  out = tryCatch({
    warnings = collectWarnings({
        with(preparedExam$examFields, {
          # if(length(file) < fileBoundaries[1] || length(file) > fileBoundaries[2]){
          #   message = "Number of exam tasks is not valid."
          #   stop(message)
          # }
          # 
          # if(!is.numeric(seed) || (seed < seedBoundaries[1] && seed > seedBoundaries[2])){
          #   message = "Seed value is not valid."
          #   stop(message)
          # }
          
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
    if(value != "") key = "Warning"
    
    return(list(message=list(key=key, value=value), files=list(sourceFiles=preparedExam$sourceFiles, examFiles=preparedExam$examFiles)))
  },
  error = function(e){
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

prepareEvaluation = function(evaluation, rotate, input){
  # exam
  solutionFile = unlist(lapply(seq_along(evaluation$examSolutionsName), function(i){
    file = tempfile(pattern = paste0(evaluation$examSolutionsName[[i]], "_"), tmpdir = dir, fileext = ".rds")
    raw = openssl::base64_decode(evaluation$examSolutionsFile[[i]])
    writeBin(raw, con = file)

    return(file)
  }))
  examExerciseMetaData = readRDS(solutionFile)
  
  # registered participants
  registeredParticipantsFile = unlist(lapply(seq_along(evaluation$examRegisteredParticipantsnName), function(i){
    file = tempfile(pattern = paste0(evaluation$examRegisteredParticipantsnName[[i]], "_"), tmpdir = dir, fileext = ".csv")
    writeLines(text = gsub("\r\n", "\n", evaluation$examRegisteredParticipantsnFile[[i]]), con = file)

    return(file)
  }))
  
  # process scans to end up with only png files at the end
  pngFiles = unlist(lapply(seq_along(evaluation$examScanPngNames), function(i){
    file = tempfile(pattern = paste0(evaluation$examScanPngNames[[i]], "_"), tmpdir = dir, fileext = ".png")
    raw = openssl::base64_decode(evaluation$examScanPngFiles[[i]])
    writeBin(raw, con = file)

    return(file)
  }))
  
  pdfFiles = lapply(setNames(seq_along(evaluation$examScanPdfNames), evaluation$examScanPdfNames), function(i){
    file = tempfile(pattern = paste0(evaluation$examScanPdfNames[[i]], "_"), tmpdir = dir, fileext = ".pdf")
    raw = openssl::base64_decode(evaluation$examScanPdfFiles[[i]])
    writeBin(raw, con = file)

    if(rotate){
      output = tempfile(pattern = paste0(evaluation$examScanPdfNames[[i]], "_"), tmpdir = dir, fileext = ".pdf")
      numberOfPages = qpdf::pdf_length(file)
      qpdf::pdf_rotate_pages(input=file, output=output, pages=1:numberOfPages, angle=ifelse(rotate, 180, 0))

      file = output
    }
    
    return(file)
  })
  
  convertedPngFiles = unlist(lapply(seq_along(pdfFiles), function(i){
    numberOfPages = qpdf::pdf_length(pdfFiles[[i]])
    filenames = sapply(1:numberOfPages, function(page){
     tempfile(pattern = paste0(names(pdfFiles)[i], "_scan", page, "_"), tmpdir = dir, fileext = ".png")
    })
    
    convertedFiles = pdftools::pdf_convert(pdf=pdfFiles[[i]], filenames=filenames, pages=NULL, format='png', dpi=300, antialias=TRUE, verbose=FALSE)
  }))
  
  scanFiles = c(pngFiles, convertedPngFiles)

  # meta data
  examName = evaluation$examSolutionsName[[1]]
  numExercises = length(examExerciseMetaData[[1]])
  numChoices = length(examExerciseMetaData[[1]][[1]]$questionlist)
  
  # additional settings
  points = input$fixedPoints
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
        # process scans
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
        
        scans_reg_fullJoinData <<- scans_reg_fullJoinData
      })
      
      NULL
    })
    key = "Success"
    value = paste(unique(unlist(warnings)), collapse="<br>")
    if(value != "") key = "Warning"

    return(list(message=list(key=key, value=value), 
                scans_reg_fullJoinData=scans_reg_fullJoinData, 
                preparedEvaluation=preparedEvaluation))
  },
  error = function(e){
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
      # if(any(is.na(preparedEvaluation$fields$mark))){
      #   stop("Clef is invalid.")
      # }
      # 
      # if(!is.null(preparedEvaluation$fields$labels) && any(preparedEvaluation$fields$labels=="")){
      #   stop("Clef is invalid.")
      # }

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
    if(value != "") key = "Warning"
    
    return(list(message=list(key=key, value=value), 
                preparedEvaluation=preparedEvaluation))
  },
  error = function(e){
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
  removeRuntimeFiles()
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
dir = tempdir()
keep = list.files(dir)
seedMin = 1
seedMax = 999999999999
initSeed = as.numeric(gsub("-", "", Sys.Date()))
numberOfTaskBlocks = 1
maxNumberOfExamTasks = 0
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

# UI -----------------------------------------------------------------
ui = fluidPage(
  shinyjs::useShinyjs(),
  textOutput("debug"),
  htmlTemplate(
    filename = "main.html",

    # TASKS -------------------------------------------------------------------
    numericInput_seedValue = numericInput("seedValue", label = NULL, value = initSeed, min = seedMin, max = seedMax),
    button_taskExportAll = myDownloadButton('taskDownloadAll'),

    # EXAM --------------------------------------------------------------------
      # CREATE ------------------------------------------------------------------
      numericInput_seedValueExam = numericInput("seedValueExam", label = NULL, value = initSeed, min = seedMin, max = seedMax),
      numericInput_numberOfExams = numericInput("numberOfExams", label = NULL, value = 1, min = 1, step = 1),
      numericInput_numberOfTasks = numericInput("numberOfTasks", label = NULL, value = 0, min = 0, max = 45, step = 1),
      selectInput_examLanguage = selectInput("examLanguage", label = NULL, choices = languages, selected = NULL, multiple = FALSE),
      textInput_examTitle = textInput("examTitle", label = NULL, value = NULL),
      textInput_examCourse = textInput("examCourse", label = NULL, value = NULL),
      textInput_examInstitution = textInput("examInstitution", label = NULL, value = NULL),
      dateInput_examDate = dateInput("examDate", label = NULL, value = NULL, format = "yyyy-mm-dd"),
      numericInput_numberOfBlanks = numericInput("numberOfBlanks", label = NULL, value = 0, min = 0),
      numericInput_numberOfFixedPoints = numericInput("numberOfFixedPoints", label = NULL, value = NULL, min = 1),
      checkboxInput_showPoints = checkboxInput("showPoints", label = NULL, value = NULL),
      checkboxInput_duplex = checkboxInput("duplex", label = NULL, value = NULL),

      # EVALUATE ----------------------------------------------------------------
      numericInput_fixedPoints = numericInput("fixedPoints", label = NULL, value = NULL, min = 0),
      checkboxInput_partialPoints = checkboxInput("partialPoints", label = NULL, value = NULL),
      checkboxInput_negativePoints = checkboxInput("negativePoints", label = NULL, value = NULL),
      selectInput_rule = selectInput("rule", label = NULL, choices = rules, selected = NULL, multiple = FALSE),
    
      numericInput_markThreshold1 = numericInput("markThreshold1", label = NULL, value = 0, min = 0),
      numericInput_markThreshold2 = numericInput("markThreshold2", label = NULL, value = 0.5, min = 0),
      numericInput_markThreshold3 = numericInput("markThreshold3", label = NULL, value = 0.6, min = 0),
      numericInput_markThreshold4 = numericInput("markThreshold4", label = NULL, value = 0.75, min = 0),
      numericInput_markThreshold5 = numericInput("markThreshold5", label = NULL, value = 0.85, min = 0),
      
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
  # STARTUP -------------------------------------------------------------
  session$sendCustomMessage("debugMessage", session$token)
  session$sendCustomMessage("debugMessage", dir)
  
  dir <<- paste0(dir, "/", session$token)
  dir.create(dir)
  removeRuntimeFiles()
  
  # print(tempdir())
  # dir <<- paste0(dir, "/", session$token)
  # unlink(tempdir(), recursive = TRUE)
  # 
  # dir.create(dir, recursive = TRUE)
  # Sys.setenv(TMPDIR = tools::file_path_as_absolute(dir))
  # 
  # print(tempdir())
  
  # dir.create(dir)
  # Sys.setenv(TMPDIR = tools::file_path_as_absolute(dir))
  # print(tempdir())

  # print(tempdir())
  # newtmp <- dir
  # print(newtmp)
  # dir.create(newtmp)
  # Sys.setenv(TMPDIR = tools::file_path_as_absolute(newtmp))
  # # unlink(tempdir(), recursive = TRUE)
  # print(tempdir(check=TRUE))
  
  # CLEANUP -------------------------------------------------------------
  onStop(function() {
    unlink(dir, recursive = TRUE)
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
  
  # EXPORT ALL TASKS ------------------------------------------------------
  # TODO: implement async with popup like exam create / evaluate, ...
  # taskFiles = reactiveVal()
  # 
  # observeEvent(input$taskExportAllProxy, {
  #   result = prepareExportAllTasks(isolate(input$taskExportAllProxy))
  #   taskFiles(unlist(result$taskFiles, recursive = TRUE))
  #   if(length(isolate(taskFiles())) > 0) {
  #     # session$sendCustomMessage("taskDownloadAll", 1) #tried via js, same resulst
  #     print(isolate(taskFiles()))
  #     # click("taskDownloadAll")
  #   }
  # })
  # 
  # output$taskDownloadAll = downloadHandler(
  #   filename = "tasks.zip",
  #   content = function(fname) {
  #     zip(zipfile=fname, files=isolate(taskFiles()), flags='-r9XjFS')
  #   },
  #   contentType = "application/zip"
  # )

  # PARSE TASKS -------------------------------------------------------------
  # TODO: (sync, prepare function) send list of tasks with javascript taskID and taskCode; 
  # (sync, prepare function) store all files in temp; 
  # (a sync, parse function) parse all tasks ans store results as one list and add to taskID;
  # (sync, send values to frontend and load into dom)
  exerciseParsing = eventReactive(input$parseExercise, {
    startWait(session)
    
    x = callr::r_bg(
      func = parseExercise,
      args = list(isolate(input$parseExercise), isolate(input$seedValue), collectWarnings, dir),
      supervise = TRUE
      # env = c(callr::rcmd_safe_env(), MAKEBSP = FALSE)
    )
    
    # x$wait() makes it a sync task again - not what we want, but for now lets do this
    # in the future maybe send tasks to parse as batch from javascript
    # then async parse all tasks with one "long" wait screen
    # fill fields sync by looping through reponses (list of reponses, one for each task parsed)
    x$wait()
    
    return(x)
  })
  
  observe({
    if (exerciseParsing()$is_alive()) {
      invalidateLater(millis = 10, session = session)
    } else {
      result = exerciseParsing()$get_result()
      loadExercise(result$id, result$seed, result$html, result$figure, result$message, session)
      stopWait(session)
    }
  })
  
  # CREATE EXAM -------------------------------------------------------------
  # exam seed change
  examFiles = reactiveVal()

  examCreation = eventReactive(input$createExam, {
    startWait(session)

    preparedExam = prepareExam(isolate(input$createExam), isolate(input$seedValue), isolate(input))

    x = callr::r_bg(
      func = createExam,
      args = list(preparedExam, collectWarnings, dir),
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

      examCreationResponse(session, result$message, length(isolate(examFiles())) > 0)
    }
  })

  output$downloadExamFiles = downloadHandler(
    filename = paste0(paste0(c("exam", input$examTitle,
                               input$examCourse,
                               as.character(input$examDate),
                               input$seedValue), collapse="_"), ".zip"),
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
    examEvaluationData(prepareEvaluation(isolate(input$evaluateExam), isolate(input$rotateScans), isolate(input)))

    # background task
    x = callr::r_bg(
      func = evaluateExamScans,
      args = list(isolate(examEvaluationData()), collectWarnings, dir),
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
    removeModal()
    preparedEvaluation = isolate(examEvaluationData())

    # process scanData
    scanData = Reduce(c, lapply(input$proceedEvaluation, function(x) paste0(unlist(unname(x)), collapse=" ")))
    scanData = paste0(scanData, collapse="\n")

    # write scanData
    scanDatafile = paste0(dir, "/", "Daten.txt")
    writeLines(text = scanData, con = scanDatafile)
    
    # create *_nops_scan.zip file needed for exams::nops_eval
    zipFile = paste0(dir, "/", preparedEvaluation$meta$examName, "_nops_scan.zip")
    zip(zipFile, c(preparedEvaluation$files$scans, scanDatafile), flags='-r9XjFS')
    
    # manage preparedEvaluation data
    preparedEvaluation$files$scanEvaluation = zipFile
    preparedEvaluation$files = within(preparedEvaluation$files, rm(list=c("scans")))
    examEvaluationData(preparedEvaluation)
    
    # background task
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