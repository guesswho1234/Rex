let uibkTools = new Object();
uibkTools['visParticipantLists'] = new Array();
uibkTools['rexEvaluationLists'] = new Array(); 
uibkTools['visGradingLists'] = new Array();

/* --------------------------------------------------------------
ADDON DEFAULT INPUT VALUES
-------------------------------------------------------------- */
function setDefaultValue(field, value){
	$('#' + field).val(value);
	Shiny.onInputChange(field, $('#' + field).val());
}

setDefaultValue("examInstitution", "Universität Innsbruck");
setDefaultValue("markLabel1", "NGD5");
setDefaultValue("markLabel2", "GEN4");
setDefaultValue("markLabel3", "BEF3");
setDefaultValue("markLabel4", "GUT2");
setDefaultValue("markLabel5", "SGT1");
	
/* --------------------------------------------------------------
VIS PARTICIPANT FILES
-------------------------------------------------------------- */
function loadVisParticipantListsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'csv') {
			addVisParticipantListFile(file);
		}
	});
}

function addVisParticipantListFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	let fileReader;
	let fileName;
	
	switch(fileExt) {
		case 'csv':
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];
			
			fileReader.onload = function(fileLoadedEvent) {
				csv = fileLoadedEvent.target.result;
				uibkTools['visParticipantLists'].push([fileName, fileExt, csv]);
			};

			fileReader.readAsText(file);
			
			$('#visParticipantListFile_list_items').append('<div class="visParticipantListFileItem"><span class="visParticipantListFileName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

$('#visParticipantListFile_list_items').on('click', '.visParticipantListFileItem', function() {
	const fileID = $(this).index('.visParticipantListFileItem');
	uibkTools['visParticipantLists'].splice(fileID, 1);
	$(this).remove();
});

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

			fileReader.readAsText(file);
			
			$('#rexEvaluationListFile_list_items').append('<div class="rexEvaluationListFileItem"><span class="rexEvaluationListFileName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

$('#rexEvaluationListFile_list_items').on('click', '.rexEvaluationListFileItem', function() {
	const fileID = $(this).index('.rexEvaluationListFileItem');
	uibkTools['rexEvaluationLists'].splice(fileID, 1);
	$(this).remove();
});


/* --------------------------------------------------------------
VIS GRADING FILES
-------------------------------------------------------------- */
function loadvisGradingListsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'csv') {
			addVisGradingListFile(file);
		}
	});
}

function addVisGradingListFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	let fileReader;
	let fileName;
	
	switch(fileExt) {
		case 'csv':
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				csv = fileLoadedEvent.target.result;
				uibkTools['visGradingLists'].push([fileName, fileExt, csv]);
			};

			fileReader.readAsText(file);
			
			$('#visGradingListFile_list_items').append('<div class="visGradingListFileItem"><span class="visGradingListFileName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

$('#visGradingListFile_list_items').on('click', '.visGradingListFileItem', function() {
	const fileID = $(this).index('.visParticipantListFileItem');
	uibkTools['visGradingLists'].splice(fileID, 1);
	$(this).remove();
});


/* --------------------------------------------------------------
...
-------------------------------------------------------------- */
$('body').on('click', '#downloadRexParticipantsList', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createRexParticipantsList", args: uibkTools['visParticipantLists']}, {priority: 'event'});
});

$('body').on('click', '#downloadOlatEvalList', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createOlatEvalList", args: uibkTools['rexEvaluationLists']}, {priority: 'event'});
});

$('body').on('click', '#downloadVISgradingList', function() {
	Shiny.onInputChange("callAddonFunction", {func: "createGradingLists", args: {rexEvaluationLists: uibkTools['rexEvaluationLists'], visGradingLists: uibkTools['visGradingLists']}}, {priority: 'event'});
});
