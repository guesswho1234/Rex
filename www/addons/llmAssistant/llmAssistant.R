# SOURCE ------------------------------------------------------------------
source("./source/filesAndDirectories.R")
source("./source/customElements.R")

# PACKAGES

# FUNCTIONS ------------------------------------------------------------------
  # INTEGRATION ------------------------------------------------------------- 
  llmAssistant_callModules = function(){
  }
  
  llmAssistant_observers = function(input){
    observeEvent(input$callAddonFunction, {
		result = get(input$callAddonFunction$func)(input$callAddonFunction$args)
		llmAssistantData(result)
    })
  }
  
# CONTENT ------------------------------------------------------------------
llmAssistantData = reactiveVal()

llmAssistant_fields = list()
