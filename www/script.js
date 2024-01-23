/**
* Script
*
*/

/* --------------------------------------------------------------
 DOCUMENT READY 
-------------------------------------------------------------- */
$(document).ready(function () {
	iuf['exercises'] = new Array();
	iuf['examAdditionalPdf'] = new Array(); 
	iuf['examEvaluation'] = new Array();
	iuf['examEvaluation']['scans'] = new Array(); 
	iuf['examEvaluation']['registeredParticipants'] = new Array();
	iuf['examEvaluation']['solutions'] = new Array();
	iuf['examEvaluation']['scans_reg_fullJoinData'] = new Array();
});

/* --------------------------------------------------------------
RSHINY CONNECTION 
-------------------------------------------------------------- */
let connected = false;
$(document).on('shiny:disconnected', function(event) {
   connected = false;
   $('#heart span').addClass('dead');
}).on('shiny:connected', function(event) {
   connected = true;
});

/* --------------------------------------------------------------
RSHINY SESSION 
-------------------------------------------------------------- */
$(document).on('shiny:sessioninitialized', function(event) {
	$('#s_initialSeed').html(itemSingle($('#seedValueExercises').val(), 'greenLabel'));
	$('#s_numberOfExams').html(itemSingle($('#numberOfExams').val(), 'grayLabel'));
	
	f_hotKeys();
	f_buttonMode();
	f_langDeEn();
	resetOutputFields();
});

/* --------------------------------------------------------------
DEBUG 
-------------------------------------------------------------- */
Shiny.addCustomMessageHandler('debugMessage', function(message) {
	console.log("DEBUG MESSAGE:\n")
	console.log(message)
	console.log("\n\n")
});

/* --------------------------------------------------------------
 HEARTBEAT 
-------------------------------------------------------------- */
Shiny.addCustomMessageHandler('heartbeat', function(heartbeat) {
	ping();
});

function ping(){
	$('#heart').addClass("ping");

	setTimeout(pong, 300); 
}

function pong(){
	$('#heart').removeClass("ping");
}

$('body').on('click', '#heart.ping', function(e) {
	alert("Hey, stop that!");
});

/* --------------------------------------------------------------
 KEY EVENTS 
-------------------------------------------------------------- */
$('#hotkeysActiveContainer').click(function () {
	setHotkeysCookie(+!getHotkeysCookie());
	f_hotKeys();
});

function f_hotKeys() {
	if (getHotkeysCookie()) {
		$('#hotkeysActiveContainer span').addClass('active');
		return;
	} 
	
	$('#hotkeysActiveContainer span').removeClass('active');
}

Shiny.addCustomMessageHandler('f_hotKeys', function(x) {
	f_hotKeys();
});

function setHotkeysCookie(hotkeysActive) {
    document.cookie = 'REX_JS_hotkeys=' + hotkeysActive + ';path=/;SameSite=Lax';
}

function getHotkeysCookie() {
    const name = 'REX_JS_hotkeys';
    const ca = document.cookie.split(';');
	
    for(let i=0;i < ca.length;i++) {
        let c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(name) == 0) {
			return c.substring(name.length + 1,c.length) === "1";
		}
    }
    return null;
}

document.onkeyup = function(evt) {
	if($('#disableOverlay').hasClass("active")) return;
	if(!getHotkeysCookie()) return;
	
	const evtobj = window.event? event : evt
	
	if( $('#exercises').hasClass('active') ) {
		const targetEditable = $(evtobj.target).attr('contenteditable');

		if (evtobj.shiftKey && evtobj.keyCode == 70 && !targetEditable) {
			const searchField = $('#searchExercises').find('input');
			const searchValLength = searchField.val().length;
			
			searchField.focus();
			searchField[0].setSelectionRange(searchValLength, searchValLength);
		}
	}
}

document.onkeydown = function(evt) {
	if(!getHotkeysCookie()) return;
	
	const evtobj = window.event? event : evt
	
	// INSPECT SCAN
	if( $('#inspectScanButtons').length == 1 ) {
		switch (evtobj.keyCode) {
			case 13: // enter
				applyInspect();
				break;
			case 27: // ESC
				cancleInspect();
				break;
		}
	} 
	
	// EXERCISES
	if($('#disableOverlay').hasClass("active")) return;
	if( $('#exercises').hasClass('active') ) {	
		if ($(evtobj.target).is('input') && evtobj.keyCode == 13) { // enter
			$(evtobj.target).change();
			$(evtobj.target).blur();
		}
		
		const targetEditable = $(evtobj.target).attr('contenteditable');
	
		if (evtobj.keyCode == 27) { // ESC
			if(targetEditable) {
				$(evtobj.target).blur();
			} else {
				$('#searchExercises input').val("");
				$('.exerciseItem').removeClass("filtered");
			}
		}
		
		const targetInput = $(evtobj.target).is('input');
		const itemsExist = $('.exerciseItem').length > 0;
			
		if (!targetInput && !targetEditable) {
			if(itemsExist){
				let updateView = false;
				
				if (evtobj.shiftKey) {
					switch (evtobj.keyCode) {
						case 65: // shift+a
							examExerciseAll();
							break;
						case 68: // shift+d
							exerciseRemoveAll();
							break;
						case 82: // shift+r 
							exerciseParseAll()
							break;
					}
				} 
							
				if(!evtobj.shiftKey && !evtobj.ctrlKey) {
					switch (evtobj.keyCode) {
						case 65: // a
							if ($('.exerciseItem.active:not(.filtered)').length > 0 && !$('.exerciseItem.active:not(.filtered) .examExercise').hasClass('disabled')) {
								$('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').toggleClass('exam');	
								setExamExercise($('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').index('.exerciseItem:not(.filtered)'), $('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').hasClass('exam'));
							}
							break;
						case 87: // w
							sidebarMoveUp($('.mainSection.active'));
							updateView = true;
							break;
						case 83: // s
							sidebarMoveDown($('.mainSection.active'));
							updateView = true;
							break;
						case 68: // d
							resetOutputFields();	
							
							const exerciseID = $('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').index('.exerciseItem:not(.filtered)')
							removeExercise(exerciseID);
							$('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').remove();
							
							if($('.exerciseItem:not(.filtered)').length > 0) {
								$('.exerciseItem.active:not(.filtered)').removeClass('active');
								$('.exerciseItem:not(.filtered)').eq(Math.min(exerciseID, $('.exerciseItem:not(.filtered)').length - 1)).addClass('active');
							}
							updateView = true;
							break;
						case 82: // r 
							viewExercise($('.exerciseItem.active:not(.filtered)').first().index('.exerciseItem'));
							break;

					}
				}
				
				if (updateView && $('.exerciseItem.active:not(.filtered)').length > 0) {
					viewExercise($('.exerciseItem.active:not(.filtered)').first().index('.exerciseItem'));
				}
			} 
			
			if (evtobj.keyCode == 67) // c
				newSimpleExercise();
		}
	} else {
		if (!$(evtobj.target).is('input')) {
			switch (evtobj.keyCode) {
				case 87: // w
					sidebarMoveUp($('.mainSection.active'));
					selectListItem($('.mainSection.active .sidebarListItem.active').index());
					break;
				case 83: // s
					sidebarMoveDown($('.mainSection.active'));
					selectListItem($('.mainSection.active .sidebarListItem.active').index());
					break;
			}
		}
	}
};

function sidebarMoveUp(parent) {
	if (parent.find('.sidebarListItem.active:not(.filtered)').length == 0) {
		parent.find('.sidebarListItem:not(.filtered)').first().addClass('active');
	} else {
		const itemId = parent.find('.sidebarListItem.active:not(.filtered)').index('#' + parent.attr('id') + ' .sidebarListItem:not(.filtered)');
		parent.find('.sidebarListItem.active:not(.filtered)').removeClass('active');
		
		if (itemId == 0) {
			parent.find('.sidebarListItem:not(.filtered)').eq(parent.find('.sidebarListItem:not(.filtered)').length - 1).addClass('active');
		} else {
			parent.find('.sidebarListItem:not(.filtered)').eq(itemId - 1).addClass('active');
		}
	}
}

function sidebarMoveDown(parent) {
	if (parent.find('.sidebarListItem.active:not(.filtered)').length == 0) {
		parent.find('.sidebarListItem:not(.filtered)').first().addClass('active');
	} else {
		const itemId = parent.find('.sidebarListItem.active:not(.filtered)').index('#' + parent.attr('id') + ' .sidebarListItem:not(.filtered)');
		parent.find('.sidebarListItem.active:not(.filtered)').removeClass('active');
		
		if (itemId + 1 == parent.find('.sidebarListItem:not(.filtered)').length) {
			parent.find('.sidebarListItem:not(.filtered)').eq(0).addClass('active');
		} else {
			parent.find('.sidebarListItem:not(.filtered)').eq(itemId + 1).addClass('active');
		}
	}
}

