/**
* Script
*
*/

/* --------------------------------------------------------------
 DOCUMENT READY 
-------------------------------------------------------------- */
$(document).ready(function () {
	iuf['tasks'] = new Array();
	iuf['examAdditionalPdf'] = new Array(); 
	iuf['examEvaluation'] = new Array();
	iuf['examEvaluation']['scans'] = new Array(); 
	iuf['examEvaluation']['registeredParticipants'] = new Array();
	iuf['examEvaluation']['solutions'] = new Array();
	iuf['examEvaluation']['scans_reg_fullJoinData'] = new Array();
	
	$('#s_initialSeed').html(itemSingle($('#seedValue').val(), 'greenLabel'));
	$('#s_numberOfExams').html(itemSingle($('#numberOfExams').val(), 'grayLabel'));
	
	f_hotKeys();
	f_buttonMode();
	f_langDeEn();
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
	
	if( $('#tasks').hasClass('active') ) {
		const targetEditable = $(evtobj.target).attr('contenteditable');

		if (evtobj.shiftKey && evtobj.keyCode == 70 && !targetEditable) {
			const searchField = $('#searchTasks').find('input');
			const searchValLength = searchField.val().length;
			
			searchField.focus();
			searchField[0].setSelectionRange(searchValLength, searchValLength);
		}
	}
}

document.onkeydown = function(evt) {
	if($('#disableOverlay').hasClass("active")) return;
	if(!getHotkeysCookie()) return;
	
	const evtobj = window.event? event : evt
	
	// TASKS
	if( $('#tasks').hasClass('active') ) {
		if ($(evtobj.target).is('input') && evtobj.keyCode == 13) {
			$(evtobj.target).change();
			$(evtobj.target).blur();
		}
		
		const targetEditable = $(evtobj.target).attr('contenteditable');
	
		if (evtobj.keyCode == 27) { // ESC
			if(targetEditable) {
				$(evtobj.target).blur();
			} else {
				$('#searchTasks input').val("");
				$('.taskItem').removeClass("filtered");
			}
		}
		
		const targetInput = $(evtobj.target).is('input');
		const itemsExist = $('.taskItem').length > 0;
			
		if (!targetInput && !targetEditable && itemsExist) {
			let updateView = false;
			
			if (evtobj.shiftKey) {
				switch (evtobj.keyCode) {
					case 65: // shift+a
						examTaskAll();
						break;
					case 68: // shift+d
						taskRemoveAll();
						break;
					case 82: // shift+r 
						taskParseAll()
						break;
				}
			} 
			
			if(!evtobj.shiftKey && !evtobj.ctrlKey) {
				switch (evtobj.keyCode) {
					case 65: // a
						if ($('.taskItem.active:not(.filtered)').length > 0 && !$('.taskItem.active:not(.filtered) .examTask').hasClass('disabled')) {
							$('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').toggleClass('exam');	
							setExamTask($('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').index('.taskItem:not(.filtered)'), $('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').hasClass('exam'));
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
						
						const taskID = $('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').index('.taskItem:not(.filtered)')
						removeTask(taskID);
						$('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').remove();
						
						if($('.taskItem:not(.filtered)').length > 0) {
							$('.taskItem.active:not(.filtered)').removeClass('active');
							$('.taskItem:not(.filtered)').eq(Math.min(taskID, $('.taskItem:not(.filtered)').length - 1)).addClass('active');
						}
						updateView = true;
						break;
					case 82: // r 
						viewTask($('.taskItem.active:not(.filtered)').first().index('.taskItem'));
						break;
					case 67: // c
						newSimpleTask();
						break;
				}
			}
			
			if (updateView && $('.taskItem.active:not(.filtered)').length > 0) {
				viewTask($('.taskItem.active:not(.filtered)').first().index('.taskItem'));
			}
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
	
	// EXAMS
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
$('#tasksNav').parent().click(function () {	
	if( $(this).parent().hasClass('disabled') ) return;
	
	$('.mainSection').removeClass('active');
	$('#tasks').addClass('active');
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

let tasks = -1;
let taskID_hook = -1;

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
 TASKS SETTINGS 
-------------------------------------------------------------- */
$("#seedValue").change(function(){
	const seed = $(this).val();
	$('#s_initialSeed').html(itemSingle(seed, 'greenLabel'));
	
	if(iuf.tasks.length > 0) viewTask(getID());
}); 

/* --------------------------------------------------------------
 TASKS SUMMARY 
-------------------------------------------------------------- */
function examTasksSummary() {
	numberOfExamTasks();
	numberOfTaskBlocks();
	 
	$('#s_initialSeed').html(itemSingle($('#seedValue').val(), 'greenLabel'));
	
	if($('.taskItem.exam').length == 0) { 
		$('#s_numberOfTasks').html("");
		$('#s_totalPoints').html("");
		$('#s_topicsTable').html("");
		$('#s_typeTable').html("");
		
		return;
	}
	
	let numberOfExamTasksCounter = 0;
	let totalPoints = 0;
	let topics = [];
	let types = [];
		
	iuf['tasks'].forEach((item, index) => {
		if(item.exam) {
			numberOfExamTasksCounter++;
			totalPoints += Number(item.points);
			if (item.topic !== null) topics.push(item.topic);
			Array.isArray(item.result) ? types.push("mc") : types.push("num");
		}
	})
	
	$('#s_numberOfTasks').html(itemSingle(numberOfExamTasksCounter, 'grayLabel'));
	$('#s_totalPoints').html(itemSingle(totalPoints, 'yellowLabel'));
	$('#s_topicsTable').html(itemTable(topics));
	$('#s_typeTable').html(itemTable(types));
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
 TASKS LIST
-------------------------------------------------------------- */
function examTaskAll(){
	const examTaskAllButton = $('#examTaskAll');
	
	$('.taskItem').each(function (index) {
		if( $('.taskItem').eq(index).hasClass('filtered')) {
			return;
		}
		
		$(this).removeClass('exam');
		iuf['tasks'][index]['exam'] = false;
				
		if (!$(this).find('.examTask').hasClass('disabled') && !examTaskAllButton.hasClass('allAdded')) {	
			$(this).addClass('exam');
			iuf['tasks'][index]['exam'] = true;
		}
	});
	
	examTaskAllButton.toggleClass('allAdded');
	examTasksSummary();
}

function taskRemoveAll(){
	const removeIndices = $('.taskItem:not(.filtered)').map(function() {
		return $(this).index();
	}).get();
	
	for (var i = removeIndices.length -1; i >= 0; i--) {
		iuf['tasks'].splice(removeIndices[i],1);
		tasks = tasks - 1;
	}
	
	$('.taskItem:not(.filtered)').remove();

	examTasksSummary();
	resetOutputFields();	
}

function taskParseAll(){
	iuf.tasks.forEach((t, index) => {
		if( $('.taskItem:nth-child(' + (index + 1) + ')').hasClass('filtered')) {
			return;
		}
		
		viewTask(index)
	});	
}

$('#newTask').click(function () {
	newSimpleTask();
});

$('#taskExportAllProxy').click(function () {
	alert("Oops - This button does not work yet");
	// taskExportAllProxy();
});

$('#examTaskAll').click(function () {
	examTaskAll();
});

$('#taskRemoveAll').click(function () {
	taskRemoveAll();	
});

$('#taskParseAll').click(function () {
	taskParseAll();
});

$('#searchTasks input').change(function () {
	// no tasks 
	if($('.taskItem').length <= 0) {
		return;
	}
	
	// no search input
	if($('#searchTasks input').val() == 0) {
		$('.taskItem').removeClass("filtered");
		return;
	}
	
	const userInput = $(this).val().split(";");

	let matches = new Set();
	
	function filterTasks(fieldsToFilter, filterBy) {
		fieldsToFilter.filter((content, index) => {			
			const test = content.toString().includes(filterBy);
			if(test) matches.add(index);
		}); 
	}
	
	userInput.map(input => {
		const filterBy = input.split(":")[1];
		
		if (input.includes("name:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.name === null) {
					return "";
				} 
				
				return task.examHistory.join(',');
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("examHistory:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.examHistory === null) {
					return "";
				} 
				
				return task.examHistory.join(',');
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("authoredBy:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.authoredBy === null) {
					return "";
				} 
				
				return task.authoredBy.join(',');
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("topic:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.topic === null) {
					return "";
				} 
				
				return task.topic;
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("tags:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.tags === null) {
					return "";
				} 
				
				return task.tags.join(',');
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("precision:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.precision === null) {
					return "";
				} 
				
				return task.precision;
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("points:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.points === null) {
					return "";
				} 
				
				return task.points;
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("type:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.type === null) {
					return "";
				} 
				
				return task.type;
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("question:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.question === null) {
					return "";
				} 
				
				return task.question.join(',');
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("e:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.e === null) {
					return "";
				} 
				
				return task.e;
			})
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("exam:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( !task.exam ) {
					return "0";
				} 
				
				return "1";
			})
			
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (input.includes("editable:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( !task.editable ) {
					return "0";
				} 
				
				return "1";
			})
			
			filterTasks(fieldsToFilter, filterBy);
		}
		
		if (!input.includes(":")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.name === null) {
					return "";
				} 
				
				return task.name;
			})
			filterTasks(fieldsToFilter, input);
		}
	});  
	
	matches = Array.from(matches);
	
	$('.taskItem').removeClass("filtered");
	
	$('.taskItem').each(function (index) {
		if( matches.every(m => m !== index) ){
			$('.taskItem:nth-child(' + (index + 1) + ')').addClass('filtered');
		}
	});
});

