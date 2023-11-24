/**
* Script
*
*/

/* --------------------------------------------------------------
 DOCUMENT READY 
-------------------------------------------------------------- */
$(document).ready(function () {
	iuf['tasks'] = new Array();
	iuf['examAdditionalPDF'] = new Array();
	
	$('#s_initialSeed').html(itemSingle($('#seedValue').val(), 'greenLabel'));
	$('#s_numberOfExams').html(itemSingle($('#numberOfExams').val(), 'grayLabel'));
	
	f_langDeEn();
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

/* --------------------------------------------------------------
 KEY EVENTS 
-------------------------------------------------------------- */
document.onkeyup = function(evt) {
	const evtobj = window.event? event : evt
	
	if (evtobj.shiftKey && evtobj.keyCode == 70) {
		const searchField = $('#searchTasks').find('input');
		const searchValLength = searchField.val().length;
		searchField.focus();
		searchField[0].setSelectionRange(searchValLength, searchValLength);
	}
}

document.onkeydown = function(evt) {
	const evtobj = window.event? event : evt
	
	// TASKS
	if ($(evtobj.target).is('input') && evtobj.keyCode == 13) {
		$(evtobj.target).change();
		$(evtobj.target).blur();
	}
	
	if( $('#tasks').hasClass('active') ) {
		if (evtobj.keyCode == 27) { // ESC
			$('#searchTasks input').val("");
			$('.taskItem').removeClass("filtered");
		}
		
		if (evtobj.keyCode == 67) { // c
			newSimpleTask();
		}
		
		const targetInput = $(evtobj.target).is('input');
		const targetEditable = $(evtobj.target).attr('contenteditable');
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
			} else {
				switch (evtobj.keyCode) {
					case 65: // a
						if ($('.taskItem.active:not(.filtered)').length > 0 && !$('.taskItem.active:not(.filtered) .examTask').hasClass('disabled')) {
							$('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').toggleClass('exam');	
							toggleExamTask($('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').index('.taskItem:not(.filtered)'), $('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').hasClass('exam'));
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
						viewTask($('.taskItem.active:not(.filtered)').first().index('.taskItem'), true);
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
	} else {
		$('#disableOverlay').removeClass("active");
	}
});

/* --------------------------------------------------------------
 NAV 
-------------------------------------------------------------- */
$('#tasksNav').parent().click(function () {	
	$('.mainSection').removeClass('active');
	$('#tasks').addClass('active');
});

$('#examNav').parent().click(function () {	
	$('.mainSection').removeClass('active');
	$('#exam').addClass('active');
});

$('#helpNav').parent().click(function () {	
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
	$('#buttonModeSwitchContainer').find('.active').removeClass('active');
	$(this).addClass('active');
	
	$('body').removeClass("iconButtonMode");
	$('body').removeClass("textButtonMode");
	
	switch( $(this).attr('id') ) {
		case "iconButtons": 
			$('body').addClass("iconButtonMode");
			break;
		case "textButtons": 
			$('body').addClass("textButtonMode");
			break;
	}

	f_langDeEn();
});

/* --------------------------------------------------------------
 LANGUAGE 
-------------------------------------------------------------- */
$('#languageSwitchContainer span').click(function () {
	$('#languageSwitchContainer').find('.active').removeClass('active');
	$(this).addClass('active');
	
	setLanguageCookie($(this).text().toLowerCase());
	f_langDeEn();
});

function f_langDeEn() {
	let lang = $('#languageSwitchContainer').find('.active').text().toLowerCase();
	
	if (getLanguageCookie() == 'en') {
		lang = getLanguageCookie()
		$('#languageSwitchContainer').find('.active').removeClass('active');
		$('#enLang').addClass('active');	
	} else {
		lang = getLanguageCookie()
		$('#languageSwitchContainer').find('.active').removeClass('active');
		$('#deLang').addClass('active');	
	}

	/* switch to EN */
	if ( lang === 'en' ) {
		iuf['language'] = 'en';
		
		$('html').attr('lang', 'en');
		$('html').attr('xml:lang', 'en');
		
		$('[lang="de"]').hide();
		$('[lang="en"]').show();
	/* switch to DE */
	} else {
		iuf['language'] = 'de';
		
		$('html').attr('lang', 'de');
		$('html').attr('xml:lang', 'de');
		
		$('[lang="en"]').hide();
		$('[lang="de"]').show();
	}
}

$('#languageSwitchContainer span').click(function () {
	$('#languageSwitchContainer').find('.active').removeClass('active');
	$(this).addClass('active');
	
	setLanguageCookie($(this).text().toLowerCase());
	f_langDeEn();
});

function setLanguageCookie(lang) {
    document.cookie = 'IuF_JS_lang=' + lang + ';path=/;SameSite=Lax';
}

function getLanguageCookie() {
    const name = 'IuF_JS_lang';
    const ca = document.cookie.split(';');
    for(let i=0;i < ca.length;i++) {
        const c = ca[i];
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
	
Shiny.addCustomMessageHandler('setExamLanguageChoices', function(test) {
    $('#examLanguage').parent().find('.selectize-dropdown-content div').each(function (index, element) {	
		element.innerHTML = '<span lang="de">' + languages[element.attributes['data-value'].nodeValue][0] + '</span><span lang="en">' + languages[element.attributes['data-value'].nodeValue][1] + '</span>';
	});
		
	f_langDeEn();
});			   

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
		$('#s_averageDifficulty').html("");
		$('#s_totalPoints').html("");
		$('#s_topicsTable').html("");
		$('#s_tagsTable').html("");
		$('#s_typeTable').html("");
		$('#s_tasksChecked').html("");
		
		return;
	}
	
	let numberOfExamTasksCounter = 0;
	let totalDifficulty = 0;
	let totalPoints = 0;
	let topics = [];
	let tags = [];
	let types = [];
	let checkedBy = 0;
		
	iuf['tasks'].forEach((item, index) => {
		if(item.exam) {
			numberOfExamTasksCounter++;
			totalDifficulty += Number(item.difficulty);
			totalPoints += Number(item.points);
			if (item.topic !== null) topics.push(item.topic);
			if (item.tags !== null) item.tags.forEach(i => tags.push(i));
			Array.isArray(item.result) ? types.push("mc") : types.push("num");
			checkedBy += (item.checkedBy != "" && item.checkedBy !== null);
		}
	})
	
	$('#s_numberOfTasks').html(itemSingle(numberOfExamTasksCounter, 'grayLabel'));
	$('#s_averageDifficulty').html(itemSingle(Math.round(totalDifficulty / numberOfExamTasksCounter * 100)/100, 'yellowLabel'));	
	$('#s_totalPoints').html(itemSingle(totalPoints, 'yellowLabel'));
	$('#s_topicsTable').html(itemTable(topics));
	$('#s_tagsTable').html(itemTable(tags));
	$('#s_typeTable').html(itemTable(types));
	$('#s_tasksChecked').html(itemSingle(checkedBy + "/" + numberOfExamTasksCounter, 'grayLabel'));
}

function itemSingle(item, className) {
	return '<span class="s_labelSingle ' + className + '">' + item + '</span>';
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
		
		viewTask(index, true)
	});	
}

$('#newTask').click(function () {
	newSimpleTask();
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
		
		if (input.includes("checkedBy:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.checkedBy === null) {
					return "";
				} 
				
				return task.checkedBy.join(',');
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
		
		if (input.includes("difficulty:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.difficulty === null) {
					return "";
				} 
				
				return task.difficulty;
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
				
				loadTasksDnD(e.dataTransfer.items);
			});
		}
	},
};

