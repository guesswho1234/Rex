myUserProfileInterface = function() {
  content = paste0('<div class="well">
     <h2 class="text-center" style="padding-top: 0;">
     	<span lang="de">Benutzerprofil</span><span lang="en">User Profile</span>
     </h2>
        <div class="form-group shiny-input-container">
     	<label class="control-label" id="current-login-user_name-label" for="current-login-user_name">
            <i class="far fa-user" role="presentation" aria-label="user icon"></i>
			<span lang="de">Benutzername</span><span lang="en">User name</span>
     	</label>
     	<input id="current-login-user_name" type="text" class="form-control shinyjs-resettable shiny-bound-input" value="" disabled>
        </div>
        <div class="form-group shiny-input-container">
			<label class="control-label" id="current-login-password-label" for="current-login-password">
				<i class="fas fa-unlock-keyhole" role="presentation" aria-label="unlock-keyhole icon"></i>
				<span lang="de">Aktuelles Passwort</span><span lang="en">Current password</span>
			</label>
			<input id="current-login-password" type="password" class="form-control shinyjs-resettable shiny-bound-input" value="" data-shinyjs-resettable-id="login-password1" data-shinyjs-resettable-type="Password" data-shinyjs-resettable-value="">
			<br/>
			<label class="control-label" id="new-login-password-label1" for="new-login-password1">
				<i class="fas fa-unlock-keyhole" role="presentation" aria-label="unlock-keyhole icon"></i>
				<span lang="de">Neues Passwort</span><span lang="en">New password</span>
			</label>
			<input id="new-login-password1" type="password" class="form-control shinyjs-resettable shiny-bound-input" value="" data-shinyjs-resettable-id="login-password1" data-shinyjs-resettable-type="Password" data-shinyjs-resettable-value="">
			<br/>
			<label class="control-label" id="new-login-password-label2" for="new-login-password2">
				<i class="fas fa-unlock-keyhole" role="presentation" aria-label="unlock-keyhole icon"></i>
				<span lang="de">Neues Passwort wiederholen</span><span lang="en">Repeat new password</span>
			</label>
			<input id="new-login-password2" type="password" class="form-control shinyjs-resettable shiny-bound-input" value="" data-shinyjs-resettable-id="login-password2" data-shinyjs-resettable-type="Password" data-shinyjs-resettable-value="">
		</div>
		<div style="text-align: center;">
			<button class="btn btn-default action-button btn-primary shiny-bound-input" id="cancle-change-password-button" style="color: white;" type="button">
			<span lang="de">Abbrechen</span><span lang="en">Cancle</span>
			</button>
			<button class="btn btn-default action-button btn-primary shiny-bound-input" id="change-password-button" style="color: white;" type="button">
			<span lang="de">Passwort ändern</span><span lang="en">Change password</span>
			</button>
		</div>
		<div id="change-password-error" class="" style="display: none;">
			<p style="color: red; font-weight: bold; padding-top: 5px;" class="text-center"></p>
		</div>
   </div>', collapse='')

  return(HTML(content))
}

myKillWorkerProcessButton = function() {
  tags$button(id='killWorkerProcess-button', class='btn btn-default action-button shiny-bound-input', type='button', tags$span(HTML('<span lang="de">Abbrechen</span><span lang="en">Cancle</span>')))
}

myUserProfileButton = function() {
  tags$button(id='profile-button', class='btn btn-default action-button shiny-bound-input', type='button', tags$span(HTML('<span lang="de">Benutzer</span><span lang="en">User</span>')))
}

myUserLogoutButton = function() {
  tags$button(id='logout-button', class='btn btn-default action-button btn-danger shiny-bound-input', type='button', tags$span(HTML('<span lang="de">Ausloggen</span><span lang="en">Log out</span>')))
}

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

myButtonStyle = function(deText, enText, icon="") {
  if(icon != "")
	icon = paste0('<span class="iconButton"><i class="', icon, '"></i></span>')
	
  text = paste0('<span class="textButton"><span lang="de">', deText, '</span><span lang="en">', enText, '</span></span>')
  text = paste0('<span class="textButton"><span lang="de">', deText, '</span><span lang="en">', enText, '</span></span>')
  
  return(tags$span(HTML(paste0(icon, text, collapse=""))))
}

myGradingKey = function(size) {
	if (!is.numeric(size) || is.infinite(size) || size < 2)
		size = 2
		
	thresholdValues = round(c(0.5, seq(0.5+0.5/size, 1, 0.5/size)), 2)
    markValues = size:1	
	
	gradingKey = sapply(1:size, \(x){
		gradingKeyItem = myGradingkeyItem(x, thresholdValues[x], markValues[x])
	})
	
	return(HTML(paste0(gradingKey, collapse="")))
} 

myGradingKeyThresholdItem = function(index, value, disabled){
	paste0('<td><div class="form-group shiny-input-container', ifelse(disabled,' shinyjs-disabled disabled" disabled="disabled"','"'), '><input id="markThreshold', index, '" type="text" class="markThreshold form-control shiny-bound-input shinyjs-resettable', ifelse(disabled,' disabled',''), '" value="', value, '" data-shinyjs-resettable-id="markThreshold', index, '" data-shinyjs-resettable-type="Text" data-shinyjs-resettable-value=""', ifelse(disabled,' disabled=""',''), '></td>')
}

myGradingKeyMarkItem = function(index, value){
	paste0('<td><div class="form-group shiny-input-container"><input id="markLabel', index, '" type="text" value="', value, '" class="markLabel form-control shiny-bound-input shinyjs-resettable" data-shinyjs-resettable-id="markLabel', index, '" data-shinyjs-resettable-type="Text" data-shinyjs-resettable-value=""></div></td>')
}


myGradingkeyItem = function(index, thresholdValue, markValue) {
  firstItem = index == 1
  removable = index > 2
  
  itemClasses = paste0('gradingKeyItem ', ifelse(removable,"removable",""))

  itemThresholdItem = myGradingKeyThresholdItem(index, thresholdValue, firstItem)
  
  itemMarkItem = myGradingKeyMarkItem(index, markValue)
  
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
	'<div id="', idContainer, '" class="fileImportContainer">',
		'<label class="', labelClass, '" for="', idInput, '">',
			'<div class="fileImportButton ', buttonClass, '">',
				'<span class="iconButton"><i class="fa-solid fa-upload"></i></span>',
				'<span class="textButton"><span lang="de">Importieren</span><span lang="en">Import</span></span>',
			'</div>',
			'<input type="file" id="', idInput, '" onchange="', javascriptFunction, '" multiple>',
		'</label>',
		'<div id="', idFiles, '" class="fileImportFiles">',
			'<div id="', idFileList, '" class="itemList">',
				'<div id="', idFileListItems, '" class="listItems">',
				'</div>',
			'</div>',
		'</div>',
	'</div>'
	)
	
	return(HTML(fileImport))
}

