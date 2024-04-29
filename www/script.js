/**
* Script
*
*/

/* --------------------------------------------------------------
 DEBUG 
-------------------------------------------------------------- */
Shiny.addCustomMessageHandler('debugMessage', function(message) {
	console.log("DEBUG MESSAGE:\n");
	console.log(message);
	console.log("\n\n");
});

/* --------------------------------------------------------------
 APP INIT
-------------------------------------------------------------- */
$(document).on('shiny:idle', function(event) {
	initApp();
});

function initApp(){
	if( initApp.fired ) return;
	initApp.fired = true;
	 
	rex.exercises = [];
	rex.examAdditionalPdf = []; 
	rex.examEvaluation = [];
	rex.examEvaluation.scans = []; 
	rex.examEvaluation.registeredParticipants = [];
	rex.examEvaluation.solutions = [];
	rex.examEvaluation.examIds = [];
	rex.examEvaluation.changeHistory = null;
	rex.examEvaluation.scans_reg_fullJoinData = [];
	rex.examEvaluation.statistics = [];
	
	$('#s_initialSeed').html(itemSingle($('#seedValueExercises').val(), 'yellowLabelValue'));
	$('#s_numberOfExams').html(itemSingle($('#numberOfExams').val(), 'yellowLabelValue'));
	$('#logout-button').removeClass('shinyjs-hide');
	
	dndExercises.init();
	dndAdditionalPdf.init();
	dndExamEvaluation.init();
	
	f_tex();
	f_hotKeys();
	f_buttonMode();
	f_langDeEn();
	resetOutputFields();
	
	$('#copyright small').append('<div id="additionalCopyright"><div>Based on <a href="https://cran.r-project.org/web/packages/exams/index.html" target="_blank" rel="noopener noreferrer">R/exams</a> © ' + new Date().getFullYear() + ' Achim Zeileis</div><div>Licensed under <a href="LICENSE.html" target="_blank" rel="noopener noreferrer">GNU GPL-3</a></div><div><a href="https://github.com/guesswho1234/Rex" target="_blank" rel="noopener noreferrer">Rex</a> source code</div></div>');
	
	const linkElements = ['<link rel="stylesheet" href="/www/styleApp.css" type="text/css">',
	'<link rel="stylesheet" href="/www/fontawesome/css/fontawesome.min.css" type="text/css">',
	'<link rel="stylesheet" href="/www/fontawesome/css/all.min.css" type="text/css">'];	
	
	if( $('#addons .sidebarListItem').length > 0 && $('#addons .contentTab').length > 0 && $('#addons .sidebarListItem').length == $('#addons .contentTab').length) {
		$('.noAddons').removeClass('noAddons');
	}

	linkElements.forEach(style => $("head").append(style));
	
	$('#heart span').css('background', 'var(---heartRed)');
	$('#heart span').css('-webkit-background-clip', 'text');
}

/* --------------------------------------------------------------
SHINY INPUT VALUE SETTER
-------------------------------------------------------------- */
function setShinyInputValue(field, value){
	$('#' + field).val(value);
	Shiny.onInputChange(field, $('#' + field).val());
}

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
 LOGOUT 
-------------------------------------------------------------- */
$('body').on('click', '#logout-button', function() {
	location.reload();
});

/* --------------------------------------------------------------
 COLORS 
-------------------------------------------------------------- */
const myColors = Array.from(document.styleSheets)
.filter(
sheet =>
  sheet.href === null || sheet.href.startsWith(window.location.origin)
)
.reduce(
(acc, sheet) =>
  (acc = [
	...acc,
	...Array.from(sheet.cssRules).reduce(
	  (def, rule) =>
		(def =
		  rule.selectorText === ".color-theme" ? [
				...def,
				...Array.from(rule.style).filter(name =>
				  name.startsWith("--")
				)
			  ] : def),
	  []
	)
  ]),
[]
);

/* --------------------------------------------------------------
 SCROLL TOP 
-------------------------------------------------------------- */
$('#logoApp').on('click', function() {
	scrollTop();
});

function scrollTop(){
	window.scrollTo(0, 0);
}

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
	Shiny.onInputChange("pong", "heartbeat", {priority: 'event'});
}

$('body').on('click', '#heart.ping', function(e) {
	changeHeartColor();
});

function changeHeartColor() {
	let colorId = getHeartColorCookie();
	colorId = colorId === null ? 0 : 1 - parseInt(colorId);
	
	$('#heart span').css('background', 'var(' + myColors[colorId] + ')');
	$('#heart span').css('-webkit-background-clip', 'text');
	setHeartColorCookie(colorId);
}

function setHeartColorCookie(colorId) {
    document.cookie = 'REX_JS_heartColor=' + colorId + ';path=/;SameSite=Lax';
}