/* --------------------------------------------------------------
 TASKS 
-------------------------------------------------------------- */
let dndTasks = {
	hzone: null,
	dzone: null,

	init : function () {
		dndTasks.hzone = document.querySelector("body");
		dndTasks.dzone = document.getElementById('dnd_tasks');

		if ( window.File && window.FileReader && window.FileList && window.Blob) {
			// hover zone
			dndTasks.hzone.addEventListener('dragenter', function (e) {
				e.preventDefault();
				e.stopPropagation();
				
				if($('#disableOverlay').hasClass("active")) return;
				
				if( $('#tasks').hasClass('active') ) {
					dndTasks.dzone.classList.add('drag');
				}
			});
			dndTasks.hzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			dndTasks.hzone.addEventListener('dragover', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			
			// drop zone
			dndTasks.dzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndTasks.dzone.classList.remove('drag');
			});
			dndTasks.dzone.addEventListener('drop', async function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndTasks.dzone.classList.remove('drag');
				
				if($('#disableOverlay').hasClass("active")) return;
				
				loadTasksDnD(e.dataTransfer.items);
			});
		}
	},
};

window.addEventListener('DOMContentLoaded', dndTasks.init);

function loadTasksDnD(items) {	
	const blockNum = getBlockNum();
	
	getFilesDataTransferItems(items).then((files) => {
		Array.from(files).forEach(file => {	
			loadTask(file, blockNum);
		});
	});
}