/* --------------------------------------------------------------
 WAIT 
-------------------------------------------------------------- */
Shiny.addCustomMessageHandler('wait', function(status) {
	if(status === 0) {
		$('#disableOverlay').addClass("active");
		$('nav .nav.navbar-nav li').addClass("disabled");
	} else {
		$('#disableOverlay').removeClass("active");
		$('nav .nav.navbar-nav li').removeClass("disabled");
	}
});

/* --------------------------------------------------------------
 NAV 
-------------------------------------------------------------- */
$('#exercisesNav').parent().click(function () {	
	if( $(this).parent().hasClass('disabled') ) return;
	
	$('.mainSection').removeClass('active');
	$('#exercises').addClass('active');
});

$('#examNav').parent().click(function () {	
	if( $(this).parent().hasClass('disabled') ) return;
	
	$('.mainSection').removeClass('active');
	$('#exam').addClass('active');
});

$('#helpNav').parent().click(function () {	
	if( $(this).parent().hasClass('disabled') ) return;
	
	$('.mainSection').removeClass('active');
	$('#help').addClass('active');
});

function selectListItem(index) {	
	$('.mainSection.active .contentTab').removeClass('active');
	$('.mainSection.active .contentTab').eq(index).addClass('active');
}

/* --------------------------------------------------------------
 BUTTON MODE 
-------------------------------------------------------------- */
$('#buttonModeSwitchContainer span').click(function () {
	setButtonModeCookie($(this).attr('id').toLowerCase());
	f_buttonMode();
	f_langDeEn();
});

function f_buttonMode() {
	$('body').removeClass("iconButtonMode");
	$('body').removeClass("textButtonMode");
	
	buttonMode = getButtonModeCookie()
	
	if (buttonMode === 'iconbuttons') {
		$('body').addClass("iconButtonMode");
	} else {
		$('body').addClass("textButtonMode");
	}
}

Shiny.addCustomMessageHandler('f_buttonMode', function(x) {
	f_buttonMode();
});

function setButtonModeCookie(buttonMode) {
    document.cookie = 'REX_JS_buttonMode=' + buttonMode + ';path=/;SameSite=Lax';
}

function getButtonModeCookie() {
    const name = 'REX_JS_buttonMode';
    const ca = document.cookie.split(';');
	
    for(let i=0;i < ca.length;i++) {
        let c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(name) == 0) {
			return c.substring(name.length + 1,c.length);
		}
    }
    return null;
}

/* --------------------------------------------------------------
 LANGUAGE 
-------------------------------------------------------------- */
$('#languageSwitchContainer span').click(function () {
	setLanguageCookie($(this).text().toLowerCase());
	f_langDeEn();
});

function f_langDeEn() {
	lang = getLanguageCookie()
	
	if (lang === 'en') {
		iuf['language'] = 'en';
		
		$('html').attr('lang', 'en');
		$('html').attr('xml:lang', 'en');
		
		$('[lang="de"]').hide();
		$('[lang="en"]').show();
	} else {
		iuf['language'] = 'de';
		
		$('html').attr('lang', 'de');
		$('html').attr('xml:lang', 'de');
		
		$('[lang="en"]').hide();
		$('[lang="de"]').show();
	}
}

Shiny.addCustomMessageHandler('f_langDeEn', function(x) {
	f_langDeEn();
});

function setLanguageCookie(lang) {
    document.cookie = 'REX_JS_lang=' + lang + ';path=/;SameSite=Lax';
}

function getLanguageCookie() {
    const name = 'REX_JS_lang';
    const ca = document.cookie.split(';');
    for(let i=0;i < ca.length;i++) {
        let c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(name) == 0) {
			return c.substring(name.length + 1,c.length);
		}
    }
    return null;
}

const languages = {en:["Englisch", "English"],
				   hr:["Kroatisch", "Croatian"],
				   da:["Dänisch", "Danisch"],
				   nl:["Niederländisch ", "Dutch"],
				   fi:["Finnisch", "Finnish"],
				   fr:["Französisch", "French"],
				   de:["Deutsch", "German"],
				   hu:["Ungarisch", "Hungarian"],
				   it:["Italienisch", "Italian"],
				   ja:["Japanisch", "Japanese"],
				   ko:["Koreanisch", "Korean"],
				   no:["Norwegisch", "Norwegian"],
				   pt:["Portugisisch", "Portuguese"],
				   ro:["Rumänisch", "Romanian"],
				   ru:["Russisch", "Russian"],
				   sr:["Serbisch", "Serbian"],
				   sk:["Slowakisch", "Slovak"],
				   sl:["Slowenisch", "Slovenian"],
				   es:["Spansich", "Spanish"],
				   tr:["Türkisch", "Turkish"]}		   

/* --------------------------------------------------------------
 DATA 
-------------------------------------------------------------- */
let iuf = new Object();

let exercises = -1;
let exerciseID_hook = -1;

function getFilesDataTransferItems(dataTransferItems) {
	function traverseFileTreePromise(item, path = "", files) {
		return new Promise(resolve => {
			if (item.isFile) {
				item.file(file => {
				file.filepath = path || "" + file.name;
				files.push(file);
				resolve(file);
				});
			} else if (item.isDirectory) {
				const dirReader = item.createReader();
				dirReader.readEntries(entries => {
					let entriesPromises = [];
					for (let entr of entries) {
						entriesPromises.push(
							traverseFileTreePromise(entr, path || ""  + item.name + "/", files)
						);
					}
					resolve(Promise.all(entriesPromises));
				});
			}
		});
	}

	let files = [];
	return new Promise((resolve, reject) => {
		let entriesPromises = [];
		for (let item of dataTransferItems) {
			entriesPromises.push(
				traverseFileTreePromise(item.webkitGetAsEntry(), null, files)
			);
		}
		Promise.all(entriesPromises).then(entries => {
			resolve(files);
		});
	});
}

/* --------------------------------------------------------------
 EXERCISES SETTINGS 
-------------------------------------------------------------- */
$("#seedValueExercises").change(function(){
	const seed = getIntegerInput(1, 999999999999, null, $(this).val());
	$(this).val(seed);
	$('#s_initialSeed').html(itemSingle(seed, 'greenLabel'));
	
	if(iuf.exercises.length > 0) viewExercise(getID());
}); 

/* --------------------------------------------------------------
 EXERCISES SUMMARY 
-------------------------------------------------------------- */
function examExercisesSummary() {
	numberOfExamExercises();
	numberOfExerciseBlocks();
	 
	$('#s_initialSeed').html(itemSingle($('#seedValueExercises').val(), 'greenLabel'));
	
	if($('.exerciseItem.exam').length == 0) { 
		$('#s_numberOfExercises').html("");
		$('#s_totalPoints').html("");
		$('#s_topicsTable').html("");
		
		return;
	}
	
	let numberOfExamExercisesCounter = 0;
	let totalPoints = 0;
	let topics = [];
		
	iuf['exercises'].forEach((item, index) => {
		if(item.exam) {
			numberOfExamExercisesCounter++;
			totalPoints += Number(item.points);
			if (item.topic !== null) topics.push(item.topic);
		}
	})
	
	$('#s_numberOfExercises').html(itemSingle(numberOfExamExercisesCounter, 'grayLabel'));
	$('#s_totalPoints').html(itemSingle(totalPoints, 'yellowLabel'));
	$('#s_topicsTable').html(itemTable(topics));
}

function itemSingle(item, className) {
	return '<span class="s_labelContainer"><span class="s_label"><span class="s_labelSingle ' + className + '">' + item + '</span></span></span>';
}

function itemTable(arr) {
	let counts = {};
	for (let i of arr) {
		counts[i] = counts[i] ? counts[i] + 1 : 1;
	}
	
	let out = "";
	
	out = Object.entries(counts).map(entry => {
		const [key, value] = entry;
		return '<span class="s_label"><span class="s_key">' + key + '</span><span class="s_value">' + value + '</span></span>';
	}).join('');
	
	return '<span class="s_labelContainer">' + out + '</span>';
}

/* --------------------------------------------------------------
 EXERCISES LIST
-------------------------------------------------------------- */
function examExerciseAll(){
	const examExerciseAllButton = $('#examExerciseAll');
	
	$('.exerciseItem').each(function (index) {
		if( $('.exerciseItem').eq(index).hasClass('filtered')) {
			return;
		}
		
		$(this).removeClass('exam');
		iuf['exercises'][index]['exam'] = false;
				
		if (!$(this).find('.examExercise').hasClass('disabled') && !examExerciseAllButton.hasClass('allAdded')) {	
			$(this).addClass('exam');
			iuf['exercises'][index]['exam'] = true;
		}
	});
	
	examExerciseAllButton.toggleClass('allAdded');
	examExercisesSummary();
}