function getHeartColorCookie() {
    const name = 'REX_JS_heartColor';
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
 LATEX
-------------------------------------------------------------- */
$('#texActiveContainer').click(function () {
	setTexCookie(+!getTexCookie());
	f_tex();
});

function f_tex() {
	$('#texActiveContainer span').removeClass('active');
	$('.texMode').removeClass('texInputsEnabled');
	$('.texMode').addClass('texInputsEscaped');
	
	if (getTexCookie()) {
		$('#texActiveContainer span').addClass('active');
		$('.texMode').removeClass('texInputsEscaped');
		$('.texMode').addClass('texInputsEnabled');
	} 
}

Shiny.addCustomMessageHandler('f_tex', function(x) {
	f_tex();
});

function setTexCookie(texActive) {
    document.cookie = 'REX_JS_tex=' + texActive + ';path=/;SameSite=Lax';
}

function getTexCookie() {
    const name = 'REX_JS_tex';
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

/* --------------------------------------------------------------
 KEY EVENTS 
-------------------------------------------------------------- */
$('#hotkeysActiveContainer').click(function () {
	setHotkeysCookie(+!getHotkeysCookie());
	f_hotKeys();
});

$('#hotkeysActiveContainer').hover(
  function() {
    $('.hotkeyInfo').addClass('reveal');
  }, function() {
    $('.hotkeyInfo').removeClass('reveal');
  }
);

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
	
	const evtobj = window.event? event : evt;
	
	if( $('#exercises').hasClass('active') ) {
		const targetEditable = $(evtobj.target).attr('contenteditable');

		if (evtobj.shiftKey && evtobj.keyCode == 70 && !targetEditable) {
			const searchField = $('#searchExercises').find('input');
			const searchValLength = searchField.val().length;
			
			searchField.focus();
			searchField[0].setSelectionRange(searchValLength, searchValLength);
		}
	}
};

document.onkeydown = function(evt) {
	if(!getHotkeysCookie()) return;
	
	const evtobj = window.event? event : evt;
	const targetInput = $(evtobj.target).is('input') || $(evtobj.target).is('textarea');
	const targetEditable = $(evtobj.target).attr('contenteditable');
	
	// SCROLL TOP
	if (!targetInput && !targetEditable) {
		if (evtobj.keyCode == 84) // t
			scrollTop();
	}
	
	// INSPECT SCAN
	if( $('#inspectScanButtons').length == 1 ) {
		switch (evtobj.keyCode) {
			case 13: // enter
				applyInspect();
				break;
			case 32: // space
				if (!targetInput && !targetEditable) 
					applyInspectNext();
				break;
			case 27: // ESC
				cancelInspect();
				break;
		}
	} 
	
	if($('#disableOverlay').hasClass("active")) return;
		
	// EXERCISES
	if( $('#confirmdialogOverlay').hasClass('active') ) {
		switch (evtobj.keyCode) {
			case 13: // enter
				$('#confirmdialogYes').click();
				break;
			case 27: // ESC
				$('#confirmdialogNo').click();
				break;
		}
	} 
	
	if( $('#exercises').hasClass('active') && !$('#confirmdialogOverlay').hasClass('active') ) {	
		if ($(evtobj.target).is('input') && evtobj.keyCode == 13) { // enter
			$(evtobj.target).change();
			$(evtobj.target).blur();
		}
	
		if (evtobj.keyCode == 27) { // ESC
			$(evtobj.target).blur();
		
			if(!targetEditable) {
				$('#searchExercises input').val("");
			
				searchExercises();
			}
		}
		
		const itemsExist = $('.exerciseItem').length > 0;
			
		if (!targetInput && !targetEditable) {
			if(itemsExist){
				let updateView = false;
				
				if (evtobj.shiftKey) {
					switch (evtobj.keyCode) {
						case 69: // shift+e
							examExerciseAll();
							break;
						case 68: // shift+d
							exerciseRemoveAll();
							break;
						case 83: // shift+s
							$("#downloadExercises")[0].click();
							break;
						case 82: // shift+r 
							exerciseParseAll(true);
							break;
					}
				} 
							
				if(!evtobj.shiftKey && !evtobj.ctrlKey) {
					switch (evtobj.keyCode) {
						case 69: // e
							if ($('.exerciseItem.active:not(.filtered)').length > 0 && !$('.exerciseItem.active:not(.filtered) .examExercise').hasClass('disabled')) {
								$('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').toggleClass('exam');	
								setExamExercise($('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').index('.exerciseItem:not(.filtered)'), $('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').hasClass('exam'));
							}
							break;
						case 38: // ARROW UP
							evtobj.preventDefault();
							sidebarMoveUp($('.mainSection.active'));
							updateView = true;
							break;
						case 40: // ARROW DOWN
							evtobj.preventDefault();
							sidebarMoveDown($('.mainSection.active'));
							updateView = true;
							break;
						case 68: // d
							const exerciseID = $('.exerciseItem.active:not(.filtered)').closest('.exerciseItem:not(.filtered)').index('.exerciseItem');
							removeExercise(exerciseID);
							break;
						case 82: // r 
							viewExercise($('.exerciseItem.active:not(.filtered)').first().index('.exerciseItem'), true);
							break;
						case 83: // s 
							$("#downloadExercise")[0].click();
							break;
						case 89: // y 
							sequenceUp();
							break;	
						case 88: // x 
							sequenceDown();
							break;	
					}
				}
				
				if (updateView && $('.exerciseItem.active:not(.filtered)').length > 0) {
					viewExercise($('.exerciseItem.active:not(.filtered)').first().index('.exerciseItem'));
				}
			} 
			
			switch (evtobj.keyCode) {
				case 65: // a 
					newSimpleExercise();
					break;	
				case 81: // q 
					$('#file-upload_exercises').click();
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
		$('#logoutContainer').addClass("disabled");
	} else {
		$('#disableOverlay').removeClass("active");
		$('nav .nav.navbar-nav li').removeClass("disabled");
		$('#logoutContainer').removeClass("disabled");
	}
});

/* --------------------------------------------------------------
 CONFIRM  
-------------------------------------------------------------- */
function confirmDialog(deMessage, enMessage, deButtonYes, enButtonYes, iconButtonYes, deButtonNo, enButtonNo, iconButtonNo, callback, ...args) {
	$('#confirmdialogOverlayContent span[lang="de"]').html(deMessage);
	$('#confirmdialogOverlayContent span[lang="en"]').html(enMessage);
	$('#confirmdialogYes .textButton span[lang="de"]').html(deButtonYes);
	$('#confirmdialogYes .textButton span[lang="en"]').html(enButtonYes);
	$('#confirmdialogYes .iconButton').html(iconButtonYes);
	$('#confirmdialogNo .textButton span[lang="de"]').html(deButtonNo);
	$('#confirmdialogNo .textButton span[lang="en"]').html(enButtonNo);
	$('#confirmdialogNo .iconButton').html(iconButtonNo);
		
	$('#confirmdialogOverlay').addClass("active");
	$('nav .nav.navbar-nav li').addClass("disabled");
	$('#logoutContainer').addClass("disabled");
	
	$('#confirmdialogYes').one('click', function() {
        $('#confirmdialogOverlay').removeClass("active");
		$('nav .nav.navbar-nav li').removeClass("disabled");
		$('#logoutContainer').removeClass("disabled");
		
		$('#confirmdialogNo').off();
		
        callback(true, ...args);
    });
	
    $('#confirmdialogNo').one('click', function() {
        $('#confirmdialogOverlay').removeClass("active");
		$('nav .nav.navbar-nav li').removeClass("disabled");
		$('#logoutContainer').removeClass("disabled");
		
		$('#confirmdialogYes').off();
				
        callback(false, ...args);
    });
	
	return;
}

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

$('#addonsNav').parent().click(function () {	
	if( $(this).parent().hasClass('disabled') ) return;
	
	$('.mainSection').removeClass('active');
	$('#addons').addClass('active');
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
	
	buttonMode = getButtonModeCookie();
	
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
	lang = getLanguageCookie();
	
	if (lang === 'en') {
		rex.language = 'en';
		
		$('html').attr('lang', 'en');
		$('html').attr('xml:lang', 'en');
		
		$('[lang="de"]').hide();
		$('[lang="en"]').show();
	} else {
		rex.language = 'de';
		
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
let rex = new Object();
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
	setShinyInputValue("seedValueExercises", seed);
	$('#s_initialSeed').html(itemSingle(seed, 'yellowLabelValue'));
		
	if(rex.exercises.length > 0) viewExercise(getID());
}); 

/* --------------------------------------------------------------
 EXERCISES SUMMARY 
-------------------------------------------------------------- */
function examExercisesSummary() {	
	$('#s_initialSeed').html(itemSingle($('#seedValueExercises').val(), 'yellowLabelValue'));
	
	if($('.exerciseItem.exam').length == 0) { 
		$('#s_numberOfExercises').html("");
		$('#s_totalPoints').html("");
		$('#s_topicsTable').html("");
		
		return;
	}
	
	let numberOfExamExercisesCounter = 0;
	let totalPoints = 0;
	let topics = [];
		
	rex.exercises.forEach((item, index) => {
		if(item.exam) {
			numberOfExamExercisesCounter++;
			totalPoints += Number(item.points);
			if (item.topic !== null) topics.push(item.topic);
		}
	})
	
	$('#s_numberOfExercises').html(itemSingle(numberOfExamExercisesCounter, 'yellowLabelValue'));
	$('#s_totalPoints').html(itemSingle(totalPoints, 'yellowLabelValue'));
	$('#s_topicsTable').html(itemTable(topics));
}

function itemSingle(item, className) {
	return '<span class="myLabelContainer"><span class="myLabel"><span class="myLabelSingle ' + className + '">' + item + '</span></span></span>';
}

function itemTable(arr) {
	let counts = {};
	for (let i of arr) {
		counts[i] = counts[i] ? counts[i] + 1 : 1;
	}
	
	let out = "";
	
	out = Object.entries(counts).map(entry => {
		const [key, value] = entry;
		return '<span class="myLabel"><span class="label_key yellowLabelKey">' + key + '</span><span class="label_value yellowLabelValue">' + value + '</span></span>';
	}).join('');
	
	return '<span class="myLabelContainer">' + out + '</span>';
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
		rex.exercises[index].exam = false;
				
		if (!$(this).find('.examExercise').hasClass('disabled') && !examExerciseAllButton.hasClass('allAdded')) {	
			$(this).addClass('exam');
			rex.exercises[index].exam = true;
		}
	});
	
	examExerciseAllButton.toggleClass('allAdded');
	examExercisesSummary();
}

function exerciseRemoveAll(){
	confirmDialog('Alle Aufgaben löschen?', 'Delete all exercises?', 'Ja', 'Yes', '<i class="fa-solid fa-check"></i>', 'Nein', 'No', '<i class="fa-solid fa-xmark"></i>',
		function(remove) {
			if(!remove)
				return;
			
			const removeIndices = $('.exerciseItem:not(.filtered)').map(function() {
			return $(this).index();
			}).get();
			
			for (let i = removeIndices.length -1; i >= 0; i--) {
				rex.exercises.splice(removeIndices[i],1);
				exercises = exercises - 1;
			}
			
			$('.exerciseItem:not(.filtered)').remove();

			resetOutputFields();
			examExercisesSummary();
	});
}

function exerciseParseAll(forceParse = false){
	rex.exercises.forEach((t, index) => {
		if( $('.exerciseItem:nth-child(' + (index + 1) + ')').hasClass('filtered')) {
			return;
		}
		
		viewExercise(index, forceParse)
	});	
}

$("#exerciseDownload").click(function(){
	const exerciseID = getID();
	exerciseDownload(exerciseID);
}); 

//todo
$("#exerciseConvert").click(function(){
	const exerciseID = getID();
	exerciseConvert(exerciseID);
});

function exerciseDownload(exerciseID) {	
	if(rex.exercises[exerciseID].editable)
		setSimpleExerciseFileContents(exerciseID);
	
	const exerciseName = rex.exercises[exerciseID].name;
	const exerciseCode = rex.exercises[exerciseID].file;
	const exerciseExt = rex.exercises[exerciseID].ext;
			
	Shiny.onInputChange("exerciseToDownload", {exerciseName:exerciseName, exerciseCode: exerciseCode, exerciseExt: exerciseExt}, {priority: 'event'});	
}

function exerciseConvert(exerciseID){
	confirmDialog('Beim Konvertieren in eine bearbeitbare Aufgabe wird nur der aktuell sichtbare Text übernommen. Alle weiteren Details der Aufgabe gehen verloren. <b>Möchten Sie die Aufgabe wirklich konverteiren?</b>', 'When converting to an editable exercise, only the currently visible text is transferred. All other details of the exercise are lost. Do you really want to convert the exercise?', 'Ja', 'Yes', '<i class="fa-solid fa-check"></i>', 'Nein', 'No', '<i class="fa-solid fa-xmark"></i>',
		function(remove) {
			if(!remove)
				return;
			
			setSimpleExerciseFileContents(exerciseID, true);
			viewExercise(exerciseID, true);
	});	
}

$('#exerciseDownloadAll').click(function () {
	exerciseDownloadAll();
});

function exerciseDownloadAll() {	
	const filteredTasks = rex.exercises.filter((x, index) => {
		if(rex.exercises[index].editable)
			setSimpleExerciseFileContents(index);
		return !$('.exerciseItem:nth-child(' + (index + 1) + ')').hasClass('filtered')
	});
	
	const exerciseNames = filteredTasks.map(exercise => exercise.name);
	const exerciseCodes = filteredTasks.map(exercise => exercise.file);
	const exerciseExts = filteredTasks.map(exercise => exercise.ext);
	
	Shiny.onInputChange("exercisesToDownload", {exerciseNames:exerciseNames, exerciseCodes: exerciseCodes, exerciseExts: exerciseExts}, {priority: 'event'});	
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
	exerciseParseAll(true);
});

$('#searchExercises input').change(function () {
	searchExercises();
});

