# developed in r version 4.2.2

#TODO: some connections are not properly closed and warnings can be thrown in R: "Warnung in list(...) ungenutzte Verbindung 4 () geschlossen"

#TODO: opening the dashboard, loading tasks, deleting all of them and refreshing the pages causes the app to break and throw a warning in R: "Warnung: Error in if: Fehlender Wert, wo TRUE/FALSE nötig ist"

#TODO: expand edit functions: allow to add / remove choices

#TODO: after each edit to a task, check if it is valid for an exam (e.g. minimum of 5 answers)

#TODO: add "save" / "download" button to task list header and to each task view (not the task list item)

#TODO: switch from temp folder to downloadable files (zip) files. relevant for tasks, exams, ...

#TODO: to "scramble" simple tasks, one has to provide enough choices for there to be enough to cause sufficient variation: 
# its probably would be best to show all these answers in the task viewer and make
# such tasks independent of seeds (at least for the viewer). otherweise, creating and 
# editing such tasks gets messy. however, to be still able to use them in an exam, these 
# tasks somehow need to be modified, such that when an exam is created, seeds and scramblings 
# do matter again. tl;dr; show all choices in taks viewer for simple task. when creating an exam, 
# for simple tasks, sample 5 choices out of all choices based on the exam seed. 
# it might be necessary to restructure the source file (*.rnw) of such simple tasks in the 
# background to achieve all of this.

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

# FUNCTIONS ----------------------------------------------------------------
parseExercise = function(task, seed, output, session) {
  out <- tryCatch({
    startWait(session)
    session$sendCustomMessage("setTaskId", task$taskID)
    
    file = tempfile(fileext = ".Rnw") # tempfile name
    writeLines(text = task$taskCode, con = file) # write contents to file
    
    htmlTask = exams2html(file, dir = tempdir(), seed = if(is.na(seed)) NULL else seed)

    examHistory = c() 
    authoredBy = c()
    checkedBy = c()
    tags = c()
    type = c()
    question = c()
    
    if(length(htmlTask$exam1$exercise1$metainfo$examHistory) > 0) {
      examHistory = trimws(strsplit(htmlTask$exam1$exercise1$metainfo$examHistory, ",")[[1]], "both")
      examHistory = rjs_vectorToJsonStringArray(examHistory)
    }
    
    if(length(htmlTask$exam1$exercise1$metainfo$authoredBy) > 0) {
      authoredBy = trimws(strsplit(htmlTask$exam1$exercise1$metainfo$authoredBy, ",")[[1]], "both") 
      authoredBy = rjs_vectorToJsonStringArray(authoredBy) 
    }
      
    if(length(htmlTask$exam1$exercise1$metainfo$checkedBy) > 0) { 
      checkedBy = trimws(strsplit(htmlTask$exam1$exercise1$metainfo$checkedBy, ",")[[1]], "both")
      checkedBy = rjs_vectorToJsonStringArray(checkedBy)
    }
      
    if(length(htmlTask$exam1$exercise1$metainfo$tags) > 0) { 
      tags = trimws(strsplit(htmlTask$exam1$exercise1$metainfo$tags, ",")[[1]], "both")
      tags = rjs_vectorToJsonStringArray(tags)
    }
    
    precision = htmlTask$exam1$exercise1$metainfo$precision
    difficulty = htmlTask$exam1$exercise1$metainfo$difficulty  
    points = htmlTask$exam1$exercise1$points
    topic = htmlTask$exam1$exercise1$metainfo$topic
    type = htmlTask$exam1$exercise1$metainfo$type
    question = htmlTask$exam1$exercise1$question
    editable = ifelse(htmlTask$exam1$exercise1$metainfo$editable == 1, 1, 0)
    
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
      session$sendCustomMessage("setTaskChoices", rjs_vectorToJsonStringArray(htmlTask$exam1$exercise1$questionlist))
      session$sendCustomMessage("setTaskResultMchoice", rjs_vectorToJsonArray(tolower(as.character(htmlTask$exam1$exercise1$metainfo$solution))))
    } 
    
    if(type == "num") {
      session$sendCustomMessage("setTaskResultNumeric", result)
    }

    unlink(file)
    
    session$sendCustomMessage("setTaskE", rjs_keyValuePairsToJsonObject(c("key", "value"), c("Success", "")))
    return(NULL)
  },
  error = function(e){
    message = e$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "", message)

    session$sendCustomMessage("setTaskE", rjs_keyValuePairsToJsonObject(c("key", "value"), c("Error", message)))
    return(NA)
  },
  warning = function(w){ 
    message = w$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "",message)

    session$sendCustomMessage("setTaskE", rjs_keyValuePairsToJsonObject(c("key", "value"), c("Warning", message)))
    return(NULL)
  },
  finally = {
    session$sendCustomMessage("setTaskId", -1)
    stopWait(session)
  })
  
  return(out)
}