function exerciseRemoveAll(){
	const removeIndices = $('.exerciseItem:not(.filtered)').map(function() {
		return $(this).index();
	}).get();
	
	for (var i = removeIndices.length -1; i >= 0; i--) {
		iuf['exercises'].splice(removeIndices[i],1);
		exercises = exercises - 1;
	}
	
	$('.exerciseItem:not(.filtered)').remove();

	examExercisesSummary();
	resetOutputFields();	
}

function exerciseParseAll(){
	iuf.exercises.forEach((t, index) => {
		if( $('.exerciseItem:nth-child(' + (index + 1) + ')').hasClass('filtered')) {
			return;
		}
		
		viewExercise(index)
	});	
}

$("#exerciseDownload").click(function(){
	exerciseDownload();
}); 

function exerciseDownload() {	
	const exerciseID = getID();
	
	const exerciseName = iuf.exercises[exerciseID].name;
	const exerciseCode = iuf.exercises[exerciseID].file;
	
	Shiny.onInputChange("exerciseToDownload", {exerciseName:exerciseName, exerciseCode: exerciseCode}, {priority: 'event'});	
}

$('#exerciseDownloadAll').click(function () {
	exerciseDownloadAll();
});

function exerciseDownloadAll() {	
	const filteredTasks = iuf.exercises.filter((x, index) => {
		return !$('.exerciseItem:nth-child(' + (index + 1) + ')').hasClass('filtered')
	});
	
	const exerciseNames = filteredTasks.map(exercise => exercise.name);
	const exerciseCodes = filteredTasks.map(exercise => exercise.file);
	
	Shiny.onInputChange("exercisesToDownload", {exerciseNames:exerciseNames, exerciseCodes: exerciseCodes}, {priority: 'event'});	
}

$('#newExercise').click(function () {
	newSimpleExercise();
});

$('#examExerciseAll').click(function () {
	examExerciseAll();
});

$('#exerciseRemoveAll').click(function () {
	exerciseRemoveAll();	
});

$('#exerciseParseAll').click(function () {
	exerciseParseAll();
});

$('#searchExercises input').change(function () {
	// no exercises 
	if($('.exerciseItem').length <= 0) {
		return;
	}
	
	// no search input
	if($('#searchExercises input').val() == 0) {
		$('.exerciseItem').removeClass("filtered");
		return;
	}
	
	const userInput = $(this).val().split(";");

	let matches = new Set();
	
	function filterExercises(fieldsToFilter, filterBy) {
		fieldsToFilter.filter((content, index) => {			
			const test = content.toString().includes(filterBy);
			if(test) matches.add(index);
		}); 
	}
	
	userInput.map(input => {
		const filterBy = input.split(":")[1];
		
		if (input.includes("name:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.name === null) {
					return "";
				} 
				
				return exercise.name;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("examHistory:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.examHistory === null) {
					return "";
				} 
				
				return exercise.examHistory.join(',');
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("authoredBy:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.authoredBy === null) {
					return "";
				} 
				
				return exercise.authoredBy.join(',');
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("topic:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.topic === null) {
					return "";
				} 
				
				return exercise.topic;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("tags:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.tags === null) {
					return "";
				} 
				
				return exercise.tags.join(',');
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("precision:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.precision === null) {
					return "";
				} 
				
				return exercise.precision;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("points:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.points === null) {
					return "";
				} 
				
				return exercise.points;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("type:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.type === null) {
					return "";
				} 
				
				return exercise.type;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("question:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.question === null) {
					return "";
				} 
				
				return exercise.question.join(',');
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("e:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.e === null) {
					return "";
				} 
				
				return exercise.e;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("exam:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( !exercise.exam ) {
					return "0";
				} 
				
				return "1";
			})
			
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("editable:")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( !exercise.editable ) {
					return "0";
				} 
				
				return "1";
			})
			
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (!input.includes(":")) {
			const fieldsToFilter = iuf.exercises.map(exercise => {
				if( exercise.name === null) {
					return "";
				} 
				
				return exercise.name;
			})
			filterExercises(fieldsToFilter, input);
		}
	});  
	
	matches = Array.from(matches);
	
	$('.exerciseItem').removeClass("filtered");
	
	$('.exerciseItem').each(function (index) {
		if( matches.every(m => m !== index) ){
			$('.exerciseItem:nth-child(' + (index + 1) + ')').addClass('filtered');
		}
	});
});

/* --------------------------------------------------------------
 EXERCISES 
-------------------------------------------------------------- */
let dndExercises = {
	hzone: null,
	dzone: null,

	init : function () {
		dndExercises.hzone = document.querySelector("body");
		dndExercises.dzone = document.getElementById('dnd_exercises');

		if ( window.File && window.FileReader && window.FileList && window.Blob) {
			// hover zone
			dndExercises.hzone.addEventListener('dragenter', function (e) {
				e.preventDefault();
				e.stopPropagation();
				
				if($('#disableOverlay').hasClass("active")) return;
				
				if( $('#exercises').hasClass('active') ) {
					dndExercises.dzone.classList.add('drag');
				}
			});
			dndExercises.hzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			dndExercises.hzone.addEventListener('dragover', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			
			// drop zone
			dndExercises.dzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndExercises.dzone.classList.remove('drag');
			});
			dndExercises.dzone.addEventListener('drop', async function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndExercises.dzone.classList.remove('drag');
				
				if($('#disableOverlay').hasClass("active")) return;
				
				loadExercisesDnD(e.dataTransfer.items);
			});
		}
	},
};

window.addEventListener('DOMContentLoaded', dndExercises.init);

function loadExercisesDnD(items) {	
	const blockNum = getBlockNum();
	
	getFilesDataTransferItems(items).then((files) => {
		Array.from(files).forEach(file => {	
			loadExercise(file, blockNum);
		});
	});
}

function loadExercisesFileDialog(items) {	
	const blockNum = getBlockNum();
	
	Array.from(items).forEach(file => {	
		loadExercise(file, blockNum);
	});
}

function getBlockNum() {
	const blockNum = Math.max(...iuf['exercises'].map(x => x.block)) + 1;
	return blockNum > 0 ? blockNum : 1;
}

function loadExercise(file, block = 1) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	switch(fileExt) {
		case 'rnw':
			newComplexExercise(file, block);
			break;
	}
}

const d_exerciseName = 'Name';
const d_questionText = 'Text';
const d_answerText = 'Text';
const d_result = false;

function newSimpleExercise(file = '', block = 1) {
	const exerciseID = exercises + 1
		addExercise();
		createExercise(exerciseID, d_exerciseName, 
					       null, 
					       d_questionText,
					       [d_answerText + '1', d_answerText + '2'],
					       [d_result, d_result],
					       null,
						   null,
					       true,
						   "mchoice",
						   block,
						   'Text');
		viewExercise(exerciseID);
}

async function newComplexExercise(file, block) {
	const fileText = await file.text();
	const exerciseID = exercises + 1
	
	addExercise();
	
	createExercise(exerciseID, file.name.split('.')[0], 
					   fileText,
					   '',
					   [],
					   [],
					   null,
					   null,
					   false,
					   null,
					   block);
	
	viewExercise(exerciseID);
}

function createExercise(exerciseID, name='exercise', 
							file=null,
						    question='',
						    choices=[],
							result=[],
							message=null,
							e=null,
							editable=false,
							type=null,
							block=1,
							topic=null,
							seed=null, 
						    exam=false, 
							examHistory=null,
							authoredBy=null,
							precision=null,
							points=1,
							tags=null,
							figure=null){
	iuf['exercises'][exerciseID]['file'] = file;
	iuf['exercises'][exerciseID]['name'] = name;
	iuf['exercises'][exerciseID]['seed'] = seed;
	iuf['exercises'][exerciseID]['exam'] = exam;
	iuf['exercises'][exerciseID]['question'] = question;
	iuf['exercises'][exerciseID]['choices'] = choices;
	iuf['exercises'][exerciseID]['result'] = result;
	iuf['exercises'][exerciseID]['examHistory'] = examHistory;
	iuf['exercises'][exerciseID]['authoredBy'] = authoredBy;
	iuf['exercises'][exerciseID]['precision'] = precision;
	iuf['exercises'][exerciseID]['points'] = points;
	iuf['exercises'][exerciseID]['topic'] = topic;
	iuf['exercises'][exerciseID]['tags'] = tags;
	iuf['exercises'][exerciseID]['type'] = type;
	iuf['exercises'][exerciseID]['message'] = message;	
	iuf['exercises'][exerciseID]['e'] = e;	
	iuf['exercises'][exerciseID]['editable'] = editable;
	iuf['exercises'][exerciseID]['block'] = block;
	iuf['exercises'][exerciseID]['figure'] = figure;
	
	if( file === null) {
		setSimpleExerciseFileContents(exerciseID);
	}
		
	$('#exercise_list_items').append('<div class="exerciseItem sidebarListItem"><span class="exerciseName">' + name + '</span></span><span class="exerciseBlock"><span lang="de">Block:</span><span lang="en">Block:</span><input value="' + block + '"/></span><span class="exerciseButtons"><span class="exerciseParse exerciseButton disabled"><i class="fa-solid fa-rotate"></i></span><span class="examExercise exerciseButton disabled"><span class="iconButton"><i class="fa-solid fa-star"></i></span><span class="textButton"><span lang="de">Prüfungsrelevant</span><span lang="en">Examinable</span></span></span><span class="exerciseRemove exerciseButton"><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></span></span></div>');
}