function searchExercises() {
	$this = $('#searchExercises input');
	
	// no exercises 
	if($('.exerciseItem').length <= 0) {
		return;
	}
	
	// no search input
	if($('#searchExercises input').val() == 0) {
		$('.exerciseItem').removeClass("filtered");
		
		resetOutputFields();
		$('.exerciseItem.active').removeClass('active');
		
		if($('.exerciseItem:not(.filtered)').length > 0) {
			$('.exerciseItem:not(.filtered)').first().addClass('active');
			viewExercise($('.exerciseItem.active:not(.filtered)').first().index('.exerciseItem'));
		}
		
		return;
	}
	
	const userInput = $this.val().split(";");

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
			const fieldsToFilter = rex.exercises.map(exercise => {
				if( exercise.name === null) {
					return "";
				} 
				
				return exercise.name;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
				
		if (input.includes("topic:")) {
			const fieldsToFilter = rex.exercises.map(exercise => {
				if( exercise.topic === null) {
					return "";
				} 
				
				return exercise.topic;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
				
		if (input.includes("section:")) {
			const fieldsToFilter = rex.exercises.map(exercise => {
				if( exercise.section === null) {
					return "";
				} 
				
				return exercise.section.join(',');
			})
			filterExercises(fieldsToFilter, filterBy);
		}
	
		
		if (input.includes("points:")) {
			const fieldsToFilter = rex.exercises.map(exercise => {
				if( exercise.points === null) {
					return "";
				} 
				
				return exercise.points;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("type:")) {
			const fieldsToFilter = rex.exercises.map(exercise => {
				if( exercise.type === null) {
					return "";
				} 
				
				return exercise.type;
			})
			filterExercises(fieldsToFilter, filterBy);
		}
		
		if (input.includes("question:")) {
			const fieldsToFilter = rex.exercises.map(exercise => {
				if( exercise.question === null) {
					return "";
				} 
				
				return exercise.question.join(',');
			})
			filterExercises(fieldsToFilter, filterBy);
		}
				
		if (!input.includes(":")) {
			const fieldsToFilter = rex.exercises.map(exercise => {
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
	
	resetOutputFields();
	$('.exerciseItem.active').removeClass('active');
	
	if($('.exerciseItem:not(.filtered)').length > 0) {
		$('.exerciseItem:not(.filtered)').first().addClass('active');
		viewExercise($('.exerciseItem.active:not(.filtered)').first().index('.exerciseItem'));
	}
}

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

function loadExercisesDnD(items) {	
	getFilesDataTransferItems(items).then((files) => {
		Array.from(files).forEach(file => {	
			loadExercise(file);
		});
	});
}

function exercisesFileDialog(items) {	
	Array.from(items).forEach(file => {	
		loadExercise(file);
	});
}

function loadExercise(file, block = 1) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	switch(fileExt) {
		case 'rnw':
		case 'rmd':
			newComplexExercise(file, fileExt, block);
			break;
	}
}

const d_exerciseName = 'Name';
const d_questionText = 'Text';
const d_choiceText = 'Text';
const d_topicText = '';
const d_sectionText = '';
const d_solution = false;
const d_solutionNoteText = '';

function newSimpleExercise(file = '', block = 1) {
	const exerciseID = exercises + 1
		addExercise();
		createExercise(exerciseID, d_exerciseName, 
					       null, 
						   "rnw",
					       d_questionText,
					       [d_choiceText + '1', d_choiceText + '2'],
					       [d_solution, d_solution],
						   [d_solutionNoteText, d_solutionNoteText],
					       null,
						   null,
					       true,
						   "mchoice",
						   block,
						   d_topicText,
						   d_sectionText);
		viewExercise(exerciseID);
}

async function newComplexExercise(file, ext, block) {
	const fileText = await file.text();
	const exerciseID = exercises + 1
	
	addExercise();
	
	createExercise(exerciseID, file.name.split('.')[0], 
					   fileText,
					   ext, 
					   '',
					   [],
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
							ext="rnw",
						    question='',
						    choices=[],
							solution=[],
							solutionNotes=[],
							statusMessage=null,
							statusCode=null,
							editable=false,
							type=null,
							block=1,
							topic=null,
							section=null,
							seed=null, 
						    exam=false, 
							examHistory=null,
							authoredBy=null,
							points=1,
							tags=null,
							figure=null){
	rex.exercises[exerciseID]['file'] = file;
	rex.exercises[exerciseID]['ext'] = ext;
	rex.exercises[exerciseID]['name'] = name;
	rex.exercises[exerciseID]['seed'] = seed;
	rex.exercises[exerciseID]['exam'] = exam;
	rex.exercises[exerciseID]['question'] = question;
	rex.exercises[exerciseID]['question_raw'] = question;
	rex.exercises[exerciseID]['choices'] = choices;
	rex.exercises[exerciseID]['choices_raw'] = choices;
	rex.exercises[exerciseID]['solution'] = solution;
	rex.exercises[exerciseID]['solutionNotes'] = solutionNotes;
	rex.exercises[exerciseID]['solutionNotes_raw'] = solutionNotes;
	rex.exercises[exerciseID]['examHistory'] = examHistory;
	rex.exercises[exerciseID]['authoredBy'] = authoredBy;
	rex.exercises[exerciseID]['points'] = points;
	rex.exercises[exerciseID]['topic'] = topic;
	rex.exercises[exerciseID]['tags'] = tags;
	rex.exercises[exerciseID]['type'] = type;
	rex.exercises[exerciseID]['statusMessage'] = statusMessage;	
	rex.exercises[exerciseID]['statusCode'] = statusCode;	
	rex.exercises[exerciseID]['editable'] = editable;
	rex.exercises[exerciseID]['block'] = block;
	rex.exercises[exerciseID]['section'] = section;
	rex.exercises[exerciseID]['figure'] = figure;
	
	if( file === null) {
		setSimpleExerciseFileContents(exerciseID);
	}
		
	$('#exercise_list_items').append('<div class="exerciseItem sidebarListItem"><span class="exerciseSequence"><span class="sequenceButton sequenceUp"><span class="hotkeyInfo"><span lang="de">Y</span><span lang="en">Y</span></span><i class="fa-solid fa-sort-up"></i></span><span class="sequenceButton sequenceDown"><span class="hotkeyInfo"><span lang="de">X</span><span lang="en">X</span></span><i class="fa-solid fa-sort-down"></i></span></span><span class="exerciseName">' + name + '</span></span><span class="exerciseBlock"><span lang="de">Block:</span><span lang="en">Block:</span><input value="' + block + '"/></span><span class="exerciseButtons"><span class="exerciseParse exerciseButton disabled"> <span class="hotkeyInfo"><span lang="de">R</span><span lang="en">R</span></span> <span class="iconButton"><i class="fa-solid fa-rotate"></i></span><span class="textButton"><span lang="de">Berechnen</span><span lang="en">Parse</span></span></span><span class="examExercise exerciseButton disabled"><span class="hotkeyInfo"><span lang="de">E</span><span lang="en">E</span></span><span class="iconButton"><i class="fa-solid fa-star"></i></span><span class="textButton"><span lang="de">Prüfungsrelevant</span><span lang="en">Examinable</span></span></span><span class="exerciseRemove exerciseButton"><span class="hotkeyInfo"><span lang="de">D</span><span lang="en">D</span></span><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></span></span></div>');
}

function parseExercise(exerciseID) {	
	const exerciseCode = rex.exercises[exerciseID].file;
	const exerciseExt = rex.exercises[exerciseID].ext;
	
	Shiny.onInputChange("parseExercise", {exerciseCode: exerciseCode, exerciseExt: exerciseExt, exerciseID: exerciseID}, {priority: 'event'});	
}

function getNumberOfExerciseBlocks() {
	return new Set(rex.exercises.filter((x) => x.exam).map(x => x.block)).size;
}

function getMaxNumberOfExamExercises() {
	const numberOfExerciseBlocks = getNumberOfExerciseBlocks();
	
	let setNumberOfExamExercises = 0;
	rex.exercises.map(x => setNumberOfExamExercises += x.exam);
	setNumberOfExamExercises = setNumberOfExamExercises - setNumberOfExamExercises % numberOfExerciseBlocks;
	
	return Math.min(setNumberOfExamExercises, getMaxExercisesPerBlock()) * numberOfExerciseBlocks;
}

function checkNumberOfExamExercises(numExercises) {
	if(numExercises < 0)
		return 0;
	
	const maxNumExercises = getMaxNumberOfExamExercises()
	
	if(numExercises > maxNumExercises)
		return maxNumExercises;
	
	const numberOfExerciseBlocks = getNumberOfExerciseBlocks();
	
	if(numExercises % numberOfExerciseBlocks !== 0)
		return numberOfExerciseBlocks;

	return numExercises;
}

function getMaxExercisesPerBlock(){
	const exercisesPerBlock = rex.exercises.filter((x) => x.exam).reduce( (acc, x) => (acc[x.block] = (acc[x.block] || 0) + 1, acc), {} );
	return Math.min(...Object.values(exercisesPerBlock));
}

function viewExercise(exerciseID, forceParse = false) {
	$('.exerciseItem').removeClass('active');
	$('.exerciseItem').eq(exerciseID).addClass('active');
	
	if(exerciseShouldbeParsed(exerciseID) || forceParse) {
		parseExercise(exerciseID);	
	} else {
		loadExerciseFromObject(exerciseID);
	}
		
	f_langDeEn();
}

function exerciseShouldbeParsed(exerciseID){
	const seedChanged = rex.exercises[exerciseID].seed == "" || rex.exercises[exerciseID].seed != $("#seedValueExercises").val();
	const error = rex.exercises[exerciseID].statusCode === null || rex.exercises[exerciseID].statusCode.charAt(0) === "E"
	
	return seedChanged || error;
}

function resetOutputFields() {
	$('#exercise_info').addClass('hidden');	
	$('#exercise_info').removeClass("editableExercise");
	$('#exerciseConvert').hide();
	
	let fields = ['exerciseName',
				  'question',
				  'type',
				  'figure',
			      'points',
			      'answers',
			      'examHistory',
			      'authoredBy',
			      'topic',
				  'section',
			      'tags'];
			  
	fields.forEach(field => {	
		if(field == 'figure') {
			$('#exerciseFigureFiles_list_items').empty();
		} else {
			$('#' + field).html('');
		}
		
		$('#' + field + '-info').hide();
		$('#' + field).hide();
		$('label[for="'+ field +'"]').hide();
	});	
}

$('#exercise_info').on('click', '.editType', function(e) {
	const exerciseID = getID();
	invalidateAfterEdit(exerciseID);
	const newValue = rex.exercises[exerciseID].type == "schoice" ? "mchoice" : "schoice";
		
	$(this).removeClass("schoice");
	$(this).removeClass("mchoice");
	$(this).addClass(newValue);
		
	rex.exercises[exerciseID].type = newValue;
	$(this).html(getTypeText(newValue));
	
	setSimpleExerciseFileContents(exerciseID);	
	examExercisesSummary();
	f_langDeEn();
});

$('#exercise_info').on('click', '.editTrueFalse', function(e) {
	const exerciseID = getID();
	invalidateAfterEdit(exerciseID);
	const newValue = rex.exercises[exerciseID].solution[$(this).index('.solution')] !== true;
		
	$(this).removeClass("trueSolution");
	$(this).removeClass("falseSolution");
	$(this).addClass(newValue + "Solution");
		
	rex.exercises[exerciseID].solution[$(this).index('.solution')] = newValue;
	$(this).html(getTrueFalseText(newValue));
	
	setSimpleExerciseFileContents(exerciseID);	
	examExercisesSummary();
	f_langDeEn();
});

function getTypeText(value) {
	if(value == "schoice") value = 0;
	if(value == "mchoice") value = 1;

	let textDe = ["Single Choice", "Multiple Choice"];
	let textEn = ["Single Choice", "Multiple Choice"];
		
	return '<span lang="de">' + textDe[value] + '</span><span lang="en">' + textEn[value] + '</span>'
}

function getTrueFalseText(value) {
	let textDe = ["Falsch", "Richtig"];
	let textEn = ["False", "True"];
		
	return '<span lang="de">' + textDe[+value] + '</span><span lang="en">' + textEn[+value] + '</span>'
}

Array.fromList = function(list) {
    let array= new Array(list.length);
    for (let i= 0, n= list.length; i<n; i++)
        array[i]= list[i];
    return array;
};

function invalidateAfterEdit(exerciseID) {
	setExamExercise(exerciseID, false);
	rex.exercises[exerciseID].statusCode = "E000";
	rex.exercises[exerciseID].statusMessage = '<span class="exerciseTryCatch tryCatch Error"><span class="responseSign ErrorSign"><i class="fa-solid fa-circle-exclamation"></i></span><span class="exerciseTryCatchText tryCatchText"><span lang="de">Aufgabe muss neu berechnet werden.</span><span lang="en">Exercise needs to be parsed again.</span></span></span>';
	
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .examExercise').addClass('disabled');
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .exerciseTryCatch').remove();
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').prepend(rex.exercises[exerciseID].statusMessage);
}

//latex test string $ % & \ ^ _ { } ~ #
$('body').on('focus', '[contenteditable]', function() {
    const $this = $(this);
	const exerciseID = getID();
	
	if ($this.hasClass('questionText')) {
		$this.html(rex.exercises[exerciseID].question_raw);
	}
	
	if ($this.hasClass('choiceText')) {
		$this.html(rex.exercises[exerciseID].choices_raw[$this.index('.choiceText')]);
	}
	
    $this.data('before', $this.html());
}).on('blur', '[contenteditable]', function() {
    const $this = $(this);
	const exerciseID = getID();	
	
    if ($this.data('before') !== $this.html()) {
		invalidateAfterEdit(exerciseID);
		
		$this.contents().each(function() {
			if(this.nodeType === Node.COMMENT_NODE) {
				$(this).remove();
			}
		});
		
		let content = $this.get(0);
			
		if ($this.hasClass('exerciseNameText')) {
			content = contenteditable_getPlain(content);
			content = contentFileNameSanitize(content);
			
			$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .exerciseName').text(content);
			rex.exercises[exerciseID].name = content;
		}
		
		if ($this.hasClass('questionText')) {
			content = contenteditable_getSpecial(content);
			
			if(!$('#texActiveContainer span').hasClass('active'))
				content = contentTexSanitize(content);

			rex.exercises[exerciseID].question = content;
			rex.exercises[exerciseID].question_raw = content;
		}
		
		if ($this.hasClass('choiceText')) {
			content = contenteditable_getPlain(content);
			content = contentTexSanitize(content);

			rex.exercises[exerciseID].choices[$this.index('.choiceText')] = content;
			rex.exercises[exerciseID].choices_raw[$this.index('.choiceText')] = content;
		}
		
		if ($this.hasClass('solutionNoteText')) {
			content = contenteditable_getPlain(content);
			content = contentTexSanitize(content);
			
			rex.exercises[exerciseID].solutionNotes[$this.index('.solutionNoteText')] = content;
			rex.exercises[exerciseID].solutionNotes_raw[$this.index('.solutionNoteText')] = content;
		}
		
		if ($this.hasClass('points')) {
			content = contenteditable_getPlain(content);
			content = getIntegerInput(0, null, 1, content);
			rex.exercises[exerciseID].points = content;
		}
		
		if ($this.hasClass('topicText')) {
			content = contenteditable_getPlain(content);
			content = contentTextSanitize(content);
			
			rex.exercises[exerciseID].topic = content;
		}
		
		if ($this.hasClass('sectionText')) {
			content = contenteditable_getPlain(content);
			content = contentSectionSanitize(content);
			
			rex.exercises[exerciseID].section = content;
		}

		$this.html(content);
		
		setSimpleExerciseFileContents(exerciseID);	
		examExercisesSummary();
    } else {
		if(rex.exercises[exerciseID].statusCode === "S000") {
			if ($this.hasClass('questionText'))
				$this.html(rex.exercises[exerciseID].question);
	
			if ($this.hasClass('choiceText'))
				$this.html(rex.exercises[exerciseID].choices[$this.index('.choiceText')]);
		}
	}
});

function contenteditable_getPlain(content) {
	content = content.textContent;
	content = content.replaceAll('\\\\', '');
	content = content.replaceAll('&nbsp;', ' ');
	content = content.replaceAll('\n', ' ');
		
	return content;
}

function contenteditable_getSpecial(content) {
	if(content.childNodes.length === 1 && content.childNodes[0].nodeType === 3) {
		content = content.textContent;
	} else {
		content = filterNodes(content, {br: []}).innerHTML;
		content = content.replaceAll('<br>', '\\\\');
		content = content.replaceAll('<br />', '\\\\');
		content = content.replaceAll('<br/>', '\\\\');
		content = content.replaceAll('</br>', '\\\\');
		content = content.replaceAll('&nbsp;', ' ');
		content = content.replaceAll('\n', ' ');
	}
	
	return content;
}

function contentTextSanitize(content){
	return content.replaceAll(/[^a-z0-9\_\- \u00c4\u00e4\u00d6\u00f6\u00dc\u00fc\u00df]/gi, '');
}

function contentFileNameSanitize(content){
	return content.replaceAll(/[^a-z0-9\_\- ]/gi, '');
}

function contentSectionSanitize(content){
	return content.replaceAll(/[^a-z0-9\_\-\/]/gi, '');
}

function contentTexSanitize(content){
	// content = content.replaceAll(/[^\<,\.\-#\+`ß\|~\\\}\]\[\{@\!"§\$%&/\(\)\=\?´\*'\:;\>\^a-z0-9_ \u00c4\u00e4\u00d6\u00f6\u00dc\u00fc\u00df]/gi, '');
	// content = content.replaceAll('\\~{}', '~');
	// content = content.replaceAll(/[\\](?=[$%&\^_{}~#])/g, '');
	// content = content.replaceAll(/[{}]/g, '\\$&');
	// content = content.replaceAll(/[~]/g, '\\~{}');
	// content = content.replaceAll(/[$%&#\^_]/g, '\\$&');
	// content = content.replaceAll(/(\\)(?:[^$%&\^_{}~#])/g, '');
	// content = content.replaceAll(/(\\)($)/g, '');
	// ^ old
		
	content = content.replaceAll(/[^\<,\.\-#\+`ß\|~\\\}\]\[\{@\!"§\$%&/\(\)\=\?´\*'\:;\>\^a-z0-9_ \u00c4\u00e4\u00d6\u00f6\u00dc\u00fc\u00df]/gi, '');
	// content = content.replaceAll(/[\\](?=[$%&\^_{}~#])/g, '');
	content = content.replaceAll(/[\\]/g, '');// does this solve the issue? - removes all backslash - looking good - check if can break it in any way
	// content = content.replaceAll(/(\\)(?:[^$%&\^_{}~#])/g, '');
	content = content.replaceAll(/(\\)($)/g, '');
	content = content.replaceAll('"', "'");
	content = content.replaceAll('\\~{}', '~');
	content = content.replaceAll(/[{}]/g, '\\$&');
	content = content.replaceAll(/[~]/g, '\\~{}');
	content = content.replaceAll(/[$%&#\^_]/g, '\\$&');

	return content;
}

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

document.addEventListener('dblclick', (event) => {
  window.getSelection().selectAllChildren(event.target)
})

function loadExerciseFromObject(exerciseID) {
	resetOutputFields();
	
	const editable = rex.exercises[exerciseID].editable; 
	
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').removeClass("editable");
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .exerciseParse').removeClass("disabled");
	
	if(rex.exercises[exerciseID].name !== null) {	
		const field = 'exerciseName';
		const content = '<span class="exerciseNameText" contenteditable="' + editable + '" spellcheck="false">' + rex.exercises[exerciseID].name + '</span>';
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(rex.exercises[exerciseID].question !== null) {
		const field = 'question';
		let content = '';
		
		if(Array.isArray(rex.exercises[exerciseID][field])) {
			content = '<span class="questionText highlightField" contenteditable="' + editable + '" spellcheck="false">' + rex.exercises[exerciseID][field].join('') + '</span>';
		} else {
			content = '<span class="questionText highlightField" contenteditable="' + editable + '" spellcheck="false">' + rex.exercises[exerciseID][field] + '</span>';
		}
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(editable) {
		const field = 'figure';
		
		const imgContet = rex.exercises[exerciseID].figure !== null ? '<div class="exerciseFigureItem"><span class="exerciseFigureName"><img src="data:image/png;base64, ' + rex.exercises[exerciseID][field][2] + '"/></span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>' : '';
		
		const content = '<div id="exerciseFigureFiles_list_items">' + imgContet + '</div>';
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(rex.exercises[exerciseID].points !== null) {	
		const field = 'points';
				
		const content = '<span class="points highlightField" contenteditable="' + editable + '" spellcheck="false">' + rex.exercises[exerciseID][field] + '</span>';
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(rex.exercises[exerciseID].type !== null) {
		const field = 'type';
		const content = '<span class=\"type highlightField ' + rex.exercises[exerciseID].type + (editable ? ' editType' : '') + '\">' + getTypeText(rex.exercises[exerciseID].type) + '</span>'
		
		setExerciseFieldFromObject(field, content);
	}
			
	if(rex.exercises[exerciseID].type === "schoice" || rex.exercises[exerciseID].type === "mchoice" || rex.exercises[exerciseID].editable) {
		const field = 'answers';
		const zip = rex.exercises[exerciseID].solution.map((x, i) => [x, rex.exercises[exerciseID].choices[i], rex.exercises[exerciseID].solutionNotes[i]]);
		let content = '<div id="answerContent">' + zip.map(i => '<p>' + (editable ? '<button type="button" class="removeAnswer btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-trash"></i></span><span class="textButton"><span lang="de">Entfernen</span><span lang="en">Remove</span></span></button>' : '') + '<span class=\"solution ' + (i[0] + 'Solution ') + (editable ? 'editTrueFalse' : '') + '\">' + getTrueFalseText(i[0]) + '</span><span class="answerText choice"><span class="choiceText highlightField" contenteditable="' + editable + '" spellcheck="false">' + i[1] + '</span></span><span class="answerText solutionNote"><span class="solutionNoteText" contenteditable="' + editable + '" spellcheck="false">' + i[2] + '</span></span></p>').join('') + '</div>';

		if( rex.exercises[exerciseID].editable ) {
			content = '<button id="addNewAnswer" type="button" class="btn btn-default action-button shiny-bound-input"><span class="iconButton"><i class="fa-solid fa-plus"></i></span><span class="textButton"><span lang="de">Neue Antwortmöglichkeit</span><span lang="en">New Answer</span></span></button>' + content;
		}
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(rex.exercises[exerciseID].examHistory !== null) {
		const field = 'examHistory';
		const content = rex.exercises[exerciseID][field].map(i => '<span>' + i + '</span>').join('');
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(rex.exercises[exerciseID].authoredBy !== null) {
		const field = 'authoredBy';
		const content = rex.exercises[exerciseID][field].map(i => '<span>' + i + '</span>').join('');
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(rex.exercises[exerciseID].topic !== null) {
		const field = 'topic'
		const content = '<span class="topicText" contenteditable="' + editable + '" spellcheck="false">' + rex.exercises[exerciseID][field] + '</span>';
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(rex.exercises[exerciseID].section !== null) {
		const field = 'section';
		const content = '<span class="sectionText" contenteditable="' + editable + '" spellcheck="false">' + rex.exercises[exerciseID][field] + '</span>';
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(rex.exercises[exerciseID].tags !== null) {
		const field = 'tags';
		const content = rex.exercises[exerciseID][field].map(i => '<span>' + i + '</span>').join('');
		
		setExerciseFieldFromObject(field, content);
	}
	
	if(editable) {
		$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').addClass("editable");
		$('#exercise_info').addClass("editableExercise");
	} else {
		$('#exerciseConvert').show();
	}
		
	$('.exerciseItem.active').removeClass('active');
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').addClass('active');
	$('#exercise_info').removeClass('hidden');
	
	f_langDeEn();
}

function setSimpleExerciseFileContents(exerciseID, convertFromComplex=false){
	let fileText = rnwTemplate;
			
	fileText = fileText.replace("?rnwTemplate_type", rex.exercises[exerciseID].type);
	fileText = fileText.replace("?rnwTemplate_solutions", 'c(' + rex.exercises[exerciseID].solution.map(x=>x?"T":"F").join(',') + ')');	
	fileText = fileText.replace("?rnwTemplate_points", rex.exercises[exerciseID].points);
	fileText = fileText.replace("?rnwTemplate_topic", rex.exercises[exerciseID].topic);
	fileText = fileText.replace("?rnwTemplate_section", rex.exercises[exerciseID].section === null ? "" : rex.exercises[exerciseID].section);
	fileText = fileText.replace("?rnwTemplate_tags", rex.exercises[exerciseID].tags === null ? "" : rex.exercises[exerciseID].tags);
	fileText = fileText.replace("?rnwTemplate_figure", rex.exercises[exerciseID].figure !== null ? 'c(' + rex.exercises[exerciseID].figure.map(x=>'"' + x + '"').join(',') + ')' : '""');
	
	if(convertFromComplex) {
		let question_ =  rex.exercises[exerciseID].question

		if( Array.isArray(question_) )
			question_ = question_.join('')
		
		question_ = '<span>' + question_ + '</span>';
		question_ = $(question_);
		
		question_.contents().each(function() {
			if(this.nodeType === Node.COMMENT_NODE) {
				$(this).remove();
			}
		});
		
		question_ = question_.get(0);
		question_ = contenteditable_getPlain(question_);
		question_ = contentTexSanitize(question_);
		question_ = question_.replaceAll('\\', '\\\\')
		
		fileText = fileText.replace("?rnwTemplate_question", '"' + question_ + '"');
		fileText = fileText.replace("?rnwTemplate_choices", 'c(' + rex.exercises[exerciseID].choices.map(x=>'"' + x.replaceAll('\\', '\\\\') + '"').join(',') + ')');
		fileText = fileText.replace("?rnwTemplate_solutionNotes", 'c(' + rex.exercises[exerciseID].solutionNotes.map((x, i) => '"' + x.replace(/[01]. */g, '') + '"').join(',') + ')');
	} else {
		fileText = fileText.replace("?rnwTemplate_question", '"' + rex.exercises[exerciseID].question_raw.replaceAll('\\', '\\\\') + '"');
		fileText = fileText.replace("?rnwTemplate_choices", 'c(' + rex.exercises[exerciseID].choices_raw.map(x=>'"' + x.replaceAll('\\', '\\\\') + '"').join(',') + ')');
		fileText = fileText.replace("?rnwTemplate_solutionNotes", 'c(' + rex.exercises[exerciseID].solutionNotes_raw.map((x, i) => '"' + x.replace(/[01]. */g, '') + '"').join(',') + ')');
	}
	
	fileText = fileText.replaceAll("\n", "\r\n");

	rex.exercises[exerciseID].file = fileText;
}

function setExerciseFieldFromObject(field, content) {
	if(field == 'figure') {
		$('#exerciseFigureFiles_list_items').empty();
		$('#exerciseFigureFiles_list_items').append(content);
	} else {
		$('#' + field).html(content);
	}
			
	$('#' + field + '-info').show();
	$('#' + field).show();
	if($('label[for="'+ field +'"]').length > 0) $('label[for="'+ field +'"]').show();
}

function addExercise() {
	exercises = exercises + 1;	
	rex.exercises.splice(exercises, 0, []);
}

function removeExercise(exerciseID) {
	confirmDialog('Aufgabe "' + rex.exercises[exerciseID].name + '" löschen?', 'Delete exercises "' + rex.exercises[exerciseID].name + '" ?', 'Ja', 'Yes', '<i class="fa-solid fa-check"></i>', 'Nein', 'No', '<i class="fa-solid fa-xmark"></i>',
		function(remove) {
			if(!remove)
				return;
			
			rex.exercises.splice(exerciseID, 1);
			exercises = exercises - 1;
			
			$('.exerciseItem').eq(exerciseID).remove();
					
			resetOutputFields();
					
			if($('.exerciseItem:not(.filtered)').length > 0) {
				$('.exerciseItem.active:not(.filtered)').removeClass('active');
				$('.exerciseItem:not(.filtered)').eq(Math.min(exerciseID, $('.exerciseItem:not(.filtered)').length - 1)).addClass('active');
				viewExercise($('.exerciseItem.active:not(.filtered)').first().index('.exerciseItem'));
			}
			
			examExercisesSummary();
	}, exerciseID);	
}

function changeExerciseBlock(exerciseID, b) {
	const b_ = getIntegerInput(1, null, 1, b)
	rex.exercises[exerciseID].block = b_;
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
	
	rex.exercises[exerciseID].exam = b;
	
	examExercisesSummary();
}

function arrayMove(arr, fromIndex, toIndex) {
    var element = arr[fromIndex];
    arr.splice(fromIndex, 1);
    arr.splice(toIndex, 0, element);
}

$('#exercise_list_items').on('click', '.sequenceUp', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	index = $(this).closest('.exerciseItem').index('.exerciseItem');
	exercise = $(this).closest('.exerciseItem');
	
	sequenceUp(index, exercise);
});


$('#exercise_list_items').on('click', '.sequenceDown', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	index = $(this).closest('.exerciseItem').index('.exerciseItem');
	exercise = $(this).closest('.exerciseItem');
	
	sequenceDown(index, exercise);
});

function sequenceUp(index = null, exercise = null) {
	if(index === null || exercise === null) {
		exercise = $('.exerciseItem.active').first();
		index = exercise.index('.exerciseItem');
	}
	
	if(index > 0) {
		arrayMove(rex.exercises, index, index - 1);
		$(exercise).insertBefore($('#exercise_list_items').find('.exerciseItem').eq(index - 1));
	}
}

function sequenceDown(index = null, exercise = null) {
	if(index === null || exercise === null) {
		exercise = $('.exerciseItem.active').first();
		index = exercise.index('.exerciseItem');
	}
	
	if(index < $('.exerciseItem').length - 1) {
		arrayMove(rex.exercises, index, index +1);
		$(exercise).insertAfter($('#exercise_list_items').find('.exerciseItem').eq(index + 1));
	}
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
	
	viewExercise($(this).closest('.exerciseItem').index('.exerciseItem'), true);
});

$('#exercise_list_items').on('click', '.examExercise', function(e) {
	e.preventDefault();
	e.stopPropagation();
	
	setExamExercise($(this).closest('.exerciseItem').index('.exerciseItem'), !$(this).closest('.exerciseItem').hasClass('exam'));
});

$('#exercise_list_items').on('click', '.exerciseRemove', function(e) {
	e.preventDefault();
	e.stopPropagation();
		
	const exerciseID = $(this).closest('.exerciseItem:not(.filtered)').index('.exerciseItem')
	removeExercise(exerciseID);
});

$('#exercise_list_items').on('click', '.exerciseItem', function() {
	$('.exerciseItem.active').removeClass('active');
	$(this).addClass('active');
		
	viewExercise($(this).index('.exerciseItem'));
});

$('#exercise_info').on('click', '#addNewAnswer', function() {
	const exerciseID = getID();
	
	rex.exercises[exerciseID].solution.push(d_solution);
	rex.exercises[exerciseID].choices.push(d_choiceText);
	rex.exercises[exerciseID].choices_raw.push(d_choiceText);
	rex.exercises[exerciseID].solutionNotes.push(d_solutionNoteText);
	rex.exercises[exerciseID].solutionNotes_raw.push(d_solutionNoteText);
	
	invalidateAfterEdit(exerciseID);
	setSimpleExerciseFileContents(exerciseID);
	loadExerciseFromObject(exerciseID);
	
	f_langDeEn();
});

$('#exercise_info').on('click', '.removeAnswer', function() {
	const exerciseID = getID();
	const choicesID = $(this).index('.removeAnswer');
	
	if( rex.exercises[exerciseID].choices.length > 0 && rex.exercises[exerciseID].choices_raw.length > 0 ) {
		rex.exercises[exerciseID].solution.splice(choicesID, 1);		
		rex.exercises[exerciseID].choices.splice(choicesID, 1);
		rex.exercises[exerciseID].choices_raw.splice(choicesID, 1);
		rex.exercises[exerciseID].solutionNotes.splice(choicesID, 1);
		rex.exercises[exerciseID].solutionNotes_raw.splice(choicesID, 1);
	} 
	
	invalidateAfterEdit(exerciseID);
	setSimpleExerciseFileContents(exerciseID);
	loadExerciseFromObject(exerciseID);
});

function exerciseFigureFileDialog(items) {+	
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
			rex.exercises[exerciseID].figure = [fileName, fileExt, base64.split(',')[1]];
			
			$('#exerciseFigureFiles_list_items').empty();
			$('#exerciseFigureFiles_list_items').append('<div class="exerciseFigureItem"><span class="exerciseFigureName"><img src="data:image/png;base64, ' + rex.exercises[getID()].figure[2] + '"/></span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			
			setSimpleExerciseFileContents(exerciseID);
			loadExerciseFromObject(exerciseID);
		};

		fileReader.readAsDataURL(file);
	}
}

function removeExerciseFigure(element) {
	const exerciseID = getID();
	
	rex.exercises[exerciseID].figure = null;
	element.remove();
	
	setSimpleExerciseFileContents(exerciseID);
	loadExerciseFromObject(exerciseID);
}

$('#exerciseFigureFiles_list_items').on('click', '.exerciseFigureItem', function() {
	removeExerciseFigure($(this));
});

getID = function() {
	return exerciseID_hook == -1 ? $('.exerciseItem.active').index('.exerciseItem') : exerciseID_hook;
}

Shiny.addCustomMessageHandler('setExerciseId', function(exerciseID) {
	exerciseID_hook = exerciseID;
});

Shiny.addCustomMessageHandler('setExerciseSeed', function(seed) {
	rex.exercises[getID()].seed = seed;
});

Shiny.addCustomMessageHandler('setExerciseExamHistory', function(jsonData) {
	const examHistory = JSON.parse(jsonData);
	rex.exercises[getID()].examHistory = examHistory;
});

Shiny.addCustomMessageHandler('setExercisePoints', function(exercisePoints) {
	rex.exercises[getID()].points = exercisePoints;
});

Shiny.addCustomMessageHandler('setExerciseTopic', function(exerciseTopic) {
	rex.exercises[getID()].topic = exerciseTopic;
});

Shiny.addCustomMessageHandler('setExerciseTags', function(jsonData) {
	const exerciseTags = JSON.parse(jsonData);
	rex.exercises[getID()].tags = exerciseTags;
});

Shiny.addCustomMessageHandler('setExerciseType', function(exerciseType) {
	rex.exercises[getID()].type = exerciseType;
});

Shiny.addCustomMessageHandler('setExerciseQuestion', function(exerciseQuestion) {
	rex.exercises[getID()].question = exerciseQuestion;
});

Shiny.addCustomMessageHandler('setExerciseQuestionRaw', function(exerciseQuestionRaw) {
	rex.exercises[getID()].question_raw = exerciseQuestionRaw;
});

Shiny.addCustomMessageHandler('setExerciseSection', function(exerciseSection) {
	rex.exercises[getID()].section = exerciseSection;
});

Shiny.addCustomMessageHandler('setExerciseFigure', function(jsonData) {
	const figure = JSON.parse(jsonData);
	rex.exercises[getID()].figure = figure[0] === "" ? null : figure;
});

Shiny.addCustomMessageHandler('setExerciseChoices', function(jsonData) {
	const exerciseChoices = JSON.parse(jsonData);
	rex.exercises[getID()].choices = exerciseChoices;
});

Shiny.addCustomMessageHandler('setExerciseChoicesRaw', function(jsonData) {
	const exerciseChoicesRaw = JSON.parse(jsonData);
	rex.exercises[getID()].choices_raw = exerciseChoicesRaw;
});

Shiny.addCustomMessageHandler('setExerciseSolutions', function(jsonData) {
	const exerciseSolution = JSON.parse(jsonData);
	rex.exercises[getID()].solution = exerciseSolution;
});

Shiny.addCustomMessageHandler('setExerciseSolutionNotes', function(jsonData) {
	const exerciseSolutionNotes = JSON.parse(jsonData);
	rex.exercises[getID()].solutionNotes = exerciseSolutionNotes.map(x=>x.replace(/[01]. */g, ''));
});

Shiny.addCustomMessageHandler('setExerciseSolutionNotesRaw', function(jsonData) {
	const exerciseSolutionNotesRaw = JSON.parse(jsonData);
	rex.exercises[getID()].solutionNotes_raw = exerciseSolutionNotesRaw.map(x=>x.replace(/[01]. */g, ''));
});

Shiny.addCustomMessageHandler('setExerciseEditable', function(editable) {
	rex.exercises[getID()].editable = (editable === 1);
});

Shiny.addCustomMessageHandler('setExerciseStatusMessage', function(statusMessage) {
	const exerciseID = getID();
	
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .exerciseTryCatch').remove();
	$('.exerciseItem:nth-child(' + (exerciseID + 1) + ')').prepend(statusMessage);
	
	rex.exercises[exerciseID].statusMessage = statusMessage;
});

Shiny.addCustomMessageHandler('setExerciseStatusCode', function(statusCode) {
	const exerciseID = getID();
	
	rex.exercises[exerciseID].statusCode = statusCode === 0 ? "S000" : statusCode;

	if(rex.exercises[exerciseID].statusCode === "S000" || rex.exercises[exerciseID].statusCode.charAt(0) === "W")
		$('.exerciseItem:nth-child(' + (exerciseID + 1) + ') .examExercise').removeClass('disabled');
		loadExerciseFromObject(exerciseID);
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

function loadAdditionalPdfDnD(items) {	
	getFilesDataTransferItems(items).then(async (files) => {
		Array.from(files).forEach(file => {	
			additionalPdf(file);
		});
	});
}

function additionalPdfFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if( fileExt == 'pdf') {
			additionalPdf(file);
		}
	});
}

function additionalPdf(file) {
	const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
	
	if ( fileExt == 'pdf') {
		let fileReader = new FileReader();
		let base64;
		fileName = file.name.split('.')[0];

		fileReader.onload = function(fileLoadedEvent) {
			base64 = fileLoadedEvent.target.result;
			rex.examAdditionalPdf.push([fileName, base64.split(',')[1]]);
		};

		fileReader.readAsDataURL(file);
		
		$('#additionalPdfFiles_list_items').append('<div class="additionalPdfItem"><span class="additionalPdfName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
	}
}

function removeAdditionalPdf(element) {
	const additionalPdfID = element.index('.additionalPdfItem');
	rex.examAdditionalPdf.splice(additionalPdfID, 1);
	element.remove();
}

$('#seedValueExam').change(function(){
	const seed = getIntegerInput(1, 99999999, 1, $(this).val());
	setShinyInputValue("seedValueExam", seed);
}); 

$('#additionalPdfFiles_list_items').on('click', '.additionalPdfItem', function() {
	removeAdditionalPdf($(this));
});

$("#numberOfExams").change(function(){
	const numberOfExams = getIntegerInput(1, null, 1, $(this).val());
	
	setShinyInputValue("numberOfExams", numberOfExams);
	$('#s_numberOfExams').html(itemSingle(numberOfExams, 'yellowLabelValue'));
}); 

$("#autofillSeed").click(function(){
	const seed = getIntegerInput(1, 99999999, 1, $('#examDate input').val().replaceAll("-", ""));
	setShinyInputValue("seedValueExam", seed);
}); 

$("#fixedPointsExamCreate").change(function(){
	const fixedPointsExamCreate = getIntegerInput(1, null, null, $(this).val());
	setShinyInputValue("fixedPointsExamCreate", fixedPointsExamCreate);
}); 

$("#numberOfExercises").change(function(){
	const numberOfExercises = getIntegerInput(0, 45, 0, checkNumberOfExamExercises($(this).val()));
	setShinyInputValue("numberOfExercises", numberOfExercises);
}); 

$("#numberOfBlanks").change(function(){
	const numberOfBlanks = getIntegerInput(0, null, 0, $(this).val());
	setShinyInputValue("numberOfBlanks", numberOfBlanks);
});

$("#autofillNumberOfExercises").click(function(){
	const NumberOfExercises = getIntegerInput(0, 45, 0, getMaxNumberOfExamExercises());
	setShinyInputValue("numberOfExercises", NumberOfExercises);
}); 

$("#examInstitution").change(function(){
	const examInstitution = contentTextSanitize($(this).val());
	setShinyInputValue("examInstitution", examInstitution);
}); 

$("#examTitle").change(function(){
	const examTitle = contentTextSanitize($(this).val());
	setShinyInputValue("examTitle", examTitle);
}); 

$("#examCourse").change(function(){
	const examCourse = contentTextSanitize($(this).val());
	setShinyInputValue("examCourse", examCourse);
}); 

$("#examIntro").change(function(){
	if(!$('#texActiveContainer span').hasClass('active')) {
		const examIntro = contentTexSanitize($(this).val());
		setShinyInputValue("examIntro", examIntro);
	}
}); 

$("#createExamEvent").click(function(){
	createExamEvent();
}); 

async function createExamEvent() {
	const examExercises = rex.exercises.filter((exercise) => exercise.exam & exercise.file !== null);
	const exerciseNames = examExercises.map((exercise) => exercise.name);
	const exerciseCodes = examExercises.map((exercise) => exercise.file);
	const exerciseExts = examExercises.map((exercise) => exercise.ext);
	const exerciseTypes = examExercises.map((exercise) => exercise.type);
	const blocks = examExercises.map((exercise) => exercise.block);
	const additionalPdfNames = rex.examAdditionalPdf.map(pdf => pdf[0]);
	const additionalPdfFiles = rex.examAdditionalPdf.map(pdf => pdf[1]);
	
	Shiny.onInputChange("createExam", {exerciseNames: exerciseNames, exerciseCodes:exerciseCodes, exerciseExts:exerciseExts, exerciseTypes:exerciseTypes, blocks: blocks, additionalPdfNames: additionalPdfNames, additionalPdfFiles: additionalPdfFiles}, {priority: 'event'});
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

function loadExamEvaluation(items) {	
	getFilesDataTransferItems(items).then(async (files) => {
		Array.from(files).forEach(file => {	
			addExamEvaluationFile(file);
		});
	});
}

function examSolutionsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'rds') {
			addExamEvaluationFile(file);
		}
	});
}

function examRegisteredParticipantsFileDialog(items) {
	Array.from(items).forEach(file => {	
		const fileExt = file.name.slice((file.name.lastIndexOf('.') - 1 >>> 0) + 2).toLowerCase();
			
		if(fileExt == 'csv') {
			addExamEvaluationFile(file);
		}
	});
}

function examScansFileDialog(items) {
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
				rex.examEvaluation['scans'].push([fileName, fileExt, base64.split(',')[1]]);
			};

			fileReader.readAsDataURL(file);
			
			$('#examScansFiles_list_items').append('<div class="examScanItem"><span class="examScanName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
		case 'rds': 
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				base64 = fileLoadedEvent.target.result;
				rex.examEvaluation['solutions'] = [fileName, fileExt, base64.split(',')[1]];
			};

			fileReader.readAsDataURL(file);
			
			$('#examSolutionsFiles_list_items').empty();
			$('#examSolutionsFiles_list_items').append('<div class="examSolutionsItem"><span class="examSolutionsName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
		case 'csv':
			fileReader = new FileReader();
			fileName = file.name.split('.')[0];

			fileReader.onload = function(fileLoadedEvent) {
				csv = fileLoadedEvent.target.result;
				rex.examEvaluation['registeredParticipants'] = [fileName, fileExt, csv];
			};

			fileReader.readAsText(file);
			
			$('#examRegisteredParticipantsFiles_list_items').empty();
			$('#examRegisteredParticipantsFiles_list_items').append('<div class="examRegisteredParticipantsItem"><span class="examRegisteredParticipantsName">' + fileName + '.' + fileExt + '</span><span class="removeText"><i class="fa-solid fa-xmark"></i></span></div>');
			break;
	}
}

function removeExamScan(element) {
	const examScanID = element.index('.examScanItem');
	rex.examEvaluation['scans'].splice(examScanID, 1);
	element.remove();
}

$('#examScansFiles_list_items').on('click', '.examScanItem', function() {
	removeExamScan($(this));
});

function removeSolutions(element) {
	rex.examEvaluation['solutions'] = [];
	element.remove();
}

$('#examSolutionsFiles_list_items').on('click', '.examSolutionsItem', function() {
	removeSolutions($(this));
});

$("#fixedPointsExamEvaluate").change(function(){
	const fixedPointsExamEvaluate = getIntegerInput(1, null, null, $(this).val());
	setShinyInputValue("fixedPointsExamEvaluate", fixedPointsExamEvaluate);
}); 

$('#gradingKey').on('click', '.addGradingKeyItem', function() {
	addGradingKeyItem();
});

$('#gradingKey').on('click', '.removeGradingKeyItem', function() {
	removeGradingKeyItem();
});
 
function addGradingKeyItem() {
	const selector  = '#gradingKey .gradingKeyItem:last-of-type';
	Shiny.onInputChange("addGradingKeyitem", $(selector).index()+1, {priority: 'event'});
}

function removeGradingKeyItem() {
	const selector  = '#gradingKey .gradingKeyItem:last-of-type';
	const index = $(selector).index();
	
	setShinyInputValue("markThreshold" + index, "");
	setShinyInputValue("markLabel" + index, "");
	
	Shiny.onInputChange("removeGradingKeyItem", selector, {priority: 'event'});
}

$('#gradingKey').on('change', '.markThreshold', function() {
	const id = $(this).attr('id');
	const markThreshold = getFloatInput(0, null, 0, $(this).val());
	setShinyInputValue(id, markThreshold);
}); 

$('#gradingKey').on('change', '.markLabel', function() {
	const id = $(this).attr('id');
	const markLabel = contentTextSanitize($(this).val());
	setShinyInputValue(id, markLabel);
});

$('body').on('change', '#inputSheetID', function() {
	const inputSheetID = getIntegerInput(0, 99999999999, 0, $(this).val());
	setShinyInputValue("inputSheetID", inputSheetID);
});

$('body').on('change', '#inputScramblingID', function() {
	const inputScramblingID = getIntegerInput(0, 99, 0, $(this).val());
	setShinyInputValue("inputScramblingID", inputScramblingID);
});

$('body').on('change', '#inputTypeID', function() {
	const inputTypeID = getIntegerInput(0, 999, 5, $(this).val());
	setShinyInputValue("inputTypeID", inputTypeID);
});

function removeRegisteredParticipants(element) {
	rex.examEvaluation['registeredParticipants'] = [];
	element.remove();
}

$('#examRegisteredParticipantsFiles_list_items').on('click', '.examRegisteredParticipantsItem', function() {
	removeRegisteredParticipants($(this));
});

$('#evaluateExamEvent').click(function () {
	evaluateExamEvent();
});
async function evaluateExamEvent() {
	const examSolutionsName = rex.examEvaluation['solutions'][0];
	const examSolutionsFile = rex.examEvaluation['solutions'][2];
	
	const examRegisteredParticipantsnName = rex.examEvaluation['registeredParticipants'][0];
	const examRegisteredParticipantsnFile = rex.examEvaluation['registeredParticipants'][2];
	
	const examScanPdf = rex.examEvaluation['scans'].filter(x => x[1] == 'pdf')
	const examScanPdfNames = examScanPdf.map(x => x[0]);
	const examScanPdfFiles = examScanPdf.map(x => x[2]);
	
	const examScanPng = rex.examEvaluation['scans'].filter(x => x[1] == 'png')
	const examScanPngNames = examScanPng.map(x => x[0]);
	const examScanPngFiles = examScanPng.map(x => x[2]);
		
	Shiny.onInputChange("evaluateExam", {examSolutionsName: examSolutionsName, examSolutionsFile: examSolutionsFile, 
										 examRegisteredParticipantsnName: examRegisteredParticipantsnName, examRegisteredParticipantsnFile: examRegisteredParticipantsnFile, 
										 examScanPdfNames: examScanPdfNames, examScanPdfFiles: examScanPdfFiles, 
										 examScanPngNames: examScanPngNames, examScanPngFiles: examScanPngFiles}, {priority: 'event'});
}

$('body').on('click', '.compareListItem:not(.notAssigned)', function() {
	resetInspect();
	sortCompareListItems();
	
	const scanFocused = rex.examEvaluation.scans_reg_fullJoinData[parseInt($(this).find('.evalIndex').html())];
			
	$('#inspectScan').append('<div id="inspectScanContent"><div id="inspectScanImage"><img src="data:image/png;base64, ' + scanFocused.blob + '"/></div><div id="inspectScanTemplate"><span id="scannedRegistration"><span id="scannedRegistrationText"><span lang="de">Matrikelnummer:</span><span lang="en">Registration Number:</span></span><input id="selectedRegistration" list="selectRegistration"></input><datalist id="selectRegistration"></datalist></span><span id="replacementSheet"><span id="replacementSheetText"><span lang="de">Ersatzbeleg:</span><span lang="en">Replacement sheet:</span></span></span><span id="scannedSheetID"><span id="scannedSheetIDText"><span lang="de">Klausur-ID:</span><span lang="en">Exam ID:</span></span><select id="inputSheetID" autocomplete="on"></select></span><span id="scannedScramblingID"><span id="scannedScramblingIDText"><span lang="de">Variante:</span><span lang="en">Scrambling:</span></span><input id="inputScramblingID"/></span><span id="scannedTypeID"><span id="scannedTypeIDText"><span lang="de">Belegart:</span><span lang="en">Type:</span></span><input id="inputTypeID"/></span><div id="scannedAnswers"></div></div></div><div id="inspectScanButtons"><button id="cancelInspect" class="inspectScanButton" type="button" class="btn btn-default action-button shiny-bound-input"><span class="hotkeyInfo"><span lang="de">ESC</span><span lang="en">ESC</span></span><span class="iconButton"><i class="fa-solid fa-xmark"></i></span><span class="textButton"><span lang="de">Abbrechen</span><span lang="en">Cancel</span></span></button><button id="applyInspect" class="inspectScanButton" type="button" class="btn btn-default action-button shiny-bound-input"><span class="hotkeyInfo"><span lang="de">ENTER</span><span lang="en">ENTER</span></span><span class="iconButton"><i class="fa-solid fa-check"></i></span><span class="textButton"><span lang="de">Übernehmen</span><span lang="en">Accept</span></span></button><button id="applyInspectNext" class="inspectScanButton" type="button" class="btn btn-default action-button shiny-bound-input"><span class="hotkeyInfo"><span lang="de">LEERTASTE</span><span lang="en">SPACE</span></span><span class="iconButton"><i class="fa-solid fa-list-check"></i></span><span class="textButton"><span lang="de">Übernehmen & Nächter Scan</span><span lang="en">Accept & Next Scan</span></span></button></div>');
	
	// populate input fields
	let registrations = rex.examEvaluation.scans_reg_fullJoinData.filter(x => x.scan === 'NA').map(x => ({registration:x.registration, name:x.name}));
	
	$('#replacementSheet').append('<input type="checkbox"' + (scanFocused.replacement === "1" ? ' checked="checked"' : '') + '>');
	
	if(scanFocused.registration !== d_registration)
		registrations.push({registration:d_registration, name:""});
	
	registrations.sort();
	registrations.unshift({registration:scanFocused.registration, name:scanFocused.name} );
	
	$.each(registrations, function (i, p) {
		$('#selectRegistration').append($('<option></option>').val(p.registration).html(p.registration + " " + p.name));
	});
			
	let examIds = rex.examEvaluation['examIds'];
	examIds.sort()
	
	$.each(examIds, function (i, p) {
		$('#inputSheetID').append($('<option></option>').val(p).html(p));
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
		
		let answerBlock = 1;
		let answerRow = 1;
		let answerColumn = 1;
		
		let scannedAnswerBlocks = '<table class="scannedAnswerBlock answerBlock' + answerBlock + ' answerRow' + answerRow + ' answerColumn' + answerColumn + '">' + scannedAnswersHeader;
		let scannedAnswerItems = '';
		
		for (let i = 0; i < numExercises; i++) {	
			let scannedAnswer = '<tr class="scannedAnswer"><td class="scannedAnswerId">' + (i + 1) + '</td>';
			
			for (let j = 0; j < numChoices; j++) {
				const checked = scanFocused[i + 1].split('')[j] === "1" ? ' checked="checked"' : '';
				
				let checkboxItem = '<input type="checkbox"' + checked + '>';
				
				scannedAnswer = scannedAnswer + '<td>' + checkboxItem + '</td>';
			}
			
			scannedAnswerItems = scannedAnswerItems + scannedAnswer + '</tr>';
			
			const blockComplete = (i + 1) >= 5 && (i + 1) % 5 == 0;
			const lastItem = (i + 1) == numExercises;
			
			if(blockComplete || lastItem)
				scannedAnswerBlocks = scannedAnswerBlocks + scannedAnswerItems + '</span>';
			
			if(blockComplete && !lastItem) {
				scannedAnswerItems = '';
				
				answerBlock += 1; 
				answerRow = (answerBlock - 1) % 3 + 1;
				answerColumn = Math.ceil(answerBlock / 3);
				
				scannedAnswerBlocks = scannedAnswerBlocks + '<table class="scannedAnswerBlock answerBlock' + answerBlock + ' answerRow' + answerRow + ' answerColumn' + answerColumn + '">' + scannedAnswersHeader;
			}
		}
		
		$('#scannedAnswers').append(scannedAnswerBlocks);
	}
	
	$(this).addClass('focus');
	$('.compareListItem:not(.focus)').addClass('blur');
	$('#inspectScan').insertAfter('.compareListItem.focus');
		
	f_langDeEn();
	$('#inspectScan').show();
	magnifierInit();
});

function magnifierInit() {
	let magnifierSize = $('#inspectScanImage').width() / 2;
	let magnification = 3;
	let magnify = new magnifier();
	magnify.magnifyImg('#inspectScanImage  img', magnification, magnifierSize);
}

function magnifier() {
	this.magnifyImg = function(ptr, magnification, magnifierSize) {
		let $pointer;
		if (typeof ptr == "string") {
			$pointer = $(ptr);
		} else if (typeof ptr == "object") {
			$pointer = ptr;
		}
		
		if(!($pointer.is('img'))){
			alert('Object must be image.');
			return false;
		}
	
		magnification = +(magnification);
	
		$pointer.hover(function() {
			$(this).css('cursor', 'none');
			$('.magnify').show();

			let width = $(this).width();
			let height = $(this).height();
			let src = $(this).attr('src');
			let imagePos = $(this).offset();
			let image = $(this);
				
			$('.magnify').css({
				'background-size': width * magnification + 'px ' + height * magnification + "px",
				'background-image': 'url("' + src + '")',
				'width': magnifierSize,
				'height': magnifierSize
			});
			
			let magnifyOffset = +($('.magnify').width() / 2);
			let rightSide = +(imagePos.left + $(this).width());
			let bottomSide = +(imagePos.top + $(this).height());
		
			$(document).mousemove(function(e) {
					if (e.pageX < +(imagePos.left - magnifyOffset / 6) || e.pageX > +(rightSide + magnifyOffset / 6) || e.pageY < +(imagePos.top - magnifyOffset / 6) || e.pageY > +(bottomSide + magnifyOffset / 6)) {
					$('.magnify').hide();
					$(document).unbind('mousemove');
					$(window).unbind('wheel');
				}
				let backgroundPos = "" - ((e.pageX - imagePos.left) * magnification - magnifyOffset) + "px " + -((e.pageY - imagePos.top) * magnification - magnifyOffset) + "px";
				$('.magnify').css({
					'left': e.pageX - magnifyOffset,
					'top': e.pageY - magnifyOffset,
					'background-position': backgroundPos,
					'background-size': width * magnification + 'px ' + height * magnification + "px",
					'width': $('#inspectScanImage').width() / 2 + "px",
					'height': $('#inspectScanImage').width() / 2 + "px"
				});
			});
			
			$(window).on('wheel', function(e) {
				event.preventDefault();
				event.stopPropagation();
				
				console.log("wheel");
				
				const delta = e.originalEvent.deltaY;

				if (delta > 0) 
					magnification = Math.max(1, magnification - 0.2);
				else 
					magnification = Math.min(10, magnification + 0.2);
				
				let backgroundPos = "" - ((e.pageX - imagePos.left) * magnification - magnifyOffset) + "px " + -((e.pageY - imagePos.top) * magnification - magnifyOffset) + "px";
				$('.magnify').css({
					'left': e.pageX - magnifyOffset,
					'top': e.pageY - magnifyOffset,
					'background-position': backgroundPos,
					'background-size': width * magnification + 'px ' + height * magnification + "px",
					'width': $('#inspectScanImage').width() / 2 + "px",
					'height': $('#inspectScanImage').width() / 2 + "px"
				});
			});
		}, function() {
	
		});
	};
	
	this.init = function() {
		$('body').prepend('<div class="magnify"></div>');
	}
	
	return this.init();
}

function populateCompareTable() {
	$('#compareScanRegistrationDataTable').find('*').not('.loadingCompareScanRegistrationDataTable').remove();
	
	let invalidCount = 0; 
	let validCount = 0; 
	let notAssignedCount = 0;
	
	rex.examEvaluation.scans_reg_fullJoinData.forEach((element, index) => {	
		let stateClass = null;
				
		// invalid
		if(scanInvalid(element)) {
			stateClass = 'invalid';
			invalidCount++;
		}
		
		// not assigned
		if(scanNotAssiged(element)) {
			stateClass = 'notAssigned'
			notAssignedCount++;
		}
		
		// valid 
		if(scanValid(element)) {
			stateClass = 'valid'
			validCount++;
		}

		// edited
		if(scanEdited(element))
			stateClass = [stateClass, 'edited'].join(' ');		

		// lastEdited
		if(scanLastEdited(element))
			stateClass = [stateClass, 'lastEdited'].join(' ');			
		
		$('#compareScanRegistrationDataTable').append('<div class="compareListItem ' + stateClass + '"><span class="evalIndex">' + index + '</span></span><span class="evalRegistration">' + element.registration + '</span><span class="evalName">' + element.name + '</span><span class="evalId">' + element.id + '</span><span class="evalIcons"><span class="evalEditedIcon"><i class="fa-solid fa-pencil"></i></span><span class="evalInspectIcon"><i class="fa-solid fa-magnifying-glass"></i></span></span></div>')
	});
	
	// scan stats
	$('#scanStats').empty();
	$('#scanStats').append('<span id="scansInvalidCount" class="scanStat myLabel"><span class="scanStatText label_key redLabelKey"><span lang="de">Ungültige Scans</span><span lang="en">Invalid scans</span></span><span class="scanStatValue label_value redLabelValue">' + invalidCount + '</span></span>')
	$('#scanStats').append('<span id="scansValidCount" class="scanStat myLabel"><span class="scanStatText label_key greenLabelKey"><span lang="de">Gültige Scans</span><span lang="en">Valid scans</span></span><span class="scanStatValue label_value greenLabelValue">' + validCount + '</span></span>')
	$('#scanStats').append('<span id="scansnotAssignedCount" class="scanStat myLabel"><span class="scanStatText label_key yellowLabelKey"><span lang="de">Nicht zugeordnete Matrikelnummern</span><span lang="en">Registration numbers not assigned</span></span><span class="scanStatValue label_value yellowLabelValue">' + notAssignedCount + '</span></span>')
	
	$('.loadingCompareScanRegistrationDataTable').hide();
	f_langDeEn();
}

function scanInvalid(scan) {
	return scan.scan !== 'NA' && (scan.registration === d_registration || !rex.examEvaluation['examIds'].includes(scan.sheet) || isNaN(scan.sheet) || isNaN(scan.scrambling) || isNaN(scan.type) || (scan.replacement !== "0" && scan.replacement !== "1"))
}

function scanNotAssiged(scan) {
	return scan.scan === 'NA';
}

function scanValid(scan) {
	return !scanNotAssiged(scan) && !scanInvalid(scan);
}

function scanEdited(scan) {
	return Math.abs(scan.changeHistory) === 1;
}

function scanLastEdited(scan) {
	return scan.changeHistory === -1;
}

function sortCompareListItems(){
	let list = $("#compareScanRegistrationDataTable .compareListItem").get();
	let maxDigits = Math.max(...list.map(x=>$(x).find('.evalRegistration').html()).map(x=>Math.log(x) * Math.LOG10E + 1 | 0));
	let sortRegistrations = function(a, b) {
		let x = a;
		let y = b;
		a = parseInt($(a).find('.evalRegistration').html());
		b = parseInt($(b).find('.evalRegistration').html());
		
		a = (isNaN(a) ? -1 : a);
		b = (isNaN(b) ? -1 : b);
		
		if($(x).hasClass('invalid')) 
			a = a + Math.pow(10, maxDigits + 1)
	
		if($(x).hasClass('valid')) 
			a = a + Math.pow(10, maxDigits + 2)
				
		if($(x).hasClass('notAssigned')) 
			a = a + Math.pow(10, maxDigits + 3)
			
		if($(y).hasClass('invalid')) 
			b = b + Math.pow(10, maxDigits + 1)
			
		if($(y).hasClass('valid')) 
			b = b + Math.pow(10, maxDigits + 2)
			
		if($(y).hasClass('notAssigned')) 
			b = b + Math.pow(10, maxDigits + 3)	
		
		return a < b ? -1 : a > b ? 1 : 0;
	}

    list.sort(sortRegistrations);
    for (let i = 0; i < list.length; i++) {
        list[i].parentNode.appendChild(list[i]);
    }
}

function resetInspect(){
	$('.magnify').remove();
	$('#inspectScan').hide();
	$('#inspectScan').insertBefore('#compareScanRegistrationDataTable');
	$('.compareListItem').removeClass('blur');
	$('.compareListItem').removeClass('focus');
	$('#inspectScan').empty();
}

$('body').on('click', '#applyInspect', function() {
	applyInspect();
});

$('body').on('click', '#applyInspectNext', function() {
	applyInspectNext();
});

function applyInspectNext(){
	applyInspect();
	
	if($('#compareScanRegistrationDataTable .compareListItem.invalid').length !== 0) {
		$('#compareScanRegistrationDataTable .compareListItem.invalid').first().click();
	}
}

const zeroPad = (num, places) => isNaN(num) ? "NA" : String(num).padStart(places, '0');

function applyInspect(){	
	const scanFocusedIndex = parseInt($('#compareScanRegistrationDataTable .compareListItem.focus .evalIndex').html());
	rex.examEvaluation.scans_reg_fullJoinData = rex.examEvaluation.scans_reg_fullJoinData.map(obj => {
		return { ...obj, changeHistory: Math.abs(obj.changeHistory) }
	});
	rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].changeHistory = -1;
	
	const registrationUnchanged = $('#selectedRegistration').val() === rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].registration;
	const replacementUnchanged = ($('#replacementSheet').find("input").prop('checked') ? "1" : "0") === rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].replacement;
	const inputSheetIDUnchanged = zeroPad($('#inputSheetID').val(), 11) === rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].sheet;
	const scramblingIDUnchanged = zeroPad($('#inputScramblingID').val(), 2) === rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].scrambling;
	const inputTypeIDUnchanged = zeroPad($('#inputTypeID').val(), 3) === rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].type;
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
		
		return rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex][index + 1] === exerciseAnswers;
    }).get().every(x => x === true);
	
	if(registrationUnchanged && replacementUnchanged && inputSheetIDUnchanged && scramblingIDUnchanged && inputTypeIDUnchanged && answersUnchanged) {
		resetInspect();
		sortCompareListItems();
		return;
	}
	
	let itemsToAdd = null;
	let itemsToRemove = null;
	
	if(!registrationUnchanged) {
		if(rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].registration !== d_registration) {
			itemsToAdd = JSON.parse(JSON.stringify(rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex])); // clone byValue
			Object.keys(itemsToAdd).forEach(x => itemsToAdd[x] = "NA");
			itemsToAdd.registration = rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].registration;
			itemsToAdd.name = rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].name;
			itemsToAdd.id = rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].id;	
		}
			
		if($('#selectedRegistration').val() === d_registration) {	
			rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].name = "NA"
			rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].id = "NA"
		} else {
			itemsToRemove = rex.examEvaluation.scans_reg_fullJoinData.map(function(x) { return x.registration; }).indexOf($('#selectedRegistration').val()); 
			
			rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].name = rex.examEvaluation.scans_reg_fullJoinData[itemsToRemove].name
			rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].id = rex.examEvaluation.scans_reg_fullJoinData[itemsToRemove].id 
		}
	}
	
	rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].registration = $('#selectedRegistration').val();	
	rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].replacement = ($('#replacementSheet').find("input").prop('checked') ? "1" : "0");	
	rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].sheet = zeroPad($('#inputSheetID').val(), 11);	
	rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].scrambling = zeroPad($('#inputScramblingID').val(), 2);	
	rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex].type = zeroPad($('#inputTypeID').val(), 3);	
	
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
		
		rex.examEvaluation.scans_reg_fullJoinData[scanFocusedIndex][index + 1] = exerciseAnswers;
    });
	
	if(itemsToRemove !== null) 
		rex.examEvaluation.scans_reg_fullJoinData.splice(itemsToRemove, 1);
	
	if(itemsToAdd !== null)
		rex.examEvaluation.scans_reg_fullJoinData.push(itemsToAdd);
	
	resetInspect();
	populateCompareTable();
	sortCompareListItems();
}

