permissionCodes = read.csv2("./source/main/permission/permissionCodes.csv")

prime_factors = function(x, i, factors = NULL){
	if(x < i[1]) factors
	else if(! x %% i[1]) prime_factors(x/i[1], i, c(factors, i[1]))
	else  prime_factors(x, i[-1], factors)
}


checkPermission = function(code, userPm){
	permissions = prime_factors(userPm, permissionCodes$require)

	if(code %in% permissionCodes$code[permissionCodes$require %in% permissions])
		return(list(hasPermission=TRUE, code=code, response=data.frame(en="", de=""))) 
		
	return(list(hasPermission=FALSE, code=code, response=permissionCodes[permissionCodes$code == code,c("en", "de")]))
}

getNoPermissionMessage = function(code, response, html=TRUE){
	if(html){
		noPermissionMessage = lapply(names(response), function(lang){
			paste0("<span lang=\"", lang, "\">", response[[lang]], "</span>") 
		})
		
		noPermissionMessage = paste0(noPermissionMessage, collapse="")
		noPermissionMessage = paste0("<span class=\"noPermissionMessage\">", code, ": ", noPermissionMessage, "</span>", collapse="")
		
		return(noPermissionMessage)
	}
	
	return(c(code=code, response))
}
