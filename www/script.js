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

$(document).on({
    'shiny:inputchanged': function(event) { 
		if (event.target.id === 'examLanguage') {
			console.log($('#examLanguage').parent().find('.selectize-dropdown-content div')); 
		}
	}
});

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
			
		if (!$(evtobj.target).is('input') && $('.taskItem').length > 0) {
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
						if($('.taskItem.active:not(.filtered)').closest('.taskItem:not(.filtered)').hasClass('active')) {
							Shiny.onInputChange("resetTaskOutputFields", 1);
						}
						
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
	
	if(iuf.tasks.length > 0) viewTask(getTID());
}); 

/* --------------------------------------------------------------
 TASKS SUMMARY 
-------------------------------------------------------------- */
function examTasksSummary() {
	numberOfExamTasks();
	 
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
			topics.push(item.topic);
			if (! item.tags === null) item.tags.forEach(i => tags.push(i));
			Array.isArray(item.result) ? types.push("mc") : types.push("num");
			checkedBy += (item.checkedBy != "");
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
		
		if (input.includes("filename:")) {
			const fieldsToFilter = iuf.tasks.map(task => {
				if( task.file.name === null) {
					return "";
				} 
				
				return task.file.name;
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
	getFilesDataTransferItems(items).then(async (files) => {
		Array.from(files).forEach(file => {	
			loadTask(file);
		});
	});
}

function loadTasksFileDialog(items) {
	items.forEach(function(file) {
		loadTask(file);
	});
}

async function loadTask(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	switch(fileExt) {
		case 'rnw':
			const taskID = tasks + 1
			addTask();

			iuf['tasks'][taskID]['file'] = file;
			iuf['tasks'][taskID]['seed'] = null;
			iuf['tasks'][taskID]['exam'] = false;
			iuf['tasks'][taskID]['question'] = null;
			iuf['tasks'][taskID]['choices'] = null;
			iuf['tasks'][taskID]['result'] = null;
			iuf['tasks'][taskID]['examHistory'] = null;
			iuf['tasks'][taskID]['authoredBy'] = null;
			iuf['tasks'][taskID]['checkedBy'] = null;
			iuf['tasks'][taskID]['precision'] = null;
			iuf['tasks'][taskID]['difficulty'] = null;
			iuf['tasks'][taskID]['points'] = null;
			iuf['tasks'][taskID]['topic'] = null;
			iuf['tasks'][taskID]['tags'] = null;
			iuf['tasks'][taskID]['type'] = null;
			iuf['tasks'][taskID]['e'] = null;
			
			$('#task_list_items').append('<div class="taskItem sidebarListItem"><span class="taskTryCatch"><i class="fa-solid fa-triangle-exclamation"></i><span class="taskTryCatchText"></span></span><span class="taskName">' + file.name + '</span></span><span class="taskButtons"><span class="taskParse taskButton"><i class="fa-solid fa-rotate"></i></span><span class="examTask taskButton"><i class="fa-solid fa-circle-check"></i></span><span class="taskRemove taskButton"><i class="fa-solid fa-trash"></i></span></span></div>');
			
			viewTask(taskID, true);
		
			break;
		case 'txt':				
			const parser = new DOMParser();
			const fileText = await file.text();
			const xmlDoc = parser.parseFromString(fileText,"text/xml");
			
			const questions = xmlDoc.getElementsByTagName("question");
			
			for (i = 0; i < questions.length; i++) {
				const question = questions[i];
				const questionText = question.getElementsByTagName("questionText")[0].textContent.trim();
				const questionAnswers = question.getElementsByTagName("questionAnswer");
				
				let questionAnswerChoices = new Array();
				let questionAnswerResults = new Array();
				
				for (j = 0; j < questionAnswers.length; j++) {
					const questionAnswer = questionAnswers[j];
					questionAnswerChoices.push(questionAnswer.getElementsByTagName("questionAnswerText")[0].textContent.trim()); 
					questionAnswerResults.push(questionAnswer.getElementsByTagName("questionAnswerResult")[0].textContent.trim() === "1"); 
				}

				const taskID = tasks + 1
				addTask();
				
				let fileText = xmlToRnw;
				fileText = fileText.replace("?q", '"' + questionText + '"');
				fileText = fileText.replace("?c", 'c(' + questionAnswerChoices.map(c=>'"' + c + '"').join(',') + ')');
				fileText = fileText.replace("?s", 'c(' + questionAnswerResults.map(s=>s?"T":"F").join(',') + ')');
				fileText = fileText.replaceAll("\n", "\r\n");

				iuf['tasks'][taskID]['file'] = fileText;
				iuf['tasks'][taskID]['seed'] = null;
				iuf['tasks'][taskID]['exam'] = false;
				iuf['tasks'][taskID]['question'] = questionText;
				iuf['tasks'][taskID]['choices'] = questionAnswerChoices;
				iuf['tasks'][taskID]['result'] = questionAnswerResults;
				iuf['tasks'][taskID]['examHistory'] = null;
				iuf['tasks'][taskID]['authoredBy'] = null;
				iuf['tasks'][taskID]['checkedBy'] = null;
				iuf['tasks'][taskID]['precision'] = null;
				iuf['tasks'][taskID]['difficulty'] = null;
				iuf['tasks'][taskID]['points'] = null;
				iuf['tasks'][taskID]['topic'] = null;
				iuf['tasks'][taskID]['tags'] = null;
				iuf['tasks'][taskID]['type'] = null;
				iuf['tasks'][taskID]['e'] = 'XML:' + (i+1);	
				
				$('#task_list_items').append('<div class="taskItem sidebarListItem"><span class="taskTryCatch"><i class="fa-solid fa-triangle-exclamation"></i><span class="taskTryCatchText"></span></span><span class="taskName">' + file.name + "_" + (i+1) + '</span></span><span class="taskButtons"><span class="taskParse taskButton disabled"><i class="fa-solid fa-rotate"></i></span><span class="examTask taskButton"><i class="fa-solid fa-circle-check"></i></span><span class="taskRemove taskButton"><i class="fa-solid fa-trash"></i></span></span></div>');
				
				viewTask(taskID);
			}
			break;
	}
}

async function parseTask(taskID) {	
	const taskCode = await iuf['tasks'][taskID].file.text();
	
	Shiny.onInputChange("parseExercise", {taskCode: taskCode, taskID: taskID}, {priority: 'event'});	
}

function numberOfExamTasks() {
	let setNumberOfExamTasks = 0;
	iuf['tasks'].map(t => setNumberOfExamTasks += t.exam); 
	Shiny.onInputChange("setNumberOfExamTasks", setNumberOfExamTasks, {priority: 'event'});
}

function viewTask(taskID, forceParse = false) {
	resetOutputFields();
	
	const isFromXml = iuf['tasks'][taskID]['e'] != null ? iuf['tasks'][taskID]['e'].includes("XML") : false;
	const parse = !isFromXml && (forceParse || iuf['tasks'][taskID]['seed'] == "" || iuf['tasks'][taskID]['seed'] != $("#seedValue").val() || ! iuf.tasks[taskID].e.includes("Success: "));
	
	if(parse) {
		parseTask(taskID);	
	} else {
		loadTaskFromObject(taskID);
		$('.taskItem.active').removeClass('active');
		$('.taskItem:nth-child(' + (taskID + 1) + ')').addClass('active');
	}
	
	f_langDeEn();
}

function resetOutputFields() {
	document.getElementById('question').innerHTML = '';
	document.getElementById('points').innerHTML = '';
	document.getElementById('type').innerHTML = '';
	document.getElementById('result').innerHTML = '';
	document.getElementById('examHistory').innerHTML = '';
	document.getElementById('authoredBy').innerHTML = '';
	document.getElementById('checkedBy').innerHTML = '';
	document.getElementById('precision').innerHTML = '';
	document.getElementById('difficulty').innerHTML = '';
	document.getElementById('topic').innerHTML = '';
	document.getElementById('tags').innerHTML = '';
}

function loadTaskFromObject(taskID) {
	if(iuf['tasks'][taskID]['question'] !== null && Array.isArray(iuf['tasks'][taskID]['question'])) {
		document.getElementById('question').innerHTML = '<span>' + iuf['tasks'][taskID]['question'].join('') + '</span>';
	} else {
		document.getElementById('question').innerHTML = '<span>' + iuf['tasks'][taskID]['question'] + '</span>';
	}
	document.getElementById('points').innerHTML = '<span>' + iuf['tasks'][taskID]['points'] + '</span>';
	document.getElementById('type').innerHTML = '<span>' + iuf['tasks'][taskID]['type'] + '</span>';
	
	if(iuf['tasks'][taskID]['type'] === "mchoice" || iuf['tasks'][taskID].e.includes("XML")) {
		const zip = iuf['tasks'][taskID]['result'].map((x, i) => [x, iuf['tasks'][taskID]['choices'][i]]);
		const results = '<div>' + zip.map(i => '<p><span class=\"result mchoiceResult\">' + ( + i[0]) + '</span><span class="choice"><input type=\"checkbox\" name=\"\" value=\"\"><span class="choiceText">' + i[1] + '</span></span></p>').join('') + '</div>';
		
		document.getElementById('result').innerHTML = results;
	}
	
	if(iuf['tasks'][taskID]['type'] === "num") {
		const result = '<div><p><span class=\"result numericResult\">' + iuf['tasks'][taskID]['result'] + '</span><span class="solution"><input type=\"text\" class=\"form-control shinyjs-resettable shiny-bound-input\"></span></p></div>';
		
		document.getElementById('result').innerHTML = result;
	}
	
	if(iuf['tasks'][taskID]['examHistory'] !== null) document.getElementById('examHistory').innerHTML = iuf['tasks'][taskID]['examHistory'].map(i => '<span>' + i + '</span>').join('');
	if(iuf['tasks'][taskID]['authoredBy'] !== null) document.getElementById('authoredBy').innerHTML = iuf['tasks'][taskID]['authoredBy'].map(i => '<span>' + i + '</span>').join('');
	if(iuf['tasks'][taskID]['checkedBy'] !== null) document.getElementById('checkedBy').innerHTML = iuf['tasks'][taskID]['checkedBy'].map(i => '<span>' + i + '</span>').join('');
	document.getElementById('precision').innerHTML = '<span>' + iuf['tasks'][taskID]['precision'] + '</span>';
	document.getElementById('difficulty').innerHTML = '<span>' + iuf['tasks'][taskID]['difficulty'] + '</span>';
	document.getElementById('topic').innerHTML = '<span>' + iuf['tasks'][taskID]['topic'] + '</span>';
	if(iuf['tasks'][taskID]['tags'] !== null) document.getElementById('tags').innerHTML = iuf['tasks'][taskID]['tags'].map(i => '<span>' + i + '</span>').join('');
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

function toggleExamTask(taskID, b) {
	iuf['tasks'][taskID]['exam'] = b;
	
	examTasksSummary();
}

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
	$('#result').find('.correct').removeClass('correct');
	$('#result').find('.incorrect').removeClass('incorrect');
}

function validateAnswer() {
	resetValidation();
	
	if($('#result').find('input').length == 1) {
		Number($('#result input').val().replace(',', '.')) === Number(iuf.tasks[getTID()].result) ? $('#result input').addClass('correct') : $('#result input').addClass('incorrect');
		
		setTimeout(function(){
			resetValidation();
		}, 1000);
	} 
	
	if($('#result').find('input').length > 1) {
		resetValidation();

		let correct = true;		
		$('#result input[type=checkbox]').each(function (index, element) {		
			correct = correct && element.checked === iuf.tasks[getTID()].result[index]; 
		});
		
		correct ? $('#result input[type=checkbox]').nextAll('span').addClass('correct') : $('#result input[type=checkbox]').nextAll('span').addClass('incorrect');
		
		setTimeout(function(){
			resetValidation();
		}, 1000);
	} 
}

$('#validateAnswer_preview').click(function () {
	validateAnswer();
});

$('#result').on('mouseenter', '.result', function() {
    $('#result .result').addClass( "spoiler");
});

$('#result').on('mouseleave', '.result', function() {
    $('#result .result').removeClass( "spoiler");
});

getTID = function() {
	return(taskID_hook == -1 ? $('.taskItem.active').index('.taskItem') : taskID_hook);
}

Shiny.addCustomMessageHandler('setTaskId', function(taskID) {
	taskID_hook = taskID;
});

Shiny.addCustomMessageHandler('setTaskSeed', function(seed) {
	iuf['tasks'][getTID()]['seed'] = seed;
});

Shiny.addCustomMessageHandler('setTaskExamHistory', function(jsonData) {
	const examHistory = JSON.parse(jsonData);
	iuf['tasks'][getTID()]['examHistory'] = examHistory;
});

Shiny.addCustomMessageHandler('setTaskAuthoredBy', function(jsonData) {
	const taskAuthors = JSON.parse(jsonData);
	iuf['tasks'][getTID()]['authoredBy'] = taskAuthors;
});

Shiny.addCustomMessageHandler('setTaskCheckedBy', function(jsonData) {
	const taskCheckers = JSON.parse(jsonData);
	iuf['tasks'][getTID()]['checkedBy'] = taskCheckers;
});

Shiny.addCustomMessageHandler('seTasktPrecision', function(taskPrecision) {
	iuf['tasks'][getTID()]['precision'] = taskPrecision;
});

Shiny.addCustomMessageHandler('setTaskDifficulty', function(taskDifficulty) {
	iuf['tasks'][getTID()]['difficulty'] = taskDifficulty;
});

Shiny.addCustomMessageHandler('setTaskPoints', function(taskPoints) {
	iuf['tasks'][getTID()]['points'] = taskPoints;
});

Shiny.addCustomMessageHandler('setTaskTopic', function(taskTopic) {
	iuf['tasks'][getTID()]['topic'] = taskTopic;
});

Shiny.addCustomMessageHandler('setTaskTags', function(jsonData) {
	const taskTags = JSON.parse(jsonData);
	iuf['tasks'][getTID()]['tags'] = taskTags;
});

Shiny.addCustomMessageHandler('setTaskType', function(taskType) {
	iuf['tasks'][getTID()]['type'] = taskType;
});

Shiny.addCustomMessageHandler('setTaskQuestion', function(taskQuestion) {
	iuf['tasks'][getTID()]['question'] = taskQuestion;
});

Shiny.addCustomMessageHandler('setTaskChoices', function(jsonData) {
	const taskChoices = JSON.parse(jsonData);
	iuf['tasks'][getTID()]['choices'] = taskChoices;
});

Shiny.addCustomMessageHandler('setTaskResultMchoice', function(jsonData) {
	const taskResult = JSON.parse(jsonData);
	iuf['tasks'][getTID()]['result'] = taskResult;
});

Shiny.addCustomMessageHandler('setTaskResultNumeric', function(taskResult) {
	iuf['tasks'][getTID()]['result'] = taskResult;
});

Shiny.addCustomMessageHandler('setTaskE', function(jsonData) {
	e = JSON.parse(jsonData)
		
	const taskID = getTID();
	
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
			loadTaskFromObject(taskID);
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

Shiny.addCustomMessageHandler('setTaskActive', function(active) {
	$('.taskItem.active').removeClass('active');
	
	if(active == 1) {
		$('.taskItem:nth-child(' + (getTID() + 1) + ')').addClass('active');
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
	console.log(items);
	
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
	let setNumberOfExamTasks = 0;
	iuf['tasks'].map(t => setNumberOfExamTasks += t.exam);
	$('#numberOfTasks').val(setNumberOfExamTasks);
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
	const examTaskCodes = iuf['tasks'].filter((task) => task.exam).map((task) => task.e.includes("XML") ? task.file : task.file.text());
		
	Promise.all(examTaskCodes).then((values) => {
		Shiny.onInputChange("parseExam", {numberOfExams: $("#numberOfExams").val(), numberOfTasks: $("#numberOfTasks").val(), tasks: values, additionalPDF: iuf['examAdditionalPDF']}, {priority: 'event'});
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
