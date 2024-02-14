$('body').on('click', '#visParticipantsToRexParticipants', function() {
	Shiny.onInputChange("callAddonFunction", {func: "visParticipantsToRexParticipants", args: 0}, {priority: 'event'});
});

$('body').on('click', '#rexEvalToOlatEval', function() {
	Shiny.onInputChange("callAddonFunction", {func: "rexEvalToOlatEval", args: 0}, {priority: 'event'});
});

$('body').on('click', '#rexEvalToVISgrading', function() {
	Shiny.onInputChange("callAddonFunction", {func: "rexEvalToVISgrading", args: 0}, {priority: 'event'});
});
