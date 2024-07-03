myActionButton = function(id, deText, enText, icon){
  tags$button(id = id, class = "btn btn-default action-button shiny-bound-input", type="button", myButtonStyle(deText, enText, icon))
}

myDownloadButton = function(id, deText="Speichern", enText="Save", icon="fa-solid fa-download"){
  tags$a(id = id, class = "btn btn-default shiny-download-link", href = "", target = "_blank", type = "button", download = NA, NULL, myButtonStyle(deText, enText, icon))
}

myCheckBox = function(id, deText, enText) {
  text = paste0('<span class="checkBoxText"><span lang="de">', deText, ':</span><span lang="en">', enText, ':</span></span>')
  tags$span(id = id, HTML(text), tags$input(type="checkbox"))
}

myButtonStyle = function(deText, enText, icon) {
  icon = paste0('<span class="iconButton"><i class="', icon, '"></i></span>')
  text = paste0('<span class="textButton"><span lang="de">', deText, '</span><span lang="en">', enText, '</span></span>')
  
  return(tags$span(HTML(paste0(icon, text, collapse=""))))
}

myGradingKey = function(size) {
	if (!is.numeric(size) || is.infinite(size) || size < 2)
		size = 2
	
	  gradingKey = sapply(1:size, \(x){

		gradingKeyItem = myGradingkeyItem(x)
	})
	
	return(HTML(paste0(gradingKey, collapse="")))
} 

myGradingkeyItem = function(index) {
  firstItem = index == 1
  removable = index > 2
  
  itemClasses = paste0('gradingKeyItem ', ifelse(removable,"removable",""))
  
  itemThresholdItem = paste0('<td><div class="form-group shiny-input-container', ifelse(firstItem,' shinyjs-disabled disabled" disabled="disabled"','"'), '><input id="markThreshold', index, '" type="text" class="markThreshold form-control shiny-bound-input shinyjs-resettable', ifelse(firstItem,' disabled',''), '" value="0" data-shinyjs-resettable-id="markThreshold', index, '" data-shinyjs-resettable-type="Text" data-shinyjs-resettable-value=""', ifelse(firstItem,' disabled=""',''), '></td>')
  
  itemMarkItem = paste0('<td><div class="form-group shiny-input-container"><input id="markLabel', index, '" type="text" class="markLabel form-control shiny-bound-input shinyjs-resettable" data-shinyjs-resettable-id="markLabel', index, '" data-shinyjs-resettable-type="Text" data-shinyjs-resettable-value=""></div></td>')
  
  itemRemoveItem = paste0('<td><div class="form-group modifyGradingkeyItems"><span class="modifyGradingkeyItemButtons"><button type="button" class="removeGradingKeyItem btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></button><button type="button" class="addGradingKeyItem btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-plus"></i></span><span class="textButton"><span style="" lang="de">Hinzufügen</span><span lang="en">Add</span></span></button></span></div></td>')
  
  gradingKeyItem = paste0('<tr class="', itemClasses , '">', itemThresholdItem, itemMarkItem, itemRemoveItem, '</tr>')
  
  return(gradingKeyItem)
}

myFileImport = function(name, sectionClass) {
	idContainer = paste0(name, "Container")
	idInput = paste0("file-upload_", name)
	idFiles = paste0(name, "Files")
	idFileList = paste0(name, "Files_list")
	idFileListItems = paste0(name, "Files_list_items")
	labelClass = paste0(sectionClass, "FileUpload")
	buttonClass = paste0(sectionClass, "FileButton")
	javascriptFunction = paste0(name, "FileDialog(this.files);")

	fileImport = paste0('',
	'<div id="', idContainer, '">',
		'<label class="', labelClass, '" for="', idInput, '">',
			'<div class="', buttonClass, '">',
				'<span class="iconButton"><i class="fa-solid fa-upload"></i></span>',
				'<span class="textButton"><span lang="de">Importieren</span><span lang="en">Import</span></span>',
			'</div>',
			'<input type="file" id="', idInput, '" onchange="', javascriptFunction, '" multiple>',
		'</label>',
		'<div id="', idFiles, '">',
			'<div id="', idFileList, '" class="itemList">',
				'<div id="', idFileListItems, '">',
				'</div>',
			'</div>',
		'</div>',
	'</div>'
	)
	
	return(HTML(fileImport))
}

myEvaluationCharts = function(chartData, examMaxPoints, validExams, showGradingChart) {
	pointsChart = myPointsChart(chartData$ids[[1]], chartData$values[[1]], examMaxPoints, chartData$deCaptions[[1]], chartData$enCaptions[[1]])
	
	exerciseChart = myExerciseChart(chartData$ids[[2]], chartData$values[[2]], chartData$deCaptions[[2]], chartData$enCaptions[[2]])
	
	if(!showGradingChart)
		return(HTML(paste0(pointsChart, exerciseChart)))
	
	gradingChart = myGradingChart(chartData$ids[[3]], chartData$values[[3]], validExams, chartData$deCaptions[[3]], chartData$enCaptions[[3]])
	
	return(HTML(paste0(pointsChart, exerciseChart, gradingChart)))
}