function parseExercise(exerciseID) {	
	const exerciseCode = iuf['exercises'][exerciseID].file;
	
	Shiny.onInputChange("parseExercise", {exerciseCode: exerciseCode, exerciseID: exerciseID}, {priority: 'event'});	
}

function numberOfExamExercises() {
	Shiny.onInputChange("setNumberOfExamExercises", getNumberOfExamExercises(), {priority: 'event'});
}

function numberOfExerciseBlocks() {
	Shiny.onInputChange("setNumberOfExerciseBlocks", Math.max(1, getNumberOfExerciseBlocks()), {priority: 'event'});
}

function getNumberOfExerciseBlocks() {
	return new Set(iuf['exercises'].filter((exercise) => exercise.exam).map(x => x.block)).size;
}

function getNumberOfExamExercises() {
	let setNumberOfExamExercises = 0;
	iuf['exercises'].map(t => setNumberOfExamExercises += t.exam);
	
	let numberOfExerciseBlocks = getNumberOfExerciseBlocks();
		
	setNumberOfExamExercises = setNumberOfExamExercises - setNumberOfExamExercises % numberOfExerciseBlocks;

	const exercisesPerBlock = iuf['exercises'].filter((exercise) => exercise.exam).reduce( (acc, t) => (acc[t.block] = (acc[t.block] || 0) + 1, acc), {} );
	return Math.min(setNumberOfExamExercises, Math.min(...Object.values(exercisesPerBlock))) * numberOfExerciseBlocks;
}

function viewExercise(exerciseID) {
	resetOutputFields();
		
	if(exerciseShouldbeParsed(exerciseID)) {
		parseExercise(exerciseID);	
	} else {
		loadExerciseFromObject(exerciseID);
	}
		
	f_langDeEn();
}

function exerciseShouldbeParsed(exerciseID){
	const seedChanged = iuf['exercises'][exerciseID]['seed'] == "" || iuf['exercises'][exerciseID]['seed'] != $("#seedValueExercises").val();
	const error = iuf['exercises'][exerciseID]['e'] === 2;
	
	return seedChanged || error;
}

function resetOutputFields() {
	$('#exercise_info').addClass('hidden');	
	
	let fields = ['exerciseName',
				  'question',
				  'figure',
			      'points',
			      'result',
			      'examHistory',
			      'authoredBy',
			      'precision',
			      'topic',
			      'tags'];
			  
	fields.forEach(field => {	
		$('#' + field).html('');
		$('#' + field).hide();
		$('label[for="'+ field +'"]').hide();
	});	
}

$('#exercise_info').on('click', '.editTrueFalse', function(e) {
	const exerciseID = getID();
	const newValue = iuf['exercises'][exerciseID]['result'][$(this).index('.mchoiceResult')] !== true;
		
	iuf['exercises'][exerciseID]['result'][$(this).index('.mchoiceResult')] = newValue;
	$(this).html(getTrueFalseText(newValue));
	
	f_langDeEn();
});

function getTrueFalseText(value) {
	let textDe = ["Falsch", "Richtig"];
	let textEn = ["False", "True"];
		
	return '<span lang="de">' + textDe[+value] + '</span><span lang="en">' + textEn[+value] + '</span>'
}

Array.fromList = function(list) {
    var array= new Array(list.length);
    for (var i= 0, n= list.length; i<n; i++)
        array[i]= list[i];
    return array;
};

function filterNodes(element, allow) {
    Array.fromList(element.childNodes).forEach(function(child) {
        if (child.nodeType === 1) {
            filterNodes(child, allow);
            let tag = child.tagName.toLowerCase();
            if (tag in allow) {

                 Array.fromList(child.attributes).forEach(function(attr) {
                    if (allow[tag].indexOf(attr.name.toLowerCase()) === -1)
                       child.removeAttributeNode(attr);
                });
            } else {
                while (child.firstChild)
                    element.insertBefore(child.firstChild, child);
                element.removeChild(child);
            }
        }
    });

	return element;
}

function invalidateAfterEdit(exerciseID) {
	setExamExercise(exerciseID, false);
	iuf['exercises'][exerciseID]['e'] = 2;
	iuf['exercises'][exerciseID]['message'] = '<span class="exerciseTryCatch Error"><span class="responseSign ErrorSign"><i class="fa-solid fa-circle-exclamation"></i></span><span class="exerciseTryCatchText">Exercise needs to be parsed again.</span></span>';
	
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .examExercise').addClass('disabled');
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .exerciseTryCatch').remove();
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').prepend(iuf['exercises'][exerciseID]['message']);
}

$('body').on('focus', '[contenteditable]', function() {
    const $this = $(this);
    $this.data('before', $this.html());
}).on('blur', '[contenteditable]', function() {
    const $this = $(this);
    if ($this.data('before') !== $this.html()) {
		const exerciseID = getID();	
		
		invalidateAfterEdit(exerciseID);
		
		let content = $this.get(0);
				
		if(content.childNodes.length === 1 && content.childNodes[0].nodeType === 3) {
			content = content.textContent;
		} else {
			content = filterNodes($this.get(0), {p: [], br: [], a: ['href']}).innerHTML;
		}
		
		$this.html(content);
			
		if ($this.hasClass('exerciseNameText')) {
			$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .exerciseName').text(content);
			iuf['exercises'][exerciseID]['name'] = content;
		}
		
		if ($this.hasClass('questionText')) {
			iuf['exercises'][exerciseID]['question'] = content;
		}
		
		if ($this.hasClass('choiceText')) {
			iuf['exercises'][exerciseID]['choices'][$this.index('.choiceText')] = content;
		}
		
		if ($this.hasClass('points')) {
			content = getIntegerInput(0, null, 1, content);
			iuf['exercises'][exerciseID]['points'] = content;
		}
		
		if ($this.hasClass('topicText')) {
			iuf['exercises'][exerciseID]['topic'] = content;
		}

		$this.html(content);
		setSimpleExerciseFileContents(exerciseID);	
		examExercisesSummary();
    }
});

document.addEventListener('dblclick', (event) => {
  window.getSelection().selectAllChildren(event.target)
})