function loadTasksFileDialog(items) {	
	const blockNum = getBlockNum();
	
	Array.from(items).forEach(file => {	
		loadTask(file, blockNum);
	});
}

function getBlockNum() {
	const blockNum = Math.max(...iuf['tasks'].map(x => x.block)) + 1;
	return blockNum > 0 ? blockNum : 1;
}

function loadTask(file, block = 1) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	switch(fileExt) {
		case 'rnw':
			newComplexTask(file, block);
			break;
	}
}

const d_taskName = 'Name';
const d_questionText = 'Text';
const d_answerText = 'Text';
const d_result = false;

function newSimpleTask(file = '', block = 1) {
	const taskID = tasks + 1
		addTask();
		createTask(taskID, d_taskName, 
					       null, 
					       d_questionText,
					       [d_answerText + '1', d_answerText + '2'],
					       [d_result, d_result],
					       null,
					       true,
						   "mchoice",
						   block,
						   'Text');
		viewTask(taskID);
}

async function newComplexTask(file, block) {
	const fileText = await file.text();
	const taskID = tasks + 1
	
	addTask();
	
	createTask(taskID, file.name.split('.')[0], 
					   fileText,
					   '',
					   [],
					   [],
					   null,
					   false,
					   null,
					   block);
	
	viewTask(taskID);
}

function createTask(taskID, name='task', 
							file=null,
						    question='',
						    choices=[],
							result=[],
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
	iuf['tasks'][taskID]['file'] = file;
	iuf['tasks'][taskID]['name'] = name;
	iuf['tasks'][taskID]['seed'] = seed;
	iuf['tasks'][taskID]['exam'] = exam;
	iuf['tasks'][taskID]['question'] = question;
	iuf['tasks'][taskID]['choices'] = choices;
	iuf['tasks'][taskID]['result'] = result;
	iuf['tasks'][taskID]['examHistory'] = examHistory;
	iuf['tasks'][taskID]['authoredBy'] = authoredBy;
	iuf['tasks'][taskID]['precision'] = precision;
	iuf['tasks'][taskID]['points'] = points;
	iuf['tasks'][taskID]['topic'] = topic;
	iuf['tasks'][taskID]['tags'] = tags;
	iuf['tasks'][taskID]['type'] = type;
	iuf['tasks'][taskID]['e'] = e;	
	iuf['tasks'][taskID]['editable'] = editable;
	iuf['tasks'][taskID]['block'] = block;
	iuf['tasks'][taskID]['figure'] = figure;
	
	if( file === null) {
		setSimpleTaskFileContents(taskID);
	}
	
	$('#task_list_items').append('<div class="taskItem sidebarListItem"><span class="taskTryCatch"><i class="fa-solid fa-triangle-exclamation"></i><span class="taskTryCatchText"></span></span><span class="taskName">' + name + '</span></span><span class="taskBlock disabled"><span lang="de">Block:</span><span lang="en">Block:</span><input type="number" value="' + block + '"/></span><span class="taskButtons"><span class="examTask taskButton ' + (editable ? '' : 'disabled') + '"><span class="iconButton"><i class="fa-solid fa-circle-check"></i></span><span class="textButton"><span lang="de">Prüfungsrelevant</span><span lang="en">Examinable</span></span></span><span class="taskRemove taskButton"><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></span></span></div>');
}

function parseTask(taskID) {	
	const taskCode = iuf['tasks'][taskID].file;
	
	Shiny.onInputChange("parseExercise", {taskCode: taskCode, taskID: taskID}, {priority: 'event'});	
}

function numberOfExamTasks() {
	Shiny.onInputChange("setNumberOfExamTasks", getNumberOfExamTasks(), {priority: 'event'});
}

