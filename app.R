# developed in r version 4.2.2

#TODO: some connections are not properly closed and warnings can be thrown in R: "Warnung in list(...) ungenutzte Verbindung 4 () geschlossen"; maybe this happens when tasks with errors are sent to the backend to be parsed

#TODO: unlink all files properly and at the right time (f.e. unlik all exam files after download)

#TODO: allow to turn off hotkeys and have a hot key modal to show what does what

#TODO: "export" buttons downloads all tasks as zip

#TODO: exam fields - validation

#TODO: exam fields - expand on aids to fill form  

#TODO: only mchoice for nops exam (what about open text questions)

#TODO: disable nav and keys on "wait"

#TODO: put parsing of exercises and exam into background tasks such that the heartbeat keeps on working (parsing exercises works alread)

#TODO: task files need explicit namespaces for function calls (f.e. exams::answerlist or iuftools::eform)

#TODO: parsing multiple tasks sequentially does not work with new background task (only last exercise is parsed)

#TODO: sometimes task names do not match the contents of the task (javascript issue, probably fixed by putting the task counter after the await for the file contents)

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
library(openssl) # ?
library(iuftools) #iuftools_1.0.0
library(future) # ?

# FUNCTIONS ----------------------------------------------------------------
parseExercise = function(task, seed){
  out <- tryCatch({
    # show all possible choices in view mode
    task$taskCode = gsub("maxChoices = 5", "maxChoices = NULL", task$taskCode)
  
    seed = if(is.na(seed)) NULL else seed
    file = tempfile(fileext = ".Rnw")
    writeLines(text = task$taskCode, con = file)
    
    htmlTask = exams::exams2html(file, dir = tempdir(), seed = seed)
    Sys.sleep(10)

    return(list(id=task$taskID, seed=seed, html=htmlTask, e=c("Success", "")))
  },
  error = function(e){
    message = e$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "", message)
    
    return(list(id=task$taskID, seed=NULL, html=NULL, e=c("Error", message)))
  },
  warning = function(w){ 
    message = w$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "",message)

    return(list(id=task$taskID, seed=NULL, html=NULL, e=c("Warning", message)))
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

parseExam = function(exam, seed, input, session) {
  out <- tryCatch({
    startWait(session)
    
    examPdfFiles = c()
    examRdsFiles = c()
    taskFiles = c()
    additionalPdfFiles = c()
    
    for(examId in 1:exam$numberOfExams){
      examSeed = as.numeric(paste0(if(is.na(exam$examSeed)) NULL else exam$examSeed, examId))
      set.seed(examSeed)

      blocks = as.numeric(exam$blocks)
      numberOfTasks = as.numeric(exam$numberOfTasks)

      tasksPerBlock = numberOfTasks / length(unique(blocks))
      taskBlocks = lapply(unique(exam$blocks), function(x) exam$tasks[exam$blocks==x])

      tasks = Reduce(c, lapply(taskBlocks, sample, tasksPerBlock))

      tasks = getTaskFiles(tasks) 
      taskFiles = unlist(tasks)
      
      tasks = sample(tasks, numberOfTasks)
      seedList = rep(examSeed, length(tasks))
      name = paste0(examSeed, "_")
      dir = tempdir()

      additionalPdf = lapply(exam$additionalPdf, function(i){
        file = tempfile(fileext = ".pdf") # tempfile name
        raw = openssl::base64_decode(i)
        writeBin(raw, con = file)

        return(file)
      })

      title = input$examTitle
      course = input$examCourse
      institution = input$examInstitution
      blank = input$numberOfBlanks
      showpoints = input$showPoints

      date = Sys.Date()
      pages = NULL
      points = NULL

      if(length(input$examDate) == 1) date = input$examDate
      if(length(additionalPdf) > 0) {
        pages = additionalPdf
        additionalPdfFiles = c(additionalPdfFiles, additionalPdf)
      } 
      if(is.na(input$numberOfFixedPoints)) points = input$numberOfFixedPoints

      nopsExam = exams2nops(tasks,
                            name = name,
                            dir = dir,
                            seed = seedList,
                            #language = language, # disabled for now
                            #duplex = duplex, # disabled for now
                            title = title,
                            course = course,
                            institution = institution,
                            date = date,
                            blank = blank,
                            pages = pages,
                            points = points,
                            showpoints = showpoints
                            )

      examPdfFiles = c(examPdfFiles, paste0(dir, "/", name, "1.pdf"))
      examRdsFiles = c(examRdsFiles, paste0(dir, "/", name, ".rds"))
    }
    
    return(list(message=list(key="Success", value=""), files=list(examPdfFiles=examPdfFiles, examRdsFiles=examRdsFiles, taskFiles=taskFiles, additionalPdfFiles=additionalPdfFiles)))
  },
  error = function(e){
    message = e$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "", message)

    return(list(message=list(key="Error", value=message), files=list()))
  },
  warning = function(w){
    message = w$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "",message)

    return(list(message=list(key="Warning", value=message), files=list()))
  },
  finally = {
    stopWait(session)
  })
  
  return(out)
}

