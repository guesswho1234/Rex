let uibkTools = new Object();
uibkTools['visParticipantLists'] = new Array();
uibkTools['rexEvaluationLists'] = new Array(); 

/* --------------------------------------------------------------
VIS PARTICIPANT FILES
-------------------------------------------------------------- */
function loadVisParticipantListsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'xslx' || fileExt == 'csv') {
			addVisParticipantListFile(file);
		}
	});
}

function addVisParticipantListFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	let fileReader;
	let fileName;
	
	switch(fileExt) {
		case 'xslx':
			break;
		case 'csv':
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				csv = fileLoadedEvent.target.result;
				uibkTools['visParticipantLists'].push([fileName, fileExt, csv]);
			};

			// fileReader.readAsText(file);
			
			// $('#examRegisteredParticipants_list_items').empty();
			// $('#examRegisteredParticipants_list_items').append('<div class="examRegisteredParticipantsItem"><span class="examRegisteredParticipantsName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

/* --------------------------------------------------------------
REX EVALUATION FILES
-------------------------------------------------------------- */
function loadRexEvaluationListsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'csv') {
			addRexEvaluationListFile(file);
		}
	});
}

function addRexEvaluationListFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	let fileReader;
	let fileName;
	
	switch(fileExt) {
		case 'csv':
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				csv = fileLoadedEvent.target.result;
				uibkTools['rexEvaluationLists'].push([fileName, fileExt, csv]);
			};

			// fileReader.readAsText(file);
			
			// $('#examRegisteredParticipants_list_items').empty();
			// $('#examRegisteredParticipants_list_items').append('<div class="examRegisteredParticipantsItem"><span class="examRegisteredParticipantsName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

/* --------------------------------------------------------------
...
-------------------------------------------------------------- */
$('body').on('click', '#visParticipantsToRexParticipants', function() {
	Shiny.onInputChange("callAddonFunction", {func: "visParticipantsToRexParticipants", args: 0}, {priority: 'event'});
});

$('body').on('click', '#rexEvalToOlatEval', function() {
	Shiny.onInputChange("callAddonFunction", {func: "rexEvalToOlatEval", args: 0}, {priority: 'event'});
});

$('body').on('click', '#rexEvalToVISgrading', function() {
	Shiny.onInputChange("callAddonFunction", {func: "rexEvalToVISgrading", args: 0}, {priority: 'event'});
});
