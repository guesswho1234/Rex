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
