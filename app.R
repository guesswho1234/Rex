# developed in r version 4.2.2

# STARTUP -----------------------------------------------------------------
rm(list = ls())
cat("\f")
gc()

# DOCKER_WORKER ------------------------------------------------------------------
DOCKER_WORKER = !file.exists("./worker.R")

# PACKAGES ----------------------------------------------------------------
library(shiny) # shiny_1.8.0
library(shinyjs) # shinyjs_2.1.0
library(shinyWidgets) # shinyWidgets_0.8.0
library(shinycssloaders) #shinycssloaders_1.0.0
library(shinyauthr) # shinyauthr_1.0.0
library(sodium) # sodium_1.3.1
library(RSQLite) # RSQLite_2.3.6
library(DBI) # DBI_1.2.3

# CONNECTION --------------------------------------------------------------
options(shiny.host = "0.0.0.0")
options(shiny.port = 3838)

# RESOURCES ---------------------------------------------------------------
shiny::addResourcePath("www", "./www")

# SOURCE ------------------------------------------------------------------
source("./source/main/filesAndDirectories.R")
source("./source/main/customElements.R")
source("./source/shared/rToJson.R")
source("./source/shared/log.R")
source("./source/shared/aWrite.R")
source("./source/main/appStatus.R")
source("./source/main/database.R")
source("./source/main/permission.R")
source("./source/main/processingResponses.R")
source("./source/main/progressMonitoring.R")

if(!DOCKER_WORKER)
  source("./worker.R")  

# FUNCTIONS ----------------------------------------------------------------
  prepareExerciseDownloadFiles = function(session, exercises){
    dir = getDir(session)
    
    exercises$exerciseNames = as.list(make.unique(unlist(exercises$exerciseNames), sep="_"))
    
    exerciseFiles = unlist(lapply(setNames(seq_along(exercises$exerciseNames), exercises$exerciseNames), function(i){
      file = paste0(dir, "/", exercises$exerciseNames[[i]], ".", exercises$exerciseExts[[i]])
      writeLines(text=gsub("\r\n", "\n", exercises$exerciseCodes[[i]]), con=file)
  
      return(file)
    }))
    
    return(list(exerciseFiles=exerciseFiles))
  }

# PARAMETERS --------------------------------------------------------------
  # REXAMS ------------------------------------------------------------------
  cores = NULL
  if (Sys.info()["sysname"] == "Linux")
    cores = parallel::detectCores()

  edirName = "exercises"
  maxChoices = 5
  exerciseMin = 1
  exerciseMax = 45
  seedMin = 1
  seedMax = 999999999 #xxxxsssee x = random number, s = scrambling id, e = exercise id
  initSeed = 1
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
  rules = list("1/nwrong"="false", "1/max(nwrong, 2)"="false2", "1/ncorrect"="true", "1"="all", "0"="none")

  # USER --------------------------------------------------------------------
  USERNAME = ""
  
  # ADDONS ------------------------------------------------------------------
  addons_path = "./addons/"
  addons_path_www = "./www/addons/"
  addons = list.files(addons_path_www, recursive = FALSE)

  invisible(lapply(addons, \(addon) {
    file = paste0(addons_path_www, addon, "/main/", addon, "_main.R")
    
    if(file.exists(file))
      source(file)
  }))
    
# LOG ------------------------------------------------------
log_(content="INIT", append=FALSE)

# UI -----------------------------------------------------------------
ui = htmlTemplate(
  filename = "index.html"
)
  