function numberOfTaskBlocks() {
	Shiny.onInputChange("setNumberOfTaskBlocks", Math.max(1, getNumberOfTaskBlocks()), {priority: 'event'});
}

function getNumberOfTaskBlocks() {
	return new Set(iuf['tasks'].filter((task) => task.exam).map(x => x.block)).size;
}

function getNumberOfExamTasks() {
	let setNumberOfExamTasks = 0;
	iuf['tasks'].map(t => setNumberOfExamTasks += t.exam);
	
	let numberOfTaskBlocks = getNumberOfTaskBlocks();
		
	setNumberOfExamTasks = setNumberOfExamTasks - setNumberOfExamTasks % numberOfTaskBlocks;

	const tasksPerBlock = iuf['tasks'].filter((task) => task.exam).reduce( (acc, t) => (acc[t.block] = (acc[t.block] || 0) + 1, acc), {} );
	return Math.min(setNumberOfExamTasks, Math.min(...Object.values(tasksPerBlock))) * numberOfTaskBlocks;
}

function viewTask(taskID) {
	resetOutputFields();
	
	const error = iuf['tasks'][taskID]['e'] !== null && iuf['tasks'][taskID]['e'].includes('Error:');
	if(error) return;
		
	if(taskShouldbeParsed(taskID)) {
		parseTask(taskID);	
	} else {
		loadTaskFromObject(taskID);
	}
		
	f_langDeEn();
}

function taskShouldbeParsed(taskID){
	const editable = iuf['tasks'][taskID]['editable'] 
	const seedChanged = iuf['tasks'][taskID]['seed'] == "" || iuf['tasks'][taskID]['seed'] != $("#seedValue").val();
	
	return !editable && seedChanged;
}