window.addEventListener('DOMContentLoaded', dndTasks.init);

function loadTasksDnD(items) {	
	let blockNum = getBlockNum();
	
	getFilesDataTransferItems(items).then(async (files) => {
		Array.from(files).forEach(file => {	
			loadTask(file, blockNum);
		});
	});
}

function loadTasksFileDialog(items) {	
	let blockNum = getBlockNum();
	
	items.forEach(function(file) {
		loadTask(file, blockNum);
	});
}

function getBlockNum() {
	const blockNum = Math.max(...iuf['tasks'].map(x => x.block))+1;
	return String(blockNum > 0 ? blockNum : 1);
}

function loadTask(file, block = 1) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	switch(fileExt) {
		case 'rnw':
			newComplexTask(file, block);
			break;
	}
}

const d_taskName = 'taskName';
const d_questionText = 'QuestionText';
const d_answerText = 'AnswerText';
const d_result = false;

function newSimpleTask(file = '', block = 1) {
	const taskID = tasks + 1
		addTask();
		createTask(taskID, d_taskName, 
					       null, 
					       d_questionText,
					       [d_answerText, d_answerText, d_answerText, d_answerText, d_answerText],
					       [d_result, d_result, d_result, d_result, d_result],
					       null,
					       true,
						   "mchoice");
		viewTask(taskID);
}

