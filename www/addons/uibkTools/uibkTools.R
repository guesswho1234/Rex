# SOURCE ------------------------------------------------------------------
source("source/filesAndDirectories.R")
source("source/customElements.R")

# FUNCTIONS ------------------------------------------------------------------
  # INTEGRATION -------------------------------------------------------------
  uibkTools_downloadObjUI <- function(id, deText, enText, icon) {
    ns <- NS(id)
    
    myDownloadButton(ns("uibkToolsDl"), deText, enText, icon)
  }
  
  uibkTools_downloadObj <- function(input, output, session) {
    output$uibkToolsDl <- downloadHandler(
      filename = function() {
        uibkToolsData()$name
      },
      content = function(fname) {
        if(uibkToolsData()$contentType=="text/csv")
          write.csv(uibkToolsData()$data, fname, row.names = FALSE, quote = FALSE)
        
        if(uibkToolsData()$contentType=="application/zip") {
          dir = getDir(session)
          
          lapply(names(uibkToolsData()$data), \(x){
            write.csv2(uibkToolsData()$data[[x]], paste0(dir, "/", x), row.names = FALSE, quote = FALSE)
          })
            
          zip(zipfile=fname, files=paste0(dir, "/", names(uibkToolsData()$data)), flags='-r9XjFS')
          
          removeRuntimeFiles(session)
        }
  
        uibkToolsData(NULL)
      },
      contentType = uibkToolsData()$contentType
    )
  }
  
  uibkTools_callModules = function(){
    callModule(uibkTools_downloadObj, id = "createRexParticipantsList")
    callModule(uibkTools_downloadObj, id = "createOlatEvalList")
    callModule(uibkTools_downloadObj, id = "createGradingLists")
  }
  
  uibkTools_observers = function(input){
    observeEvent(input$callAddonFunction, {
      result = get(input$callAddonFunction$func)(input$callAddonFunction$args)
      uibkToolsData(result)
    })
  }
  
  # DATA PROCESSING ---------------------------------------------------------
  createRexParticipantsList = function(args) {
    name = "registredParticipants.csv"
    contentType = "text/csv"
    
    if(length(args)==0)
      return(list(name=name, data=NULL,  contentType=contentType))
    
    data = Reduce(rbind, lapply(args, \(x){
      content = read.table(text=x[[3]], sep=";", header = FALSE)
    }))
    
    if(is.null(data))
      return(list(name=name, data=NULL,  contentType=contentType))
    
    data = data[,c(1,3,2)]
    data = data[rowSums(is.na(data))==0,]
    colnames(data) = c("registration", "name", "id")
    
    return(list(name=name, data=data, contentType=contentType))
  }
  
  createOlatEvalList = function(args) {
    name = "olatEvalList.csv"
    contentType = "text/csv"
    
    if(length(args)==0)
      return(list(name=name, data=NULL,  contentType=contentType))
    
    data = Reduce(rbind, lapply(args, \(x){
      content = read.table(text=x[[3]], sep=";", header = TRUE)
    }))
    
    if(is.null(data))
      return(list(name=name, data=NULL, contentType=contentType))
    
    data = data[,c("id", "points")]
    data = data[rowSums(is.na(data))==0,]
    
    return(list(name=name, data=data, contentType=contentType))
  }
  
  createGradingLists = function(args) {
    name = "gradingLists.zip"
    contentType = "application/zip"
    
    if(length(args)==0)
      return(list(name=name, data=NULL,  contentType=contentType))
    
    evalData = Reduce(rbind, lapply(args$rexEvaluationLists, \(x){
      content = read.table(text=x[[3]], sep=";", header = TRUE)
    }))
    
    if(is.null(evalData))
      return(list(name=name, data=NULL,  contentType=contentType))
    
    evalData$registration = as.numeric(evalData$registration)
    
    files=sapply(args$visGradingLists, \(x) paste0(x[1:2], collapse="."))
    
    gradingData = lapply(setNames(args$visGradingLists, files), \(x){
      content = read.table(text=x[[3]], sep=";", header = FALSE)
      
      if(is.null(content))
        return(list(name=name, data=NULL,  contentType=contentType))
      
      content = content[,1:3]
      content = content[rowSums(is.na(content))==0,]
      content[,1] = as.numeric(content[,1])
      
      content = merge(content, evalData[,c("registration", "mark")], by=1)
      
      if(is.null(content))
        return(list(name=name, data=NULL,  contentType=contentType))
      
      colnames(content) = c("registration", "name", "program", "mark")
      
      return(content)
    })
    
    return(list(name=name, data=gradingData, contentType=contentType))
  }

# CONTENT ------------------------------------------------------------------
uibkToolsData = reactiveVal()

uibkTools_fields = list(button_createRexParticipantsList = uibkTools_downloadObjUI(id = "createRexParticipantsList", "Rex Teilnehmerliste erstellen", "Create Rex registered participant list", "fa-solid fa-users"),
                        button_createOlatEvalList = uibkTools_downloadObjUI(id = "createOlatEvalList", "OLAT Massenbewertungliste erstellen", "Create OLAT mass evaluation list", "fa-solid fa-file-circle-check"),
                        button_createGradingLists = uibkTools_downloadObjUI(id = "createGradingLists", "Notenlisten erstellen", "Create grading lists", "fa-solid fa-graduation-cap"))
