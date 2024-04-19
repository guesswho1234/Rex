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
library(exams) #exams_2.4-1
library(png) #png_0.1-8 
library(tth) #tth_4.12-0-1 
library(xtable) #xtable_1.8-4
library(callr) # callr_3.7.3
library(pdftools) # pdftools_3.4.0
library(qpdf) # qpdf_1.3.2
library(openssl) # openssl_2.1.1
library(shinyauthr) # shinyauthr_1.0.0
library(sodium) # sodium_1.3.1
# library(magick) # magick_2.7.4

# CONNECTION --------------------------------------------------------------
options(shiny.host = "0.0.0.0")
options(shiny.port = 8180)

# SOURCE ------------------------------------------------------------------
source("./source/filesAndDirectories.R")
source("./source/customElements.R")
source("./source/tryCatch.R")

# FUNCTIONS ----------------------------------------------------------------
  # PREPARE DOWNLOAD EXERCISES ----------------------------------------------
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
  
  # PARSE EXERCISES ---------------------------------------------------------
  parseExercise = function(exercise, seed, collectWarnings, dir){
     out = tryCatch({
      warnings = collectWarnings({
        splitBy = ";\n" # originally it is ";\r\n" but "\r\n" is replaced by "\n"
        
        # unify line breaks
        exercise$exerciseCode = gsub("\r\n", "\n", exercise$exerciseCode)
        
        # show all possible choices when viewing exercises (only relevant for editable exercises)
        exercise$exerciseCode = sub("maxChoices=5", "maxChoices=NULL", exercise$exerciseCode)
        
        # remove image from question when viewing exercises (only relevant for editable exercises)
        exercise$exerciseCode = sub("rnwTemplate_showFigure=TRUE", "rnwTemplate_showFigure=FALSE", exercise$exerciseCode)
  
        # extract figure to display it in the respective field when viewing a exercise (only relevant for editable exercises)
        figure = strsplit(exercise$exerciseCode, "rnwTemplate_figure=")[[1]][2]
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
        question_raw = strsplit(exercise$exerciseCode, "rnwTemplate_question=")[[1]][2]
        question_raw = strsplit(question_raw, splitBy)[[1]][1]
        question_raw = paste0(rev(rev(strsplit(question_raw, "")[[1]][-1])[-1]), collapse="") # trim
        question_raw = gsub("\\\\", "\\", question_raw, fixed=TRUE)
        
        # extract raw choice texts
        choices_raw = strsplit(exercise$exerciseCode, "rnwTemplate_choices=")[[1]][2]
        choices_raw = strsplit(choices_raw, splitBy)[[1]][1]
        choices_raw = strsplit(choices_raw, ",\"")[[1]]
        choices_raw[1] = paste0(strsplit(choices_raw[1], "")[[1]][-c(1:3)], collapse="")
        choices_raw[length(choices_raw)] = paste0(rev(rev(strsplit(choices_raw[length(choices_raw)], "")[[1]])[-1]), collapse="") #trim
        choices_raw = Reduce(c, lapply(choices_raw, \(x) paste0(rev(rev(strsplit(x, "")[[1]])[-c(1)]), collapse=""))) # trim
        
        if(grepl("rnwTemplate_choices", exercise$exerciseCode) & length(choices_raw) < 2)
          stop("E1022")
        
        # extract raw solution note texts
        solutionNotes_raw = strsplit(exercise$exerciseCode, "rnwTemplate_solutionNotes=")[[1]][2]
        solutionNotes_raw = strsplit(solutionNotes_raw, splitBy)[[1]][1]
        solutionNotes_raw = strsplit(solutionNotes_raw, ",\"")[[1]]
        solutionNotes_raw[1] = paste0(strsplit(solutionNotes_raw[1], "")[[1]][-c(1:3)], collapse="")
        solutionNotes_raw[length(solutionNotes_raw)] = paste0(rev(rev(strsplit(solutionNotes_raw[length(solutionNotes_raw)], "")[[1]])[-1]), collapse="") #trim
        solutionNotes_raw = Reduce(c, lapply(solutionNotes_raw, \(x) paste0(rev(rev(strsplit(x, "")[[1]])[-c(1)]), collapse=""))) # trim
        
        seed = if(seed == "") NULL else seed
        
        file = tempfile(fileext = paste0(".", exercise$exerciseExt))
        writeLines(text=exercise$exerciseCode, con=file)
  
        htmlPreview = exams::exams2html(file, dir = dir, seed = seed, base64 = TRUE)
        
        htmlPreview$exam1$exercise1$question_raw = question_raw
        htmlPreview$exam1$exercise1$choices_raw = choices_raw
        htmlPreview$exam1$exercise1$solutionNotes_raw = solutionNotes_raw

        if (!htmlPreview$exam1$exercise1$metainfo$type %in% c("schoice", "mchoice")) {
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
        value = paste0("W1001: ", value)
      }
  
      return(list(message=list(key=key, value=value), id=exercise$exerciseID, seed=seed, html=htmlPreview, figure=figure))
    },
    error = function(e){
      if(!grepl("E\\d{4}", e$message))
        e$message = paste0("E1001: ", e$message)
      
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
      
      if(length(html$exam1$exercise1$metainfo$examHistory) > 0) {
        examHistory = trimws(strsplit(html$exam1$exercise1$metainfo$examHistory, ",")[[1]], "both")
        examHistory = rjs_vectorToJsonStringArray(examHistory)
      }
      
      if(length(html$exam1$exercise1$metainfo$authoredBy) > 0) {
        authoredBy = trimws(strsplit(html$exam1$exercise1$metainfo$authoredBy, ",")[[1]], "both") 
        authoredBy = rjs_vectorToJsonStringArray(authoredBy) 
      }
      
      if(length(html$exam1$exercise1$metainfo$tags) > 0) { 
        tags = trimws(html$exam1$exercise1$metainfo$tags, "both")
        tags = rjs_vectorToJsonStringArray(tags)
      }

      points = html$exam1$exercise1$metainfo$points
      topic = html$exam1$exercise1$metainfo$topic
      type = html$exam1$exercise1$metainfo$type
      question = html$exam1$exercise1$question
      question_raw = html$exam1$exercise1$question_raw
      figure = rjs_vectorToJsonStringArray(unlist(figure))
      editable = ifelse(html$exam1$exercise1$metainfo$editable == 1, 1, 0)
      choices = rjs_vectorToJsonStringArray(html$exam1$exercise1$questionlist)
      choices_raw = rjs_vectorToJsonStringArray(html$exam1$exercise1$choices_raw)
      solutions = rjs_vectorToJsonArray(tolower(as.character(html$exam1$exercise1$metainfo$solution)))
      solutionNotes = rjs_vectorToJsonStringArray(as.character(html$exam1$exercise1$solutionlist))
      solutionNotes_raw = rjs_vectorToJsonStringArray(html$exam1$exercise1$solutionNotes_raw)
      section = html$exam1$exercise1$metainfo$section

      session$sendCustomMessage("setExerciseExamHistory", examHistory)
      session$sendCustomMessage("setExerciseAuthoredBy", authoredBy)
      session$sendCustomMessage("setExercisePoints", points)
      session$sendCustomMessage("setExerciseTopic", topic)
      session$sendCustomMessage("setExerciseType", type)
      session$sendCustomMessage("setExerciseTags", tags)
      session$sendCustomMessage("setExerciseSection", section)
      session$sendCustomMessage("setExerciseSeed", seed)
      session$sendCustomMessage("setExerciseQuestion", question)
      session$sendCustomMessage("setExerciseQuestionRaw", question_raw)
      session$sendCustomMessage("setExerciseFigure", figure)
      session$sendCustomMessage("setExerciseEditable", editable)
      session$sendCustomMessage("setExerciseChoices", choices)
      session$sendCustomMessage("setExerciseChoicesRaw", choices_raw)
      session$sendCustomMessage("setExerciseSolutions", solutions)
      session$sendCustomMessage("setExerciseSolutionNotes", solutionNotes)
      session$sendCustomMessage("setExerciseSolutionNotesRaw", solutionNotes_raw)
    }
  
    session$sendCustomMessage("setExerciseStatusMessage", myMessage(message, "exercise"))
    session$sendCustomMessage("setExerciseStatusCode", getMessageCode(message))
    session$sendCustomMessage("setExerciseId", -1)
  }
  
  # CREATE EXAM -------------------------------------------------------------
  createExam = function(exam, settings, input, collectWarnings, dir) {
    out = tryCatch({
      warnings = collectWarnings({
        if(any(input$seedValueExam < settings$seedMin))
          stop("E1008")
        
        if(any(input$seedValueExam > settings$seedMax))
          stop("E1009")

        if(length(exam$exerciseNames) < settings$exerciseMin)
          stop("E1010")

        if(length(exam$exerciseNames) > settings$exerciseMax)
          stop("E1011")
        
        if(length(unique(exam$exerciseTypes)) > 1)
          stop("E1019")
        
        if(!all(unique(exam$exerciseTypes) %in% c("schoice", "mchoice")))
          stop("E1020")

        edir = paste0(dir, "/", settings$edirName)
        dir.create(file.path(edir), showWarnings = TRUE)
        
        exam$exerciseNames = as.list(make.unique(unlist(exam$exerciseNames), sep="_"))
        exerciseFiles = unlist(lapply(setNames(seq_along(exam$exerciseNames), exam$exerciseNames), function(i){
          file = paste0(edir, "/", exam$exerciseNames[[i]], ".", exam$exerciseExts[[i]])
          writeLines(text=gsub("\r\n", "\n", exam$exerciseCodes[[i]]), con=file, sep="")
          
          return(file)
        }))
        
        numberOfExams = as.numeric(input$numberOfExams)
        blocks = as.numeric(exam$blocks)
        uniqueBlocks = unique(blocks)
        numberOfExercises = as.numeric(input$numberOfExercises)
        exercisesPerBlock = numberOfExercises / length(uniqueBlocks)
        exercises = lapply(uniqueBlocks, function(x) exerciseFiles[blocks==x])
        
        seedList = matrix(1, nrow=numberOfExams, ncol=length(exam$exerciseNames))
        seedList = seedList * as.numeric(paste0(if(is.na(is.numeric(input$seedValueExam))) NULL else input$seedValueExam, 1:numberOfExams))
        
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
        points = if(!is.na(as.numeric(input$fixedPointsExamCreate))) input$fixedPointsExamCreate else NULL
        reglength = if(!is.na(as.numeric(input$examRegLength))) as.numeric(input$examRegLength) else 7
        date = input$examDate
        name = paste0(c("exam", input$seedValueExam, ""), collapse="_")
        
        examFields = list(
          file = exercises,
          edir = edir,
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
          reglength = reglength,
          header = NULL,
          intro = c(input$examIntro), 
          replacement = input$replacement,
          samepage = input$samepage,
          newpage = input$newpage,
          logo = NULL
        )
        
        # needed for pdf files (not for html files) - somehow exams needs it that way
        fileIds = 1:numberOfExams
        fileIdSizes = floor(log10(fileIds))
        fileIdSizes = max(fileIdSizes) - fileIdSizes
        fileIds = sapply(seq_along(fileIdSizes), function(x){
          paste0(paste0(rep("0", max(fileIdSizes))[0:fileIdSizes[x]], collapse=""), fileIds[x])
        })
        
        examHtmlFiles = paste0(dir, "/", name, 1:numberOfExams, ".html")
        examPdfFiles = paste0(dir, "/", name, fileIds, ".pdf")
        examRdsFile = paste0(dir, "/", name, ".rds")
        
        preparedExam = list(examFields=examFields, examFiles=list(examHtmlFiles=examHtmlFiles, pdfFiles=examPdfFiles, rdsFile=examRdsFile), sourceFiles=list(exerciseFiles=exerciseFiles, additionalPdfFiles=additionalPdfFiles))
        
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
        value = paste0("W1002: ", value)
      }
  
      return(list(message=list(key=key, value=value), files=list(sourceFiles=preparedExam$sourceFiles, examFiles=preparedExam$examFiles)))
    },
    error = function(e){
      if(!grepl("E\\d{4}", e$message))
        e$message = paste0("E1002: ", e$message)
  
      return(list(message=list(key="Error", value=e), files=list()))
    })
  
    return(out)
  }
  
  examCreationResponse = function(session, message, downloadable) {
    showModal(modalDialog(
      title = tags$span(HTML('<span lang="de">Prüfung erstellen</span><span lang="en">Create exam</span>')),
      tags$span(id="responseMessage", myMessage(message, "modal")),
      footer = tagList(
        myActionButton("dismiss_examCreationResponse", "Schließen", "Close", "fa-solid fa-xmark"),
        if (downloadable)
          myDownloadButton('downloadExamFiles')
      )
    ))
    session$sendCustomMessage("f_langDeEn", 1)
  }
  
  # EVALUATE EXAM -----------------------------------------------------------
  evaluateExamScans = function(input, settings, collectWarnings, dir){
    out = tryCatch({
      scans_reg_fullJoinData = NULL
      
      warnings = collectWarnings({
        # settings
        regLength = input$evaluationRegLength
        
        points = input$fixedPointsExamEvaluate
        if(is.numeric(points) && points > 0) {
          points = rep(points, numExercises)
        } else {
          points = NULL
        }
        
        partial = input$partialPoints
        negative = input$negativePoints
        rule = input$rule
        
        mark = input$mark
        labels = NULL
        
        if(mark) {
          markThresholdsInputIds = paste0("markThreshold", 1:length(which(grepl("markThreshold", names(input)))))
          markLabelsInputIds = paste0("markLabel", 1:length(which(grepl("markLabel", names(input)))))
          
          mark = as.numeric(input[markThresholdsInputIds])
          labels = unlist(input[markLabelsInputIds])
          
          invalidGradingKeyItems = mark == "" | labels == ""
          
          mark = mark[!invalidGradingKeyItems][-1]

          labels = labels[!invalidGradingKeyItems]
        }
        
        language = input$evaluationLanguage
        
        # exam
        input$evaluateExam$examSolutionsName = unlist(input$evaluateExam$examSolutionsName)[1]
        
        solutionFile = unlist(lapply(seq_along(input$evaluateExam$examSolutionsName), function(i){
          file = paste0(dir, "/", input$evaluateExam$examSolutionsName[[i]], ".rds")
          raw = openssl::base64_decode(input$evaluateExam$examSolutionsFile[[i]])
          writeBin(raw, con = file)
          
          return(file)
        }))
        examExerciseMetaData = readRDS(solutionFile)
        
        # registered participants
        input$evaluateExam$examRegisteredParticipantsnName = unlist(input$evaluateExam$examRegisteredParticipantsnName)[1]
        
        registeredParticipantsFile = unlist(lapply(seq_along(input$evaluateExam$examRegisteredParticipantsnName), function(i){
          file = paste0(dir, "/", input$evaluateExam$examRegisteredParticipantsnName[[i]], ".csv")
          content = gsub("\r\n", "\n", input$evaluateExam$examRegisteredParticipantsnFile[[i]])
          content = gsub(",", ";", content)
          content = read.table(text=content, sep=";", header = TRUE)
          
          if(all(content$id==content$registration))
            content$id = sprintf(paste0("%0", regLength, "d"), as.numeric(content$id))
          
          content$registration = sprintf(paste0("%0", regLength, "d"), as.numeric(content$registration))

          write.csv2(content, file, row.names = FALSE, quote = FALSE)
          
          return(file)
        }))
        
        # process scans to end up with only png files at the end
        pngFiles = NULL
        pdfFiles = NULL
        convertedPngFiles = NULL
        
        if(length(input$evaluateExam$examScanPdfNames) > 0){
          input$evaluateExam$examScanPdfNames = as.list(make.unique(unlist(input$evaluateExam$examScanPdfNames), sep="_"))
          
          pdfFiles = lapply(setNames(seq_along(input$evaluateExam$examScanPdfNames), input$evaluateExam$examScanPdfNames), function(i){
            file = paste0(dir, "/", input$evaluateExam$examScanPdfNames[[i]], ".pdf")
            raw = openssl::base64_decode(input$evaluateExam$examScanPdfFiles[[i]])
            
            if(input$rotateScans){
              file = gsub(".pdf", "_.pdf", file)
              writeBin(raw, con = file)
              output = paste0(dir, "/", input$evaluateExam$examScanPdfNames[[i]], ".pdf")
              numberOfPages = qpdf::pdf_length(file)
              qpdf::pdf_rotate_pages(input=file, output=output, pages=1:numberOfPages, angle=ifelse(input$rotateScans, 180, 0))
              
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
        
        if(length(input$evaluateExam$examScanPngNames) > 0){
          namesToConsider = c(sub("(.*\\/)([^.]+)(\\.[[:alnum:]]+$)", "\\2", convertedPngFiles), unlist(input$evaluateExam$examScanPngNames))
          namesToConsider_idx = (length(namesToConsider)-length(input$evaluateExam$examScanPngNames) + 1):length(namesToConsider)
          
          input$evaluateExam$examScanPngNames = as.list(make.unique(namesToConsider, sep="_"))[namesToConsider_idx]
          pngFiles = unlist(lapply(seq_along(input$evaluateExam$examScanPngNames), function(i){
            file = paste0(dir, "/", input$evaluateExam$examScanPngNames[[i]], ".png")
            raw = openssl::base64_decode(input$evaluateExam$examScanPngFiles[[i]])
            writeBin(raw, con = file)
            
            return(file)
          }))
        }
        
        #todo: change to use pdf and png files without conversion (exams can do it now with r magick package and qpdf)
        scanFiles = c(convertedPngFiles, pngFiles)
        
        #todo: check if this helps reduce ram load
        rm(pdfFiles, convertedPngFiles, pngFiles)
        gc()
        
        # meta data
        examName = input$evaluateExam$examSolutionsName[[1]]
        examIds = names(examExerciseMetaData)
        numExercises = length(examExerciseMetaData[[1]])
        numChoices = length(examExerciseMetaData[[1]][[1]]$questionlist)
        
        preparedEvaluation = list(meta=list(examIds=examIds, examName=examName, numExercises=numExercises, numChoices=numChoices),
                                  fields=list(points=points, regLength=regLength, partial=partial, negative=negative, rule=rule, mark=mark, labels=labels, language=language),
                                  files=list(solution=solutionFile, registeredParticipants=registeredParticipantsFile, scans=scanFiles))
        
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

          # read registered participants
          registeredParticipantData = read.csv2(files$registeredParticipants)
  
          if(ncol(registeredParticipantData) != 3)
            stop("E1015")
  
          if(!all(names(registeredParticipantData)[1:3] == c("registration", "name", "id")))
            stop("E1016")
  
          scanData = exams::nops_scan(images=files$scans,
                           file=FALSE,
                           dir=dir,
                           cores=settings$cores)
          scanData = read.table(text=scanData, sep=" ", fill=TRUE)
          names(scanData)[c(1:6)] = c("scan", "sheet", "scrambling", "type", "replacement", "registration")
          names(scanData)[-c(1:6)] = (7:ncol(scanData)) - 6
          
          # reduce columns using additional data from exam to know how many questions and answer per question existed
          scanData = scanData[,-which(grepl("^[[:digit:]]+$", names(scanData)))[-c(1:meta$numExercises)]] # remove unnecessary placeholders for unused questions
          scanData$numExercises = meta$numExercises
          scanData$numChoices = meta$numChoices
  
          # add scans as base64 to be displayed in browser
          scanData$blob = lapply(scanData$scan, function(x) {
            file = paste0(dir, "/", x)
            blob = readBin(file, "raw", n=file.info(file)$size)
            openssl::base64_encode(blob)
          })
  
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
  
          # pad zeroes to registration numbers and answers
          scans_reg_fullJoinData$registration[scans_reg_fullJoinData$registration != "XXXXXXX"] = sprintf(paste0("%0", fields$regLength, "d"), as.numeric(scans_reg_fullJoinData$registration[scans_reg_fullJoinData$registration != "XXXXXXX"]))
          scans_reg_fullJoinData[,as.character(1:meta$numExercises)] = apply(scans_reg_fullJoinData[,as.character(1:meta$numExercises)], 2, function(x){
            x[is.na(x)] = 0
            x = sprintf(paste0("%0", meta$numChoices, "d"), as.numeric(x))
          })
  
          scans_reg_fullJoinData <<- scans_reg_fullJoinData
        })
  
        NULL
      })
      key = "Success"
      value = paste(unique(unlist(warnings)), collapse="<br>")
      if(value != "") {
        key = "Warning"
        value = paste0("W1003: ", value)
      }
  
      return(list(message=list(key=key, value=value),
                  scans_reg_fullJoinData=scans_reg_fullJoinData,
                  preparedEvaluation=preparedEvaluation))
    },
    error = function(e){
      if(!grepl("E\\d{4}", e$message))
        e$message = paste0("E1003: ", e$message)

      return(list(message=list(key="Error", value=e), scans_reg_fullJoinData=NULL, examName=NULL, files=list(), data=list()))
    })
  
    return(out)
  }
  
  evaluateExamScansResponse = function(session, result) {
    showModal(modalDialog(
      title = tags$span(HTML('<span lang="de">Scans überprüfen</span><span lang="en">Check scans</span>')),
      tags$span(id="responseMessage", myMessage(result$message, "modal")),
      
      if (!is.null(result$scans_reg_fullJoinData)) 
        tagList(
          tags$div(id="scanStats"),
          tags$div(id="inspectScan"),
          tags$div(id="compareScanRegistrationDataTable", HTML('<div class="loadingCompareScanRegistrationDataTable"><span lang="de">BITTE WARTEN ...</span><span lang="en">PLEASE WAIT ...</span></div>')),
        ),
      
      footer = tagList(
        myActionButton(id="dismiss_evaluateExamScansResponse", deText="Abbrechen", enText="Cancle", icon="fa-solid fa-xmark", disabled=TRUE),
        if (!is.null(result$scans_reg_fullJoinData)) 
          myActionButton(id="proceedEval", deText="Weiter", enText="Proceed", icon="fa-solid fa-circle-right", disabled=TRUE)
      ),
      size = "l"
    ))
    session$sendCustomMessage("f_langDeEn", 1)
    
    # display scanData in modal
    if (!is.null(result$scans_reg_fullJoinData) && nrow(result$scans_reg_fullJoinData) > 0) {
      scans_reg_fullJoinData_json = rjs_vectorToJsonArray(
        apply(result$scans_reg_fullJoinData, 1, function(x) {
          rjs_keyValuePairsToJsonObject(names(result$scans_reg_fullJoinData), x)
        })
      )
      
      examIds_json = rjs_vectorToJsonStringArray(result$preparedEvaluation$meta$examIds)
  
      session$sendCustomMessage("setExanIds", examIds_json)
      session$sendCustomMessage("compareScanRegistrationData", scans_reg_fullJoinData_json)
    } 
    
    # display scanData again after going back from "evaluateExamFinalizeResponse"
    if (!is.null(result$scans_reg_fullJoinData) && nrow(result$scans_reg_fullJoinData) == 0) {
      session$sendCustomMessage("backTocompareScanRegistrationData", 1)
    }
  }
  
  evaluateExamFinalize = function(preparedEvaluation, proceedEvaluation, settings, collectWarnings, dir){
    out = tryCatch({
      warnings = collectWarnings({
        # process scanData
        scanData = Reduce(c, lapply(proceedEvaluation$datenTxt, function(x) paste0(unlist(unname(x)), collapse=" ")))
        scanData = paste0(scanData, collapse="\n")
        
        if(scanData == "")
          stop("E1021")

        # write scanData
        scanDatafile = paste0(dir, "/", "Daten.txt")
        writeLines(text=scanData, con=scanDatafile)
        
        # create *_nops_scan.zip file needed for exams::nops_eval
        zipFile = gsub("_+", "_", paste0(dir, "/", preparedEvaluation$meta$examName, "_nops_scan.zip"))
        zip(zipFile, c(preparedEvaluation$files$scans, scanDatafile), flags='-r9XjFS')

        # manage preparedEvaluation data
        preparedEvaluation$files$scanEvaluation = zipFile
        preparedEvaluation$files = within(preparedEvaluation$files, rm(list=c("scans")))
        
        # file path and name settings
        nops_evaluation_fileNames = "evaluation.html"
        nops_evaluation_fileNamePrefix = gsub("_+", "_", paste0(preparedEvaluation$meta$examName, "_nops_eval"))
        preparedEvaluation$files$nops_evaluationCsv = paste0(dir, "/", nops_evaluation_fileNamePrefix, ".csv")
        preparedEvaluation$files$nops_evaluationZip = paste0(dir, "/", nops_evaluation_fileNamePrefix, ".zip")
        
        #todo:
        # statistics
        # preparedEvaluation$files$nops_statisticsCsv = paste0(dir, "/statistics.csv")
        
        with(preparedEvaluation, {
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
            dir = dir,
            file = nops_evaluation_fileNames,
            language = fields$language,
            interactive = TRUE
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
            if(all(grepl(paste0(settings$edirName, "_"), exerciseNames)))
              exerciseNames = sapply(strsplit(exerciseNames, paste0(settings$edirName, "_")), \(name) name[2])
            
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
          
          #todo: make statistics data writeable, different files for each statistic?
          # statistics
          # examMaxPoints = matrix(max(as.numeric(evaluationData$examMaxPoints)), dimnames=list("examMaxPoints", "value"))
          # validExams = matrix(nrow(evaluationData), dimnames=list("validExams", "value"))
          # 
          # exerciseNames = unique(unlist(evaluationData[,grepl("exercise.*", names(evaluationData))]))
          # if(all(grepl(paste0(settings$edirName, "_"), exerciseNames)) )
          #   exerciseNames = sapply(strsplit(exerciseNames, paste0(settings$edirName, "_")), \(name) name[2])
          # 
          # exercisePoints = Reduce(rbind, lapply(exerciseNames, \(exercise){
          #   summary(apply(evaluationData, 1, \(participant){
          # 
          #     if(!exercise %in% participant)
          #       return(NULL)
          # 
          #     as.numeric(participant[gsub("exercise", "check", names(evaluationData)[participant==exercise])])
          #   }))
          # }))
          # 
          # rownames(exercisePoints) = exerciseNames
          # 
          # totalPoints = t(summary(as.numeric(evaluationData$points)))
          # rownames(totalPoints) = "totalPoints"
          # 
          # points = matrix(mean(as.numeric(evaluationData$points))/examMaxPoints)
          # colnames(points) = c("mean")
          # 
          # marks = matrix()
          # 
          # if(fields$mark[1] != FALSE) {
          #   marks = table(factor(evaluationData$mark, fields$labels))
          #   marks = cbind(marks, marks/sum(marks), rev(cumsum(rev(marks)))/sum(marks))
          #   colnames(marks) = c("absolute", "relative", "relative cumulative")
          # 
          #   points = cbind(points, t(c(0, fields$mark)))
          #   colnames(points) = c("mean", fields$labels)
          # }
          # 
          # chartData = list(ids = list("evaluationPointStatistics", "evaluationExerciseStatistics", "evaluationGradingStatistics"),
          #                  values = list(points, exercisePoints, marks),
          #                  deCaptions = c("Punkte", "Aufgaben", "Noten"),
          #                  enCaptions = c("Points", "Exercises", "Marks"))
          # 
          # evaluationStatistics = list(
          #   examMaxPoints=examMaxPoints,
          #   validExams=validExams,
          #   exercisePoints=exercisePoints,
          #   totalPoints=totalPoints,
          #   markThresholds=fields$mark,
          #   marks=marks
          # )
          # 
          # preparedEvaluation$evaluationStatistics = evaluationStatistics
          
          #todo:
          # write
          # write.csv2(evaluationStatistics, files$nops_statisticsCsv, row.names = FALSE)
          write.csv2(evaluationData, files$nops_evaluationCsv, row.names = FALSE)
        })
  
        NULL
      })
      key = "Success"
      value = paste(unique(unlist(warnings)), collapse="<br>")
      if(value != "") {
        key = "Warning"
        value = paste0("W1004: ", value)
      }
      
      return(list(message=list(key=key, value=value), 
                  preparedEvaluation=preparedEvaluation))
    },
    error = function(e){
      if(!grepl("E\\d{4}", e$message))
        e$message = paste0("E1004: ", e$message)

      return(list(message=list(key="Error", value=e), examName=NULL, files=list()))
    })
  
    return(out)
  }
  
  evaluateExamFinalizeResponse = function(session, input, result) {
    # process exam statistics
    showModalStatistics = !is.null(result$preparedEvaluation$files$nops_evaluationCsv) && length(unlist(result$preparedEvaluation$files, recursive = TRUE)) > 0

    if (showModalStatistics) {
      evaluationResultsData = read.csv2(result$preparedEvaluation$files$nops_evaluationCsv)
      
      examMaxPoints = matrix(max(as.numeric(evaluationResultsData$examMaxPoints)), dimnames=list("examMaxPoints", "value"))
      validExams = matrix(nrow(evaluationResultsData), dimnames=list("validExams", "value"))
      
      exerciseNames = unique(unlist(evaluationResultsData[,grepl("exercise.*", names(evaluationResultsData))]))
      if(all(grepl(paste0(edirName, "_"), exerciseNames)) )
        exerciseNames = sapply(strsplit(exerciseNames, paste0(edirName, "_")), \(name) name[2])

      exercisePoints = Reduce(rbind, lapply(exerciseNames, \(exercise){
        summary(apply(evaluationResultsData, 1, \(participant){

          if(!exercise %in% participant)
            return(NULL)

          as.numeric(participant[gsub("exercise", "check", names(evaluationResultsData)[participant==exercise])])
        }))
      }))

      rownames(exercisePoints) = exerciseNames
      
      totalPoints = t(summary(as.numeric(evaluationResultsData$points)))
      rownames(totalPoints) = "totalPoints"
      
      points = matrix(mean(as.numeric(evaluationResultsData$points))/examMaxPoints)
      colnames(points) = c("mean")

      marks = matrix()
      markThresholds = matrix()
      if(input$mark) {
        marks = table(factor(evaluationResultsData$mark, levels=result$preparedEvaluation$fields$labels))
        marks = cbind(marks, marks/sum(marks), rev(cumsum(rev(marks)))/sum(marks))
        colnames(marks) = c("absolute", "relative", "relative cumulative")
        
        markThresholdsInputIds = paste0("markThreshold", 1:length(which(grepl("markThreshold", names(input)))))
        markLabelsInputIds = paste0("markLabel", 1:length(which(grepl("markLabel", names(input)))))
        
        markThresholds = as.numeric(input[markThresholdsInputIds])
        labels = unlist(input[markLabelsInputIds])
        
        invalidGradingKeyItems = markThresholds == "" | labels == ""
        
        markThresholds = matrix(markThresholds[!invalidGradingKeyItems], nrow=1)
        colnames(markThresholds) = labels[!invalidGradingKeyItems]
        
        points = cbind(points, markThresholds)
        colnames(points) = c("mean", colnames(markThresholds))
      }
      
      chartData = list(ids = list("evaluationPointStatistics", "evaluationExerciseStatistics", "evaluationGradingStatistics"),
                       values = list(points, exercisePoints, marks),
                       deCaptions = c("Punkte", "Aufgaben", "Noten"),
                       enCaptions = c("Points", "Exercises", "Marks"))
      
      evaluationStatistics = list(
        examMaxPoints=examMaxPoints,
        validExams=validExams,
        exercisePoints=exercisePoints,
        totalPoints=totalPoints,
        markThresholds=markThresholds,
        marks=marks
      )

      evaluationStatistics_json = rjs_vectorToJsonArray(Reduce(c, lapply(seq_along(evaluationStatistics), \(x) {
        rjs_keyValuePairsToJsonObject(names(evaluationStatistics)[x],
                                      rjs_vectorToJsonArray(Reduce(c, lapply(1:nrow(evaluationStatistics[[x]]), \(y) {
                                        rjs_keyValuePairsToJsonObject(c("name", colnames(evaluationStatistics[[x]])),
                                                                      c(rownames(evaluationStatistics[[x]])[y], evaluationStatistics[[x]][y,]),
                                                                      c(TRUE, rep(FALSE, length(evaluationStatistics[[x]][y,]))))
                                      }))), FALSE)
      })))

      session$sendCustomMessage("evaluationStatistics", evaluationStatistics_json)
    }
    
    # show modal
    showModal(modalDialog(
      title = tags$span(HTML('<span lang="de">Prüfung auswerten</span><span lang="en">Evaluate exam</span>')),
      tags$span(id='responseMessage', myMessage(result$message, "modal")),
      if (showModalStatistics)
        myEvaluationCharts(chartData, examMaxPoints, validExams, input$mark),
      footer = tagList(
        myActionButton("dismiss_evaluateExamFinalizeResponse", "Schließen", "Close", "fa-solid fa-xmark"),
        myActionButton("backTo_evaluateExamScansResponse", "Zurück", "Back", "fa-solid fa-arrow-left"),
        if (length(unlist(result$preparedEvaluation$files, recursive = TRUE)) > 0)
          myDownloadButton('downloadEvaluationFiles')
      )
    ))
    session$sendCustomMessage("f_langDeEn", 1)
  }
  
  # WAIT --------------------------------------------------------------------
  startWait = function(session){
    session$sendCustomMessage("wait", 0)
  }
  
  stopWait = function(session){
    removeRuntimeFiles(session)
    session$sendCustomMessage("wait", 1)
  }

  # HELPER FUNCTIONS ---------------------------------------
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
  
  rjs_keyValuePairsToJsonObject = function(keys, values, escapeValues=TRUE){
    if(length(escapeValues) < length(values))
      escapeValues = rep(TRUE, length(values))
    
    values = sapply(seq_along(values), \(x){
      if(escapeValues[x]) {
        values[x] = gsub("\"", "\\\\\"", values[x])
        values[x] = gsub(":", "\\:", values[x])
        values[x] = gsub("\\n", " ", values[x])
        values[x] = paste0("\"", values[x], "\"")
      }
        
      return(values[x])
    })

    keys = paste0("\"", keys, "\":")
    
    x = paste0(keys, values, collapse=", ")
    x = paste0("{", x, "}")
    
    return(x)
  }

# PARAMETERS --------------------------------------------------------------
  # REXAMS ------------------------------------------------------------------
  cores = NULL
  if (Sys.info()["sysname"] == "Linux")
    cores = parallel::detectCores()

  edirName = "exercises"
  exerciseMin = 1
  exerciseMax = 45
  seedMin = 1
  seedMax = 999999999999
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

  # ADDONS ------------------------------------------------------------------
  addons_path = "./addons/"
  addons_path_www = "./www/addons/"
  addons = list.files(addons_path_www, recursive = TRUE) 
  addons = unique(Reduce(c, lapply(addons[grepl("/", addons)], \(x) strsplit(x, split="/")[[1]][1])))
  
  invisible(lapply(addons, \(addon) {
    source(paste0(addons_path_www, addons, "/", addons, ".R"))
  }))
  
  # AUTH --------------------------------------------------------------------
  user_base = data.frame(
    user = c("rex"),
    password = sapply(c("rex"), sodium::password_store),
    permissions = c("admin"),
    name = c("Rex")
  )

# UI -----------------------------------------------------------------
ui = htmlTemplate(
  filename = "index.html"
)
  
# SERVER -----------------------------------------------------------------
server = function(input, output, session) {
  session$sendCustomMessage("debugMessage", Sys.info()) # ping
  
  # AUTH --------------------------------------------------------------------
  credentials = shinyauthr::loginServer(
    id = "login",
    data = user_base,
    user_col = user,
    pwd_col = password,
    sodium_hashed = TRUE,
    log_out = reactive(logout_init())
  )

  # Logout to hide
  logout_init = shinyauthr::logoutServer(
    id = "logout",
    active = reactive(credentials()$user_auth)
  )
  
  eventReactive
  output$rexApp = renderUI({
    req(credentials()$user_auth)
    
    # STARTUP -------------------------------------------------------------
    unlink(getDir(session), recursive = TRUE)
    dir.create(getDir(session))
    removeRuntimeFiles(session)

    initSeed <<- as.numeric(gsub("-", "", Sys.Date()))

    # LOAD APP ----------------------------------------------------------------
    fluidPage(
     htmlTemplate(
      filename = "app.html",
    
      # EXERCISES
      textInput_seedValueExercises = textInput("seedValueExercises", label = NULL, value = initSeed),
      button_downloadExercises = myDownloadButton('downloadExercises'),
      button_downloadExercise = myDownloadButton('downloadExercise'),
      
      exerciseFigureFileImport = myFileImport("exerciseFigure", "exerciseFigure"),
    
      # EXAM CREATE
      dateInput_examDate = dateInput("examDate", label = NULL, value = NULL, format = "yyyy-mm-dd"),
      textInput_seedValueExam = textInput("seedValueExam", label = NULL, value = initSeed),
      textInput_numberOfExams = textInput("numberOfExams", label = NULL, value = 1),
      textInput_numberOfExercises = textInput("numberOfExercises", label = NULL, value = 0),
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
      
      additionalPdfFileImport = myFileImport("additionalPdf", "exam"),
    
      # EXAM EVALUATE
      textInput_fixedPointsExamEvaluate = textInput("fixedPointsExamEvaluate", label = NULL, value = NULL),
      selectInput_evaluateReglength = selectInput("evaluationRegLength", label = NULL, choices = 1:10, selected = 8, multiple = FALSE),
      checkboxInput_partialPoints = checkboxInput("partialPoints", label = NULL, value = TRUE),
      checkboxInput_negativePoints = checkboxInput("negativePoints", label = NULL, value = NULL),
      selectInput_rule = selectInput("rule", label = NULL, choices = rules, selected = NULL, multiple = FALSE),
      checkboxInput_mark = checkboxInput("mark", label = NULL, value = TRUE), 
      
      gradingKey = myGradingKey(5),
    
      textInput_markThreshold1 = disabled(textInput("markThreshold1", label = NULL, value = 0)),
      textInput_markLabel1 = textInput("markLabel1", label = NULL, value = NULL),
      
      textInput_markThreshold2 = textInput("markThreshold2", label = NULL, value = 0.5),
      textInput_markLabel2 = textInput("markLabel2", label = NULL, value = NULL),
    
      textInput_markThreshold3 = textInput("markThreshold3", label = NULL, value = 0.6),
      textInput_markLabel3 = textInput("markLabel3", label = NULL, value = NULL),
    
      textInput_markThreshold4 = textInput("markThreshold4", label = NULL, value = 0.75),
      textInput_markLabel4 = textInput("markLabel4", label = NULL, value = NULL),
    
      textInput_markThreshold5 = textInput("markThreshold5", label = NULL, value = 0.85),
      textInput_markLabel5 = textInput("markLabel5", label = NULL, value = NULL),
    
      selectInput_evaluationLanguage = selectInput("evaluationLanguage", label = NULL, choices = languages, selected = "de", multiple = FALSE),
      checkboxInput_rotateScans = checkboxInput("rotateScans", label = NULL, value = TRUE),
      
      examSolutionsFileImport = myFileImport("examSolutions", "exam"),
      examRegisteredParticipantsFileImport = myFileImport("examRegisteredParticipants", "exam"),
      examScansFileImport = myFileImport("examScans", "exam"),
      
      # ADDON CONTENT
      addonSidebarListItems = lapply(addons, \(addon) {
        htmlTemplate(filename = paste0(addons_path_www, addon, "/", addon, "_sidebarListItem.html"))
      }),
      
      addonContentTabs = lapply(addons, \(addon) {
        htmlTemplate(filename = paste0(addons_path_www, addon, "/", addon, "_contentTab.html"), init=get(paste0(addon, "_fields")))
      })
    ),
    
    # SCRIPTS
    tags$script(src="script.js"),
    tags$script(src="rnwTemplate.js"),
    
    # ADDON SCRIPTS
    lapply(addons, \(addon) {
      tags$script(src=paste0(addons_path, addon, "/", addon, "_script.js"))
    }),
    
    # ADDON STYLESHEET
    lapply(addons, \(addon) {
      tags$link(rel="stylesheet", type="text/css", href=paste0(addons_path, addon, "/", addon, "_style.css"))
    }),
   )
  })
  
  # CLEANUP -------------------------------------------------------------
  onStop(function() {
    unlink(getDir(session), recursive = TRUE)
  })
  
  # HEARTBEAT -------------------------------------------------------------
  initialState = TRUE

  observe({
    invalidateLater(1000 * 5, session)
    if(!initialState) 
      session$sendCustomMessage("heartbeat", 1) # ping

    initialState <<- FALSE
  })
  
  observeEvent(input$pong, {
    # pong
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

      zip(zipfile=fname, files=exerciseFiles, flags='-r9XjFS')
      removeRuntimeFiles(session)
    },
    contentType = "application/zip",
  )

  # PARSE EXERCISES -------------------------------------------------------------
  #todo: (sync, prepare function) send list of exercises with javascript exerciseID and exerciseCode;
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
  examFiles = reactiveVal()

  examCreation = eventReactive(input$createExam, {
    startWait(session)
    
    settings = list(edirName=edirName,
                    exerciseMin=exerciseMin,
                    exerciseMax=exerciseMax,
                    seedMin=seedMin,
                    seedMax=seedMax)
    
    x = callr::r_bg(
      func = createExam,
      args = list(isolate(input$createExam), settings, isolate(reactiveValuesToList(input)), collectWarnings, getDir(session)),
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
    filename = "exam.zip",
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
  examScanEvaluationData = reactiveVal()
  examFinalizeEvaluationData = reactiveVal()
  
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
  
  # evaluate scans - trigger
  examScanEvaluation = eventReactive(input$evaluateExam, {
    startWait(session)
    
    settings = list(cores=cores)

    # background exercise
    x = callr::r_bg(
      func = evaluateExamScans,
      args = list(isolate(reactiveValuesToList(input)), settings, collectWarnings, getDir(session)),
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
      examScanEvaluationData(result)
      
      # open modal
      evaluateExamScansResponse(session, result)
    }
  })

  # finalizing evaluation - trigger
  examFinalizeEvaluation = eventReactive(input$proceedEvaluation, {
    dir = getDir(session)
    removeModal()
    
    result = isolate(examScanEvaluationData())
    result$scans_reg_fullJoinData = isolate(input$proceedEvaluation$scans_reg_fullJoinData)
    result$scans_reg_fullJoinData = as.data.frame(Reduce(rbind, result$scans_reg_fullJoinData)) 
    
    examScanEvaluationData(result)
    
    settings = list(edirName=edirName)
    
    # background exercise
    x = callr::r_bg(
      func = evaluateExamFinalize,
      args = list(isolate(examScanEvaluationData()$preparedEvaluation), isolate(input$proceedEvaluation), settings, collectWarnings, dir),
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
      examFinalizeEvaluationData(result)
      
      # open modal
      evaluateExamFinalizeResponse(session, isolate(reactiveValuesToList(input)), result)
    }
  })
  
  # get evaluation statistics
  output$downloadEvaluationStatistics = downloadHandler(
    filename = "statistics.csv",
    content = function(fname) {
      zip(zipfile=fname, files=unlist(isolate(examFinalizeEvaluationData()$preparedEvaluation$files), recursive = TRUE), flags='-r9XjFS')
    },
    contentType = "application/zip"
  )

  # back to evaluateExamScansResponse
  observeEvent(input$backTo_evaluateExamScansResponse, {
    removeModal()
    
    unlink(examFinalizeEvaluationData()$preparedEvaluation$files$scanEvaluation)
    unlink(examFinalizeEvaluationData()$preparedEvaluation$files$nops_evaluationCsv)
    unlink(examFinalizeEvaluationData()$preparedEvaluation$files$nops_evaluationZip)
    
    result = isolate(examScanEvaluationData())
    
    evaluateExamScansResponse(session, result)
  })

  # modal close
  observeEvent(input$dismiss_evaluateExamScansResponse, {
    removeModal()
    stopWait(session)
  })

  observeEvent(input$dismiss_evaluateExamFinalizeResponse, {
    removeModal()
    stopWait(session)
  })
  
  # ADDONS ------------------------------------------------------------------
  lapply(addons, \(addon) {
    get(paste0(addon, "_callModules"))()
    get(paste0(addon, "_observers"))(input)
  })
}

# RUN APP -----------------------------------------------------------------
shinyApp(ui, server)