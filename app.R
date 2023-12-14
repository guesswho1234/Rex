# developed in r version 4.2.2

#TODO: some connections are not properly closed and warnings can be thrown in R: "Warnung in list(...) ungenutzte Verbindung 4 () geschlossen"; maybe this happens when tasks with errors are sent to the backend to be parsed

#TODO: unlink all files properly and at the right time (f.e. unlik all exam files after download) -> on.exit(unlink(...)) right after creation of tempdir() or tmpfile()

#TODO: turn off hotkeys per default, allow to turn on hotkeys in nav bar and have a hot key modal to show what does what

#TODO: "export" button to download all tasks as zip (need to implement this in javascript)

#TODO: allow only mchoice questions for nops exam

#TODO: add possibility to create pdf exam with open questions (can then be appended to nops)

#TODO: disable nav and keys on "wait"

#TODO: parsing multiple tasks sequentially does not work properly with new background processing (only last exercise is parsed)

#TODO: change all iuf tasks by adding "library(exams)" and "library(iuftools)" and replacing "if(MAKEBSP) set.seed(1)" to "if(exists(MAKEBSP) && MAKEBSP) set.seed(1)"

#TODO: check if tasks can be "reproduced exactly" with exam seed as task seed

#TODO: refactor javascript code (f.e. combine the three drag and drop setups to one)

#TODO: click between text / icon toggle removes all button info (remove this effect)

#TODO: fix csv file (registeredParticipants) since it has empty rows after each text row after importing

#TODO: field validation and helpers to fill in forms

# STARTUP -----------------------------------------------------------------
rm(list = ls())
cat("\f")
gc()

# PACKAGES ----------------------------------------------------------------
library(shiny) # shiny_1.4.0
library(shinyjs) # shinyjs_2.1.0
library(shinyWidgets) # shinyWidgets_0.5.1
library(shinycssloaders) #shinycssloaders_0.3
library(exams) #exams_2.4
library(xtable) #xtable_1.8
library(iuftools) #iuftools_1.0.0
library(callr) # callr_3.7.3
library(pdftools) # pdftools_3.4.0

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
    checkedBy = c()
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
    
    if(length(html$exam1$exercise1$metainfo$checkedBy) > 0) { 
      checkedBy = trimws(strsplit(html$exam1$exercise1$metainfo$checkedBy, ",")[[1]], "both")
      checkedBy = rjs_vectorToJsonStringArray(checkedBy)
    }
    
    if(length(html$exam1$exercise1$metainfo$tags) > 0) { 
      tags = trimws(strsplit(html$exam1$exercise1$metainfo$tags, ",")[[1]], "both")
      tags = rjs_vectorToJsonStringArray(tags)
    }
    
    precision = html$exam1$exercise1$metainfo$precision
    difficulty = html$exam1$exercise1$metainfo$difficulty  
    points = html$exam1$exercise1$points
    topic = html$exam1$exercise1$metainfo$topic
    type = html$exam1$exercise1$metainfo$type
    question = html$exam1$exercise1$question
    editable = ifelse(html$exam1$exercise1$metainfo$editable == 1, 1, 0)
    
    session$sendCustomMessage("setTaskExamHistory", examHistory)
    session$sendCustomMessage("setTaskAuthoredBy", authoredBy)
    session$sendCustomMessage("setTaskCheckedBy", checkedBy)
    session$sendCustomMessage("setTaskPrecision", precision)
    session$sendCustomMessage("setTaskDifficulty", difficulty)
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
  
  examPdfFiles = paste0(dir, "/", name, 1:exam$numberOfExams, ".pdf")
  examRdsFile = paste0(dir, "/", name, ".rds")
  
  return(list(examFields=examFields, examFiles=list(pdfFiles=examPdfFiles, rdsFile=examRdsFile), sourceFiles=list(taskFiles=taskFiles, additionalPdfFiles=additionalPdfFiles)))
}