async function newComplexTask(file, block) {
	const taskID = tasks + 1
	addTask();
	
	const fileText = await file.text();
	createTask(taskID, file.name.split('.')[0], fileText);
	
	viewTask(taskID, true);
}

function createTask(taskID, name='task', 
							file=null,
						    question='',
						    choices=[],
							result=[],
							e=null,
							editable=false,
							type=null,
							seed=null, 
						    exam=false, 
							examHistory=null,
							authoredBy=null,
							checkedBy=null,
							precision=null,
							difficulty=null,
							points=null,
							topic=null,
							tags=null,
							block=1){
	iuf['tasks'][taskID]['file'] = file;
	iuf['tasks'][taskID]['name'] = name;
	iuf['tasks'][taskID]['seed'] = seed;
	iuf['tasks'][taskID]['exam'] = exam;
	iuf['tasks'][taskID]['question'] = question;
	iuf['tasks'][taskID]['choices'] = choices;
	iuf['tasks'][taskID]['result'] = result;
	iuf['tasks'][taskID]['examHistory'] = examHistory;
	iuf['tasks'][taskID]['authoredBy'] = authoredBy;
	iuf['tasks'][taskID]['checkedBy'] = checkedBy;
	iuf['tasks'][taskID]['precision'] = precision;
	iuf['tasks'][taskID]['difficulty'] = difficulty;
	iuf['tasks'][taskID]['points'] = points;
	iuf['tasks'][taskID]['topic'] = topic;
	iuf['tasks'][taskID]['tags'] = tags;
	iuf['tasks'][taskID]['type'] = type;
	iuf['tasks'][taskID]['e'] = e;	
	iuf['tasks'][taskID]['editable'] = editable;
	iuf['tasks'][taskID]['block'] = block;
	
	if( file === null) {
		setSimpleTaskFileContents(taskID);
	}
	
	$('#task_list_items').append('<div class="taskItem sidebarListItem"><span class="taskTryCatch"><i class="fa-solid fa-triangle-exclamation"></i><span class="taskTryCatchText"></span></span><span class="taskName">' + name + '</span></span><span class="taskBlock disabled"><input type="number" value="' + block + '"/></span><span class="taskButtons"><span class="taskParse taskButton"><span class="iconButton"><i class="fa-solid fa-rotate"></i></span><span class="textButton"><span lang="de">Berechnen</span><span lang="en">Prase</span></span></span><span class="examTask taskButton"><span class="iconButton"><i class="fa-solid fa-circle-check"></i></span><span class="textButton"><span lang="de">Prüfungsrelevant</span><span lang="en">Examinable</span></span></span><span class="taskRemove taskButton"><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></span></span></div>');
}

function parseTask(taskID) {	
	const taskCode = iuf['tasks'][taskID].file;
	
	Shiny.onInputChange("parseExercise", {taskCode: taskCode, taskID: taskID}, {priority: 'event'});	
}

function numberOfExamTasks() {
	Shiny.onInputChange("setNumberOfExamTasks", getNumberOfExamTasks(), {priority: 'event'});
}

