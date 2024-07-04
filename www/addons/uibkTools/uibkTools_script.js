/* --------------------------------------------------------------
DATA
-------------------------------------------------------------- */
let uibkTools = new Object();
uibkTools['visParticipants'] = new Array();
uibkTools['rexEvaluation'] = new Array(); 
uibkTools['visGrading'] = new Array();

/* --------------------------------------------------------------
ADDON DEFAULT INPUT VALUES
-------------------------------------------------------------- */
setShinyInputValue("examInstitution", "Universität Innsbruck");

setShinyInputValue("markThreshold1", 0);
setShinyInputValue("markThreshold2", 0.5);
setShinyInputValue("markThreshold3", 0.6);
setShinyInputValue("markThreshold4", 0.75);
setShinyInputValue("markThreshold5", 0.85);

setShinyInputValue("markLabel1", "NGD5");
setShinyInputValue("markLabel2", "GEN4");
setShinyInputValue("markLabel3", "BEF3");
setShinyInputValue("markLabel4", "GUT2");
setShinyInputValue("markLabel5", "SGT1");
	
/* --------------------------------------------------------------
VIS PARTICIPANT FILES
-------------------------------------------------------------- */
function visParticipantsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'csv') {
			addVisParticipantsFile(file);
		}
	});
}

function addVisParticipantsFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	let fileReader;
	let fileName;
	
	switch(fileExt) {
		case 'csv':
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];
			
			fileReader.onload = function(fileLoadedEvent) {
				csv = fileLoadedEvent.target.result;
				uibkTools['visParticipants'].push([fileName, fileExt, csv]);
			};

			fileReader.readAsText(file, "ansi_x3.4-1968");
			
			$('#visParticipantsFiles_list_items').append('<div class="visParticipantsFileItem"><span class="visParticipantsFileName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

$('#visParticipantsFiles_list_items').on('click', '.visParticipantsFileItem', function() {
	const fileID = $(this).index('.visParticipantsFileItem');
	uibkTools['visParticipants'].splice(fileID, 1);
	$(this).remove();
});

/* --------------------------------------------------------------
REX EVALUATION FILES
-------------------------------------------------------------- */
function rexEvaluationFileDialog(items) {
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
				uibkTools['rexEvaluation'].push([fileName, fileExt, csv]);
			};

			fileReader.readAsText(file, "ansi_x3.4-1968");
			
			$('#rexEvaluationFiles_list_items').append('<div class="rexEvaluationFileItem"><span class="rexEvaluationFileName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

$('#rexEvaluationFiles_list_items').on('click', '.rexEvaluationFileItem', function() {
	const fileID = $(this).index('.rexEvaluationFileItem');
	uibkTools['rexEvaluation'].splice(fileID, 1);
	$(this).remove();
});


/* --------------------------------------------------------------
VIS GRADING FILES
-------------------------------------------------------------- */
function visGradingFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'csv') {
			addVisGradingFile(file);
		}
	});
}

function addVisGradingFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	let fileReader;
	let fileName;
	
	switch(fileExt) {
		case 'csv':
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				csv = fileLoadedEvent.target.result;
				uibkTools['visGrading'].push([fileName, fileExt, csv]);
			};

			fileReader.readAsText(file, "ansi_x3.4-1968");
			
			$('#visGradingFiles_list_items').append('<div class="visGradingFileItem"><span class="visGradingFileName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

$('#visGradingFiles_list_items').on('click', '.visGradingFileItem', function() {
	const fileID = $(this).index('.visParticipantsFileItem');
	uibkTools['visGrading'].splice(fileID, 1);
	$(this).remove();
});


/* --------------------------------------------------------------
DOWNLOAD CONVERTED FILES
-------------------------------------------------------------- */
$('body').on('click', '#createRexParticipantsList-uibkToolsDl', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createRexParticipantsList", args: uibkTools['visParticipants']}, {priority: 'event'});
});

$('body').on('click', '#createOlatEvaluationList-uibkToolsDl', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createOlatEvaluationList", args: uibkTools['rexEvaluation']}, {priority: 'event'});
});

$('body').on('click', '#createGradingLists-uibkToolsDl', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createGradingLists", args: {rexEvaluationLists: uibkTools['rexEvaluation'], visGradingLists: uibkTools['visGrading']}}, {priority: 'event'});
});
