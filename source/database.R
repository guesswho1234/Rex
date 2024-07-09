con = function() {
	dbConnect(SQLite(), dbname = "rex.sqlite")
}

discon = function(){
	dbDisconnect(con())
}

Myloginserver <- function(id, sodium_hashed = FALSE, id_col, pw_col, table, log_out = shiny::reactiveVal(), reload_on_logout = FALSE) {
  data <- reactive(DBI::dbGetQuery(con(), paste0("SELECT * FROM ", table)))
  discon()
  
  shiny::moduleServer(id, function(input, output, session) {
    credentials <- shiny::reactiveValues(user_auth = FALSE, 
                                         info = NULL, cookie_already_checked = FALSE)
    shiny::observeEvent(log_out(), {
      if (reload_on_logout) {
        session$reload()
      }
      else {
        shiny::updateTextInput(session, "password", value = "")
        credentials$user_auth <- FALSE
        credentials$info <- NULL
      }
    })
    shiny::observe({
      shinyjs::toggle(id = "panel", condition = !credentials$user_auth)
    })
 
    shiny::observeEvent(input$button, {
      
      row_username <- data()[data()[[id_col]]== input$user_name, id_col]
      
      if (length(row_username)==1) {
        row_password <- data()[data()[[id_col]]== row_username, pw_col]
        if (sodium_hashed) {
          password_match <- sodium::password_verify(row_password, 
                                                    input$password)
        }
        else {
          password_match <- identical(row_password, input$password)
        }
      }else {
        password_match <- FALSE
      }
      
      if (length(row_username) == 1 && password_match) {
        credentials$user_auth <- TRUE
        credentials$info <- data()[data()[[id_col]] == input$user_name, ]
      }
      else {
        shinyjs::toggle(id = "error", anim = TRUE, time = 1, 
                        animType = "fade")
        shinyjs::delay(5000, shinyjs::toggle(id = "error", 
                                             anim = TRUE, time = 1, animType = "fade"))
      }
    })
    shiny::reactive({
      shiny::reactiveValuesToList(credentials)
    })
  })
}

changePassword = function(session, userInfo, c_pw, n_pw1, n_pw2){
	if(userInfo$id == "rex"){
      session$sendCustomMessage("errorUpdateUserProfile", "This user is protected.")
      return(NULL)
    }

	if(!sodium::password_verify(userInfo$pw, c_pw)){
      session$sendCustomMessage("errorUpdateUserProfile", "Incorrect password.")
      return(NULL)
    }

    if (n_pw1 != n_pw2){
      session$sendCustomMessage("errorUpdateUserProfile", "New passwords differ.")
      return(NULL)
    }
    
	tryCatch({
		DBI::dbExecute(con(), "UPDATE user SET pw = ? WHERE id = ?", c(sodium::password_store(n_pw2), userInfo$id))
		session$sendCustomMessage("closeUserProfile", 1)
	},
	error = function(e) {
		session$sendCustomMessage("errorUpdateUserProfile", "Unknown error.")
	})
}