myFileData = function(session, path, name, ext, js_function) {
  file = paste0(path, name, ".", ext)
  file = openssl::base64_encode(readBin(file, "raw", n = file.info(file)$size))
  
  session$sendCustomMessage(js_function, list(name, ext, file))
}

myEvaluationCharts = function(chartData, examMaxPoints, validExams, showGradingChart) {
	pointsChart = myPointsChart(chartData$ids[[1]], chartData$values[[1]], examMaxPoints, chartData$deCaptions[[1]], chartData$enCaptions[[1]])
	
	exerciseChart = myExerciseChart(chartData$ids[[2]], chartData$values[[2]], chartData$deCaptions[[2]], chartData$enCaptions[[2]])

	if(showGradingChart[1] == FALSE)
		return(HTML(paste0(pointsChart, exerciseChart)))

	gradingChart = myGradingChart(chartData$ids[[3]], chartData$values[[3]], validExams, chartData$deCaptions[[3]], chartData$enCaptions[[3]])

	return(HTML(paste0(pointsChart, exerciseChart, gradingChart)))
}

myPointsChart = function(id, values, examMaxPoints, deCaption, enCaption) {
  values = values[,-1,drop=F]
  meanValue = values[1]
  
  values_ = values
  
  if(length(values) > 1) {
    names(values_) = c(names(values)[1], "", names(values)[-c(1,length(values))])
    values_ = values_[,as.numeric(values_) > 0 | names(values_) == "mean",drop=FALSE]
    values_ = values_[,order(as.numeric(values_)),drop=FALSE]
  } else {
    names(values) = ""
  }
  
	cssChart = paste0('',
		'<figure id="', id, '" aria-hidden="true">',
			paste0('<figcaption><span lang="de">', deCaption, ' (', examMaxPoints, ' erreichbare Punkte):</span><span lang="en">', enCaption, ' (', examMaxPoints, ' achievable points):</span></figcaption>'),
		  '<div class="graph rowGraph" style="grid: repeat(1, auto) max-content / max-content repeat(7, auto);">',
			'<div class="graphRowBar valueBar fullBar" style="grid-row: 1; width: 100%;"><span class="markValue">', tail(names(values), 1), '</span></div>',
    		paste0(sapply(ncol(values_):1, \(v) paste0('<div class="graphRowBar valueBar ', ifelse(names(values_)[v]=="mean", 'meanValue', ''), '" style="grid-row: 1; width: ', 
    		                                           ifelse(as.numeric(values_[,v]) == 1, 'calc(100% - 2px);', paste0(as.numeric(values_[,v]) * 100, '%;')), '"><span class="markValue">', ifelse(names(values_)[v]=="mean", paste0('&#x2205; ', round(as.numeric(meanValue) * as.numeric(examMaxPoints),0)), names(values_)[v]), '</span></div>')), collapse=""),
			'<div class="graphRowBar valueBar nullBar" style="grid-row: 1; width: 0%;"></div>',
			'<div class="graphRowBar overlayBar" style="grid-row: 1; width: 100%;"><span class="absoluteValue"></span></div>',
		  '</div>',
		'</figure>'
	)
  	
	return(cssChart)
}

