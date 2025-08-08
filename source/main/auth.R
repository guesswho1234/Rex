dbname = "rex.sqlite"
table = "user"

con = function() {
	dbConnect(SQLite(), dbname = dbname)
}

discon = function(){
	dbDisconnect(con())
}

loginModule = function(id, sodium_hashed = FALSE, id_col, pw_col, pm_col, table, log_out = shiny::reactiveVal(), reload_on_logout = FALSE) {
  shiny::moduleServer(id, function(input, output, session) {
    ns = session$ns

    # Load config
    sso_cfg = load_sso_config()
    sso_mode = !is.null(sso_cfg)

    # Set login button mode
    if(sso_mode){
      shinyjs::runjs(sprintf(
        "$('#login-button').attr('class', 'btn btn-sso');"
      ))
    }

    user_data = reactiveValues(user_auth = FALSE, info = NULL, mode = NULL)
    
    # SSO
    observeEvent(input$button, {
      if (!sso_mode) return()
      
      log_(content="Logging in via SSO.")
      
      redirect_url = httr::modify_url(sso_cfg$auth_url, query = list(
        client_id = sso_cfg$client_id,
        response_type = "code",
        scope = sso_cfg$scope,
        redirect_uri = sso_cfg$redirect_uri
      ))

      session$sendCustomMessage(type = 'redirect', message = redirect_url)
    })

    observeEvent(session$clientData$url_search, {
      if (!sso_mode) return()

      query = shiny::parseQueryString(session$clientData$url_search)

      if (!is.null(query$code)) {
        # Token exchange
        token = tryCatch({
          res = httr::POST(
            url = sso_cfg$token_url,
            body = list(
              grant_type = "authorization_code",
              code = query$code,
              redirect_uri = sso_cfg$redirect_uri,
              client_id = sso_cfg$client_id,
              client_secret = sso_cfg$client_secret
            ),
            encode = "form"
          )
          
          token_data = httr::content(res, as = "parsed")
          token_data
        }, error = function(e) NULL)
        

        if (!is.null(token)) {
          userinfo = tryCatch({
            httr::content(
              httr::GET(
                url = sso_cfg$userinfo_url,
                httr::add_headers(
                  Authorization = paste("Bearer", token$access_token)
                )
              ),
              as = "parsed"
            )
          }, error = function(e) NULL)

          if (!is.null(userinfo$email)) {
            user_data$mode = "sso"
            user_data$user_auth = TRUE
            user_data$info = userinfo # google oauth2 user info fields -> c("sub", "picture", "email", "email_verified")
            
            # fields needed inside the app
            user_data$info$id = user_data$info$email # set id to whatever should be isplayed in the user profile
            user_data$info$pm = 105 # default permission code
          }
        }
      }
    })

    # Shinyauthr fallback
    user_data_fallback = if (!sso_mode) {
      log_(content="Logging in via shinyauthr.")
      
      # read database
      query = DBI::sqlInterpolate(DBI::ANSI(), "SELECT * FROM ?table",
                                  table = DBI::dbQuoteIdentifier(DBI::ANSI(), table))
      
      data = reactive(DBI::dbGetQuery(con(), query))
      discon()
      
      fallback_credentials = reactiveValues(user_auth = FALSE, info = NULL)
      
      observeEvent(input$button, {
        row_username = data()[data()[[id_col]] == input$user_name, id_col]
        
        if (length(row_username)==1) {
          row_password = data()[data()[[id_col]] == row_username, pw_col]
          if (sodium_hashed) {
            password_match = sodium::password_verify(row_password, 
                                                     input$password)
          }
          else {
            password_match = identical(row_password, input$password)
          }
        }else {
          password_match = FALSE
        }
        
        if (length(row_username) == 1 && password_match) {
          fallback_credentials$user_auth = TRUE
          fallback_credentials$info = data()[data()[[id_col]] == row_username,][c(id_col, pm_col)]
        }
        else {
          shinyjs::toggle(id =  "error", anim = TRUE, time = 1, animType = "fade")
          shinyjs::delay(5000, shinyjs::toggle(id = "error", anim = TRUE, time = 1, animType = "fade"))
        }
      })
      
      reactive({
        list(
          user_auth = fallback_credentials$user_auth,
          info = fallback_credentials$info
        )
      })
    } else NULL

    # set user data to fallback credentials
    observe({
      fallback = if (!is.null(user_data_fallback)) user_data_fallback() else NULL
      if (!sso_mode && !is.null(fallback) && fallback$user_auth) {
        user_data$mode = "shinyauthr"
        user_data$user_auth = TRUE
        user_data$info = fallback$info
      }
    })
    
    # logout observer
    shiny::observeEvent(log_out(), {
      if (reload_on_logout) {
        session$reload()
      }
      else {
        shiny::updateTextInput(session, "password", value = "")
        user_data$mode = NULL
        user_data$user_auth = FALSE
        user_data$info = NULL
      }
    })
    
    # manage visibility of login panel
    observe({
      hide_panel = user_data$user_auth
      hide_user_password = sso_mode
      shinyjs::toggle(id = "panel", condition = !hide_panel)
      shinyjs::toggle(id = "user_name", condition = !hide_user_password)
      shinyjs::toggle(id = "password", condition = !hide_user_password)
      shinyjs::toggle(id = "sso_title", condition = hide_user_password)
    })

    # return user data
    return(reactive({
      list(
        mode = user_data$mode,
        user_auth = user_data$user_auth,
        info = user_data$info
      )
    }))
  })
}

changePassword = function(session, userInfo, c_pw, n_pw1, n_pw2){
  if(!sodium::password_verify(userInfo$pw, c_pw)){
    session$sendCustomMessage("errorUpdateUserProfile", '<span lang="de">Falsches Passwort.</span><span lang="en">Incorrect password.</span>')
    return(NULL)
  }
  
  if (n_pw1 != n_pw2){
	
    session$sendCustomMessage("errorUpdateUserProfile", '<span lang="de">Neue Passwörter unterscheiden sich.</span><span lang="en">New passwords differ.</span>')
    return(NULL)
  }
  
	tryCatch({  
	  query = DBI::sqlInterpolate(DBI::ANSI(), "UPDATE ?table SET pw = ?pw WHERE id = ?id",
	                              table = DBI::dbQuoteIdentifier(ANSI(), table),
	                              pw = sodium::password_store(n_pw2),
	                              id = userInfo$id)

		DBI::dbExecute(con(), query)
	  discon()
	  session$sendCustomMessage("closeUserProfile", 1)
		session$reload()
	},
	error = function(e) {
		session$sendCustomMessage("errorUpdateUserProfile", '<span lang="de">Unbekannter Fehler.</span><span lang="en">Unknown error..</span>')
	})
}

load_sso_config = function(path = "sso_config.csv") {
  if (!file.exists(path)) return(NULL)
  
  cfg_raw = read.csv(path, stringsAsFactors = FALSE)
  cfg = as.list(setNames(cfg_raw$value, cfg_raw$key))
  
  if (!nzchar(cfg[["client_id"]])) return(NULL)
  
  return(cfg)
}