myPointsChart = function(id, values, examMaxPoints, deCaption, enCaption) {
	meanValue = values[1]
	
	values_	= values
	
	if(length(values)>1) {
		colnames(values_) = c(colnames(values)[1], "", colnames(values)[-c(1,length(values))])
		values_ = values_[,values_>0,drop=FALSE]
		values_ = values_[,order(values_),drop=FALSE]
	} else {
		colnames(values) = ""
	}

	cssChart = paste0('',
		'<figure id="', id, '" aria-hidden="true">',
			paste0('<figcaption><span lang="de">', deCaption, ' (', examMaxPoints, ' erreichbare Punkte):</span><span lang="en">', enCaption, ' (Total points: ', examMaxPoints, ' achievable points):</span></figcaption>'),
		  '<div class="graph rowGraph" style="grid: repeat(1, auto) max-content / max-content repeat(7, auto);">',
			'<div class="graphRowBar valueBar fullBar" style="grid-row: 1; width: 100%;"><span class="markValue">', tail(colnames(values),1), '</span></div>',
    		paste0(sapply(length(values_):1, \(v) paste0('<div class="graphRowBar valueBar ', ifelse(colnames(values_)[v]=="mean", 'meanValue', ''), '" style="grid-row: 1; width: ', values_[v] * 100, '%;"><span class="markValue">', ifelse(colnames(values_)[v]=="mean", paste0('&#x2205; ', round(meanValue * examMaxPoints,0)), colnames(values_)[v]), '</span></div>')), collapse=""),
			'<div class="graphRowBar valueBar nullBar" style="grid-row: 1; width: 0%;"></div>',
			'<div class="graphRowBar overlayBar" style="grid-row: 1; width: 100%;"><span class="absoluteValue"></span></div>',
		  '</div>',
		'</figure>'
	)
  	
	return(cssChart)
}

myExerciseChart = function(id, values, deCaption, enCaption) {
	cssChart = paste0('',
		'<figure id="', id, '" aria-hidden="true">',
			paste0('<figcaption><span lang="de">', deCaption, ' (', nrow(values), ' Aufgaben):</span><span lang="en">', enCaption, ' (', nrow(values), ' Exercises):</span></figcaption>'),
			'<div class="graph columnGraph">',
				'<div class="graphBars">',
					paste0(sapply(1:nrow(values), \(v) {
						paste0('',
							'<div class="graphColumnBar valueBar" style="grid-column: ', v, '; height: 100%;"></div>',
							'<div class="graphColumnBar backgroundBar" style="grid-column: ', v, '; height: ', (1 - values[v,4]) * 100, '%;"></div>',
							'<div class="graphColumnBar overlayBar" style="grid-column: ', v, '; height: 100%;"><span class="absoluteValue">', round(values[v,4]*100, 0), '%</span></div>'
						)
					}), collapse=""),
				'</div>',
				'<div class="graphLabels">',
					paste0(sapply(1:nrow(values), \(v) paste0('<span class="graphColumnLabel" style="grid-column: ', v, '; height: 100%;"><span class="graphColumnLabelText">', v, '</span><span class="graphColumnLabelHoverText"><span lang="de">Aufgabe: ', rownames(values)[v], '</span><span lang="en">Exercise: ', rownames(values)[v], '</span></span></span>')), collapse=""),
				'</div>',
			'</div>',
		'</figure>'
	)
	
	return(cssChart)
}

myGradingChart = function(id, values, validExams, deCaption, enCaption) {
	cssChart = paste0('',
		'<figure id="', id, '" aria-hidden="true">',
			paste0('<figcaption><span lang="de">', deCaption, ' (', validExams, ' gültige Prüfungen):</span><span lang="en">', enCaption, ' (', validExams, ' valid exams):</span></figcaption>'),
			'<div class="graph columnGraph">',
				'<div class="graphBars">',
					paste0(sapply(1:nrow(values), \(v) {
						paste0('',
							'<div class="graphColumnBar valueBar" style="grid-column: ', v, '; height: 100%;"></div>',
							'<div class="graphColumnBar backgroundBar" style="grid-column: ', v, '; height: ', (1 - values[v,2]) * 100, '%;"></div>',
							'<div class="graphColumnBar overlayBar" style="grid-column: ', v, '; height: 100%;"><span class="absoluteValue">', round(values[v,2]*100, 0), '%</span></div>'
						)
					}), collapse=""),
				'</div>',
				'<div class="graphLabels">',
					paste0(sapply(1:nrow(values), \(v) paste0('<span class="graphColumnLabel" style="grid-column: ', v, '; height: 100%;">', rownames(values)[v], '</span>')), collapse=""),
				'</div>',
			'</div>',
		'</figure>'
	)
	
	return(cssChart)
}