parseExam = function(exam, seed, input, output, session) {
  out <- tryCatch({
    startWait(session)
    
    for(examId in 1:exam$numberOfExams){
      examSeed = as.numeric(paste0(if(is.na(exam$examSeed)) NULL else exam$examSeed, examId))
      set.seed(examSeed)
      
      blocks = as.numeric(exam$blocks)
      numberOfTasks = as.numeric(exam$numberOfTasks)

      tasksPerBlock = numberOfTasks / length(unique(blocks))
      taskBlocks = lapply(unique(exam$blocks), function(x) exam$tasks[exam$blocks==x])
      
      tasks = Reduce(c, lapply(taskBlocks, sample, tasksPerBlock))

      tasks = lapply(tasks, function(i){
        file = tempfile(fileext = ".rnw") # tempfile name
        writeLines(text = i, con = file) # write contents to file
        print(i)

        return(file)
      })
      
      tasks = sample(tasks, numberOfTasks)
      seedList = rep(examSeed, length(tasks))
      
      additionalPDF = lapply(exam$additionalPDF, function(i){
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
      if(length(additionalPDF) > 0) pages = additionalPDF
      if(is.na(input$numberOfFixedPoints)) points = input$numberOfFixedPoints
      
      #debug prints
      print(input$examTitle)
      print(input$examCourse)
      print(input$examInstitution)
      print(input$examDate)
      print(input$numberOfBlanks)
      print(additionalPDF) # only works with one pdf file?
      print(input$numberOfFixedPoints)
      print(input$showPoints)
      
      nopsExam = exams2nops(tasks,
                            name = paste0(examSeed, "_"),
                            dir = tempdir(),
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

      lapply(tasks, unlink)  
      lapply(additionalPDF, unlink)  
    }

    examParseResponse(list(key="Success", value=""))
    session$sendCustomMessage("examParseResponse", rjs_keyValuePairsToJsonObject(c("key", "value"), c("Success", "")))
    return(NULL)
  },
  error = function(e){
    print(e)
    message = e$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "", message)

    examParseResponse(list(key="Error", value=message))
    session$sendCustomMessage("examParseResponse", rjs_keyValuePairsToJsonObject(c("key", "value"), c("Error", message)))
    return(NA)
  },
  warning = function(w){
    print(w)
    message = w$message
    message = gsub("\"", "'", message)
    message = gsub("[\r\n]", "",message)

    examParseResponse(list(key="Warning", value=message))
    session$sendCustomMessage("examParseResponse", rjs_keyValuePairsToJsonObject(c("key", "value"), c("Warning", message)))
    return(NULL)
  },
  finally = {
    print(tempfile())
    stopWait(session)
  })
  
  return(out)
}

examParseResponse = function(message){
  showModal(modalDialog(
    title = "exams2nops",
    tags$span(id = 'responseMessage', class=message$key, paste0(message$key, ": ", message$value)),
    easyClose = TRUE
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
    print("wrong format")
    return(0)
  } 
  
  if(numberOfExamTasks < 0) {
    print("< 0")
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
  observeEvent(input$parseExercise, {
    parseExercise(input$parseExercise, input$seedValue, output, session)
  })
  
  # parse exam
  observeEvent(input$parseExam, {
    parseExam(input$parseExam, input$seedValue, input, output, session)
  })
  
  # set max number of exam tasks
  observeEvent(input$setNumberOfExamTasks, {
    maxNumberOfExamTasks <<- input$setNumberOfExamTasks
  })
  
  # set number of task blocks
  observeEvent(input$setNumberOfTaskBlocks, {
    numberOfTaskBlocks <<- input$setNumberOfTaskBlocks
  })
}

# RUN APP -----------------------------------------------------------------
shinyApp(ui, server)