getTaskFiles = function(tasks) {
  out <- tryCatch({

    tasks = lapply(tasks, function(i){
      file = tempfile(fileext = ".rnw") # tempfile name
      writeLines(text = i, con = file) # write contents to file
      
      return(file)
    })
    
    return(tasks)
  },
  error = function(e){
    return(NULL)
  },
  warning = function(w){
    return(NULL)
  },
  finally = {
  })
  
  return(out)
}

examParseResponse = function(session, message, success){
  showModal(modalDialog(
    title = "exams2nops",
    tags$span(id='responseMessage', class=message$key, paste0(message$key, ": ", message$value)),
    downloadButton('downloadExamFiles', 'Download')
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
plan(multisession)
# options(future.rng.onMisue = "ignore")
# future.seed = NULL

exerciseParseBgTask = list()

seedMin = 1
seedMax = 99999999
initSeed = as.numeric(gsub("-", "", Sys.Date()))
numberOfTaskBlocks = 1
maxNumberOfExamTasks = 0
assign("MAKEBSP", F, envir = .GlobalEnv)
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
  textOutput("SilenceIsGolden"),
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
      print("heartbeat")
    }
    initialState <<- FALSE
  })
  
  # seed change
  observeEvent(input$seedValue, {
    updateNumericInput(session, "seedValue", value = checkSeed(input$seedValue))
  })
  
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
  exerciseParsing <- eventReactive(input$parseExercise, {
    x <- callr::r_bg(
      func = parseExercise,
      args = list(input$parseExercise, input$seedValue),
      supervise = TRUE
    )

    # x$wait() #makes it a sync task again - not what we want
    # somehow work with lists?

    return(x)
  })

  checkExerciseParsed <- reactive({
    if (exerciseParsing()$is_alive()) {
      startWait(session)
      invalidateLater(millis = 100, session = session)
    } else {
      task = exerciseParsing()$get_result()
      loadExercise(task$id, task$seed, task$html, task$e, session)
      stopWait(session)
    }

    return("")
  })

  output$SilenceIsGolden <- renderText({
    checkExerciseParsed()
  })
  
  # parse exam
  examFiles = reactiveVal()
  
  observeEvent(input$parseExam, {
    response = parseExam(input$parseExam, input$seedValue, input, session)
    examFiles(unlist(response$files))
    examParseResponse(session, response$message, length(response$files) > 0)

    session$sendCustomMessage("debugMessage", unlist(response$files)) #debug
  })
  
  observeEvent(input$setNumberOfExamTasks, {
    maxNumberOfExamTasks <<- input$setNumberOfExamTasks
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
  output$downloadExamFiles <- downloadHandler(
    filename = paste0("exam_", isolate(input$seedValue), ".zip"),
    content = function(fname) {
      zip(zipfile=fname, files=isolate(examFiles()), flags='-r9Xj')
    },
    contentType = "application/zip"
  )
}

# RUN APP -----------------------------------------------------------------
shinyApp(ui, server)