function loadExerciseFromObject(exerciseID) {
	const e = iuf['exercises'][exerciseID]['e']; 
	const editable = iuf['exercises'][exerciseID]['editable']; 
	
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').removeClass("editable");
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .exerciseParse').removeClass("disabled");
	
	if(iuf['exercises'][exerciseID]['name'] !== null) {	
		const field = 'exerciseName'
		const content = '<span class="exerciseNameText" contenteditable="' + editable + '" spellcheck="false">' + iuf['exercises'][exerciseID]['name'] + '</span>';
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(iuf['exercises'][exerciseID]['question'] !== null) {
		const field = 'question'
		let content = ''
		
		if(Array.isArray(iuf['exercises'][exerciseID][field])) {
			content = '<span class="questionText" contenteditable="' + editable + '" spellcheck="false">' + iuf['exercises'][exerciseID][field].join('') + '</span>';
		} else {
			content = '<span class="questionText" contenteditable="' + editable + '" spellcheck="false">' + iuf['exercises'][exerciseID][field] + '</span>';
		}
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(editable) {
		const field = 'figure'
		
		const imgContet = iuf['exercises'][exerciseID]['figure'] !== null ? '<div class="exerciseFigureItem"><span class="exerciseFigureName"><img src="data:image/png;base64, ' + iuf['exercises'][exerciseID][field][2] + '"/></span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>' : '';
		
		const content = '<label class="exerciseFigureUpload" for="file-upload_exerciseFigure"><div class="exerciseFigureButton"><span class="iconButton"><i class="fa-solid fa-upload"></i></span><span class="textButton"><span lang="de">Importieren</span><span lang="en">Import</span></span></div><input type="file" id="file-upload_exerciseFigure" onchange="loadExerciseFigureFileDialog(this.files);" multiple="" class="shiny-bound-input"></label><div id="exerciseFigureFiles"><div id="exerciseFigure_list" class="itemList"><div id="exerciseFigure_list_items">' + imgContet + '</div></div></div></div>';
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(iuf['exercises'][exerciseID]['points'] !== null) {	
		const field = 'points'
				
		const content = '<span class="points" contenteditable="' + editable + '" spellcheck="false">' + iuf['exercises'][exerciseID][field] + '</span>';
		
		setExerciseFieldFromObject(field, content);
	}
			
	if(iuf['exercises'][exerciseID]['type'] === "mchoice" || iuf['exercises'][exerciseID]['editable']) {
		const field = 'result'
		const zip = iuf['exercises'][exerciseID][field].map((x, i) => [x, iuf['exercises'][exerciseID]['choices'][i]]);
		let content = '<div id="resultContent">' + zip.map(i => '<p>' + (editable ? '<button type="button" class="removeAnswer btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></button>' : '') + '<span class=\"result mchoiceResult ' + (editable ? 'editTrueFalse' : '') + '\">' + getTrueFalseText(i[0]) + '</span><span class="choice"><span class="choiceText" contenteditable="' + editable + '" spellcheck="false">' + i[1] + '</span></span></p>').join('') + '</div>';
		
		if( iuf['exercises'][exerciseID]['editable'] ) {
			content = '<button id="addNewAnswer" type="button" class="btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-plus"></i></span><span class="textButton"><span lang="de">Neue Antwortmöglichkeit</span><span lang="en">New Answer</span></span></button>' + content;
		}
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(iuf['exercises'][exerciseID]['examHistory'] !== null) {
		const field = 'examHistory'
		const content = iuf['exercises'][exerciseID][field].map(i => '<span>' + i + '</span>').join('');
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(iuf['exercises'][exerciseID]['authoredBy'] !== null) {
		const field = 'authoredBy'
		const content = iuf['exercises'][exerciseID][field].map(i => '<span>' + i + '</span>').join('');
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(iuf['exercises'][exerciseID]['precision'] !== null) {
		const field = 'precision'
		const content = '<span>' + iuf['exercises'][exerciseID][field] + '</span>';
		
		setExerciseFieldFromObject(field, content);
	}

	if(iuf['exercises'][exerciseID]['topic'] !== null) {
		const field = 'topic'
		const content = '<span class="topicText" contenteditable="' + editable + '" spellcheck="false">' + iuf['exercises'][exerciseID][field] + '</span>';
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(iuf['exercises'][exerciseID]['tags'] !== null) {
		const field = 'tags'
		const content = iuf['exercises'][exerciseID][field].map(i => '<span>' + i + '</span>').join('');
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(editable)
		$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').addClass("editable");
		
	$('.exerciseItem.active').removeClass('active');
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').addClass('active');
	$('#exercise_info').removeClass('hidden');
	
	f_langDeEn();
}

function setSimpleExerciseFileContents(exerciseID){
	let fileText = rnwTemplate;
	fileText = fileText.replace("?rnwTemplate_q", '"' + iuf['exercises'][exerciseID]['question'] + '"');
	fileText = fileText.replace("?rnwTemplate_c", 'c(' + iuf['exercises'][exerciseID]['choices'].map(c=>'"' + c + '"').join(',') + ')');
	fileText = fileText.replace("?rnwTemplate_s", 'c(' + iuf['exercises'][exerciseID]['result'].map(s=>s?"T":"F").join(',') + ')');
	fileText = fileText.replace("?rnwTemplate_p", iuf['exercises'][exerciseID]['points']);
	fileText = fileText.replace("?rnwTemplate_t", iuf['exercises'][exerciseID]['topic']);
	fileText = fileText.replace("?rnwTemplate_f", iuf['exercises'][exerciseID]['figure'] !== null ? 'c(' + iuf['exercises'][exerciseID]['figure'].map(c=>'"' + c + '"').join(',') + ')' : '""');
	fileText = fileText.replaceAll("\n", "\r\n");

	iuf['exercises'][exerciseID]['file'] = fileText;
}

function setExerciseFieldFromObject(field, content) {
	$('#' + field).html(content);
	$('#' + field).show();
	if($('label[for="'+ field +'"]').length > 0) $('label[for="'+ field +'"]').show();
}

function addExercise() {
	exercises = exercises + 1;	
	iuf['exercises'].splice(exercises, 0, new Array());
}

function removeExercise(exerciseID) {
	iuf['exercises'].splice(exerciseID, 1);
	exercises = exercises - 1;
	
	examExercisesSummary();
}

function changeExerciseBlock(exerciseID, b) {
	const b_ = getIntegerInput(1, null, 1, b)
	iuf['exercises'][exerciseID]['block'] = b_;
	examExercisesSummary();
	
	return b_;
}

function getIntegerInput(min, max, defaultValue, value) {
	let value_ = defaultValue;
	
	if(!isNaN(Number(value)) && value !== null && value !== "") {
		value = min === null ? value : Math.max(min, Number(value));
		value = max === null ? value : Math.min(max, Number(value));
		
		value_ = parseInt(value)
	} 
	
	return value_;
}

function getFloatInput(min, max, defaultValue, value) {
	let value_ = defaultValue;
	
	if(!isNaN(Number(value)) && value !== null && value !== "") {
		value = min === null ? value : Math.max(min, Number(value));
		value = max === null ? value : Math.min(max, Number(value));
		
		value_ = parseFloat(value)
	} 
	
	return value_;
}

function setExamExercise(exerciseID, b) {
	if(b)	
		$('.exerciseItem').eq(exerciseID).addClass('exam');	
	else
		$('.exerciseItem').eq(exerciseID).removeClass('exam');	
	
	iuf['exercises'][exerciseID]['exam'] = b;
	
	examExercisesSummary();
}

$('#exercise_list_items').on('change', '.exerciseBlock input', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	$(this).closest('.exerciseItem .exerciseBlock input').val(changeExerciseBlock($(this).closest('.exerciseItem').index('.exerciseItem'), $(this).closest('.exerciseItem .exerciseBlock input').val()));
	
	examExercisesSummary();
});

$('#exercise_list_items').on('click', '.exerciseParse', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	viewExercise($(this).closest('.exerciseItem').index('.exerciseItem'));
});

$('#exercise_list_items').on('click', '.examExercise', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	setExamExercise($(this).closest('.exerciseItem').index('.exerciseItem'), !$(this).closest('.exerciseItem').hasClass('exam'));
});

$('#exercise_list_items').on('click', '.exerciseRemove', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	resetOutputFields();
	
	if($(this).closest('.exerciseItem').hasClass('active')) {
		Shiny.onInputChange("resetExerciseOutputFields", 1);
	}
	
	const exerciseID = $(this).closest('.exerciseItem').index('.exerciseItem');
	removeExercise(exerciseID);
	$(this).closest('.exerciseItem').remove();
	
	if($('.exerciseItem').length > 0) {
		$('.exerciseItem.active').removeClass('active');
		$('.exerciseItem:nth-child(' + Math.min(exerciseID + 1, $('.exerciseItem').length) + ')').addClass('active');
		viewExercise($('.exerciseItem.active').first().index('.exerciseItem'));
	}
});

$('#exercise_list_items').on('click', '.exerciseItem', function() {
	$('.exerciseItem.active').removeClass('active');
	$(this).addClass('active');
		
	viewExercise($(this).index('.exerciseItem'));
});

$('#exercise_info').on('click', '#addNewAnswer', function() {
	const exerciseID = getID();
	
	iuf['exercises'][exerciseID]['choices'].push(d_answerText);
	iuf['exercises'][exerciseID]['result'].push(d_result);
	
	invalidateAfterEdit(exerciseID);
	setSimpleExerciseFileContents(exerciseID);
	loadExerciseFromObject(exerciseID);
	
	f_langDeEn();
});

$('#exercise_info').on('click', '.removeAnswer', function() {
	const exerciseID = getID();
	const choicesID = $(this).index('.removeAnswer');
	
	console.log(choicesID);
	
	if( iuf['exercises'][exerciseID]['choices'].length > 0 ) {	
		iuf['exercises'][exerciseID]['choices'].splice(choicesID, 1);
		iuf['exercises'][exerciseID]['result'].splice(choicesID, 1);
	} 
	
	invalidateAfterEdit(exerciseID);
	setSimpleExerciseFileContents(exerciseID);
	loadExerciseFromObject(exerciseID);
});

function loadExerciseFigureFileDialog(items) {+	
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if( fileExt == 'png' ) {
			addExerciseFigureFile(file);
		}
	});
}

function addExerciseFigureFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	if ( fileExt == 'png' ) {
		const exerciseID = getID();
		
		let fileReader;
		let base64;
		let fileName;
		
		fileReader = new FileReader();
		fileName = file.name.split('.')[0];

		fileReader.onload = function(fileLoadedEvent) {
			base64 = fileLoadedEvent.target.result;
			iuf['exercises'][exerciseID]['figure'] = [fileName, fileExt, base64.split(',')[1]];
			
			$('#figure').empty();
			$('#figure').append('<label class="exerciseFigureUpload" for="file-upload_exerciseFigure"><div class="exerciseFigureButton"><span class="iconButton"><i class="fa-solid fa-upload"></i></span><span class="textButton"><span lang="de">Importieren</span><span lang="en">Import</span></span></div><input type="file" id="file-upload_exerciseFigure" onchange="loadExerciseFigureFileDialog(this.files);" multiple="" class="shiny-bound-input"></label><div id="exerciseFigureFiles"><div id="exerciseFigure_list" class="itemList"><div id="exerciseFigure_list_items"><div class="exerciseFigureItem"><span class="exerciseFigureName"><img src="data:image/png;base64, ' + iuf['exercises'][getID()]['figure'][2] + '"/></span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div></div></div></div></div>');
			
			setSimpleExerciseFileContents(exerciseID);
			loadExerciseFromObject(exerciseID);
		};

		fileReader.readAsDataURL(file);
	}
}

function removeExerciseFigure(element) {
	const exerciseID = getID();
	
	iuf['exercises'][exerciseID]['figure'] = null;
	element.remove();
	
	setSimpleExerciseFileContents(exerciseID);
	loadExerciseFromObject(exerciseID);
}

$('#figure').on('click', '.exerciseFigureItem', function() {
	removeExerciseFigure($(this));
});

getID = function() {
	return(exerciseID_hook == -1 ? $('.exerciseItem.active').index('.exerciseItem') : exerciseID_hook);
}

Shiny.addCustomMessageHandler('setExerciseId', function(exerciseID) {
	exerciseID_hook = exerciseID;
});

Shiny.addCustomMessageHandler('setExerciseSeed', function(seed) {
	iuf['exercises'][getID()]['seed'] = seed;
});

Shiny.addCustomMessageHandler('setExerciseExamHistory', function(jsonData) {
	const examHistory = JSON.parse(jsonData);
	iuf['exercises'][getID()]['examHistory'] = examHistory;
});

Shiny.addCustomMessageHandler('setExerciseAuthoredBy', function(jsonData) {
	const exerciseAuthors = JSON.parse(jsonData);
	iuf['exercises'][getID()]['authoredBy'] = exerciseAuthors;
});

Shiny.addCustomMessageHandler('seExercisetPrecision', function(exercisePrecision) {
	iuf['exercises'][getID()]['precision'] = exercisePrecision;
});

Shiny.addCustomMessageHandler('setExercisePoints', function(exercisePoints) {
	iuf['exercises'][getID()]['points'] = exercisePoints;
});

Shiny.addCustomMessageHandler('setExerciseTopic', function(exerciseTopic) {
	iuf['exercises'][getID()]['topic'] = exerciseTopic;
});

Shiny.addCustomMessageHandler('setExerciseTags', function(jsonData) {
	const exerciseTags = JSON.parse(jsonData);
	iuf['exercises'][getID()]['tags'] = exerciseTags;
});

Shiny.addCustomMessageHandler('setExerciseType', function(exerciseType) {
	iuf['exercises'][getID()]['type'] = exerciseType;
});

Shiny.addCustomMessageHandler('setExerciseQuestion', function(exerciseQuestion) {
	iuf['exercises'][getID()]['question'] = exerciseQuestion;
});

Shiny.addCustomMessageHandler('setExerciseFigure', function(jsonData) {
	const figure = JSON.parse(jsonData);
	iuf['exercises'][getID()]['figure'] = figure[0] === "" ? null : figure;
});

Shiny.addCustomMessageHandler('setExerciseChoices', function(jsonData) {
	const exerciseChoices = JSON.parse(jsonData);
	iuf['exercises'][getID()]['choices'] = exerciseChoices;
});

Shiny.addCustomMessageHandler('setExerciseResultMchoice', function(jsonData) {
	const exerciseResult = JSON.parse(jsonData);
	iuf['exercises'][getID()]['result'] = exerciseResult;
});

Shiny.addCustomMessageHandler('setExerciseResultNumeric', function(exerciseResult) {
	iuf['exercises'][getID()]['result'] = exerciseResult;
});

Shiny.addCustomMessageHandler('setExerciseEditable', function(editable) {
	iuf['exercises'][getID()]['editable'] = (editable === 1);
});

Shiny.addCustomMessageHandler('setExerciseMessage', function(message) {
	const exerciseID = getID();
	
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .exerciseTryCatch').remove();
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').prepend(message);
	
	iuf['exercises'][exerciseID]['message'] = message;
});

Shiny.addCustomMessageHandler('setExerciseE', function(e) {
	const exerciseID = getID();
	
	iuf['exercises'][exerciseID]['e'] = e;

	if(e === 0 || e.charAt(0) === "W")
		$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .examExercise').removeClass('disabled');
		loadExerciseFromObject(exerciseID);
});

/* --------------------------------------------------------------
 CREATE EXAM 
-------------------------------------------------------------- */
$("#examFunctions_list_items .sidebarListItem").click(function(){
	$('#examFunctions_list_items .sidebarListItem').removeClass('active');
	$(this).addClass('active');
	
	selectListItem($('.mainSection.active .sidebarListItem.active').index());
}); 

let dndAdditionalPdf = {
	hzone: null,
	dzone: null,

	init : function () {
		dndAdditionalPdf.hzone = document.querySelector("body");
		dndAdditionalPdf.dzone = document.getElementById('dnd_additionalPdf');

		if ( window.File && window.FileReader && window.FileList && window.Blob ) {
			// hover zone
			dndAdditionalPdf.hzone.addEventListener('dragenter', function (e) {
				e.preventDefault();
				e.stopPropagation();
				if($('#disableOverlay').hasClass("active")) return;
				
				if( $('#exam').hasClass('active') && $('#createExamTab').hasClass('active')) {
					dndAdditionalPdf.dzone.classList.add('drag');
				}
			});
			dndAdditionalPdf.hzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			dndAdditionalPdf.hzone.addEventListener('dragover', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			
			// drop zone
			dndAdditionalPdf.dzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndAdditionalPdf.dzone.classList.remove('drag');
			});
			dndAdditionalPdf.dzone.addEventListener('drop', async function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndAdditionalPdf.dzone.classList.remove('drag');
				
				if($('#disableOverlay').hasClass("active")) return;
				
				loadAdditionalPdfDnD(e.dataTransfer.items);
			});
		}
	},
};