function resetOutputFields() {
	$('#task_info').addClass('hidden');	
	
	let fields = ['taskName',
				  'question',
				  'figure',
			      'points',
			      'type',
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

$('#task_info').on('click', '.editTrueFalse', function(e) {
	const taskID = getID();
	const newValue = iuf['tasks'][taskID]['result'][$(this).index('.mchoiceResult')] !== true;
		
	iuf['tasks'][taskID]['result'][$(this).index('.mchoiceResult')] = newValue;
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
}

$('body').on('focus', '[contenteditable]', function() {
    const $this = $(this);
    $this.data('before', $this.html());
}).on('blur', '[contenteditable]', function() {
    const $this = $(this);
    if ($this.data('before') !== $this.html()) {
		const taskID = getID();	
		const content = filterNodes($this.get(0), {p: [], br: [], a: ['href']});

		$this.html(content);
			
		if ($this.hasClass('taskNameText')) {
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskName').text(content);
			iuf['tasks'][taskID]['name'] = content;
		}
		
		if ($this.hasClass('questionText')) {
			iuf['tasks'][taskID]['question'] = content;
		}
		
		if ($this.hasClass('choiceText')) {
			iuf['tasks'][taskID]['choices'][$this.index('.choiceText')] = content;
		}
		
		if ($this.hasClass('points')) {
			iuf['tasks'][taskID]['points'] = parseInt(content);
		}
		
		if ($this.hasClass('topicText')) {
			iuf['tasks'][taskID]['topic'] = content;
		}

		setSimpleTaskFileContents(taskID);
		
		examTasksSummary();
    }
});

document.addEventListener('dblclick', (event) => {
  window.getSelection().selectAllChildren(event.target)
})

function loadTaskFromObject(taskID) {
	const editable = iuf['tasks'][taskID]['editable']; 
	
	$('.taskItem:nth-child(' + (taskID + 1) + ')').removeClass("editable");
	$('.taskItem:nth-child(' + (taskID + 1) + ') .taskParse').removeClass("disabled");
	
	if(iuf['tasks'][taskID]['name'] !== null) {	
		const field = 'taskName'
		const content = '<span class="taskNameText" contenteditable="' + editable + '" spellcheck="false">' + iuf['tasks'][taskID]['name'] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['question'] !== null) {
		const field = 'question'
		let content = ''
		
		if(Array.isArray(iuf['tasks'][taskID][field])) {
			content = '<span class="questionText" contenteditable="' + editable + '" spellcheck="false">' + iuf['tasks'][taskID][field].join('') + '</span>';
		} else {
			content = '<span class="questionText" contenteditable="' + editable + '" spellcheck="false">' + iuf['tasks'][taskID][field] + '</span>';
		}
		
		setTaskFieldFromObject(field, content);
	}
	
	if(editable) {
		const field = 'figure'
		
		const imgContet = iuf['tasks'][taskID]['figure'] !== null ? '<div class="taskFigureItem"><span class="taskFigureName"><img src="data:image/png;base64, ' + iuf['tasks'][taskID][field][2] + '"/></span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>' : '';
		
		const content = '<label class="taskFigureUpload" for="file-upload_taskFigure"><div class="taskFigureButton"><span class="iconButton"><i class="fa-solid fa-upload"></i></span><span class="textButton"><span lang="de">Importieren</span><span lang="en">Import</span></span></div><input type="file" id="file-upload_taskFigure" onchange="loadTaskFigureFileDialog(this.files);" multiple="" class="shiny-bound-input"></label><div id="taskFigureFiles"><div id="taskFigure_list" class="itemList"><div id="taskFigure_list_items">' + imgContet + '</div></div></div></div>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['points'] !== null) {	
		const field = 'points'
				
		const content = '<span class="points" contenteditable="' + editable + '" spellcheck="false">' + iuf['tasks'][taskID][field] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['type'] !== null) {
		const field = 'type'
		const content = '<span>' + iuf['tasks'][taskID][field] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
		
	if(iuf['tasks'][taskID]['type'] === "mchoice" || iuf['tasks'][taskID]['editable']) {
		const field = 'result'
		const zip = iuf['tasks'][taskID][field].map((x, i) => [x, iuf['tasks'][taskID]['choices'][i]]);
		let content = '<div id="resultContent">' + zip.map(i => '<p>' + (editable ? '<button type="button" class="removeAnswer btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></button>' : '') + '<span class=\"result mchoiceResult ' + (editable ? 'editTrueFalse' : '') + '\">' + getTrueFalseText(i[0]) + '</span><span class="choice"><span class="choiceText" contenteditable="' + editable + '" spellcheck="false">' + i[1] + '</span></span></p>').join('') + '</div>';
		
		if( iuf['tasks'][taskID]['editable'] ) {
			content = '<button id="addNewAnswer" type="button" class="btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-plus"></i></span><span class="textButton"><span lang="de">Neue Antwortmöglichkeit</span><span lang="en">New Answer</span></span></button>' + content;
		}
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['examHistory'] !== null) {
		const field = 'examHistory'
		const content = iuf['tasks'][taskID][field].map(i => '<span>' + i + '</span>').join('');
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['authoredBy'] !== null) {
		const field = 'authoredBy'
		const content = iuf['tasks'][taskID][field].map(i => '<span>' + i + '</span>').join('');
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['precision'] !== null) {
		const field = 'precision'
		const content = '<span>' + iuf['tasks'][taskID][field] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}

	if(iuf['tasks'][taskID]['topic'] !== null) {
		const field = 'topic'
		const content = '<span class="topicText" contenteditable="' + editable + '" spellcheck="false">' + iuf['tasks'][taskID][field] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['tags'] !== null) {
		const field = 'tags'
		const content = iuf['tasks'][taskID][field].map(i => '<span>' + i + '</span>').join('');
		
		setTaskFieldFromObject(field, content);
	}
	
	if(editable) {
		$('.taskItem:nth-child(' + (taskID + 1) + ')').addClass("editable");
		$('.taskItem:nth-child(' + (taskID + 1) + ') .taskParse').addClass("disabled");
	} 
		
	$('.taskItem.active').removeClass('active');
	$('.taskItem:nth-child(' + (taskID + 1) + ')').addClass('active');
	$('#task_info').removeClass('hidden');
	
	f_langDeEn();
}

function setSimpleTaskFileContents(taskID){
	let fileText = rnwTemplate;
	fileText = fileText.replace("?rnwTemplate_q", '"' + iuf['tasks'][taskID]['question'] + '"');
	fileText = fileText.replace("?rnwTemplate_c", 'c(' + iuf['tasks'][taskID]['choices'].map(c=>'"' + c + '"').join(',') + ')');
	fileText = fileText.replace("?rnwTemplate_s", 'c(' + iuf['tasks'][taskID]['result'].map(s=>s?"T":"F").join(',') + ')');
	fileText = fileText.replace("?rnwTemplate_p", iuf['tasks'][taskID]['points']);
	fileText = fileText.replace("?rnwTemplate_t", iuf['tasks'][taskID]['topic']);
	fileText = fileText.replace("?rnwTemplate_f", iuf['tasks'][taskID]['figure'] !== null ? 'c(' + iuf['tasks'][taskID]['figure'].map(c=>'"' + c + '"').join(',') + ')' : '""');
	fileText = fileText.replaceAll("\n", "\r\n");

	iuf['tasks'][taskID]['file'] = fileText;
}

function setTaskFieldFromObject(field, content) {
	$('#' + field).html(content);
	$('#' + field).show();
	if($('label[for="'+ field +'"]').length > 0) $('label[for="'+ field +'"]').show();
}

function addTask() {
	tasks = tasks + 1;	
	iuf['tasks'].splice(tasks, 0, new Array());
}

function removeTask(taskID) {
	iuf['tasks'].splice(taskID, 1);
	tasks = tasks - 1;
	
	examTasksSummary();
}

function changeTaskBlock(taskID, b) {
	b_ = 1;
	
	if(Number(b) != NaN) {
		b_ = Math.max(1, Number(b));
		iuf['tasks'][taskID]['block'] = b_;
		examTasksSummary();
	} 
	
	return b_;
}

function setExamTask(taskID, b) {
	iuf['tasks'][taskID]['exam'] = b;
	
	examTasksSummary();
}

$('#task_list_items').on('change', '.taskBlock input', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	$(this).closest('.taskItem .taskBlock input').val(changeTaskBlock($(this).closest('.taskItem').index('.taskItem'), $(this).closest('.taskItem .taskBlock input').val()));
	
	examTasksSummary();
});

$('#task_list_items').on('click', '.taskParse', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	viewTask($(this).closest('.taskItem').index('.taskItem'));
});

$('#task_list_items').on('click', '.examTask', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	$(this).closest('.taskItem').toggleClass('exam');	
	setExamTask($(this).closest('.taskItem').index('.taskItem'), $(this).closest('.taskItem').hasClass('exam'));
});

$('#task_list_items').on('click', '.taskRemove', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	resetOutputFields();
	
	if($(this).closest('.taskItem').hasClass('active')) {
		Shiny.onInputChange("resetTaskOutputFields", 1);
	}
	
	const taskID = $(this).closest('.taskItem').index('.taskItem');
	removeTask(taskID);
	$(this).closest('.taskItem').remove();
	
	if($('.taskItem').length > 0) {
		$('.taskItem.active').removeClass('active');
		$('.taskItem:nth-child(' + Math.min(taskID + 1, $('.taskItem').length) + ')').addClass('active');
		viewTask($('.taskItem.active').first().index('.taskItem'));
	}
});

