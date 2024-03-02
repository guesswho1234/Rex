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
function setDefaultValue(field, value){
	$('#' + field).val(value);
	Shiny.onInputChange(field, $('#' + field).val());
}

setDefaultValue("examInstitution", "Universität Innsbruck");

setDefaultValue("markThreshold1", 0);
setDefaultValue("markThreshold2", 0.5);
setDefaultValue("markThreshold3", 0.6);
setDefaultValue("markThreshold4", 0.75);
setDefaultValue("markThreshold5", 0.85);

setDefaultValue("markLabel1", "NGD5");
setDefaultValue("markLabel2", "GEN4");
setDefaultValue("markLabel3", "BEF3");
setDefaultValue("markLabel4", "GUT2");
setDefaultValue("markLabel5", "SGT1");
	
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

			fileReader.readAsText(file);
			
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

			fileReader.readAsText(file);
			
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

			fileReader.readAsText(file);
			
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
$('body').on('click', '#createRexParticipantFiles-uibkToolsDl', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createRexParticipantFiles", args: uibkTools['visParticipants']}, {priority: 'event'});
});

$('body').on('click', '#createOlatEvaluationFiles-uibkToolsDl', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createOlatEvaluationFiles", args: uibkTools['rexEvaluation']}, {priority: 'event'});
});

$('body').on('click', '#createGradingFiles-uibkToolsDl', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createGradingFiles", args: {rexEvaluationLists: uibkTools['rexEvaluation'], visGradingLists: uibkTools['visGrading']}}, {priority: 'event'});
});