window.addEventListener('DOMContentLoaded', dndAdditionalPdf.init);

function loadAdditionalPdfDnD(items) {	
	getFilesDataTransferItems(items).then(async (files) => {
		Array.from(files).forEach(file => {	
			addAdditionalPdf(file);
		});
	});
}

function loadAdditionalPdfFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if( fileExt == 'pdf') {
			addAdditionalPdf(file);
		}
	});
}

function addAdditionalPdf(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	if ( fileExt == 'pdf') {
		let fileReader = new FileReader();
		let base64;
		fileName = file.name.split('.')[0];

		fileReader.onload = function(fileLoadedEvent) {
			base64 = fileLoadedEvent.target.result;
			iuf['examAdditionalPdf'].push([fileName, base64.split(',')[1]]);
		};

		fileReader.readAsDataURL(file);
		
		$('#additionalPdf_list_items').append('<div class="additionalPdfItem"><span class="additionalPdfName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
	}
}

function removeAdditionalPdf(element) {
	const additionalPdfID = element.index('.additionalPdfItem');
	iuf['examAdditionalPdf'].splice(additionalPdfID, 1);
	element.remove();
}

$('#seedValueExam').change(function(){
	$(this).val(getIntegerInput(1, 99999999, 1, $(this).val()));
}); 

$('#additionalPdf_list_items').on('click', '.additionalPdfItem', function() {
	removeAdditionalPdf($(this));
});

$("#numberOfExams").change(function(){
	$(this).val(getIntegerInput(1, null, 1, $(this).val()));
	$('#s_numberOfExams').html(itemSingle($(this).val(), 'grayLabel'));
}); 

$("#autofillSeed").click(function(){
	const seed = getIntegerInput(1, 99999999, 1, $('#seedValueExercises').val());
	$('#seedValueExam').val(seed);
}); 

$("#fixedPointsExamCreate").change(function(){
	$(this).val(getIntegerInput(1, null, null, $(this).val()));
}); 

$("#numberOfExercises").change(function(){
	$(this).val(getIntegerInput(0, 45, 0, $(this).val()));
}); 

$("#numberOfBlanks").change(function(){
	$(this).val(getIntegerInput(0, null, 0, $(this).val()));
}); 

$("#autofillNumberOfExercises").click(function(){
	$('#numberOfExercises').val(getIntegerInput(0, 45, 0, getNumberOfExamExercises()));
}); 

$("#createExamEvent").click(function(){
	createExamEvent();
}); 

async function createExamEvent() {
	const examExercises = iuf['exercises'].filter((exercise) => exercise.exam & exercise.file !== null);
	const exerciseNames = examExercises.map((exercise) => exercise.name);
	const exerciseCodes = examExercises.map((exercise) => exercise.file);
	const blocks = examExercises.map((exercise) => exercise.block);
	const additionalPdfNames = iuf.examAdditionalPdf.map(pdf => pdf[0]);
	const additionalPdfFiles = iuf.examAdditionalPdf.map(pdf => pdf[1]);
	
	Shiny.onInputChange("createExam", {examSeed: $('#seedValueExam').val(), numberOfExams: $("#numberOfExams").val(), numberOfExercises: $("#numberOfExercises").val(), exerciseNames: exerciseNames, exerciseCodes:exerciseCodes, blocks: blocks, additionalPdfNames: additionalPdfNames, additionalPdfFiles: additionalPdfFiles}, {priority: 'event'});
}

/* --------------------------------------------------------------
 EVALUATE EXAM 
-------------------------------------------------------------- */
const d_registration = 'XXXXXXX'; 

let dndExamEvaluation = {
	hzone: null,
	dzone: null,

	init : function () {
		dndExamEvaluation.hzone = document.querySelector("body");
		dndExamEvaluation.dzone = document.getElementById('dnd_examEvaluation');

		if ( window.File && window.FileReader && window.FileList && window.Blob ) {
			// hover zone
			dndExamEvaluation.hzone.addEventListener('dragenter', function (e) {
				e.preventDefault();
				e.stopPropagation();
				
				if($('#disableOverlay').hasClass("active")) return;
				
				if( $('#exam').hasClass('active') && $('#evaluateExamTab').hasClass('active')) {
					dndExamEvaluation.dzone.classList.add('drag');
				}
			});
			dndExamEvaluation.hzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			dndExamEvaluation.hzone.addEventListener('dragover', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			
			// drop zone
			dndExamEvaluation.dzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndExamEvaluation.dzone.classList.remove('drag');
			});
			dndExamEvaluation.dzone.addEventListener('drop', async function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndExamEvaluation.dzone.classList.remove('drag');
				
				if($('#disableOverlay').hasClass("active")) return;
				
				loadExamEvaluation(e.dataTransfer.items);
			});
		}
	},
};

