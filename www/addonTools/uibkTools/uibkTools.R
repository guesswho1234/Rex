uibkTools_fields = list(textInput_visParticipantsToRexParticipants = textAreaInput("visParticipantsToRexParticipants", label = NULL, value = NULL),
                        textInput_rexEvalToOlatEval = textAreaInput("rexEvalToOlatEval", label = NULL, value = NULL),
                        textInput_rexEvalToVISgrading = textAreaInput("rexEvalToVISgrading", label = NULL, value = NULL))
						
visParticipantsToRexParticipants = function() {
	return("returnValue: visParticipantsToRexParticipants");
}

rexEvalToOlatEval = function() {
	return("returnValue: rexEvalToOlatEval");
}

rexEvalToVISgrading = function() {
	return("returnValue: rexEvalToVISgrading");
}						