function numberOfTaskBlocks() {
	Shiny.onInputChange("setNumberOfTaskBlocks", getNumberOfTaskBlocks(), {priority: 'event'});
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

function viewTask(taskID, forceParse = false) {
	resetOutputFields();
	
	const editable = iuf['tasks'][taskID]['editable'] 
	const seedChanged = iuf['tasks'][taskID]['seed'] == "" || iuf['tasks'][taskID]['seed'] != $("#seedValue").val();
	const previousParseFailed = iuf.tasks[taskID].e !== null && !iuf.tasks[taskID].e.includes("Success: ");
	const parse = !editable && (forceParse || seedChanged || previousParseFailed);

	if(parse) {
		parseTask(taskID);	
	} else {
		loadTaskFromObject(taskID);
	}
		
	f_langDeEn();
}

function resetOutputFields() {
	$('#task_info').addClass('hidden');	
	
	let fields = ['taskName',
				  'question',
			      'points',
			      'type',
			      'result',
			      'examHistory',
			      'authoredBy',
			      'checkedBy',
			      'precision',
			      'difficulty',
			      'topic',
			      'tags'];
			  
	fields.forEach(field => {	
		$('#' + field).html('');
		$('#' + field).hide();
		$('label[for="'+ field +'"]').hide();
	});	
}

$('#task_info').on('click', '.editTrueFalse', function(e) {
	$(this).text(+ !(($(this).text() === '1')));
	
	const taskID = getID();
	
	iuf['tasks'][taskID]['result'][$(this).index('.mchoiceResult')] = $(this).text() === '1';
});

$('body').on('focus', '[contenteditable]', function() {
    const $this = $(this);	
    $this.data('before', $this.html());
}).on('blur', '[contenteditable]', function() {
    const $this = $(this);
    if ($this.data('before') !== $this.html()) {
		const taskID = getID();
		
		if ($this.hasClass('taskNameText')) {
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskName').text($this.text());
			iuf['tasks'][taskID]['name'] = $this.text();
		}
		
		if ($this.hasClass('questionText')) {
			iuf['tasks'][taskID]['question'] = $this.text();
		}
		
		if ($this.hasClass('choiceText')) {
			iuf['tasks'][taskID]['choices'][$this.index('.choiceText')] = $this.text();
		}

		setSimpleTaskFileContents(taskID);
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
		
		if(Array.isArray(iuf['tasks'][taskID]['question'])) {
			content = '<span class="questionText" contenteditable="' + editable + '" spellcheck="false"> ' + iuf['tasks'][taskID]['question'].join('') + '</span>';
		} else {
			content = '<span class="questionText" contenteditable="' + editable + '" spellcheck="false">' + iuf['tasks'][taskID]['question'] + '</span>';
		}
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['points'] !== null) {	
		const field = 'points'
		const content = '<span>' + iuf['tasks'][taskID]['points'] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['type'] !== null) {
		const field = 'type'
		const content = '<span>' + iuf['tasks'][taskID]['type'] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
		
	if(iuf['tasks'][taskID]['type'] === "mchoice" || iuf['tasks'][taskID]['editable']) {
		const field = 'result'
		const zip = iuf['tasks'][taskID]['result'].map((x, i) => [x, iuf['tasks'][taskID]['choices'][i]]);
		let content = '<div id="resultContent">' + zip.map(i => '<p>' + (editable ? '<button type="button" class="removeAnswer btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></button>' : '') + '<span class=\"result mchoiceResult ' + (editable ? 'editTrueFalse' : '') + '\">' + ( + i[0]) + '</span><span class="choice"><input type=\"checkbox\" name=\"\" value=\"\"><span class="choiceText" contenteditable="' + editable + '" spellcheck="false">' + i[1] + '</span></span></p>').join('') + '</div>';
		
		if( iuf['tasks'][taskID]['editable'] ) {
			content = '<button id="addNewAnswer" type="button" class="btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-plus"></i></span><span class="textButton"><span lang="de">Neue Antwortmöglichkeit</span><span lang="en">New Answer</span></span></button>' + content;
		}
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['type'] === "num") {
		const field = 'resultContent'
		const content = '<div><p><span class=\"result numericResult\">' + iuf['tasks'][taskID]['result'] + '</span><span class="solution"><input type=\"text\" class=\"form-control shinyjs-resettable shiny-bound-input\"></span></p></div>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['examHistory'] !== null) {
		const field = 'examHistory'
		const content = iuf['tasks'][taskID]['examHistory'].map(i => '<span>' + i + '</span>').join('');
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['authoredBy'] !== null) {
		const field = 'authoredBy'
		const content = iuf['tasks'][taskID]['authoredBy'].map(i => '<span>' + i + '</span>').join('');
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['checkedBy'] !== null) {
		const field = 'checkedBy'
		const content = iuf['tasks'][taskID]['checkedBy'].map(i => '<span>' + i + '</span>').join('');
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['precision'] !== null) {
		const field = 'precision'
		const content = '<span>' + iuf['tasks'][taskID]['precision'] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['difficulty'] !== null) {
		const field = 'difficulty'
		const content = '<span>' + iuf['tasks'][taskID]['difficulty'] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['topic'] !== null) {
		const field = 'topic'
		const content = '<span>' + iuf['tasks'][taskID]['topic'] + '</span>';
		
		setTaskFieldFromObject(field, content);
	}
	
	if(iuf['tasks'][taskID]['tags'] !== null) {
		const field = 'tags'
		const content = iuf['tasks'][taskID]['tags'].map(i => '<span>' + i + '</span>').join('');
		
		setTaskFieldFromObject(field, content);
	}
	
	if(editable) {
		$('.taskItem:nth-child(' + (taskID + 1) + ')').addClass("editable");
		$('.taskItem:nth-child(' + (taskID + 1) + ') .taskParse').addClass("disabled");
	} 
		
	$('.taskItem.active').removeClass('active');
	$('.taskItem:nth-child(' + (taskID + 1) + ')').addClass('active');
	$('#task_info').removeClass('hidden');
}

function setSimpleTaskFileContents(taskID){
	let fileText = rnwTemplate;
	fileText = fileText.replace("?q", '"' + iuf['tasks'][taskID]['question'] + '"');
	fileText = fileText.replace("?c", 'c(' + iuf['tasks'][taskID]['choices'].map(c=>'"' + c + '"').join(',') + ')');
	fileText = fileText.replace("?s", 'c(' + iuf['tasks'][taskID]['result'].map(s=>s?"T":"F").join(',') + ')');
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
	b_value = 1;
	
	if(Number(b) != NaN) {
		b_value = Math.max(1, Number(b));
		iuf['tasks'][taskID]['block'] = b_value;
		numberOfTaskBlocks();
	} 
	
	return b_value;
}

function toggleExamTask(taskID, b) {
	iuf['tasks'][taskID]['exam'] = b;
	
	examTasksSummary();
}

$('#task_list_items').on('change', '.taskBlock input', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	$(this).closest('.taskItem .taskBlock input').val(changeTaskBlock($(this).closest('.taskItem').index('.taskItem'), $(this).closest('.taskItem .taskBlock input').val()));
});

$('#task_list_items').on('click', '.taskParse', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	viewTask($(this).closest('.taskItem').index('.taskItem'), true);
});

$('#task_list_items').on('click', '.examTask', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	$(this).closest('.taskItem').toggleClass('exam');	
	toggleExamTask($(this).closest('.taskItem').index('.taskItem'), $(this).closest('.taskItem').hasClass('exam'));
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

function resetValidation() {
	$('#resultContent').find('.correct').removeClass('correct');
	$('#resultContent').find('.incorrect').removeClass('incorrect');
}

function validateAnswer() {
	resetValidation();
	
	if($('#resultContent').find('input').length == 1) {
		Number($('#resultContent input').val().replace(',', '.')) === Number(iuf.tasks[getID()].result) ? $('#resultContent input').addClass('correct') : $('#resultContent input').addClass('incorrect');
		
		setTimeout(function(){
			resetValidation();
		}, 1000);
	} 
	
	if($('#resultContent').find('input').length > 1) {
		resetValidation();

		let correct = true;		
		$('#resultContent input[type=checkbox]').each(function (index, element) {		
			correct = correct && element.checked === iuf.tasks[getID()].result[index]; 
		});
		
		correct ? $('#resultContent input[type=checkbox]').nextAll('span').addClass('correct') : $('#resultContent input[type=checkbox]').nextAll('span').addClass('incorrect');
		
		setTimeout(function(){
			resetValidation();
		}, 1000);
	} 
}

$('#task_info').on('click', '#addNewAnswer', function() {
	const taskID = getID();
	
	iuf['tasks'][taskID]['choices'].push(d_answerText);
	iuf['tasks'][taskID]['result'].push(d_result);
	
	loadTaskFromObject(taskID);
});

$('#task_info').on('click', '.removeAnswer', function() {
	const taskID = getID();
	const choicesID = $('.removeAnswer').index('.removeAnswer');
	
	if( iuf['tasks'][taskID]['choices'].length > 0 ) {	
		iuf['tasks'][taskID]['choices'].splice(choicesID, 1);
		iuf['tasks'][taskID]['result'].splice(choicesID, 1);
	} 
	
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

$('#validateAnswer_preview').click(function () {
	validateAnswer();
});

$('#result').on('mouseenter', '.result', function() {
    $('#resultContent .result').addClass( "spoiler");
});

$('#result').on('mouseleave', '.result', function() {
    $('#resultContent .result').removeClass( "spoiler");
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

Shiny.addCustomMessageHandler('setTaskCheckedBy', function(jsonData) {
	const taskCheckers = JSON.parse(jsonData);
	iuf['tasks'][getID()]['checkedBy'] = taskCheckers;
});

Shiny.addCustomMessageHandler('seTasktPrecision', function(taskPrecision) {
	iuf['tasks'][getID()]['precision'] = taskPrecision;
});

Shiny.addCustomMessageHandler('setTaskDifficulty', function(taskDifficulty) {
	iuf['tasks'][getID()]['difficulty'] = taskDifficulty;
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
	const taskID = getID();
	
	iuf['tasks'][taskID]['editable'] = editable === 1;
	
	if(iuf['tasks'][taskID]['editable']) {
		$('.taskItem.active').addClass('editable');
	} else {
		$('.taskItem.active').removeClass('editable');
	}
});

Shiny.addCustomMessageHandler('setTaskE', function(jsonData) {
	e = JSON.parse(jsonData)
		
	const taskID = getID();
	
	$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatch').removeClass('Warning');
	$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatch').removeClass('Error');
	$('.taskItem:nth-child(' + (taskID + 1) + ') .examTask').removeClass('disabled');
	$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatchText').text('');
	
	switch(e.key) {
		case "Success": 
			iuf['tasks'][taskID]['e'] = e.key + ': ' + e.value;
			loadTaskFromObject(taskID); 
			break;
		case "Warning": 
			iuf['tasks'][taskID]['e'] = e.key + ': ' + e.value;
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatch').addClass('Warning');
			$('.taskItem:nth-child(' + (taskID + 1) + ') .examTask').addClass('disabled');
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatchText').text(iuf['tasks'][taskID]['e']);
			break;
		case "Error": 
			iuf['tasks'][taskID]['e'] = e.key + ': ' + e.value;
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatch').addClass('Error');
			$('.taskItem:nth-child(' + (taskID + 1) + ') .examTask').addClass('disabled');
			$('.taskItem:nth-child(' + (taskID + 1) + ') .taskTryCatchText').text(iuf['tasks'][taskID]['e']);
			break;
	}
});

/* --------------------------------------------------------------
 EXAM 
-------------------------------------------------------------- */
$("#examFunctions_list_items .sidebarListItem").click(function(){
	$('#examFunctions_list_items .sidebarListItem').removeClass('active');
	$(this).addClass('active');
	
	selectListItem($('.mainSection.active .sidebarListItem.active').index());
}); 

/* --------------------------------------------------------------
 EXAM CREATE 
-------------------------------------------------------------- */
let dndAdditionalPDF = {
	hzone: null,
	dzone: null,

	init : function () {
		dndAdditionalPDF.hzone = document.querySelector("body");
		dndAdditionalPDF.dzone = document.getElementById('dnd_additionalPDF');

		if ( window.File && window.FileReader && window.FileList && window.Blob ) {
			// hover zone
			dndAdditionalPDF.hzone.addEventListener('dragenter', function (e) {
				e.preventDefault();
				e.stopPropagation();
				if( $('#exam').hasClass('active') ) {
					dndAdditionalPDF.dzone.classList.add('drag');
				}
			});
			dndAdditionalPDF.hzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			dndAdditionalPDF.hzone.addEventListener('dragover', function (e) {
				e.preventDefault();
				e.stopPropagation();
			});
			
			// drop zone
			dndAdditionalPDF.dzone.addEventListener('dragleave', function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndAdditionalPDF.dzone.classList.remove('drag');
			});
			dndAdditionalPDF.dzone.addEventListener('drop', async function (e) {
				e.preventDefault();
				e.stopPropagation();
				dndAdditionalPDF.dzone.classList.remove('drag');
				
				loadAdditionalPDFDnD(e.dataTransfer.items);
			});
		}
	},
};

window.addEventListener('DOMContentLoaded', dndAdditionalPDF.init);

function loadAdditionalPDFDnD(items) {	
	getFilesDataTransferItems(items).then(async (files) => {
		Array.from(files).forEach(file => {	
			addAdditionalPDF(file);
		});
	});
}

function loadAdditionalPDFFileDialog(items) {
	items.forEach(function(file) {
		addAdditionalPDF(file);
	});
}

function addAdditionalPDF(file) {
	if ( file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase() == 'pdf') {
		let fileReader = new FileReader();
		let base64;

		fileReader.onload = function(fileLoadedEvent) {
			base64 = fileLoadedEvent.target.result;
			iuf['examAdditionalPDF'].push(base64.split(',')[1]);
		};

		fileReader.readAsDataURL(file);
		
		$('#additionalPDF_list_items').append('<div class="additionalPDFItem"><span class="additionalPDFName">' + file.name + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
	}
}

function removeAdditionalPDF(element) {
	const additionalPDFID = element.index('.additionalPDFItem');
	iuf['examAdditionalPDF'].splice(additionalPDFID, 1);
	element.remove();
}

$('#additionalPDF_list_items').on('click', '.additionalPDFItem', function() {
	removeAdditionalPDF($(this));
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
	calcTotalFixedPoints();
}); 

$("#numberOfTasks").change(function(){
	calcTotalFixedPoints();
});

$("#autofillNumberOfTasks").click(function(){
	$('#numberOfTasks').val(getNumberOfExamTasks());
	calcTotalFixedPoints();
}); 

function calcTotalFixedPoints(){
	const totalFixedPointsValue = parseInt($('#numberOfTasks').val()) * parseInt($('#numberOfFixedPoints').val());
	
	if (isNaN(totalFixedPointsValue)) {
		$('#totalPointsValue').text("");
	} else {
		$('#totalPointsValue').text(totalFixedPointsValue);
	}
}

async function createExam() {
	const examTaskCodes = iuf['tasks'].filter((task) => task.exam & task.file !== null).map((task) => task.file);
	
	let blocks = iuf['tasks'].map(x => x.block)
		
	Promise.all(examTaskCodes).then((values) => {
		Shiny.onInputChange("parseExam", {examSeed: $('#seedValueExam').val(), numberOfExams: $("#numberOfExams").val(), numberOfTasks: $("#numberOfTasks").val(), tasks: values, blocks: blocks, additionalPDF: iuf['examAdditionalPDF']}, {priority: 'event'});
	});
}

Shiny.addCustomMessageHandler('examParseResponse', function(jsonData) {
	e = JSON.parse(jsonData)
	
	switch(e.key) {
		case "Success": 
			console.log(e.value); 
			break;
		case "Warning": 
			console.log(e.value);
			break;
		case "Error": 
			console.log(e.value);
			break;
	}
});

/* --------------------------------------------------------------
HELP 
-------------------------------------------------------------- */
$("#help_list_items .sidebarListItem").click(function(){
	$('#help_list_items .sidebarListItem').removeClass('active');
	$(this).addClass('active');
	selectListItem($('.mainSection.active .sidebarListItem.active').index());
}); 
