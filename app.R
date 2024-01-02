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
  dir = tempdir()
  
  taskFiles = unlist(lapply(setNames(seq_along(tasks$taskNames), tasks$taskNames), function(i){
    file = tempfile(pattern = paste0(tasks$taskNames[[i]], "_"), tmpdir = dir, fileext = ".rnw")
    writeLines(text = tasks$taskCodes[[i]], con = file)
    
    return(file)
  }))
  
  return(list(taskFiles=taskFiles))
}

parseExercise = function(task, seed, collectWarnings){
  out = tryCatch({
    warnings = collectWarnings({
      # show all possible choices in view mode
      task$taskCode = gsub("maxChoices = 5", "maxChoices = NULL", task$taskCode)

      seed = if(is.na(seed)) NULL else seed
      file = tempfile(fileext = ".Rnw")
      writeLines(text = task$taskCode, con = file)

      htmlTask = exams::exams2html(file, dir = tempdir(), seed = seed)
      
      NULL
    })
    key = "Success"
    value = paste(unlist(warnings), collapse="%;%")
    if(value != "") key = "Warning"

    return(list(id=task$taskID, seed=seed, html=htmlTask, e=c(key, value)))
  },
  error = function(e){
    message = e$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "%;%", message)
    
    return(list(id=task$taskID, seed=NULL, html=NULL, e=c("Error", message)))
  })
  
  return(out)
}

loadExercise = function(id, seed, html, e, session) {
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
    session$sendCustomMessage("setTaskEditable", editable)
    
    if(type == c("mchoice")) {
      session$sendCustomMessage("setTaskChoices", rjs_vectorToJsonStringArray(html$exam1$exercise1$questionlist))
      session$sendCustomMessage("setTaskResultMchoice", rjs_vectorToJsonArray(tolower(as.character(html$exam1$exercise1$metainfo$solution))))
    } 
    
    if(type == "num") {
      session$sendCustomMessage("setTaskResultNumeric", result)
    }
  }

  session$sendCustomMessage("setTaskE", rjs_keyValuePairsToJsonObject(c("key", "value"), e))
  session$sendCustomMessage("setTaskId", -1)
}