$('#task_list_items').on('click', '.taskItem', function() {
	$('.taskItem.active').removeClass('active');
	$(this).addClass('active');
		
	viewTask($(this).index('.taskItem'));
});

$('#task_info').on('click', '#addNewAnswer', function() {
	const taskID = getID();
	
	iuf['tasks'][taskID]['choices'].push(d_answerText);
	iuf['tasks'][taskID]['result'].push(d_result);
	
	setSimpleTaskFileContents(taskID);
	loadTaskFromObject(taskID);
	
	f_langDeEn();
});

$('#task_info').on('click', '.removeAnswer', function() {
	const taskID = getID();
	const choicesID = $('.removeAnswer').index('.removeAnswer');
	
	if( iuf['tasks'][taskID]['choices'].length > 0 ) {	
		iuf['tasks'][taskID]['choices'].splice(choicesID, 1);
		iuf['tasks'][taskID]['result'].splice(choicesID, 1);
	} 
	
	setSimpleTaskFileContents(taskID);
	loadTaskFromObject(taskID);
});

$("#exportTask").click(function(){
	const taskID = getID();
	
	if( iuf['tasks'][taskID]['editable'] ) {
		handleDuplicateAnswers(taskID);
		setSimpleTaskFileContents(taskID);
	}
	
	const fileContent = iuf['tasks'][taskID]['file'];
	let fileName = iuf['tasks'][taskID]['name'];
	fileName = convertToValidFilename(fileName);
	
	download(fileContent, fileName + '.rnw', 'text/plain;charset=utf-8;');
}); 

function handleDuplicateAnswers(taskID) {
	let choices = iuf['tasks'][taskID]['choices'];
	let result = iuf['tasks'][taskID]['result'];
	const duplicates = choices.flatMap((item, index) => choices.indexOf(item) !== index ? index : [] );
		
	if( duplicates.length > 0 ) {
		for (let i = duplicates.length -1; i >= 0; i--) {
			choices.splice(duplicates[i], 1);
			result.splice(duplicates[i], 1);
		}
		
		if( choices.length <= 0 ) {
			choices = ["AnswerText"];
			result = [false];
		}
		
		iuf['tasks'][taskID]['choices'] = choices;
		iuf['tasks'][taskID]['result'] = result;
	}
}

