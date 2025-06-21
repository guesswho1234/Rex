updateEvaluationData = function(solutionData, evaluationData, edirName=""){
  # add additional exercise columns
  exerciseTable = as.data.frame(Reduce(rbind, lapply(evaluationData$exam, \(exam) {
    exerciseNames = Reduce(cbind, lapply(solutionData[[as.character(exam)]], \(exercise) exercise$metainfo$file))
    if(edirName != "" && all(grepl(paste0(edirName, "_"), exerciseNames)))
      exerciseNames = sapply(strsplit(exerciseNames, paste0(edirName, "_")), \(name) name[2])
    else
      exerciseNames = sapply(strsplit(exerciseNames, "_"), \(name) tail(name,1))
    
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
  
  # set data types of evaluation data
  evaluationData[,grepl("check", names(evaluationData), ignore.case = TRUE)] = apply(evaluationData[,grepl("check", names(evaluationData), ignore.case = TRUE), drop = FALSE], 2, as.numeric)
  evaluationData[,grepl("points", names(evaluationData), ignore.case = TRUE)] = apply(evaluationData[,grepl("points", names(evaluationData), ignore.case = TRUE), drop = FALSE], 2, as.numeric)
  
  return(evaluationData)
}

getEvaluationStatisticsData = function(evaluationData, mark=FALSE, markLabels=c()){
  # exercise names
  exerciseNameColumns = grepl("exercise.*", names(evaluationData))
  exerciseNames = unique(unlist(evaluationData[,exerciseNameColumns]))
  
  exerciseShortNames = paste0(
    "\u00A0Exc-", #\u00A0: unicode non-breaking space
    sprintf(
      paste0("%0", nchar(length(exerciseNames)), "d"),
      seq_along(exerciseNames)
    )
  )
  
  # number of exercises
  numExercises = length(exerciseShortNames)
  
  # statistics parameters
  examMaxPoints = matrix(max(as.numeric(evaluationData$examMaxPoints)), dimnames=list("examMaxPoints", "value"))
  
  validExams = matrix(nrow(evaluationData), dimnames=list("validExams", "value"))
  
  totalPoints = t(summary(as.numeric(evaluationData$points)))
  rownames(totalPoints) = "totalPoints"
  
  points = matrix(mean(as.numeric(evaluationData$points))/examMaxPoints[1])
  colnames(points) = c("mean")
  rownames(points) = "points"
  
  # item responses
  identicalExercises = all(sapply(1:nrow(evaluationData), function(x){
    all(evaluationData[x,exerciseNameColumns] %in% exerciseNames)
  }))
  
  ir = matrix()
  exercisePoints = matrix()
  
  if(identicalExercises){
    ir = matrix(apply(evaluationData[,grepl("check.*", names(evaluationData)), drop = FALSE], 2, as.numeric), nrow=nrow(evaluationData))
    colnames(ir) = exerciseNames
    
    for(i in 1:nrow(ir)){
      ir[i,] = ir[i, exerciseNames[match(exerciseNames, evaluationData[i, exerciseNameColumns])]]
    }

    exercisePoints = t(apply(ir, 2, summary))
    
    colnames(ir) = exerciseShortNames
  }

  # basic statistics
  markTable = table(NULL)
  marks = matrix()

  if(mark[1] != FALSE && (length(mark) + 1) == length(markLabels)){
    markTable = table(factor(evaluationData$mark, markLabels))
    
    marks = cbind(markTable, markTable/sum(markTable), rev(cumsum(rev(markTable)))/sum(markTable))
    colnames(marks) = c("absolute", "relative", "relative cumulative")
    
    points = as.matrix(cbind(points, t(c(0, mark))), nrow=1)
    colnames(points) = c("mean", markLabels)
    rownames(points) = "points"
  }
  
  evaluationStatistics = list(
    points=points,
    examMaxPoints=examMaxPoints,
    validExams=validExams,
    exercisePoints=exercisePoints,
    totalPoints=totalPoints,
    marks=marks
  )
  
  evaluationStatisticsTxt = Reduce(c, lapply(names(evaluationStatistics), \(x){
    paste0(c(x,
             paste0(c("name", colnames(evaluationStatistics[[x]])), collapse=";"),
             paste0(rownames(evaluationStatistics[[x]]), ";", apply(evaluationStatistics[[x]], 1, \(y) paste0(paste0(y, collapse=";"), "\n")), collapse="")
    ), collapse="\n")
  }))
  
  # statistics report
  params = list()
  
  if(nrow(evaluationData) >= 5 && numExercises >= 5){
    params = list(
      validExams = validExams,
      exerciseShortNames = exerciseShortNames,
      exerciseNames = exerciseNames,
      plots = NULL,
      captions = NULL,
      descriptions = NULL,
      mark = mark,
      markLabels = markLabels,
      markTable = markTable,
      points = evaluationData$points,
      numExercises = numExercises,
      examMaxPoints = examMaxPoints,
      exercisePoints = exercisePoints,
      ir_binary = ir,
      ir_ok = NULL,
      hm = NULL,
      rasch_model = NULL
    )
    
    rownames(params$exercisePoints) = exerciseShortNames
    
    params$ir_binary[] = 0L + (as.numeric(ir) > 0)
    params$ir_binary = psychotools::itemresp(as.data.frame(params$ir_binary), mscale = 0:1)
    params$ir_ok = params$ir_binary[, apply(params$ir_binary, 2, function(x) length(unique(x)) == 2)]
    
    tryCatch({
      params$hm = suppressWarnings(homals::homals(as.data.frame(as.matrix(params$ir_ok)), ndim = if(numExercises <= 5L) numExercises else ceiling(numExercises/3)))   
    }, error = function(e) {
      params$hm = NULL
      warning("W1005")
    })
    
    tryCatch({
      params$rasch_model = psychotools::raschmodel(params$ir_ok)
    }, error = function(e) {
      params$rasch_model = NULL
      warning("W1006")
    })

    # Total points plot
    params$captions = c(params$captions, "Total Points Plot")
    params$descriptions = c(params$descriptions, "")
    params$plots = c(params$plots, quote({
      breaks = seq(0, params$examMaxPoints[1], length.out = params$numExercises)
      
      if(params$mark[1] != FALSE){
        breaks = sort(unique(c(breaks, mean(params$points), params$examMaxPoints[1] * params$mark)))
      } else {
        breaks = (0:(params$numExercises+1) - 0.5) * params$examMaxPoints[1]/params$numExercises
      }
      breaks = c(breaks, Inf)
      
      counts_per_bin = vapply(1:(length(breaks) - 1), FUN.VALUE = 1, function(x) {
        sum(params$points > breaks[x] & params$points <= breaks[x + 1])
      })
      yMax = max(counts_per_bin / (length(params$points) * diff(breaks)))
      
      plot = hist(as.numeric(params$points), xlab = "Points", ylab = "Fraction", freq = FALSE, main = "", axes = F, ylim = c(0, yMax * 1.2), breaks = breaks[-length(breaks)])
      if(params$mark[1] != FALSE){
        thresholds = c(0, params$mark, 1)
        threshold_midpoints = head(thresholds, -1) + diff(thresholds) / 2
        x_positions = threshold_midpoints * params$examMaxPoints[1]
        y_position = yMax / 2
        
        lapply(seq_along(params$markLabels), function(x){
          x_value = c(params$mark, 1)[x]
          
          if(x_value != 1){
            lines(x = rep(c(params$mark, 1)[x] * params$examMaxPoints[1], 2), y = c(0, yMax), lwd = 3, col = "#ffd380")
          }
          
          label = params$markLabels[x]
          cex = 0.7
          
          # Estimate text size in user coordinates
          strwidth_ = strwidth(label, cex = cex) * 1.2
          strheight_ = strheight(label, cex = cex) * 1.5
          
          # Draw filled rectangle (box)
          rect(xleft = x_positions[x] - strwidth_ / 2,
               xright = x_positions[x] + strwidth_ / 2,
               ybottom = y_position - strheight_ / 2,
               ytop = y_position + strheight_ / 2,
               col = "#ffd380", border = "#555555", lwd = 0.5)
          
          # Draw text on top of rectangle
          text(x = x_positions[x], y = y_position, labels = label, cex = cex)
        })
      }
      lines(x = rep(mean(params$points), 2), y = c(0, yMax), lwd = 3, lty=2, col = "#d35555")
      axis(2, at = seq(0, yMax, by = round(yMax/8, 2)), labels = seq(0, yMax, by = round(yMax/8, 2)), las=2)
      axis(1, at = unique(round(c(0, params$examMaxPoints[1] * params$mark, params$examMaxPoints[1]), 2)))
      legend("topleft", legend = c(paste0("mean points (", round(mean(params$points), 2), ")"), "mark thresholds"), lwd = 3, lty = c(2, 1), col = c("#d35555", "#ffd380"), bty="n")
    }))
    
    # Partially solved exercises plot
    params$captions = c(params$captions, "Exercise Plot")
    params$descriptions = c(params$descriptions, "")
    params$plots = c(params$plots, quote({
      barplot(t(prop.table(cbind(rev(params$exercisePoints[,4]), 1 - rev(params$exercisePoints[,4])), 1)), horiz = TRUE, las = 1, main = "Average Points", xlab = "Fraction")
      barplot(t(prop.table(summary(params$ir_binary), 1)[params$numExercises:1, 2:1]), horiz = TRUE, las = 1, main = "Partially Solved", xlab = "Fraction")
    }))
    
    # Exam marks plot
    if(length(markTable) > 0 && mark[1] != FALSE){
      params$captions = c(params$captions, "Exam marks plot")
      params$descriptions = c(params$descriptions, "")
      params$plots = c(params$plots, quote({
        plot = barplot(params$markTable, xlab = "Mark", ylab = "Frequency", main="")
        text(x = plot, y = params$markTable / 2, labels = paste0(round(params$markTable/sum(params$markTable) * 100, 0), "%"))
      }))
    }
    
    # Participant exercise plot
    if(identicalExercises && length(params$rasch_model) > 0){
      params$captions = c(params$captions, "Participant Exercise Plot")
      params$descriptions = c(params$descriptions, "Both plots are based on a Rasch-model. The histogram shows participants' abilities. The plot below the histogram shows item difficulties with zero indicating median difficulty.")
      params$plots = c(params$plots, quote({
        psychotools::piplot(params$rasch_model, xlab = "Skill", main = "")
      }))
    }
    
    # Factor analysis plot
    if(identicalExercises && length(params$hm) > 0){
      params$captions = c(params$captions, "Factor Analysis Plot")
      params$descriptions = c(params$descriptions, "")
      params$plots = c(params$plots, quote({
        plot(params$hm, plot.type = "loadplot", main = "Factor Loadings")
        barplot(params$hm$eigenvalues, xlab = "Dimension", ylab = "Eigenvalue", main = "Eigenvalues", names.arg = seq_along(params$hm$eigenvalues))
      }))
    }
  }
  
  return(list(evaluationStatistics=evaluationStatistics, 
              evaluationStatisticsTxt=evaluationStatisticsTxt,
              params=params))
}