window.addEventListener('DOMContentLoaded', dndExamEvaluation.init);

function loadExamEvaluation(items) {	
	getFilesDataTransferItems(items).then(async (files) => {
		Array.from(files).forEach(file => {	
			addExamEvaluationFile(file);
		});
	});
}

function loadExamSolutionsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'rds') {
			addExamEvaluationFile(file);
		}
	});
}

function loadExamRegisteredParticipantsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'csv') {
			addExamEvaluationFile(file);
		}
	});
}

function loadExamScansFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'pdf' || fileExt == 'png') {
			addExamEvaluationFile(file);
		}
	});
}

function addExamEvaluationFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	let fileReader;
	let base64;
	let fileName;
	
	switch(fileExt) {
		case 'pdf':
		case 'png': 
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				base64 = fileLoadedEvent.target.result;
				iuf['examEvaluation']['scans'].push([fileName, fileExt, base64.split(',')[1]]);
			};

			fileReader.readAsDataURL(file);
			
			$('#examScan_list_items').append('<div class="examScanItem"><span class="examScanName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
		case 'rds': 
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				base64 = fileLoadedEvent.target.result;
				iuf['examEvaluation']['solutions'] = [fileName, fileExt, base64.split(',')[1]];
			};

			fileReader.readAsDataURL(file);
			
			$('#examSolutions_list_items').empty();
			$('#examSolutions_list_items').append('<div class="examSolutionsItem"><span class="examSolutionsName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
		case 'csv':
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				csv = fileLoadedEvent.target.result;
				iuf['examEvaluation']['registeredParticipants'] = [fileName, fileExt, csv];
			};

			fileReader.readAsText(file);
			
			$('#examRegisteredParticipants_list_items').empty();
			$('#examRegisteredParticipants_list_items').append('<div class="examRegisteredParticipantsItem"><span class="examRegisteredParticipantsName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

function removeExamScan(element) {
	const examScanID = element.index('.examScanItem');
	iuf['examEvaluation']['scans'].splice(examScanID, 1);
	element.remove();
}

$('#examScan_list_items').on('click', '.examScanItem', function() {
	removeExamScan($(this));
});

function removeSolutions(element) {
	iuf['examEvaluation']['solutions'] = [];
	element.remove();
}

$('#examSolutions_list_items').on('click', '.examSolutionsItem', function() {
	removeSolutions($(this));
});

$("#fixedPointsExamEvaluate").change(function(){
	$(this).val(getIntegerInput(1, null, null, $(this).val()));
}); 

$("#markThreshold1").change(function(){
	$(this).val(getFloatInput(0, null, 0, $(this).val()));
}); 

$("#markThreshold2").change(function(){
	$(this).val(getFloatInput(0, null, 0.5, $(this).val()));
}); 

$("#markThreshold3").change(function(){
	$(this).val(getFloatInput(0, null, 0.6, $(this).val()));
}); 

$("#markThreshold4").change(function(){
	$(this).val(getFloatInput(0, null, 0.75, $(this).val()));
}); 

$("#markThreshold5").change(function(){
	$(this).val(getFloatInput(0, null, 0.85, $(this).val()));
}); 

$('body').on('change', '#inputSheetID', function() {
	$(this).val(getIntegerInput(0, 99999999999, 0, $(this).val()));
});

$('body').on('change', '#inputScramblingID', function() {
	$(this).val(getIntegerInput(0, 99, 0, $(this).val()));
});

$('body').on('change', '#inputTypeID', function() {
	$(this).val(getIntegerInput(0, 999, 5, $(this).val()));
});

function removeRegisteredParticipants(element) {
	iuf['examEvaluation']['registeredParticipants'] = [];
	element.remove();
}

$('#examRegisteredParticipants_list_items').on('click', '.examRegisteredParticipantsItem', function() {
	removeRegisteredParticipants($(this));
});

$('#evaluateExamEvent').click(function () {
	evaluateExamEvent();
});
async function evaluateExamEvent() {
	const examSolutionsName = iuf['examEvaluation']['solutions'][0];
	const examSolutionsFile = iuf['examEvaluation']['solutions'][2];
	
	const examRegisteredParticipantsnName = iuf['examEvaluation']['registeredParticipants'][0];
	const examRegisteredParticipantsnFile = iuf['examEvaluation']['registeredParticipants'][2];
	
	const examScanPdf = iuf['examEvaluation']['scans'].filter(x => x[1] == 'pdf')
	const examScanPdfNames = examScanPdf.map(x => x[0]);
	const examScanPdfFiles = examScanPdf.map(x => x[2]);
	
	const examScanPng = iuf['examEvaluation']['scans'].filter(x => x[1] == 'png')
	const examScanPngNames = examScanPng.map(x => x[0]);
	const examScanPngFiles = examScanPng.map(x => x[2]);
	
	Shiny.onInputChange("evaluateExam", {examSolutionsName: examSolutionsName, examSolutionsFile: examSolutionsFile, 
										 examRegisteredParticipantsnName: examRegisteredParticipantsnName, examRegisteredParticipantsnFile: examRegisteredParticipantsnFile, 
										 examScanPdfNames: examScanPdfNames, examScanPdfFiles: examScanPdfFiles, 
										 examScanPngNames: examScanPngNames, examScanPngFiles: examScanPngFiles}, {priority: 'event'});
}

$('body').on('click', '.compareListItem:not(.noParticipation)', function() {
	resetInspect();
	sortCompareListItems();
	
	const scanFocused = iuf['examEvaluation']['scans_reg_fullJoinData'][parseInt($(this).find('.evalIndex').html())];
		
	$('#inspectScan').append('<div id="focusedCompareListItem"></div><div id="inspectScanContent"><div id="inspectScanImage"><img src="data:image/png;base64, ' + scanFocused.blob + '"/></div><div id="inspectScanTemplate"><span id="scannedRegistration"><span id="scannedRegistrationText"><span lang="de">Matrikelnummer:</span><span lang="en">Registration Number:</span></span><select id="selectRegistration" autocomplete="on"></select></span><span id="scannedSheetID"><span id="scannedSheetIDText"><span lang="de">Klausur-ID:</span><span lang="en">Exam ID:</span></span><input id="inputSheetID"/></span><span id="scannedScramblingID"><span id="scannedScramblingIDText"><span lang="de">Variante:</span><span lang="en">Scrambling:</span></span><input id="inputScramblingID"/></span><span id="scannedTypeID"><span id="scannedTypeIDText"><span lang="de">Belegart:</span><span lang="en">Type:</span></span><input id="inputTypeID"/></span>	<table id="scannedAnswers"></table></div></div><div id="inspectScanButtons"><button id="cancleInspect" class="inspectScanButton" type="button" class="btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-xmark"></i></span><span class="textButton"><span lang="de">Abbrechen</span><span lang="en">Cancle</span></span></button><button id="applyInspect" class="inspectScanButton" type="button" class="btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-check"></i></span><span class="textButton"><span lang="de">Übernehmen</span><span lang="en">Apply</span></span></button></div>')
	
	// populate input fields
	let registrations = iuf['examEvaluation']['scans_reg_fullJoinData'].filter(x => x.scan === 'NA').map(x => x.registration);
	if(scanFocused.registration !== d_registration)
		registrations.push(d_registration);
	
	registrations.sort();
	registrations.unshift(scanFocused.registration);
	
	$.each(registrations, function (i, p) {
		$('#selectRegistration').append($('<option></option>').val(p).html(p));
	});
	
	$('#inputSheetID').val(parseInt(scanFocused.sheet));	
	$('#inputScramblingID').val(parseInt(scanFocused.scrambling));	
	$('#inputTypeID').val(parseInt(scanFocused.type));	
	
	// add checkboxes for answers
	const numExercises = parseInt(scanFocused.numExercises);
	const numChoices = parseInt(scanFocused.numChoices);
	
	if(numExercises > 0){
		let scannedAnswersHeader = '<tr id="scannedAnswersHeader"><th></th>'
		
		for (let i = 0; i < numChoices; i++) {
			scannedAnswersHeader = scannedAnswersHeader + '<th>' + 'abcdefghijklmnopqrstuvwxyz'.split('')[i] + '</th>';
		}
		
		scannedAnswersHeader = scannedAnswersHeader + '</tr>';
		
		let scannedAnswerItems;
		
		for (let i = 0; i < numExercises; i++) {
			let scannedAnswer = '<tr class="scannedAnswer"><td class="scannedAnswerId">' + (i + 1) + '</td>';
			
			for (let j = 0; j < numChoices; j++) {
				const checked = scanFocused[i + 1].split('')[j] === "1" ? ' checked="checked"' : '';
				
				let checkboxItem = '<input type="checkbox"' + checked + '>';
				
				scannedAnswer = scannedAnswer + '<td>' + checkboxItem + '</td>';
			}
			
			scannedAnswerItems = scannedAnswerItems + scannedAnswer + '</tr>';
		}
		
		$('#scannedAnswers').append(scannedAnswersHeader);
		$('#scannedAnswers').append(scannedAnswerItems);
	}
	
	$(this).addClass('focus');
	$('.compareListItem:not(.focus)').addClass('blur');
	$(this).clone().appendTo('#focusedCompareListItem')
	
	f_langDeEn();
	$('#inspectScan').show();
});

function populateCompareTable() {
	$('#compareScanRegistrationDataTable').empty();
	
	iuf['examEvaluation']['scans_reg_fullJoinData'].forEach((element, index) => {	
		const stateClass = (element.scan === 'NA' ? 'noParticipation' : (element.registration === d_registration ? 'noRegistration' : 'matched'))

		$('#compareScanRegistrationDataTable').append('<div class="compareListItem ' + stateClass + '"><span class="evalIndex">' + index + '</span></span><span class="evalRegistration">' + element.registration + '</span><span class="evalName">' + element.name + '</span><span class="evalId">' + element.id + '</span><span class="evalInspect"><i class="fa-solid fa-magnifying-glass"></i></span></div>')
	});
	
	sortCompareListItems();
}

function sortCompareListItems(){
	let sortRegistrations = function(a, b) {
		a = parseInt($(a).find('.evalRegistration').html());
		b = parseInt($(b).find('.evalRegistration').html());
		
		a = (isNaN(a) ? -1 : a);
		b = (isNaN(b) ? -1 : b);
		
		return a < b ? -1 : a > b ? 1 : 0;
	}

    let list = $("#compareScanRegistrationDataTable .compareListItem").get();
    list.sort(sortRegistrations);
    for (let i = 0; i < list.length; i++) {
        list[i].parentNode.appendChild(list[i]);
    }
}

function resetInspect(){
	$('#inspectScan').hide();
	$('.compareListItem').removeClass('blur');
	$('.compareListItem').removeClass('focus');
	$('#inspectScan').empty();
}

$('body').on('click', '#applyInspect', function() {
	applyInspect();
});

function applyInspect(){
	const scanFocusedIndex = parseInt($('#focusedCompareListItem .evalIndex').html());
	const zeroPad = (num, places) => String(num).padStart(places, '0')
	
	const registrationUnchanged = $('#selectRegistration').find(":selected").text() === iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].registration
	const inputSheetIDUnchanged = zeroPad($('#inputSheetID').val(), 11) === iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].sheet;
	const scramblingIDUnchanged = zeroPad($('#inputScramblingID').val(), 2) === iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].scrambling;
	const inputTypeIDUnchanged = zeroPad($('#inputTypeID').val(), 3) === iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].type;
	const answersUnchanged = $('#scannedAnswers .scannedAnswer').map(function (index) {
        let exerciseAnswers = $(this).find('input').map(function () {
            return $(this).prop('checked') ? "1" : "0";
        }).get();
		
		if (exerciseAnswers.length < 5) {
			for (let i = exerciseAnswers.length; i < 5; i++) {
				exerciseAnswers.push("0");
			}
		}
		
		exerciseAnswers = exerciseAnswers.join('');
		
		return iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex][index + 1] === exerciseAnswers;
    }).get().every(x => x === true);
	
	if(registrationUnchanged && inputSheetIDUnchanged && scramblingIDUnchanged && inputTypeIDUnchanged && answersUnchanged) {
		resetInspect();
		sortCompareListItems();
		return;
	}
	
	let itemsToAdd = null;
	let itemsToRemove = null;
	
	if(!registrationUnchanged) {
		if(iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].registration !== d_registration) {
			itemsToAdd = JSON.parse(JSON.stringify(iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex])); // clone byValue
			Object.keys(itemsToAdd).forEach(x => itemsToAdd[x] = "NA");
			itemsToAdd.registration = iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].registration;
			itemsToAdd.name = iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].name;
			itemsToAdd.id = iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].id;	
		}
		
		if($('#selectRegistration').find(":selected").text() === d_registration) {	
			iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].name = "NA"
			iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].id = "NA"
		} else {
			itemsToRemove = iuf['examEvaluation']['scans_reg_fullJoinData'].map(function(x) { return x.registration; }).indexOf($('#selectRegistration').find(":selected").text()); 
			
			iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].name = iuf['examEvaluation']['scans_reg_fullJoinData'][itemsToRemove].name
			iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].id = iuf['examEvaluation']['scans_reg_fullJoinData'][itemsToRemove].id 
		}
	}
	
	iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].registration = $('#selectRegistration').find(":selected").text();	
	iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].sheet = zeroPad($('#inputSheetID').val(), 11);	
	iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].scrambling = zeroPad($('#inputScramblingID').val(), 2);	
	iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex].type = zeroPad($('#inputTypeID').val(), 3);	
	
	$('#scannedAnswers .scannedAnswer').map(function (index) {
        let exerciseAnswers = $(this).find('input').map(function () {
            return $(this).prop('checked') ? "1" : "0";
        }).get();
		
		if (exerciseAnswers.length < 5) {
			for (let i = exerciseAnswers.length; i < 5; i++) {
				exerciseAnswers.push("0");
			}
		}
		
		exerciseAnswers = exerciseAnswers.join('');
		
		iuf['examEvaluation']['scans_reg_fullJoinData'][scanFocusedIndex][index + 1] = exerciseAnswers;
    });
	
	if(itemsToRemove !== null) 
		iuf['examEvaluation']['scans_reg_fullJoinData'].splice(itemsToRemove, 1);
	
	if(itemsToAdd !== null)
		iuf['examEvaluation']['scans_reg_fullJoinData'].push(itemsToAdd);
	
	resetInspect();
	populateCompareTable();
	sortCompareListItems();
}