prepareExam = function(exam, seed, input) {
  dir = tempdir()
  
  taskFiles = unlist(lapply(setNames(seq_along(exam$taskNames), exam$taskNames), function(i){
    file = tempfile(pattern = paste0(exam$taskNames[[i]], "_"), tmpdir = dir, fileext = ".rnw")
    writeLines(text = exam$taskCodes[[i]], con = file)
    
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
    n = numberOfExams,
    nsamp = tasksPerBlock,
    dir = dir,
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
    seed = seedList
  )
  
  examHtmlFiles = paste0(dir, "/", name, 1:exam$numberOfExams, ".html")
  examPdfFiles = paste0(dir, "/", name, 1:exam$numberOfExams, ".pdf")
  examRdsFile = paste0(dir, "/", name, ".rds")
  
  return(list(examFields=examFields, examFiles=list(examHtmlFiles=examHtmlFiles, pdfFiles=examPdfFiles, rdsFile=examRdsFile), sourceFiles=list(taskFiles=taskFiles, additionalPdfFiles=additionalPdfFiles)))
}

createExam = function(preparedExam, collectWarnings) {
  out = tryCatch({
    warnings = collectWarnings({
        with(preparedExam$examFields, {
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
    value = paste(unlist(warnings), collapse="%;%")
    if(value != "") key = "Warning"
    
    return(list(message=list(key=key, value=value), files=list(sourceFiles=preparedExam$sourceFiles, examFiles=preparedExam$examFiles)))
  },
  error = function(e){
    message = e$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "%;%", message)
    
    return(list(message=list(key="Error", value=message), files=list()))
  })
  
  return(out)
}

examCreationResponse = function(session, message, downloadable) {
  showModal(modalDialog(
    title = "exams2nops",
    tags$span(id="responseMessage", class=message$key, paste0(message$key, ": ", gsub("%;%", "<br>", message$value))),
    footer = tagList(
      if (downloadable)
        downloadButton('downloadExamFiles', 'Download'),
      modalButton("OK")
    )
  ))
}

prepareEvaluation = function(evaluation, rotate, input){
  dir = tempdir()

  solutionFile = unlist(lapply(seq_along(evaluation$examSolutionsName), function(i){
    file = tempfile(pattern = paste0(evaluation$examSolutionsName[[i]], "_"), tmpdir = dir, fileext = ".rds")
    raw = openssl::base64_decode(evaluation$examSolutionsFile[[i]])
    writeBin(raw, con = file)
    
    return(file)
  }))
  
  registeredParticipantsFile = unlist(lapply(seq_along(evaluation$examRegisteredParticipantsnName), function(i){
    file = tempfile(pattern = paste0(evaluation$examRegisteredParticipantsnName[[i]], "_"), tmpdir = dir, fileext = ".csv")
    writeLines(text = evaluation$examRegisteredParticipantsnFile[[i]], con = file)
    
    return(file)
  }))
  
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
    pdftools::pdf_convert(pdf=pdfFiles[[i]], filenames=filenames, pages=NULL, format='png', dpi=300, antialias=TRUE, verbose=FALSE)
  }))
  
  scanFiles = c(pngFiles, convertedPngFiles)

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

  return(list(dir=dir, 
              examName=evaluation$examSolutionsName[[1]], 
              fields=list(points=points, partial=partial, negative=negative, rule=rule, mark=mark, labels=labels, language=language), 
              files=list(solution=solutionFile, registeredParticipants=registeredParticipantsFile, scans=scanFiles)))
}

evaluateExamScans = function(preparedEvaluation, collectWarnings){
  out = tryCatch({
    nops_scan_fileName = paste0(preparedEvaluation$examName, "_nops_scan", ".zip")
    nops_scan_file = paste0(preparedEvaluation$dir, "/", nops_scan_fileName)
    scanData = NULL
    registeredParticipantData = NULL

    warnings = collectWarnings({
      with(preparedEvaluation, {
        # process scans
        exams::nops_scan(images=files$scans,
                         file=nops_scan_fileName,
                         dir=dir)
        
        scanData = read.table(unz(nops_scan_file, "Daten.txt"), colClasses = "character", stringsAsFactors = F)
        names(scanData)[c(1:6)] = c("scan", "sheet", "scrambling", "type", "replacement", "registration")
        names(scanData)[-c(1:6)] = (7:ncol(scanData)) - 6
        scanData = scanData[,1:(max(as.numeric(scanData$type)) + 6)] # remove unnecessary answer placeholder for non existing questions (steps of 5)
        scanData$blob = lapply(scanData$scan, function(x) {
          file = paste0(dir, "/", x)
          blob = readBin(file, "raw", n=file.info(file)$size)
          openssl::base64_encode(blob)
        })
        scanData <<- scanData 
        
        registeredParticipantData <<- read.csv2(files$registeredParticipants)
      })
      
      NULL
    })
    key = "Success"
    value = paste(unlist(warnings), collapse="%;%")
    if(value != "") key = "Warning"
    
    return(list(message=list(key=key, value=value), 
                dir=preparedEvaluation$dir,
                examName=preparedEvaluation$examName, 
                files=list(sourceFiles=preparedEvaluation$files, 
                           scanFiles=nops_scan_file), 
                data=list(scanData=scanData,
                          registeredParticipantData=registeredParticipantData))) 
  },
  error = function(e){
    message = e$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "%;%", message)
    
    return(list(message=list(key="Error", value=message), dir=NULL, examName=NULL, files=list(), data=list()))
  })
  
  return(out)
}

examScanResponse = function(session, message, scans_reg_fullJoinData) {
  showModal(modalDialog(
    title = "nops_scan",
    tags$span(id="responseMessage", class=message$key, paste0(message$key, ": ", gsub("%;%", "<br>", message$value))),
    tags$div(id="compareScanRegistrationDataTable"),
    tags$div(id="inspectScan"),
    footer = tagList(
      modalButton("Cancle"),
      if (nrow(scans_reg_fullJoinData) > 0) 
        actionButton("proceedEvaluation", "Proceed"),
    )
  ))
  
  scans_reg_fullJoinData_json = rjs_vectorToJsonArray(
    apply(scans_reg_fullJoinData, 1, function(x) {
      rjs_keyValuePairsToJsonObject(names(scans_reg_fullJoinData), x)
    })
  )
  session$sendCustomMessage("compareScanRegistrationData", scans_reg_fullJoinData_json)
}

# evaluateExam = function(preparedEvaluation, collectWarnings){
#   out = tryCatch({
#     nops_scan_fileName = paste0(preparedEvaluation$examName, "_nops_scan", ".zip")
#     nops_scan_file = paste0(preparedEvaluation$dir, "/", nops_scan_fileName)
#     nops_evaluation_fileNamePrefix = paste0(preparedEvaluation$examName, "_nops_eval")
#     nops_evaluation_files = paste0("evaluation", seq_along(preparedEvaluation$files$scans), ".html")
#     nops_evaluation_fileNames = "evaluation.html"
#     nops_evaluationCsv = paste0(preparedEvaluation$dir, "/", nops_evaluation_fileNamePrefix, ".csv")
#     nops_evaluationZip = paste0(preparedEvaluation$dir, "/", nops_evaluation_fileNamePrefix, ".zip")
# 
#     warnings = collectWarnings({
#       if(any(is.na(preparedEvaluation$fields$mark))){
#         stop("Clef is invalid.")
#       }
#       
#       if(!is.null(preparedEvaluation$fields$labels) && any(preparedEvaluation$fields$labels=="")){
#         stop("Clef is invalid.")
#       }
#       
#       with(preparedEvaluation, {
#         # process scans
#         exams::nops_scan(images=files$scans,
#                          file=nops_scan_fileName,
#                          dir=dir)
#         
#         # evaluate scans
#         exams::nops_eval(
#           register = files$registeredParticipants,
#           solutions = files$solution,
#           scans = nops_scan_file, # daten.txt and png files
#           eval = exams::exams_eval(partial = fields$partial, negative = fields$negative, rule = fields$rule),
#           # points = points,
#           mark = fields$mark,
#           labels = fields$abels,
#           results = nops_evaluation_fileNamePrefix,
#           dir = dir,
#           file = nops_evaluation_fileNames,
#           language = fields$language,
#           interactive = TRUE
#         )
#       })
#       
#       NULL
#     })
#     key = "Success"
#     value = paste(unlist(warnings), collapse="%;%")
#     if(value != "") key = "Warning"
# 
#     return(list(message=list(key=key, value=value), 
#                 examName=preparedEvaluation$examName, 
#                 files=list(sourceFiles=preparedEvaluation$files, 
#                            scanFiles=nops_scan_file, 
#                            evaluationFiles=list(summary=nops_evaluationCsv, 
#                                                 individualExams=nops_evaluationZip))))
#   },
#   error = function(e){
#     message = e$message
#     message = gsub("\"", "'", message)
#     message = gsub("[\r\n]", "%;%", message)
#     
#     return(list(message=list(key="Error", value=message), examName=NULL, files=list()))
#   })
#   
#   return(out)
# }
# 
# examEvaluationResponse = function(session, message, downloadable) {
#   showModal(modalDialog(
#     title = "nops_scan & nops_eval",
#     tags$span(id='responseMessage', class=message$key, paste0(message$key, ": ", gsub("%;%", "<br>", message$value))),
#     footer = tagList(
#       if (downloadable)
#         downloadButton('downloadEvaluationFiles', 'Download'),
#       modalButton("OK")
#     )
#   ))
# }

startWait = function(session){
  session$sendCustomMessage("wait", 0)
}

stopWait = function(session){
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
  x = paste0("\"", keys, "\":")
  y = paste0("\"", gsub(":", "\\:", values), "\"")
  x = paste0(x, y, collapse=", ")
  x = paste0("{", x, "}")
  return(x)
}

checkSeed = function(seed) {
  if(!(is.numeric(seed)) || is.null(seed) || is.na(seed)) {
    return("")
  } 
  
  if(seed < seedMin) {
    return(seedMin)
  } 
  
  if(seed > seedMax) {
    return(seedMax)
  } 

  return(isolate(seed))
}

checkNumberOfExamTasks = function(numberOfExamTasks){
  if(!(is.numeric(numberOfExamTasks)) || is.null(numberOfExamTasks) || is.na(numberOfExamTasks)) {
    return(0)
  } 
  
  if(numberOfExamTasks < 0) {
    return(0)
  } 
  
  if(numberOfExamTasks > maxNumberOfExamTasks){
    return(maxNumberOfExamTasks)
  } 
  
  if(numberOfExamTasks %% numberOfTaskBlocks != 0){
    return(numberOfTaskBlocks)
  } 
  
  return(isolate(numberOfExamTasks))
}

checkPosNumber = function(numberField){
  if(!(is.numeric(numberField)) || is.null(numberField) || is.na(numberField)) {
    return("")
  } 
  
  if(numberField < 0) {
    return("")
  } 
  
  return(isolate(numberField))
}

# PARAMETERS --------------------------------------------------------------
seedMin = 1
seedMax = 999999999999
initSeed = as.numeric(gsub("-", "", Sys.Date()))
numberOfTaskBlocks = 1
maxNumberOfExamTasks = 0
languages = c("en",
              "hr",
              "da",
              "nl",
              "fi",
              "fr",
              "de",
              "hu",
              "it",
              "ja",
              "ko",
              "no",
              "pt",
              "ro",
              "ru",
              "sr",
              "sk",
              "sl",
              "es",
              "tr")
rules = list("- 1/max(nwrong, 2)"="false2", "- 1/nwrong"="false", "- 1/ncorrect"="true", "- 1"="all", "- 0"="none")

# UI -----------------------------------------------------------------
ui = fluidPage(
  shinyjs::useShinyjs(),
  textOutput("debug"),
  htmlTemplate(
    filename = "main.html",

    # TASKS -------------------------------------------------------------------
    numericInput_seedValue = numericInput("seedValue", label = NULL, value = initSeed, min = seedMin, max = seedMax),
    button_taskExportAll = downloadButton('taskDownloadAll', 'Export'),

    # EXAM --------------------------------------------------------------------
      # CREATE ------------------------------------------------------------------
      numericInput_seedValueExam = numericInput("seedValueExam", label = NULL, value = initSeed, min = seedMin, max = seedMax),
      numericInput_numberOfExams = numericInput("numberOfExams", label = NULL, value = 1, min = 1, step = 1),
      numericInput_numberOfTasks = numericInput("numberOfTasks", label = NULL, value = 0, step = 1),
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
  # HEARTBEAT -------------------------------------------------------------
  initialState = TRUE

  observe({
    invalidateLater(1000 * 5, session)
    if(!initialState) {
      session$sendCustomMessage("heartbeat", 1)
    }
    initialState <<- FALSE
  })
  
  # INPUT VALUE CHANGES -------------------------------------------------------------
  # seed change
  observeEvent(input$seedValue, {
    updateNumericInput(session, "seedValue", value = checkSeed(input$seedValue))
  })
  
  # exam seed change
  observeEvent(input$seedValueExam, {
    updateNumericInput(session, "seedValueExam", value = checkSeed(input$seedValueExam))
  })
  
  # number of exam tasks input change
  observeEvent(input$numberOfTasks, {
    updateNumericInput(session, "numberOfTasks", value = checkNumberOfExamTasks(input$numberOfTasks))
  })
  
  # number of blank pages
  observeEvent(input$numberOfBlanks, {
    updateNumericInput(session, "numberOfBlanks", value = checkPosNumber(input$numberOfBlanks))
  })
  
  # number of fixed points per task
  observeEvent(input$numberOfFixedPoints, {
    updateNumericInput(session, "numberOfFixedPoints", value = checkPosNumber(input$numberOfFixedPoints))
  })
  
  # set max number of exam tasks
  observeEvent(input$setNumberOfExamTasks, {
    maxNumberOfExamTasks <<- input$setNumberOfExamTasks
  })
  
  # set number of task blocks
  observeEvent(input$setNumberOfTaskBlocks, {
    numberOfTaskBlocks <<- input$setNumberOfTaskBlocks
  })
  
  # EXPORT ALL TASKS ------------------------------------------------------
  taskFiles = reactiveVal()
  
  observeEvent(input$taskExportAll, {
    result = prepareExportAllTasks(isolate(input$taskExportAll))
    taskFiles(unlist(result$taskFiles, recursive = TRUE))
    if(length(taskFiles()) > 0) {
      # session$sendCustomMessage("taskDownloadAll", 1) #tried via js, same resulst
      print(taskFiles())
      # click("taskDownloadAll")
    }
  })
  
  output$taskDownloadAll = downloadHandler(
    filename = "tasks.zip",
    content = function(fname) {
      zip(zipfile=fname, files=isolate(taskFiles()), flags='-r9Xj')
    },
    contentType = "application/zip"
  )
  
  # PARSE TASKS -------------------------------------------------------------
  exerciseParsing = eventReactive(input$parseExercise, {
    startWait(session)
    
    x = callr::r_bg(
      func = parseExercise,
      args = list(isolate(input$parseExercise), isolate(input$seedValue), collectWarnings),
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
      loadExercise(result$id, result$seed, result$html, result$e, session)
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
      args = list(preparedExam, collectWarnings),
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
      examCreationResponse(session, result$message, length(examFiles()) > 0)
      stopWait(session)
    }
  })

  output$downloadExamFiles = downloadHandler(
    filename = paste0(paste0(c("exam", isolate(input$examTitle),
                               isolate(input$examCourse),
                               as.character(isolate(input$examDate)),
                               isolate(input$seedValue)), collapse="_"), ".zip"),
    content = function(fname) {
      zip(zipfile=fname, files=isolate(examFiles()), flags='-r9Xj')
    },
    contentType = "application/zip"
  )
  
  # EVALUATE EXAM -------------------------------------------------------------
  
  # exam seed change
  examScanEvaluationValues = reactiveVal()
  
  examScanEvaluation = eventReactive(input$evaluateExam, {
    startWait(session)
    
    preparedEvaluation = prepareEvaluation(isolate(input$evaluateExam), isolate(input$rotateScans), isolate(input))
    
    x = callr::r_bg(
      func = evaluateExamScans,
      args = list(preparedEvaluation, collectWarnings),
      supervise = TRUE
    )
    
    return(x)
  })
  
  observe({
    if (examScanEvaluation()$is_alive()) {
      invalidateLater(millis = 100, session = session)
    } else {
      result = examScanEvaluation()$get_result()
      examScanEvaluationValues(result)

      scans_reg_fullJoinData = merge(examScanEvaluationValues()$data$scanData, examScanEvaluationValues()$data$registeredParticipantData, by="registration", all=TRUE)
      scans_reg_fullJoinData$registration[is.na(scans_reg_fullJoinData$name) & is.na(scans_reg_fullJoinData$id)] = "XXXXXXX"
      
      examScanResponse(session, 
                       result$message, 
                       scans_reg_fullJoinData)
      stopWait(session)
    }
  })
  
  # output$scanDataTable = DT::renderDataTable({ 
  #   examScanEvaluationValues()$scanData[,c(6, c(1:as.numeric(examScanEvaluationValues()$scanData$Type))+6)] 
  # })

  # evaluationFiles = reactiveVal()
  #
  # examEvaluation = eventReactive(input$evaluateExam, {
  #   startWait(session)
  #   
  #   preparedEvaluation = prepareEvaluation(isolate(input$evaluateExam), isolate(input$rotateScans), isolate(input))
  # 
  #   x = callr::r_bg(
  #     func = evaluateExam,
  #     args = list(preparedEvaluation, collectWarnings),
  #     supervise = TRUE
  #   )
  # 
  #   return(x)
  # })
  # 
  # observe({
  #   if (examEvaluation()$is_alive()) {
  #     invalidateLater(millis = 100, session = session)
  #   } else {
  #     result = examEvaluation()$get_result()
  #     evaluationFiles(c(result$examName, unlist(result$files, recursive = TRUE)))
  #     examEvaluationResponse(session, result$message, length(evaluationFiles()) > 0)
  #     stopWait(session)
  #   }
  # })
  # 
  # output$downloadEvaluationFiles = downloadHandler(
  #   filename = paste0(gsub("exam", "evaluation", evaluationFiles()[1]), ".zip"),
  #   content = function(fname) {
  #     zip(zipfile=fname, files=isolate(evaluationFiles()[-1]), flags='-r9Xj')
  #   },
  #   contentType = "application/zip"
  # )
}

# RUN APP -----------------------------------------------------------------
shinyApp(ui, server)