createExam = function(preparedExam, collectWarnings) {
  out = tryCatch({
    warnings = collectWarnings({
        with(preparedExam$examFields, {
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
    tags$span(id='responseMessage', class=message$key, paste0(message$key, ": ", gsub("%;%", "<br>", message$value))),
    footer = tagList(
      if (downloadable)
        downloadButton('downloadExamFiles', 'Download'),
      modalButton("OK")
    )
  ))
}

prepareEvaluation = function(evaluation){
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
    
    return(file)
  })
  
  convertedPngFiles = unlist(lapply(seq_along(pdfFiles), function(i){
    filenames = tempfile(pattern = paste0(names(pdfFiles)[i], "_"), tmpdir = dir, fileext = ".png")
    pdftools::pdf_convert(pdf=pdfFiles[[i]], filenames=filenames, pages=1:1, format='png')
  }))
  
  scanFiles = c(pngFiles, convertedPngFiles)
  
  return(list(dir=dir, examName=evaluation$examSolutionsName[[1]], files=list(solution=solutionFile, registeredParticipants=registeredParticipantsFile, scans=scanFiles)))
}

evaluateExam = function(preparedEvaluation, collectWarnings){
  out = tryCatch({
    nops_scan_fileName = paste0(preparedEvaluation$examName, "_nops_scan", ".zip")
    nops_scan_file = paste0(preparedEvaluation$dir, "/", nops_scan_fileName)
    nops_evaluation_fileNamePrefix = paste0(preparedEvaluation$examName, "_nops_eval")
    nops_evaluation_files = paste0("evaluation", seq_along(preparedEvaluation$files$scans), ".html")
    nops_evaluation_fileNames = paste0("evaluation", seq_along(preparedEvaluation$files$scans), ".html")
    nops_evaluationCsv = paste0(preparedEvaluation$dir, "/", nops_evaluation_fileNamePrefix, ".csv")
    nops_evaluationZip = paste0(preparedEvaluation$dir, "/", nops_evaluation_fileNamePrefix, ".zip")
    
    warnings = collectWarnings({
      with(preparedEvaluation, {
        exams::nops_scan(images=files$scans,
                         dir=dir,
                         file=nops_scan_fileName,
                         rotate=FALSE)
        
        exams::nops_eval(
          register = files$registeredParticipants,
          solutions = files$solution,
          scans = nops_scan_file,
          # eval = exams_eval(partial = partial, negative = negative, rule = "false2"),
          # points = points,
          # mark = mark,
          # labels = labels,
          results = nops_evaluation_fileNamePrefix,
          dir = dir,
          file = nops_evaluation_fileNames
          # interactive = FALSE
        )
      })
      
      NULL
    })
    key = "Success"
    value = paste(unlist(warnings), collapse="%;%")
    if(value != "") key = "Warning"

    return(list(message=list(key=key, value=value), 
                examName=preparedEvaluation$examName, 
                files=list(sourceFiles=preparedEvaluation$files, 
                           scanFiles=nops_scan_file, 
                           evaluationFiles=list(summary=nops_evaluationCsv, 
                                                individualExams=nops_evaluationZip))))
  },
  error = function(e){
    message = e$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "%;%", message)
    
    return(list(message=list(key="Error", value=message), examName=NULL, files=list()))
  })
  
  return(out)
}

examEvaluationResponse = function(session, message, downloadable) {
  showModal(modalDialog(
    title = "nops_scan & nops_eval",
    tags$span(id='responseMessage', class=message$key, paste0(message$key, ": ", gsub("%;%", "<br>", message$value))),
    footer = tagList(
      if (downloadable)
        downloadButton('downloadEvaluationFiles', 'Download'),
      modalButton("OK")
    )
  ))
}

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
seedMax = 99999999
initSeed = as.numeric(gsub("-", "", Sys.Date()))
numberOfTaskBlocks = 1
maxNumberOfExamTasks = 0
MAKEBSP = FALSE
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

# UI -----------------------------------------------------------------
ui = fluidPage(
  shinyjs::useShinyjs(),
  textOutput("debug"),
  htmlTemplate(
    filename = "main.html",

    # TASKS -------------------------------------------------------------------
    numericInput_seedValue = numericInput("seedValue", label = NULL, value = initSeed, min = seedMin, max = seedMax),

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
      numericInput_pointsPerExercise = numericInput("pointsPerExercise", label = NULL, value = NULL, min = 1, step = 1),
      checkboxInput_partialPoints = checkboxInput("partialPoints", label = NULL, value = NULL),
      checkboxInput_negativePoints = checkboxInput("negativePoints", label = NULL, value = NULL),
      selectInput_evaluationLanguage = selectInput("selectInput_evaluationLanguage", label = NULL, choices = languages, selected = NULL, multiple = FALSE)
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
  evaluationFiles = reactiveVal()

    examEvaluation = eventReactive(input$evaluateExam, {
    startWait(session)

    preparedEvaluation = prepareEvaluation(isolate(input$evaluateExam))

    x = callr::r_bg(
      func = evaluateExam,
      args = list(preparedEvaluation, collectWarnings),
      supervise = TRUE
    )

    return(x)
  })

  observe({
    if (examEvaluation()$is_alive()) {
      invalidateLater(millis = 100, session = session)
    } else {
      result = examEvaluation()$get_result()
      evaluationFiles(c(result$examName, unlist(result$files, recursive = TRUE)))
      examEvaluationResponse(session, result$message, length(evaluationFiles()) > 0)
      stopWait(session)
    }
  })
  
  output$downloadEvaluationFiles = downloadHandler(
    filename = paste0(gsub("exam", "evaluation", evaluationFiles()[1]), ".zip"),
    content = function(fname) {
      zip(zipfile=fname, files=isolate(evaluationFiles()[-1]), flags='-r9Xj')
    },
    contentType = "application/zip"
  )
}

# RUN APP -----------------------------------------------------------------
shinyApp(ui, server)