$('body').on('click', '#cancleInspect', function() {
	cancleInspect();
});

function cancleInspect(){
	resetInspect();
	sortCompareListItems();
}

$('body').on('click', '#shiny-modal button[data-dismiss="modal"]', function() {
	$('#disableOverlay').removeClass("active");
});

Shiny.addCustomMessageHandler('compareScanRegistrationData', function(jsonData) {
	iuf['examEvaluation']['scans_reg_fullJoinData'] = JSON.parse(jsonData);

	populateCompareTable();
});

$('body').on('click', '#proceedEval', function() {
	const properties = ['scan', 'sheet', 'scrambling', 'type', 'replacement', 'registration',].concat(new Array(45).fill(1).map( (_, i) => i+1 ));

	const datenTxt = Object.assign({}, iuf['examEvaluation']['scans_reg_fullJoinData'].filter(x => x.scan !== 'NA' && x.registration !== d_registration).map(x => Object.assign({}, properties.map(y => x[y] === undefined ? "00000" : x[y], {}))));

	Shiny.onInputChange("proceedEvaluation", datenTxt, {priority: 'event'});
});

/* --------------------------------------------------------------
HELP 
-------------------------------------------------------------- */
$("#help_list_items .sidebarListItem").click(function(){
	$('#help_list_items .sidebarListItem').removeClass('active');
	$(this).addClass('active');
	selectListItem($('.mainSection.active .sidebarListItem.active').index());
}); 