$('body').on('click', '#cancelInspect', function() {
	cancelInspect();
});

function cancelInspect(){
	resetInspect();
	sortCompareListItems();
}

$('body').on('click', '#shiny-modal button[data-dismiss="modal"]', function() {
	$('#disableOverlay').removeClass("active");
});

Shiny.addCustomMessageHandler('setExanIds', function(jsonData) {
	rex.examEvaluation['examIds'] = JSON.parse(jsonData);
});

Shiny.addCustomMessageHandler('compareScanRegistrationData', function(jsonData) {
	rex.examEvaluation.scans_reg_fullJoinData = JSON.parse(jsonData);
	
	rex.examEvaluation.scans_reg_fullJoinData = rex.examEvaluation.scans_reg_fullJoinData.map(obj => {
		return { ...obj, sheet: zeroPad(obj.sheet, 11), scrambling: zeroPad(obj.scrambling, 2), type: zeroPad(obj.type, 3), changeHistory: 0 }
	});

	populateCompareTable();
	sortCompareListItems();
});

Shiny.addCustomMessageHandler('backTocompareScanRegistrationData', function(x) {
	populateCompareTable();
	sortCompareListItems();
});

Shiny.addCustomMessageHandler('evaluationStatistics', function(jsonData) {
	rex.examEvaluation.statistics = JSON.parse(jsonData);	
});

$('body').on('click', '#proceedEval', function() {
	const scans_reg_fullJoinData = rex.examEvaluation.scans_reg_fullJoinData;
	const properties = ['scan', 'sheet', 'scrambling', 'type', 'replacement', 'registration'].concat(new Array(45).fill(1).map( (_, i) => i+1 ));
	const datenTxt = Object.assign({}, scans_reg_fullJoinData.filter(x => scanValid(x)).map(x => Object.assign({}, properties.map(y => x[y] === undefined ? "00000" : x[y], {}))));
	
	Shiny.onInputChange("proceedEvaluation", {scans_reg_fullJoinData:scans_reg_fullJoinData, datenTxt:datenTxt}, {priority: 'event'});
});

/* --------------------------------------------------------------
 ADDON TOOLS
-------------------------------------------------------------- */
$("#addons_list_items .sidebarListItem").click(function(){
	$('#addons_list_items .sidebarListItem').removeClass('active');
	$(this).addClass('active');
	
	selectListItem($('.mainSection.active .sidebarListItem.active').index());
}); 
