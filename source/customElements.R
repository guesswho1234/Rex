myActionButton = function(id, deText, enText, icon){
  tags$button(id = id, class = "btn btn-default action-button shiny-bound-input", type="button", myButtonStyle(deText, enText, icon))
}

myDownloadButton = function(id, deText="Speichern", enText="Save"){
  tags$a(id = id, class = "btn btn-default shiny-download-link", href = "", 
         target = "_blank", type = "button", download = NA, NULL, myButtonStyle(deText, enText, "fa-solid fa-download"))
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
