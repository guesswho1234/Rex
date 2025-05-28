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
  evaluationData = as.data.frame(evaluationData)
  evaluationData[,grepl("check", names(evaluationData), ignore.case = TRUE)] = apply(evaluationData[,grepl("check", names(evaluationData), ignore.case = TRUE)], 2, as.numeric)
  evaluationData[,grepl("points", names(evaluationData), ignore.case = TRUE)] = apply(evaluationData[,grepl("points", names(evaluationData), ignore.case = TRUE)], 2, as.numeric)
  
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
  
  # item responses
  ir = matrix(apply(evaluationData[,grepl("check.*", names(evaluationData))], 2, as.numeric), nrow=nrow(evaluationData))
  colnames(ir) = exerciseShortNames
  
  # statistics parameters
  examMaxPoints = matrix(max(as.numeric(evaluationData$examMaxPoints)), dimnames=list("examMaxPoints", "value"))
  validExams = matrix(nrow(evaluationData), dimnames=list("validExams", "value"))
  exercisePoints = t(apply(ir, 2, summary))
  
  totalPoints = t(summary(as.numeric(evaluationData$points)))
  rownames(totalPoints) = "totalPoints"
  
  points = matrix(mean(as.numeric(evaluationData$points))/examMaxPoints[1])
  colnames(points) = c("mean")
  rownames(points) = "points"
  
  if(length(markLabels) == 0)
    markLabels = unique(evaluationData$mark)
  markTable = table(factor(evaluationData$mark, markLabels))
  
  # basic statistics
  marks = matrix()

  if(length(markTable) > 0 && mark[1] != FALSE){
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
  
  if(nrow(evaluationData) >= 5){
    params = list(
      validExams = validExams,
      exerciseShortNames = exerciseShortNames,
      exerciseNames = exerciseNames,
      plots = NULL,
      captions = NULL,
      descriptions = NULL,
      mark = mark,
      markTable = markTable,
      points = evaluationData$points,
      numExercises = numExercises,
      examMaxPoints = examMaxPoints,
      ir_binary = ir,
      ir_ok = NULL,
      hm = NULL
    )
    
    params$ir_binary[] = 0L + (as.numeric(ir) > 0)
    for(i in 1:nrow(params$ir_binary)){
      params$ir_binary[i,] = params$ir_binary[i, exerciseShortNames[match(exerciseNames, evaluationData[i, exerciseNameColumns])]]
    }
    params$ir_binary = psychotools::itemresp(as.data.frame(params$ir_binary), mscale = 0:1)
    params$ir_ok = params$ir_binary[, apply(params$ir_binary, 2, function(x) length(unique(x)) == 2)]

    params$hm = suppressWarnings(homals::homals(as.data.frame(as.matrix(params$ir_ok)), ndim = if(numExercises <= 5L) numExercises else ceiling(numExercises/3)))
    
    # Exam marks plot
    if(length(markTable) > 0 && mark[1] != FALSE){
      params$captions = c(params$captions, "Exam marks plot")
      params$descriptions = c(params$descriptions, "")
      params$plots = c(params$plots, quote({
        plot = barplot(params$markTable, xlab = "Mark", ylab = "Frequency", main="")
        text(x = plot, y = params$markTable / 2, labels = paste0(round(params$markTable/sum(params$markTable) * 100, 0), "%"))
      }))
    }
    
    # Total points plot
    params$captions = c(params$captions, "Total Points Plot")
    params$descriptions = c(params$descriptions, "Vertical lines for mean points and mark thresholds (if the exam is marked) are placed at their exact values and may not align with histogram breaks.")
    params$plots = c(params$plots, quote({
      hist(as.numeric(params$points), xlab = "Points", ylab = "Frequency", main = "", axes = F, ylim = c(0, max(table(as.numeric(params$points))) * 1.2), breaks = (0:(params$numExercises + 1) - 0.5) * params$examMaxPoints[1] / params$numExercises)
      if(params$mark[1] != FALSE)
        lapply(params$mark, function(x){
          lines(x = rep(x * params$examMaxPoints[1], 2), y = c(0, max(table(as.numeric(params$points)))), lwd = 3, col = "#ffd380")
        })
      lines(x = rep(mean(params$points), 2), y = c(0, max(table(as.numeric(params$points)))), lwd = 3, lty=2, col = "#d35555")
      axis(2, at = seq(0, 1, 0.2))
      axis(1)
      legend("topleft", legend = c("mean points", "mark thresholds"), lwd = 3, lty = c(2, 1), col = c("#d35555", "#ffd380"), bty="n")
    }))
    
    # Partially solved exercises plot
    params$captions = c(params$captions, "Partially Solved Exercise Plot")
    params$descriptions = c(params$descriptions, "The plot displays statistics for exercises that were at least solved partially.")
    params$plots = c(params$plots, quote({
      barplot(t(prop.table(summary(params$ir_binary), 1)[params$numExercises:1, 2:1]), horiz = TRUE, las = 1, main = "", xlab = "Fraction")
    }))
    
    # Participant exercise plot
    params$captions = c(params$captions, "Participant Exercise Plot")
    params$descriptions = c(params$descriptions, "Both plots are based on a Rasch-model. The histogram on the top shows participants' abilities. The plot on the bottom shows item difficulties with zero indicating median difficulty.")
    params$plots = c(params$plots, quote({
      psychotools::piplot(psychotools::raschmodel(params$ir_ok), xlab = "Skill", main = "")
    }))
    
    # Factor analysis plot
    params$captions = c(params$captions, "Factor Analysis Plot")
    params$descriptions = c(params$descriptions, "")
    params$plots = c(params$plots, quote({
      plot(params$hm, plot.type = "loadplot", main = "Factor Loadings")
      barplot(params$hm$eigenvalues, xlab = "Dimension", ylab = "Eigenvalue", main = "Eigenvalues", names.arg = seq_along(params$hm$eigenvalues))
    }))
  }
  
  return(list(evaluationStatistics=evaluationStatistics, 
              evaluationStatisticsTxt=evaluationStatisticsTxt,
              params=params))
}