# SERVER -----------------------------------------------------------------
server = function(input, output, session) {
  # AUTH --------------------------------------------------------------------
  credentials = Myloginserver(
    id = "login",
    id_col = "id",
    pw_col = "pw",
    table = "user",
    log_out = reactive(logout_init()),
    reload_on_logout = TRUE,
	  sodium_hashed = TRUE
  )
  
  # Logout to hide
  logout_init = shinyauthr::logoutServer(
    id = "logout",
    active = reactive(credentials()$user_auth)
  )

  eventReactive
  output$rexApp = renderUI({
    req(credentials()$user_auth)
    USERNAME <<- credentials()$info[1]
 
    log_(content="Successful login.", USERNAME, sessionToken=session$token)

    # STARTUP -------------------------------------------------------------
    unlink(getDir(session), recursive = TRUE)
    dir.create(getDir(session))
    removeRuntimeFiles(session)

    initSeed <<- floor(runif(1, min=1000, max=9999))

    # LOAD APP ----------------------------------------------------------------
    fluidPage(
     htmlTemplate(
      filename = "app.html",
      
      # PROFILE MANAGER
      userProfileButton = myUserProfileButton(),
      userProfileInterface = myUserProfileInterface(),
      userLogoutButton = myUserLogoutButton(),

      # EXERCISES
      textInput_seedValueExercises = textInput("seedValueExercises", label = NULL, value = initSeed),
      button_downloadExercises = myDownloadButton(id='downloadExercises', deText="Alle speichern", enText="Save all"),
      button_downloadExercise = myDownloadButton(id='downloadExercise'),
      exerciseFigureFileImport = myFileImport("exerciseFigure", "exerciseFigure"),
    
      # EXAM CREATE
      dateInput_examDate = dateInput("examDate", label = NULL, value = NULL, format = "yyyy-mm-dd"),
      textInput_seedValueExam = textInput("seedValueExam", label = NULL, value = initSeed),
      textInput_numberOfExams = textInput("numberOfExams", label = NULL, value = 1),
      textInput_numberOfExercises = textInput("numberOfExercises", label = NULL, value = 0),
      checkboxInput_fixSequence = checkboxInput("fixSequence", label = NULL, value = FALSE),
      textInput_fixedPointsExamCreate = textInput("fixedPointsExamCreate", label = NULL, value = NULL),
      selectInput_examRegLength = selectInput("examRegLength", label = NULL, choices = 1:10, selected = 8, multiple = FALSE),
      checkboxInput_showPoints = checkboxInput("showPoints", label = NULL, value = TRUE),
      checkboxInput_duplex = checkboxInput("duplex", label = NULL, value = TRUE),
      checkboxInput_replacement = checkboxInput("replacement", label = NULL, value = NULL),
      checkboxInput_samepage = checkboxInput("samepage", label = NULL, value = TRUE),
      checkboxInput_newpage = checkboxInput("newpage", label = NULL, value = NULL),
      selectInput_examLanguage = selectInput("examLanguage", label = NULL, choices = languages, selected = "de", multiple = FALSE),
      textInput_examInstitution = textInput("examInstitution", label = NULL, value = NULL),
      textInput_examTitle = textInput("examTitle", label = NULL, value = NULL),
      textInput_examCourse = textInput("examCourse", label = NULL, value = NULL),
      textInput_examIntro = textAreaInput("examIntro", label = NULL, value = NULL),
      textInput_numberOfBlanks = textInput("numberOfBlanks", label = NULL, value = 5),
      
      additionalPdfFileImport = myFileImport("additionalPdf", "additionalPdf"),
      examLogoFileImport = myFileImport("examLogo", "examLogo"),
    
      # EXAM EVALUATE
      textInput_fixedPointsExamEvaluate = textInput("fixedPointsExamEvaluate", label = NULL, value = NULL),
      selectInput_evaluateReglength = selectInput("evaluationRegLength", label = NULL, choices = 1:10, selected = 8, multiple = FALSE),
      checkboxInput_partialPoints = checkboxInput("partialPoints", label = NULL, value = TRUE),
      checkboxInput_negativePoints = checkboxInput("negativePoints", label = NULL, value = NULL),
      selectInput_rule = selectInput("rule", label = NULL, choices = rules, selected = NULL, multiple = FALSE),
      checkboxInput_mark = checkboxInput("mark", label = NULL, value = TRUE), 
      
      gradingKey = myGradingKey(5),
    
      selectInput_evaluationLanguage = selectInput("evaluationLanguage", label = NULL, choices = languages, selected = "de", multiple = FALSE),
      checkboxInput_rotateScans = checkboxInput("rotateScans", label = NULL, value = TRUE),
      
      examSolutionsFileImport = myFileImport("examSolutions", "examSolutions"),
      examRegisteredParticipantsFileImport = myFileImport("examRegisteredParticipants", "examRegisteredParticipants"),
      examScansFileImport = myFileImport("examScans", "examScans"),
      
      # ADDON CONTENT
      addonSidebarListItems = lapply(addons, \(addon) {
        file = paste0(addons_path_www, addon, "/main/", addon, "_sidebarListItem.html")
        
        if(file.exists(file))
          htmlTemplate(filename=file)
      }),
      
      addonContentTabs = lapply(addons, \(addon) {
        file = paste0(addons_path_www, addon, "/main/", addon, "_contentTab.html")
        init = paste0(addon, "_fields")
        
        if(file.exists(file)){
          if(exists(init))
            htmlTemplate(filename=file, init=get(init))
          else
            htmlTemplate(filename=file)
        }
      })
    ),
    
    # SCRIPTS
    tags$script(src="www/script.js"),
    tags$script(src="www/rnwTemplate.js"),
    
    # ADDON SCRIPTS
    lapply(addons, \(addon) {
      file = paste0(addons_path_www, addon, "/main/", addon, "_script.js")
      
      if(file.exists(file))
        tags$script(src=file, defer=TRUE)
    }),
    
    # ADDON STYLESHEET
    lapply(addons, \(addon) {
      file = paste0(addons_path_www, addon, "/main/", addon, "_style.css")
      
      if(file.exists(file))
        tags$link(rel="stylesheet", type="text/css", href=file)
    }),
   )
  })
  
  # CLEANUP -------------------------------------------------------------
  onStop(function() {
    unlink(getDir(session), recursive = TRUE)
    log_(content="Session closed.", USERNAME, sessionToken=session$token)
  })
  
  # HEARTBEAT -------------------------------------------------------------
  initialState = TRUE
  initialStateJS = TRUE

  observe({
    invalidateLater(1000 * 5, session)
    if(!initialState) 
      session$sendCustomMessage("heartbeat", 1) # ping

    initialState <<- FALSE
  })
  
  observeEvent(input$pong, {
    cat("")
    
    if(initialStateJS){
      # SET DEFAULTS
      myFileData(session = session, path = "./www/", name = "logo_rex_bw", ext = "png", "setExamLogo")
      
      # ADDON DEFAULTS
      lapply(addons, \(addon) {
        f_defaults = paste0(addon, "_defaults")
        
        if(exists(f_defaults))
          do.call(f_defaults, args=list(session=session))
      })
    }
    
    initialStateJS <<- FALSE
  })
  
  # USER --------------------------------------------------------------------
  observeEvent(input$`profile-button`, {
    session$sendCustomMessage("setCurrentUser", credentials()$info$id)
  })
  
  observeEvent(input$`change-password-button`, {
    checkPm = checkPermission("P1000", credentials()$info$pm)
    
    if(!checkPm$hasPermission){
      session$sendCustomMessage("errorUpdateUserProfile", getNoPermissionMessage(checkPm$code, checkPm$response))
      return(NULL)
    }

    changePassword(session, credentials()$info, input$`current-login-password`, input$`new-login-password1`, input$`new-login-password2`)
  })
    
  # EXPORT SINGLE EXERCISE ------------------------------------------------------
  output$downloadExercise = downloadHandler(
    filename = function() {
      paste0(isolate(input$exerciseToDownload$exerciseName), ".", input$exerciseToDownload$exerciseExt)
    },
    content = function(fname) {
      writeLines(text=gsub("\r\n", "\n", isolate(input$exerciseToDownload$exerciseCode)), con=fname)
      removeRuntimeFiles(session)
    },
    contentType = paste0("text/", input$exerciseToDownload$exerciseExt),
  )

  # EXPORT ALL EXERCISES ------------------------------------------------------
  output$downloadExercises = downloadHandler(
    filename = "exercises.zip",
    content = function(fname) {
      result = prepareExerciseDownloadFiles(session, isolate(input$exercisesToDownload))
      exerciseFiles = unlist(result$exerciseFiles, recursive = TRUE)

      zip(zipfile=fname, files=exerciseFiles, flags='-r9Xj')
      removeRuntimeFiles(session)
    },
    contentType = "application/zip",
  )

  # PARSE EXERCISE ------------------------------------------------------
    # PARAMETERS ---------------------------------------------------------------
    parseExercise_req = paste0(getDir(session), "/parseExercise_req.rds")
    parseExercise_log = paste0(getDir(session), "/parseExercise_log.txt")
    parseExercise_res = paste0(getDir(session), "/parseExercise_res.txt")
    parseExercise_fin = paste0(getDir(session), "/parseExercise_fin.txt")
  
    parseExercise_req_content = list()
    parseExercise_logHistory = c()
    parseExerciseProgressData = list(totalExercises = NULL,
                                previousProgress = 0,
                                progress = 0)
  
    # CALL ---------------------------------------------------------------
    exerciseParsing = eventReactive(input$parseExercise, {
      checkPm = checkPermission("P1001", credentials()$info$pm)
      
      if(!checkPm$hasPermission){
        session$sendCustomMessage("removeAllExercises", 1)
        session$sendCustomMessage("errorNoPermission", getNoPermissionMessage(checkPm$code, checkPm$response, FALSE))
        return(0)
      }
      
      if(length(parseExercise_req_content) == 0) {
        session$sendCustomMessage("changeTabTitle", 3)
        startWait(session)
        initProrgress(session)
        log_(content="Parsing exercise.", USERNAME, sessionToken=session$token)
      }
      
      # write exercise file
      file = tempfile(fileext = paste0(".", input$parseExercise$exerciseExt), tmpdir = getDir(session))
      file = gsub("\\", "/", file, fixed=TRUE)
      writeChar(input$parseExercise$exerciseCode, con=file, nchars=nchar(input$parseExercise$exerciseCode), eos=NULL)
      
      # request content
      parseExercise_req_content <<- append(parseExercise_req_content, 
                                           list(list(progress=as.numeric(input$parseExercise$progress),
                                                     id=as.numeric(input$parseExercise$exerciseID), 
                                                     file=tail(strsplit(file, split="/")[[1]], 1), 
                                                     seed=as.numeric(input$seedValueExercises))))
  
      if(input$parseExercise$progress == 1) {
        parseExercise_req_content <<- append(list(dir=getDir(session)), list(exercises=parseExercise_req_content))
        
        write_atomic(parseExercise_req_content, parseExercise_req)
      }
  
      return(input$parseExercise$progress)
    })
  
    # PROCESSING ---------------------------------------------------------------
    observe({
      if(exerciseParsing() != 1)
        return(0)
      
      if (is.na(file.mtime(parseExercise_fin))) {
        invalidateLater(millis = 100, session = session)
        
        logData = processLogFile(parseExercise_log, parseExercise_logHistory)
        parseExercise_logHistory <<- logData$history
        parseExerciseProgressData <<- monitorProgressExerciseParse(session, logData$out, parseExerciseProgressData)
  
        if(!DOCKER_WORKER)
          checkWorkerRequests()
      } else {
        if(!DOCKER_WORKER)
          readOutput()
  
        logData = processLogFile(parseExercise_log, parseExercise_logHistory)
        parseExercise_logHistory <<- logData$history
        parseExerciseProgressData <<- monitorProgressExerciseParse(session, logData$out, parseExerciseProgressData)
        
        # process results
        result = readLines(parseExercise_res)
        
        items = 20
        exercises = floor(length(result) / items)
        
        messageType = c()
  
        lapply(0:(exercises - 1), \(x){
          result = setNames(as.list(result[1:items + items * x]),
                                  c("id",
                                    "messageType",
                                    "statusMessage",
                                    "statusCode",
                                    "author",
                                    "exExtra",
                                    "points",
                                    "type",
                                    "tags",
                                    "section",
                                    "seed",
                                    "question",
                                    "question_raw",
                                    "figure",
                                    "editable",
                                    "choices",
                                    "choices_raw",
                                    "solutions",
                                    "solutionNotes",
                                    "solutionNotes_raw"))

          error = grepl("E\\d{4}", result$statusCode)
          messageType <<- max(messageType, as.numeric(result$messageType))
  
          examParseResponse(session, result, error)
        })
        
        session$sendCustomMessage("changeTabTitle", as.numeric(messageType))
        
        # wrap up
        finalizeProgress(session)
        parseExercise_req_content <<- list()
        parseExercise_logHistory <<- c()
        parseExerciseProgressData <<- list(totalExercises = NULL,
                                           previousProgress = 0,
                                           progress = 0)
        stopWait(session)
        session$sendCustomMessage("changeTabTitle", "reset")
        log_(content="Exercise parsed.", USERNAME, sessionToken=session$token)
      }
    })

  # CREATE EXAM -------------------------------------------------------------
    # PARAMETERS ---------------------------------------------------------------
    createExam_req = paste0(getDir(session), "/createExam_req.rds")
    createExam_log = paste0(getDir(session), "/createExam_log.txt")
    createExam_res = paste0(getDir(session), "/createExam_res.txt")
    createExam_fin = paste0(getDir(session), "/createExam_fin.txt")
    
    createExam_req_content = list()
    createExam_logHistory = c()
    createExamProgressData = list(totalExams = NULL,
                                  previousProgress = 0,
                                  progress = 0)
    
    examFiles = reactiveVal()

    # CALL ---------------------------------------------------------------
    examCreation = eventReactive(input$createExam, {
      checkPm = checkPermission("P1002", credentials()$info$pm)
  
      if(!checkPm$hasPermission){
        session$sendCustomMessage("errorNoPermission", getNoPermissionMessage(checkPm$code, checkPm$response, FALSE))
        return(0)
      }
      
      if(length(createExam_req_content) == 0) {
        session$sendCustomMessage("changeTabTitle", 3)
        startWait(session)
        initProrgress(session)
        log_(content="Creating exam.", USERNAME, sessionToken=session$token)
      }
      
      exam = input$createExam
      dir = getDir(session)
      edir = paste0(dir, "/", edirName)
      
      # write exercise files
      exerciseFiles = c()
      if(length(exam$exerciseNames) > 0) {
        dir.create(file.path(edir), showWarnings = TRUE)
        
        exam$exerciseNames = as.list(make.unique(unlist(exam$exerciseNames), sep="_"))
        exerciseFiles = unname(unlist(lapply(setNames(seq_along(exam$exerciseNames), exam$exerciseNames), function(i){
          file = paste0(edir, "/", exam$exerciseNames[[i]], ".", exam$exerciseExts[[i]])
          writeLines(text=gsub("\r\n", "\n", exam$exerciseCodes[[i]]), con=file, sep="")
          
          return(file)
        })))
      }
      
      # write additional pdf files
      additionalPdfFiles = c()
      
      if(length(exam$additionalPdfNames) > 0) {
        exam$additionalPdfNames = as.list(make.unique(unlist(exam$additionalPdfNames), sep="_"))
        additionalPdfFiles = unname(unlist(lapply(setNames(seq_along(exam$additionalPdfNames), exam$additionalPdfNames), function(i){
          file = paste0(dir, "/", exam$additionalPdfNames[[i]], ".pdf")
          raw = openssl::base64_decode(exam$additionalPdfFiles[[i]])
          writeBin(raw, con = file)
          
          return(file)
        })))
      }
      
      # write exam logo file
      examLogoFile = c()
      
      if(length(exam$examLogoName) == 1) {
        examLogoFile = unlist(lapply(seq_along(exam$examLogoName), function(i){
          file = paste0(dir, "/", exam$examLogoName[[i]], ".png")
          raw = openssl::base64_decode(exam$examLogoFile[[i]])
          writeBin(raw, con = file)
          
          return(file)
        }))
      }

      # request content
      createExam_req_content <<- list(dir=dir,
                                      edir=edir,
                                      exerciseMin=exerciseMin,
                                      exerciseMax=exerciseMax,
                                      seedMin=seedMin,
                                      seedMax=seedMax,
                                      exerciseTypes=unlist(exam$exerciseTypes),
                                      blocks=unlist(exam$blocks),
                                      seedValueExam=as.numeric(input$seedValueExam),
                                      numberOfExercises=as.numeric(input$numberOfExercises),
                                      numberOfExams=as.numeric(input$numberOfExams),
                                      examTitle=input$examTitle,
                                      examCourse=input$examCourse,
                                      fixedPointsExamCreate=as.numeric(input$fixedPointsExamCreate),
                                      examRegLength=as.numeric(input$examRegLength),
                                      fixSequence=input$fixSequence,
                                      examLanguage=input$examLanguage,
                                      examInstitution=input$examInstitution,
                                      examDate=input$examDate,
                                      numberOfBlanks=input$numberOfBlanks,
                                      duplex=input$duplex,
                                      showPoints=input$showPoints,
                                      examIntro=input$examIntro,
                                      replacement=input$replacement,
                                      samepage=input$samepage,
                                      newpage=input$newpage,
                                      exerciseFiles=exerciseFiles,
                                      additionalPdfFiles=additionalPdfFiles,
                                      examLogoFile=examLogoFile)
      
      write_atomic(createExam_req_content, createExam_req)
  
      return(1)
    })
    
    # PROCESSING ---------------------------------------------------------------
    observe({
      if(examCreation() != 1)
        return(0)
      
      if (is.na(file.mtime(createExam_fin))) {
        invalidateLater(millis = 100, session = session)
        
        logData = processLogFile(createExam_log, createExam_logHistory)
        createExam_logHistory <<- logData$history
        createExamProgressData <<- monitorProgressExamCreate(session, logData$out, createExamProgressData)
        
        if(!DOCKER_WORKER)
          checkWorkerRequests()
      } else {
        if(!DOCKER_WORKER)
          readOutput()
        
        logData = processLogFile(createExam_log, createExam_logHistory)
        createExam_logHistory <<- logData$history
        createExamProgressData <<- monitorProgressExamCreate(session, logData$out, createExamProgressData)
        
        # process results
        result = readLines(createExam_res)
        
        messageType = unlist(result[1])
        message = unlist(result[2])
        
        if(messageType != "2"){
          examFiles(result[-c(1:2)])
        } else{
          examFiles(NULL)
        }
  
        examCreationResponse(session, messageType, message, length(isolate(examFiles())) > 0)
        
        session$sendCustomMessage("changeTabTitle", as.numeric(messageType))

        # wrap up
        finalizeProgress(session)
        createExam_req_content <<- c()
        createExam_logHistory <<- c()
        createExamProgressData <<- list(totalExams = NULL,
                                        previousProgress = 0,
                                        progress = 0)
        log_(content="Exam created.", USERNAME, sessionToken=session$token)
      }
    })
  
    # ADDITIONAL HANDLERS -----------------------------------------------------
    # download exam files
    output$downloadExamFiles = downloadHandler(
      filename = "exam.zip",
      content = function(fname) {
        # zip(zipfile=fname, files=isolate(examFiles()), flags='-r9XjFS')
        zip(zipfile=fname, files=isolate(examFiles()), flags='-r9Xj')
      },
      contentType = "application/zip"
    )
  
    # modal close
    observeEvent(input$dismiss_examCreationResponse, {
      removeModal()
      stopWait(session)
      session$sendCustomMessage("changeTabTitle", "reset")
    })

  # EVALUATE EXAM -------------------------------------------------------------
  # add / remove grading key item
  observeEvent(input$addGradingKeyitem, {
    gradingKeyItemID = isolate(input$addGradingKeyitem)
    newGradingKeyItem = myGradingkeyItem(gradingKeyItemID)
    
    insertUI(selector='#gradingKey tbody', where = "beforeEnd", ui=HTML(newGradingKeyItem), immediate = TRUE)
    session$sendCustomMessage("f_langDeEn", 1)
  })
  
  observeEvent(input$removeGradingKeyItem, {
    gradingKeyItem = isolate(input$removeGradingKeyItem)
    
    removeUI(selector=gradingKeyItem, immediate = TRUE)
    session$sendCustomMessage("f_langDeEn", 1)
  })
  
    # EVALUATE EXAM SCANS -----------------------------------------------------
      # PARAMETERS ---------------------------------------------------------------
      evaluateExamScans_req = paste0(getDir(session), "/evaluateExamScans_req.rds")
      evaluateExamScans_log = paste0(getDir(session), "/evaluateExamScans_log.txt")
      evaluateExamScans_res = paste0(getDir(session), "/evaluateExamScans_res.txt")
      evaluateExamScans_fin = paste0(getDir(session), "/evaluateExamScans_fin.txt")
      
      evaluateExamScans_req_content = list()
      evaluateExamScans_logHistory = c()
      evaluateExamScansProgressData = list(totalPdfLength = NULL,
                                           totalPngLength = NULL,
                                           previousProgress = 0,
                                           progress = 0)
      
      examScanEvaluationData = reactiveVal()
    
      # CALL --------------------------------------------------------------------
      examScanEvaluation = eventReactive(input$evaluateExam, {
        checkPm = checkPermission("P1003", credentials()$info$pm)
    
        if(!checkPm$hasPermission){
          session$sendCustomMessage("errorNoPermission", getNoPermissionMessage(checkPm$code, checkPm$response, FALSE))
          return(0)
        }
        
        if(length(evaluateExamScans_req_content) == 0) {
          session$sendCustomMessage("changeTabTitle", 3)
          startWait(session)
          initProrgress(session)
          log_(content="Evaluating exam scans.", USERNAME, sessionToken=session$token)
        }
        
        exam = input$evaluateExam
        dir = getDir(session)
    
        # write solutions file
        exam$examSolutionsName = unlist(exam$examSolutionsName)[1]
    
    		solutionFile = unlist(lapply(seq_along(exam$examSolutionsName), function(i){
    		  file = paste0(dir, "/", exam$examSolutionsName[[i]], ".rds")
    		  raw = openssl::base64_decode(exam$examSolutionsFile[[i]])
    		  writeBin(raw, con = file)
    
    		  return(file)
    		}))
    		
    		# write scan files
    		pngFiles = NULL
    		pdfFiles = NULL
    		totalPdfLength = 0
    		totalPngLength = length(exam$examScanPngNames)
    		
    		if(length(exam$examScanPdfNames) > 0){
    		  exam$examScanPdfNames = as.list(make.unique(unlist(exam$examScanPdfNames), sep="_"))
    		  
    		  pdfFiles = unlist(lapply(setNames(seq_along(exam$examScanPdfNames), exam$examScanPdfNames), function(i){
    		    file = paste0(dir, "/", exam$examScanPdfNames[[i]], ".pdf")
    		    raw = openssl::base64_decode(exam$examScanPdfFiles[[i]])
    		    writeBin(raw, con = file)
    		    
    		    totalPdfLength <<- totalPdfLength + qpdf::pdf_length(file)
    		    
    		    return(file)
    		  }))
    		}
    		
    		if(length(exam$examScanPngNames) > 0){
    		  exam$examScanPngNames = as.list(make.unique(exam$examScanPngNames, sep="_"))
    		  pngFiles = unlist(lapply(seq_along(exam$examScanPngNames), function(i){
    		    file = paste0(dir, "/", exam$examScanPngNames[[i]], ".png")
    		    raw = openssl::base64_decode(exam$examScanPngFiles[[i]])
    		    writeBin(raw, con = file)
    		    
    		    return(file)
    		  }))
    		}
    		
    		scanFiles = c(pdfFiles, pngFiles)
    
    		# write registered participants file
    		registeredParticipantsFile = NULL
    		dummyParticipants = FALSE
    		
    		exam$examRegisteredParticipantsnName = unlist(exam$examRegisteredParticipantsnName)[1]
    		
    		if(is.null(exam$examRegisteredParticipantsnName)){
    		  file = paste0(dir, "/", "dummyParticipants.csv")
    		  content = rep(1:(totalPdfLength + totalPngLength))
    		  content = sprintf(paste0("%0", max(input$evaluationRegLength, 7), "d"), as.numeric(content)) 
    		  content = data.frame(registration=content,
    		                       name=content,
    		                       id=content)
    		  
    		  write.csv2(content, file, row.names = FALSE, quote = FALSE)
    		  
    		  registeredParticipantsFile = file
    		  dummyParticipants = TRUE
    		} else {
      		registeredParticipantsFile = unlist(lapply(seq_along(exam$examRegisteredParticipantsnName), function(i){
      		  file = paste0(dir, "/", exam$examRegisteredParticipantsnName[[i]], ".csv")
      		  content = gsub("\r\n", "\n", exam$examRegisteredParticipantsnFile[[i]])
      		  content = gsub(",", ";", content)
      		  content = read.table(text=content, sep=";", header = TRUE)
      
      		  idRegMatch = FALSE
      		  
      		  if(all(content$id==content$registration))
      		    idRegMatch = TRUE
      		  
      		  content$registration = sapply(strsplit(as.character(content$registration), split=""), function(x){
      		    x = paste0(x[1:(min(input$evaluationRegLength, length(x)))], collapse="")
      		    x = sprintf(paste0("%0", max(input$evaluationRegLength, 7), "d"), as.numeric(x))
      		    
      		    return(x)
      		  })
      		  
      		  if(idRegMatch)
      		    content$id = content$registration
      		  
      		  write.csv2(content, file, row.names = FALSE, quote = FALSE)
      
      		  return(file)
      		}))
    		}

    		# get mark and mark label input fields
    		markThresholdsInputIds = paste0("markThreshold", 1:length(which(grepl("markThreshold", names(input)))))
    		markLabelsInputIds = paste0("markLabel", 1:length(which(grepl("markLabel", names(input)))))
    		
    		marks = as.numeric(isolate(reactiveValuesToList(input))[markThresholdsInputIds])
    		labels = unlist(isolate(reactiveValuesToList(input))[markLabelsInputIds])
    
        # request content
    		evaluateExamScans_req_content <<- list(dir=dir,
    		                                       edirName=edirName,
    		                                       totalPdfLength=totalPdfLength,
    		                                       totalPngLength=totalPngLength,
    		                                       scanFiles=scanFiles,
    		                                       registeredParticipantsFile=registeredParticipantsFile,
    		                                       dummyParticipants=dummyParticipants,
    		                                       solutionFile=solutionFile,
    		                                       examName=exam$examSolutionsName,
    		                                       rotate=input$rotateScans,
    		                                       regLength=input$evaluationRegLength,
    		                                       points=input$fixedPointsExamEvaluate,
                                           		 partial=input$partialPoints,
                                           		 negative=input$negativePoints,
                                           		 rule=input$rule,
                                           		 mark=input$mark,
    		                                       marks=marks,
    		                                       labels=labels,
    		                                       language=input$evaluationLanguage,
    		                                       cores=cores,
    		                                       maxChoices=maxChoices)
        
        write_atomic(evaluateExamScans_req_content, evaluateExamScans_req)
        
        return(1)
      })
    
      # PROCESSING --------------------------------------------------------------
      observe({
        if(examScanEvaluation() != 1)
          return(0)
        
        if (is.na(file.mtime(evaluateExamScans_fin))) {
          invalidateLater(millis = 100, session = session)
    
          logData = processLogFile(evaluateExamScans_log, evaluateExamScans_logHistory)
          evaluateExamScans_logHistory <<- logData$history
          evaluateExamScansProgressData <<- monitorProgressExamScanEvaluation(session, logData$out, evaluateExamScansProgressData)
    
          if(!DOCKER_WORKER)
            checkWorkerRequests()
        } else {
          if(!DOCKER_WORKER)
            readOutput()
    
          logData = processLogFile(evaluateExamScans_log, evaluateExamScans_logHistory)
          evaluateExamScans_logHistory <<- logData$history
          evaluateExamScansProgressData <<- monitorProgressExamScanEvaluation(session, logData$out, evaluateExamScansProgressData)
          
          # process results
          result = as.list(readLines(evaluateExamScans_res))
          
          messageType = unlist(result[1])
          message = unlist(result[2])
          
          if(messageType != "2"){
            names(result) = c("messageType", "message", "examIds", "examName", "numExercises", "numChoices", "totalPdfLength", "totalPngLength", "scanFileZipName",
                              "dir", "edirName", "cores", "rotate", "points", "regLength", "partial", "negative", "rule", "mark", "labels", "language",
                              "solution", "registeredParticipants", "scans", "scanEvaluation", "scans_reg_fullJoin", "examCodeFile")
            
            result = lapply(setNames(result, names(result)), function(x) strsplit(x, ";")[[1]])
            
            result = with(result, {
              data = list(messageType=unlist(messageType),
                          message=unlist(message),
                          preparedEvaluation=list(meta=list(examIds=examIds, examName=examName, numExercises=as.numeric(numExercises), numChoices=as.numeric(numChoices), totalPdfLength=as.numeric(totalPdfLength), totalPngLength=as.numeric(totalPngLength), scanFileZipName=scanFileZipName), 
                                                  fields=list(dir=dir, edirName=edirName, cores=as.numeric(cores), rotate=as.logical(rotate), points=switch((length(points)==0)+1,as.numeric(points),NULL), regLength=as.numeric(regLength), partial=as.logical(partial), negative=as.logical(negative), rule=rule, mark=ifelse(mark=="FALSE",FALSE,as.numeric(mark)), labels=labels, language=language),
                                                  files=list(solution=solution, registeredParticipants=registeredParticipants, scans=scans, scanEvaluation=scanEvaluation, scans_reg_fullJoin=scans_reg_fullJoin, examCodeFile=examCodeFile)),
                          scans_reg_fullJoinData=read.csv2(file=result$scans_reg_fullJoin, check.names = FALSE, colClasses = "character")
              )
      
              return(data)
            })
            
            examScanEvaluationData(result)
          } else{
            result = list(messageType=messageType,
                          message=message,
                          scans_reg_fullJoinData=NULL)
          }
          
          evaluateExamScansResponse(session, result)
          
          session$sendCustomMessage("changeTabTitle", as.numeric(messageType))
          
          # wrap up
          finalizeProgress(session)
          evaluateExamScans_req_content <<- list()
          evaluateExamScans_logHistory <<- c()
          evaluateExamScansProgressData <<- list(totalPdfLength = NULL,
                                               totalPngLength = NULL,
                                               previousProgress = 0,
                                               progress = 0)
          
          log_(content="Exam scans evaluated.", USERNAME, sessionToken=session$token)
        }
      })
      
      # ADDITIONAL HANDLERS -----------------------------------------------------
      # modal close
      observeEvent(input$dismiss_evaluateExamScansResponse, {
        removeModal()
        stopWait(session)
        session$sendCustomMessage("changeTabTitle", "reset")
      })
    
    # EVALUATE EXAM FINALIZE --------------------------------------------------
      # PARAMETERS ---------------------------------------------------------------
      evaluateExamFinalize_req = paste0(getDir(session), "/evaluateExamFinalize_req.rds")
      evaluateExamFinalize_log = paste0(getDir(session), "/evaluateExamFinalize_log.txt")
      evaluateExamFinalize_res = paste0(getDir(session), "/evaluateExamFinalize_res.txt")
      evaluateExamFinalize_fin = paste0(getDir(session), "/evaluateExamFinalize_fin.txt")
      
      evaluateExamFinalize_req_content = list()
      evaluateExamFinalize_logHistory = c()
      evaluateExamFinalizeProgressData = list(totalExams = NULL,
                                              previousProgress = 0,
                                              progress = 0)
      
      examFinalizeEvaluationData = reactiveVal()
  
      # CALL --------------------------------------------------------------------
      examFinalizeEvaluation = eventReactive(input$proceedEvaluation, {
        checkPm = checkPermission("P1004", credentials()$info$pm)
    
        if(!checkPm$hasPermission){
          session$sendCustomMessage("errorNoPermission", getNoPermissionMessage(checkPm$code, checkPm$response, FALSE))
          return(callr::r_bg(function() NULL))
        }
        
        if(length(evaluateExamFinalize_req_content) == 0) {
          session$sendCustomMessage("changeTabTitle", 3)
          startWait(session)
          initProrgress(session)
          log_(content="Evaluating exam.", USERNAME, sessionToken=session$token)
        }
    
        dir = getDir(session)
        removeModal()
    
        result = isolate(examScanEvaluationData())

        result$scans_reg_fullJoinData = isolate(input$proceedEvaluation$scans_reg_fullJoinData)
        result$scans_reg_fullJoinData = as.data.frame(Reduce(rbind, result$scans_reg_fullJoinData))
        
        examScanEvaluationData(result)
        
        # request content
        evaluateExamFinalize_req_content <<- c(isolate(examScanEvaluationData()), proceedEvaluation=list(isolate(input$proceedEvaluation)))
    
        write_atomic(evaluateExamFinalize_req_content, evaluateExamFinalize_req)
        
        return(1)
      })
  
      # PROCESSING --------------------------------------------------------------
      observe({
        if(examFinalizeEvaluation() != 1)
          return(0)
        
        if (is.na(file.mtime(evaluateExamFinalize_fin))) {
          invalidateLater(millis = 100, session = session)
          
          logData = processLogFile(evaluateExamFinalize_log, evaluateExamFinalize_logHistory)
          evaluateExamFinalize_logHistory <<- logData$history
          evaluateExamFinalizeProgressData <<- monitorProgressExamFinalizeEvaluation(session, logData$out, evaluateExamFinalizeProgressData)
          
          if(!DOCKER_WORKER)
            checkWorkerRequests()
        } else {
          if(!DOCKER_WORKER)
            readOutput()
          
          logData = processLogFile(evaluateExamFinalize_log, evaluateExamFinalize_logHistory)
          evaluateExamFinalize_logHistory <<- logData$history
          evaluateExamFinalizeProgressData <<- monitorProgressExamFinalizeEvaluation(session, logData$out, evaluateExamFinalizeProgressData)
          
          # process results
          result = as.list(readLines(evaluateExamFinalize_res))
          
          messageType = unlist(result[1])
          message = unlist(result[2])

          if(messageType != "2"){
            names(result) = c("messageType", "message", "examIds", "examName", "numExercises", "numChoices", "totalPdfLength", "totalPngLength", "scanFileZipName",
                              "dir", "edirName", "cores", "rotate", "points", "regLength", "partial", "negative", "rule", "mark", "labels", "language",
                              "solution", "registeredParticipants", "scanEvaluation", "scans_reg_fullJoin", "examCodeFile", "nops_evaluationCsv", "nops_evaluationZip", "nops_evalInputTxt", "nops_statisticsTxt")
            
            result = lapply(setNames(result, names(result)), function(x) strsplit(x, ";")[[1]])
            
            result = with(result, {
              data = list(messageType=unlist(messageType),
                          message=unlist(message),
                          preparedEvaluation=list(meta=list(examIds=examIds, examName=examName, numExercises=as.numeric(numExercises), numChoices=as.numeric(numChoices), totalPdfLength=as.numeric(totalPdfLength), totalPngLength=as.numeric(totalPngLength), scanFileZipName=scanFileZipName),
                                                  fields=list(dir=dir, edirName=edirName, cores=as.numeric(cores), rotate=as.logical(rotate), points=switch((length(points)==0)+1,as.numeric(points),NULL), regLength=as.numeric(regLength), partial=as.logical(partial), negative=as.logical(negative), rule=rule, mark=ifelse(mark=="FALSE",FALSE,as.numeric(mark)), labels=labels, language=language),
                                                  files=list(solution=solution, registeredParticipants=registeredParticipants, scanEvaluation=scanEvaluation, nops_evaluationCsv=nops_evaluationCsv, nops_evaluationZip=nops_evaluationZip, nops_evalInputTxt=nops_evalInputTxt, nops_statisticsTxt=nops_statisticsTxt, examCodeFile=examCodeFile)),
                          evaluationStatistics=readLines(nops_statisticsTxt)
              )
              
              data$evaluationStatistics = rev(split(data$evaluationStatistics, rev(cumsum(rev(data$evaluationStatistics=="")))))
              data$evaluationStatistics = lapply(data$evaluationStatistics, function(x) setNames(list(read.csv2(text=paste0(x[x!=""][-1], collapse="\n"))), x[1]))
              data$evaluationStatistics = Reduce(c, data$evaluationStatistics)
      
              return(data)
            })
      
            examFinalizeEvaluationData(result)
          } else{
            result = list(messageType=messageType,
                          message=message,
                          preparedEvaluation=list(files=NULL))
          }
            
          evaluateExamFinalizeResponse(session, result)
          
          session$sendCustomMessage("changeTabTitle", as.numeric(messageType))
    
          # wrap up
          evaluateExamFinalize_req_content <<- list()
          evaluateExamFinalize_logHistory <<- c()
          evaluateExamFinalizeProgressData <<- list(totalExams = NULL,
                                                  previousProgress = 0,
                                                  progress = 0)
    
          log_(content="Exam evaluated.", USERNAME, sessionToken=session$token)
        }
      })
    
      # ADDITIONAL HANDLERS -----------------------------------------------------
      # download evaluation files
      output$downloadEvaluationFiles = downloadHandler(
        filename = "evaluation.zip",
        content = function(fname) {
          # zip(zipfile=fname, files=unlist(isolate(examFinalizeEvaluationData()$preparedEvaluation$files), recursive = TRUE), flags='-r9XjFS')
          zip(zipfile=fname, files=unlist(isolate(examFinalizeEvaluationData()$preparedEvaluation$files), recursive = TRUE), flags='-r9Xj')
        },
        contentType = "application/zip"
      )
    
      # go back one step
      observeEvent(input$backTo_evaluateExamScansResponse, {
        removeModal()
        
        unlink(evaluateExamFinalize_req)
        unlink(evaluateExamFinalize_log)
        unlink(evaluateExamFinalize_res)
        unlink(evaluateExamFinalize_fin)
      
        unlink(examFinalizeEvaluationData()$preparedEvaluation$files$nops_evaluationCsv)
        unlink(examFinalizeEvaluationData()$preparedEvaluation$files$nops_evaluationZip)
        unlink(examFinalizeEvaluationData()$preparedEvaluation$files$nops_evalInputTxt)
        unlink(examFinalizeEvaluationData()$preparedEvaluation$files$nops_statisticsTxt)
        
        result = isolate(examScanEvaluationData())
        
        evaluateExamScansResponse(session, result)
      })
    
      # modal close
      observeEvent(input$dismiss_evaluateExamFinalizeResponse, {
        removeModal()
        stopWait(session)
        session$sendCustomMessage("changeTabTitle", "reset")
      })
    
  # ADDONS ------------------------------------------------------------------
  lapply(addons, \(addon) {
      lapply(addons, \(addon) {
        f_callModules = paste0(addon, "_callModules")
        f_observers = paste0(addon, "_observers")
        
        if(exists(f_callModules))
          do.call(f_callModules, args=list())
        
        if(exists(f_observers))
          do.call(f_observers, args=list(input=input))
      })
  })
}

# RUN APP -----------------------------------------------------------------
shinyApp(ui, server)