function convertToValidFilename(string) {
    return (string.replace(/[\/|\\:*?"<>]/g, " "));
}

function download(content, fileName, contentType) {
	let a = document.createElement("a");
	let file = new Blob([content], {type: contentType});
	a.href = URL.createObjectURL(file);
	a.download = fileName;
	a.click();
	a.remove();
}

function taskExportAllProxy() {	
	const taskNames = iuf['tasks'].map(task => task.name);
	const taskCodes = iuf['tasks'].map(task => task.file);
	
	Shiny.onInputChange("taskExportAllProxy", {taskNames:taskNames, taskCodes: taskCodes}, {priority: 'event'});	
}

// Shiny.addCustomMessageHandler('taskDownloadAll', function(x) {
	// // TODO:
	// // does fire infinitely
	// // works when copied into browser console
	// $('#taskDownloadAll')[0].click();
// });

function loadTaskFigureFileDialog(items) {+	
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if( fileExt == 'png' ) {
			addTaskFigureFile(file);
		}
	});
}

function addTaskFigureFile(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	if ( fileExt == 'png' ) {
		const taskID = getID();
		
		let fileReader;
		let base64;
		let fileName;
		
		fileReader = new FileReader();
		fileName = file.name.split('.')[0];

		fileReader.onload = function(fileLoadedEvent) {
			base64 = fileLoadedEvent.target.result;
			iuf['tasks'][taskID]['figure'] = [fileName, fileExt, base64.split(',')[1]];
			
			$('#figure').empty();
			$('#figure').append('<label class="taskFigureUpload" for="file-upload_taskFigure"><div class="taskFigureButton"><span class="iconButton"><i class="fa-solid fa-upload"></i></span><span class="textButton"><span lang="de">Importieren</span><span lang="en">Import</span></span></div><input type="file" id="file-upload_taskFigure" onchange="loadTaskFigureFileDialog(this.files);" multiple="" class="shiny-bound-input"></label><div id="taskFigureFiles"><div id="taskFigure_list" class="itemList"><div id="taskFigure_list_items"><div class="taskFigureItem"><span class="taskFigureName"><img src="data:image/png;base64, ' + iuf['tasks'][getID()]['figure'][2] + '"/></span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div></div></div></div></div>');
			
			setSimpleTaskFileContents(taskID);
			loadTaskFromObject(taskID);
		};

		fileReader.readAsDataURL(file);
	}
}

function removeTaskFigure(element) {
	const taskID = getID();
	
	iuf['tasks'][taskID]['figure'] = null;
	element.remove();
	
	setSimpleTaskFileContents(taskID);
	loadTaskFromObject(taskID);
}

$('#figure').on('click', '.taskFigureItem', function() {
	removeTaskFigure($(this));
});

getID = function() {
	return(taskID_hook == -1 ? $('.taskItem.active').index('.taskItem') : taskID_hook);
}

Shiny.addCustomMessageHandler('setTaskId', function(taskID) {
	taskID_hook = taskID;
});

Shiny.addCustomMessageHandler('setTaskSeed', function(seed) {
	iuf['tasks'][getID()]['seed'] = seed;
});

Shiny.addCustomMessageHandler('setTaskExamHistory', function(jsonData) {
	const examHistory = JSON.parse(jsonData);
	iuf['tasks'][getID()]['examHistory'] = examHistory;
});

Shiny.addCustomMessageHandler('setTaskAuthoredBy', function(jsonData) {
	const taskAuthors = JSON.parse(jsonData);
	iuf['tasks'][getID()]['authoredBy'] = taskAuthors;
});

Shiny.addCustomMessageHandler('seTasktPrecision', function(taskPrecision) {
	iuf['tasks'][getID()]['precision'] = taskPrecision;
});

Shiny.addCustomMessageHandler('setTaskPoints', function(taskPoints) {
	iuf['tasks'][getID()]['points'] = taskPoints;
});

Shiny.addCustomMessageHandler('setTaskTopic', function(taskTopic) {
	iuf['tasks'][getID()]['topic'] = taskTopic;
});

Shiny.addCustomMessageHandler('setTaskTags', function(jsonData) {
	const taskTags = JSON.parse(jsonData);
	iuf['tasks'][getID()]['tags'] = taskTags;
});

Shiny.addCustomMessageHandler('setTaskType', function(taskType) {
	iuf['tasks'][getID()]['type'] = taskType;
});

Shiny.addCustomMessageHandler('setTaskQuestion', function(taskQuestion) {
	iuf['tasks'][getID()]['question'] = taskQuestion;
});

Shiny.addCustomMessageHandler('setTaskFigure', function(jsonData) {
	const figure = JSON.parse(jsonData);
	
	iuf['tasks'][getID()]['figure'] = figure;
});

Shiny.addCustomMessageHandler('setTaskChoices', function(jsonData) {
	const taskChoices = JSON.parse(jsonData);
	iuf['tasks'][getID()]['choices'] = taskChoices;
});

Shiny.addCustomMessageHandler('setTaskResultMchoice', function(jsonData) {
	const taskResult = JSON.parse(jsonData);
	iuf['tasks'][getID()]['result'] = taskResult;
});

Shiny.addCustomMessageHandler('setTaskResultNumeric', function(taskResult) {
	iuf['tasks'][getID()]['result'] = taskResult;
});

Shiny.addCustomMessageHandler('setTaskEditable', function(editable) {
	iuf['tasks'][getID()]['editable'] = (editable === 1);
});

Shiny.addCustomMessageHandler('setTaskE', function(jsonData) {
	e = JSON.parse(jsonData);
		
	const taskID = getID();
	
	$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatch').removeClass('Warning');
	$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatch').removeClass('Error');
	$('.taskItem:nth-child(' + (taskID + 1) + ') .examTask').removeClass('disabled');
	$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatchText').text('');
	
	const message = e.value.replaceAll('%;%', '<br><br>');
	
	switch(e.key) {
		case "Success": 
			iuf['tasks'][taskID]['e'] = e.key;
			loadTaskFromObject(taskID); 
			break;
		case "Warning": 
			iuf['tasks'][taskID]['e'] = e.key + ':<br>' + message;
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatch').addClass('Warning');
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatchText').html(iuf['tasks'][taskID]['e']);
			loadTaskFromObject(taskID); 
			break;
		case "Error": 
			iuf['tasks'][taskID]['e'] = e.key + ':<br>' + message;
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatch').addClass('Error');
			$('.taskItem:nth-child(' + (taskID + 1) + ') .examTask').addClass('disabled');
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatchText').html(iuf['tasks'][taskID]['e']);
			break;
	}
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
		
		$('#additionalPdf_list_items').append('<div class="additionalPdfItem"><span class="additionalPdfName">' + fileName + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
	}
}

function removeAdditionalPdf(element) {
	const additionalPdfID = element.index('.additionalPdfItem');
	iuf['examAdditionalPdf'].splice(additionalPdfID, 1);
	element.remove();
}

$('#additionalPdf_list_items').on('click', '.additionalPdfItem', function() {
	removeAdditionalPdf($(this));
});

$("#numberOfExams").change(function(){
	$('#s_numberOfExams').html(itemSingle($(this).val(), 'grayLabel'));
}); 

$("#autofillSeed").click(function(){
	$('#seedValueExam').val($('#seedValue').val());
}); 

$("#numberOfFixedPoints").change(function(){
	const text = $('#s_numberOfTasks span').text();
	$('#s_numberOfTasks span').text(text.replace(/^.+\//, $('#numberOfTasks').val() + '/' ));
}); 

$("#autofillNumberOfTasks").click(function(){
	$('#numberOfTasks').val(getNumberOfExamTasks());
}); 

$("#createExamEvent").click(function(){
	createExamEvent();
}); 

async function createExamEvent() {
	const examTasks = iuf['tasks'].filter((task) => task.exam & task.file !== null);
	const taskNames = examTasks.map((task) => task.name);
	const taskCodes = examTasks.map((task) => task.file);
	const blocks = examTasks.map((task) => task.block);
	const additionalPdfNames = iuf.examAdditionalPdf.map(pdf => pdf[0]);
	const additionalPdfFiles = iuf.examAdditionalPdf.map(pdf => pdf[1]);
	
	Shiny.onInputChange("createExam", {examSeed: $('#seedValueExam').val(), numberOfExams: $("#numberOfExams").val(), numberOfTasks: $("#numberOfTasks").val(), taskNames: taskNames, taskCodes:taskCodes, blocks: blocks, additionalPdfNames: additionalPdfNames, additionalPdfFiles: additionalPdfFiles}, {priority: 'event'});
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
			
			$('#examScan_list_items').append('<div class="examScanItem"><span class="examScanName">' + fileName + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
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
			$('#examSolutions_list_items').append('<div class="examSolutionsItem"><span class="examSolutionsName">' + fileName + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
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
			$('#examRegisteredParticipants_list_items').append('<div class="examRegisteredParticipantsItem"><span class="examRegisteredParticipantsName">' + fileName + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
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
		
	$('#inspectScan').append('<div id="focusedCompareListItem"></div><div id="inspectScanContent"><div id="inspectScanImage"><img src="data:image/png;base64, ' + scanFocused.blob + '"/></div><div id="inspectScanTemplate"><span id="scannedRegistration"><span id="scannedRegistrationText"><span lang="de">Matrikelnummer:</span><span lang="en">Registration Number:</span></span><select id="selectRegistration" autocomplete="on"></select></span><span id="scannedSheetID"><span id="scannedSheetIDText"><span lang="de">Klausur-ID:</span><span lang="en">Exam ID:</span></span><input id="inputSheetID" type="number" min="0" max="99999999999" step="1"/></span><span id="scannedScramblingID"><span id="scannedScramblingIDText"><span lang="de">Variante:</span><span lang="en">Scrambling:</span></span><input id="inputScramblingID" type="number" min="0" max="99"  step="1"/></span><span id="scannedTypeID"><span id="scannedTypeIDText"><span lang="de">Belegart:</span><span lang="en">Type:</span></span><input id="inputTypeID" type="number" min="0" max="999" step="1"/></span>	<table id="scannedAnswers"></table></div></div><div id="inspectScanButtons"><button id="cancleInspect" class="inspectScanButton" type="button" class="btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-xmark"></i></span><span class="textButton"><span lang="de">Abbrechen</span><span lang="en">Cancle</span></span></button><button id="applyInspect" class="inspectScanButton" type="button" class="btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-check"></i></span><span class="textButton"><span lang="de">Übernehmen</span><span lang="en">Apply</span></span></button></div>')
	
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
	
	$('#focusedCompareListItem').append($(this));
	
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
	$('#compareScanRegistrationDataTable').append($('#focusedCompareListItem .compareListItem'));
	$('#inspectScan').empty();
}

$('body').on('click', '#applyInspect', function() {
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
});

$('body').on('click', '#cancleInspect', function() {
	resetInspect();
	sortCompareListItems();
});

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