myExerciseChart = function(id, values, deCaption, enCaption) {
  names = values[,1]
  values = values[,-1,drop=F]
  
	cssChart = paste0('',
		'<figure id="', id, '" aria-hidden="true">',
			paste0('<figcaption><span lang="de">', deCaption, ' (', nrow(values), ' Aufgaben):</span><span lang="en">', enCaption, ' (', nrow(values), ' Exercises):</span></figcaption>'),
			'<div class="graph columnGraph">',
				'<div class="graphBars">',
					paste0(sapply(1:nrow(values), \(v) {
						paste0('',
							'<div class="graphColumnBar valueBar" style="grid-column: ', v, '; height: 100%;"></div>',
							'<div class="graphColumnBar backgroundBar" style="grid-column: ', v, '; height: ', (1 - as.numeric(values[v,4])) * 100, '%;"></div>',
							'<div class="graphColumnBar overlayBar" style="grid-column: ', v, '; height: 100%;"><span class="absoluteValue">', round(as.numeric(values[v,4]) * 100, 0), '%</span></div>'
						)
					}), collapse=""),
				'</div>',
				'<div class="graphLabels">',
					paste0(sapply(1:nrow(values), \(v) paste0('<span class="graphColumnLabel" style="grid-column: ', v, '; height: 100%;"><span class="graphColumnLabelText">', v, '</span><span class="graphColumnLabelHoverText"><span lang="de">Aufgabe: ', names[v], '</span><span lang="en">Exercise: ', names[v], '</span></span></span>')), collapse=""),
				'</div>',
			'</div>',
		'</figure>'
	)
	
	return(cssChart)
}

myGradingChart = function(id, values, validExams, deCaption, enCaption) {
  names = values[,1]
  values = values[,-1,drop=F]
  
	cssChart = paste0('',
		'<figure id="', id, '" aria-hidden="true">',
			paste0('<figcaption><span lang="de">', deCaption, ' (', validExams, ' gültige Prüfungen):</span><span lang="en">', enCaption, ' (', validExams, ' valid exams):</span></figcaption>'),
			'<div class="graph columnGraph">',
				'<div class="graphBars">',
					paste0(sapply(1:nrow(values), \(v) {
						paste0('',
							'<div class="graphColumnBar valueBar" style="grid-column: ', v, '; height: 100%;"></div>',
							'<div class="graphColumnBar backgroundBar" style="grid-column: ', v, '; height: ', (1 - as.numeric(values[v,2])) * 100, '%;"></div>',
							'<div class="graphColumnBar overlayBar" style="grid-column: ', v, '; height: 100%;"><span class="absoluteValue">', round(as.numeric(values[v,2]) * 100, 0), '%</span></div>'
						)
					}), collapse=""),
				'</div>',
				'<div class="graphLabels">',
					paste0(sapply(1:nrow(values), \(v) paste0('<span class="graphColumnLabel" style="grid-column: ', v, '; height: 100%;">', names[v], '</span>')), collapse=""),
				'</div>',
			'</div>',
		'</figure>'
	)
	
	return(cssChart)
}
