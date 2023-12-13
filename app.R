# developed in r version 4.2.2

#TODO: some connections are not properly closed and warnings can be thrown in R: "Warnung in list(...) ungenutzte Verbindung 4 () geschlossen"; maybe this happens when tasks with errors are sent to the backend to be parsed

#TODO: unlink all files properly and at the right time (f.e. unlik all exam files after download)

#TODO: turn off hotkeys per default, allow to turn on hotkeys in nav bar and have a hot key modal to show what does what

#TODO: "export" button to download all tasks as zip (need to implement this in javascript)

#TODO: exam fields - expand on validation and helpers to fill in the form

#TODO: allow only mchoice questions for nops exam

#TODO: add possibility to create pdf exam with open questions (can then be appended to nops)

#TODO: disable nav and keys on "wait"

#TODO: parsing multiple tasks sequentially does not work properly with new background processing (only last exercise is parsed)

#TODO: change all iuf tasks by adding "library(exams)" and "library(iuftools)" and replacing "if(MAKEBSP) set.seed(1)" to "if(exists(MAKEBSP) && MAKEBSP) set.seed(1)"

#TODO: check if tasks can be "reproduced exactly" with exam seed as task seed

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
    file = tempfile(pattern = paste0(exam$taskNames[[i]], "_"), tmpdir = dir, fileext = ".rnw") # tempfile name
    writeLines(text = exam$taskCodes[[i]], con = file) # write contents to file
    
    return(file)
  }))
  
  additionalPdfFiles = unlist(lapply(setNames(seq_along(exam$additionalPdfNames), exam$additionalPdfNames), function(i){
    file = tempfile(pattern = paste0(exam$additionalPdfNames[[i]], "_"), tmpdir = dir, fileext = ".pdf") # tempfile name
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
  
  print(input$examLanguage)
  print(input$duplex)

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

parseExam = function(preparedExam, collectWarnings) {
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

examParseResponse = function(session, message, downloadable) {
  showModal(modalDialog(
    title = "exams2nops",
    tags$span(id='responseMessage', class=message$key, paste0(message$key, ": ", gsub("%;%", "<br>", message$value))),
    footer = tagList(
      if (downloadable)
        downloadButton('downloadExamFiles', 'Download'),
      modalButton("OK")
    )
  ))
  
  session$sendCustomMessage("examParseResponse", rjs_keyValuePairsToJsonObject(c("key", "value"), c(message$key, message$value)))
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
  # textOutput("debug"),
  htmlTemplate(
    filename = "main.html",

    # TASKS -------------------------------------------------------------------
    numericInput_seedValue = numericInput("seedValue", label = NULL, value = initSeed, min = seedMin, max = seedMax),

    # EXAM --------------------------------------------------------------------
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
    checkboxInput_duplex = checkboxInput("duplex", label = NULL, value = NULL)
  )
)

# SERVER -----------------------------------------------------------------
server = function(input, output, session) {
  # heartbeat
  initialState = TRUE

  # heartbeat
  observe({
    invalidateLater(1000 * 5, session)
    if(!initialState) {
      session$sendCustomMessage("heartbeat", 1)
    }
    initialState <<- FALSE
  })
  
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
  
  # parse exercise
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
      invalidateLater(millis = 100, session = session)
    } else {
      result = exerciseParsing()$get_result()
      loadExercise(result$id, result$seed, result$html, result$e, session)
      stopWait(session)
    }
  })

  # parse exam
  examFiles = reactiveVal()
  
  examParsing = eventReactive(input$parseExam, {
    startWait(session)

    preparedExam = prepareExam(isolate(input$parseExam), isolate(input$seedValue), isolate(input))

    x = callr::r_bg(
      func = parseExam,
      args = list(preparedExam, collectWarnings),
      supervise = TRUE
    )

    return(x)
  })

  observe({
    if (examParsing()$is_alive()) {
      invalidateLater(millis = 100, session = session)
    } else {
      result = examParsing()$get_result()
      examFiles(unlist(result$files, recursive = TRUE))
      examParseResponse(session, result$message, length(examFiles()) > 0)
      stopWait(session)
    }
  })
  
  # set max number of exam tasks
  observeEvent(input$setNumberOfExamTasks, {
    maxNumberOfExamTasks <<- input$setNumberOfExamTasks
  })
  
  # set number of task blocks
  observeEvent(input$setNumberOfTaskBlocks, {
    numberOfTaskBlocks <<- input$setNumberOfTaskBlocks
  })
  
  # download exam files
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
}

# RUN APP -----------------------------------------------------------------
shinyApp(ui, server)