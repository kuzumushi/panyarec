function makeUtility(){
		var makeDiv = function(attrHash, recursiveFunction){
				var $newDiv = $("<div/>");
				if(attrHash["class"]) $newDiv.attr("class", attrHash["class"]);
				if(attrHash["id"])    $newDiv.attr("id", attrHash["id"]);
				if(attrHash["html"])  $newDiv.html(attrHash["html"]);
				if(recursiveFunction)recursiveFunction(function(attrHash, recursiveFunction){
						$newDiv.append(makeDiv(attrHash, recursiveFunction));
				}, $newDiv);
				return $newDiv;
		};
		return {
				makeDiv: makeDiv
		};
}

function makeProgramTableScrollSynchronizer($allChannelTitle){
    var defaultTopOfChannelTitle = $allChannelTitle.position().top;
    var $scrollWindow    = $("div#scroll_window");
    var $searchBox       = $("div#search_box");
    var $timeBar         = $("div#time_bar_left");
    var synchronize = function(){
				var top    = $scrollWindow.scrollTop();
				var left   = $scrollWindow.scrollLeft();
				var height = $scrollWindow.height();
				$timeBar.css("left", left + "px");
				$allChannelTitle.css("top", (top + defaultTopOfChannelTitle) + "px");
				$searchBox.css("top", (top + height - $searchBox.height() - 30) + "px");
				$searchBox.css("left", (left +  $timeBar.width() + 15) + "px");
    };
    var bind = function(){
				$scrollWindow.scroll(synchronize);
				$(window).resize(synchronize);
				synchronize();
    };
    return {bind: bind};
}

function makeProgramTableSizeFixer(){
    var $head         = $("div#head");
    var $scrollWindow = $("div#scroll_window");
    var $programTable = $("div#program_table");
    var $bar          = $("div.bar");
    var $timeBar      = $("div.time_bar");
    var fixProgramTableSize = function(){
				$scrollWindow.css("height", $(window).height() - $head.height() + "px");
				$bar.css("height", barHeight + "px");
				$programTable.css("height", barHeight + "px");
				$programTable.css("width", channelNum*150 + $timeBar.width() + "px");
    };
    var bind = function(){
				$(window).resize(fixProgramTableSize);
				fixProgramTableSize();
    };
    return {bind: bind};
}


function makeDashBoard($dashBoard){
		var $frontDocument  = null;
		var closingFunction = null;
		var dashBoardHeight = null;
		var close = function(){
				$dashBoard.hide();
		};
		var changeFront = function($newFrontDocument, newClosingFunction){
				$dashBoard.show();
				if($frontDocument){
						$frontDocument.hide();
						if(closingFunction)closingFunction();
				}
				$newFrontDocument.show();
				$frontDocument  = $newFrontDocument;
				closingFunction = newClosingFunction;
		};
		var changeHeight = function(height, callBack){
				if(typeof callBack === 'undefined') callBack = function(){}; 
				dashBoardHeight = height;
				var boardTop = ($(window).height() - dashBoardHeight)/2;
				$dashBoard.animate({"top": boardTop + "px", "height": dashBoardHeight + "px"}, "fast", "swing", callBack);
		};
		var changeHeightPlus = function(heightDiff){
				dashBoardHeight += heightDiff;
				var boardTop = ($(window).height() - dashBoardHeight)/2;
				$dashBoard.animate({"top": boardTop + "px", "height": dashBoardHeight + "px"}, "fast");
		};
		var changeWidth = function(width, callBack){
				if(typeof callBack === 'undefined') callBack = function(){}; 
				var boardLeft = ($(window).width() - width)/2
				$dashBoard.animate({"left": boardLeft + "px", "width": width + "px"}, "fast", "swing", callBack);
		};
		var fixPosition = function(){
				$dashBoard.css("left", ($(window).width() - $dashBoard.width())/2   + "px");
				$dashBoard.css("top",  ($(window).height() - $dashBoard.height())/2 + "px");
		};
		var bind = function(){
				$(window).resize(fixPosition);
		};
		fixPosition();
		var operator = {
				close:            close,
				changeFront:      changeFront,
				changeHeight:     changeHeight,
				changeHeightPlus: changeHeightPlus,
				changeWidht:      changeWidth
		};
		return {bind: bind, operator: operator};
}

function makeLogView(dashBoardOperator){
		var $logViewBox  = $("div#log_view");
		var $list        = $logViewBox.children("div.list");
		var $closeButton = $logViewBox.find("div.close_button");
		var $openButtons = $(".open_log_view");
		var $result      = $("div#log_result");
    var DETAIL_EXTENSION_HEIGHT = 100;
		var DEFAULT_LINE_HEIGHT     = 18;
		var closeFunction     = function(){};
		var page = 0;
		var postAndPrint = function(){
				$list.html("");
				$.post('./json/get_log_list', {
						type:         "",
						limit:        25
				}, print, 'json');
		};
		var print = function(jsonData){
				var isDashBoardExtended = false;
				dashBoardOperator.changeHeight(jsonData.limited_number * 21 + 40 + 20);
				changeResult(jsonData.matched_number + "件中" + jsonData.limited_number + "件を表示");
				$.each(jsonData.logs, function(){
						var log = this;
						var $newLine = util.makeDiv({"class": "log_show", "id": log.log_id}, function(makeDiv, $parent){
								makeDiv({"class": "time", "html": log.time});
								makeDiv({"class": "name", "html": log.name});
								makeDiv({"class": "message", "html": log.message});
								$parent.children().addClass("first_line");
								makeDiv({"class": "inner"}, function(makeDiv){
										makeDiv({"class": "detail", "html":
																	 "種別：" + log.name + "<br>" +
																	 "メッセージ：" + log.message + "<br>" +
																	 "詳細：" + log.detail			 
														});
								});
						});
						$newLine.children(".first_line").click(function(){
								var log_id = $newLine.attr("id");
								if(log_id == closeFunction()){
										closeFunction = function(){};
										dashBoardOperator.changeHeightPlus(-DETAIL_EXTENSION_HEIGHT);
										isDashBoardExtended = false;
										return;
								}
								changeLineHeight($newLine, DEFAULT_LINE_HEIGHT + DETAIL_EXTENSION_HEIGHT);
								if(!isDashBoardExtended){
										isDashBoardExtended = true;
										dashBoardOperator.changeHeightPlus(DETAIL_EXTENSION_HEIGHT);
								}
								closeFunction = function(){
										changeLineHeight($newLine, DEFAULT_LINE_HEIGHT);
										return log_id;
								};
						});
						$list.append($newLine);
				});
		};
		var changeLineHeight = function($line, height){
				$line.animate({"height": height + "px"}, "fast");
		};
		var changeResult = function(str){
				$result.html(str);
		};
		var bind = function(){
				$openButtons.click(function(){
						dashBoardOperator.changeFront($logViewBox);
						postAndPrint();
				});
				$closeButton.click(function(){dashBoardOperator.close();})
		};
		return {bind: bind};
}

function makeRecordedView(dashBoardOperator){
		var $recordedViewBox = $("div#recorded_view");
		var $list            = $recordedViewBox.children("div.list");
		var $closeButton     = $recordedViewBox.find("div.close_button");
		var $openButtons     = $(".open_recorded_view");
		var lastSearchedCondition = null;
		var nowPage               = 0;
		var nowShowingNumber      = 0;
		var isFirstVisit          = true;
		var LIMIT = 40;
		var makeConditionObject = function(){
				//var searchStr = $recordedViewBox.find("input.search_word").val();
				return {
						keyword: ""
				};
		};
		var postAndPrint = function(conditionObject, limit, page){
				conditionObject.page  = page;
				conditionObject.limit = limit;
				$.post('./json/get_recorded_list', conditionObject, print, 'json');
		};
		var print = function(jsonData){
				var allNumber = jsonData.matched_number;
				nowShowingNumber += jsonData.limited_number;
				$.each(jsonData.recordeds, function(){
						var recorded = this;
						var $newLine = util.makeDiv({
								"class": "recorded_show",
								"id":    recorded.recorded_id
						}, function(makeDiv, $parent){
								makeDiv({"class": "started_time", "html": recorded.started_time});
								makeDiv({"class": "title", "html": recorded.title});
								makeDiv({"class": "file_path", "html": recorded.file_path})
								$parent.children().addClass("first_line");
						});
						$list.append($newLine);
				});
		};
		var nextPage = function(){
				if(!lastSearchedCondition)return;
				postAndPrint(lastSearchedCondition, LIMIT, ++page);
		};
		var openViewBox = function(){
				dashBoardOperator.changeFront($recordedViewBox);
				dashBoardOperator.changeHeight(600);
		};
		var newSearch = function(){
				$list.html("");
				nowShowingNumber = 0;
				postAndPrint(lastSearchedCondition = makeConditionObject(), LIMIT, page = 0);
		};
		var scrollCheck = function(){
				var top    = $list.scrollTop();
				var left   = $list.scrollLeft();
		};
		var bind = function(){
				$openButtons.click(function(){
						openViewBox();
						if(isFirstVisit){
								newSearch();
								isFirstVisit = false;
						}
				});
				$list.scroll(scrollCheck);
				$closeButton.click(function(){dashBoardOperator.close();})
		};
		return {bind: bind};
}

function makeCategoryView(dashBoardOperator){
		var $categoryViewBox = $("div#category_view");
		var $list            = $categoryViewBox.children("div.list");
		var $closeButton　　 = $categoryViewBox.find("div.close_button");
		var $openButtons     = $(".open_category_view");
		var print = function(){
				$list.html("");
				$.getJSON('./json/get_category_list', function(data){
						dashBoardOperator.changeHeight(data.number * 21 + 40);
						$.each(data.categories, function(){
								var $newLine = $("<div/>").attr("class", "category_show").attr("id", this.category_id);
								$colorLine = $("<div/>").attr("class", "category_" + this.category_id);
								$newLine.append($("<div/>").attr("class", "color_line").append($colorLine));
								$newLine.append($("<div/>").attr("class", "name").html(this.name));
								$colorDiv = $("<div/>").attr("class", "color").html(this.color);
								$newLine.append($colorDiv);
								bindColorChanger($colorDiv, this.category_id);
								$list.append($newLine);
						});
						
				});
		};
		var bindColorChanger = function($colorDiv, category_id){
				var is_static = true;
				var $inputBox  = $("<input/>").attr("type", "text").attr("class", "input_box");
				var color = $colorDiv.html();
				$colorDiv.click(function(){
						if(!is_static)return;
						$colorDiv.html("");
						$colorDiv.append($inputBox);
						$inputBox.focus().val(color);;
						is_static = false;
						$inputBox.focusout(function(){
								if(is_static)return;
								var newColor = $inputBox.val();
								if(newColor === color){
										$colorDiv.html(color);
										is_static = true;
										return;
								}
								$.post('./json/change_category_color', {
										category_id: category_id,
										color:       newColor
								}, function(data){
										if(!data.result)return;
										color = newColor;
										$colorDiv.html(color);
										$("div.category_" + category_id).css("background-color", newColor);
										is_static = true;
								}, 'json');
						});
						$inputBox.keypress(function(e){
								if(e.which == 13)$inputBox.focusout();
						});
				});

		};
		var bind = function(){
				$openButtons.click(function(){
						dashBoardOperator.changeFront($categoryViewBox);
						print();
				});
				$closeButton.click(function(){dashBoardOperator.close();})
		};
		return {bind: bind};
}

function makeProgramSearchBox(dashBoardOperator){
		var $searchBox     = $("div#search_box");
		var $textInput     = $("input#search_text");
		var $showBox       = $("div#program_search_list");
		var $closeButton   = $showBox.find("div.close_button");
		var $resultList    = $showBox.children("div.list");
		var $searchIcon    = $("img#search_head_img");
		var $channelSelect = $("select#program_search_channel");
		var $resultView  = $("div#program_search_result_view");
		var PRELOAD_ICON_PATH = "./img/preloader.gif";
		var SEARCH_ICON_PATH  = "./img/search.gif";
    var DETAIL_EXTENSION_HEIGHT = 150;
		var DEFAULT_LINE_HEIGHT     = 18;
		//var boxHeight = 100;
		var searchStr         = "";
    var timer             = false;
    var observingInterval = false;
		var closeFunction     = function(){};
    var checkSearch = function(){
				var newSearchStr = $textInput.val();
				if(newSearchStr == searchStr)return;
				searchStr = newSearchStr;
				if(timer)clearTimeout(timer);
				timer = setTimeout(function(){
						if(newSearchStr === ""){
								dashBoardOperator.close();
								return;
						}
						
						search();
				}, 300);
    };
		var search = function(){
				$searchIcon.attr("src", PRELOAD_ICON_PATH);
				var newSearchStr = $textInput.val();
				$.post('./json/program_search', {
						keyword:      searchStr,
						channel_id:   $channelSelect.val() || null,
						limit:        20
				}, function(data){
						var boxHeight = data.limited_number * 21 + 40 + 20;
						var resultStr1 = data.matched_number + "件中" + data.limited_number + "件を表示";
						var resultStr2 = "(" + data.now_page_number + "/" + data.all_page_number + ")";
						$resultView.html(resultStr1 + resultStr2);
						if(newSearchStr !== searchStr)return;
						$searchIcon.attr("src", SEARCH_ICON_PATH);
						$resultList.html("");
						dashBoardOperator.changeHeight(boxHeight);
						$.each(data.programs, function(){
								var programId = this.program_id;
								var $newLine = $("<div/>").attr("class", "searched_program").attr("id", programId);
								$newLine.append($("<div/>").attr("class", "start_time").html(this.start_time_str));
								$newLine.append($("<div/>").attr("class", "title").html(this.title));
								$newLine.append($("<div/>").attr("class", "channel_name").html(this.channel_name));
								$newLine.append($("<div/>").attr("class", "event_id").html(this.event_id));
								$newLine.children().addClass("first_line");
								$reserveButton = $("<div/>").attr("class", "reserve").html("●");
								$newLine.append($reserveButton);
								$newLine.append($("<div/>").attr("class", "go").html("→"));
								var $detail = $("<div/>").attr("class", "detail");
								$newLine.append($detail);
								$resultList.append($newLine);
								$reserveButton.click(function(){
										$.getJSON("./json/reserve/" + programId, function(reserveResponse){
												alert(reserveResponse.message);
										});
								});
								$newLine.children(".first_line").click(function(){
										var program_id        = $newLine.attr("id");
										if(program_id == closeFunction()){
												closeFunction = function(){};
												dashBoardOperator.changeHeight(boxHeight);
												return;
										}
										boxHeight += DETAIL_EXTENSION_HEIGHT;
										$detail.html("");
										$newLine.animate({"height": DEFAULT_LINE_HEIGHT + DETAIL_EXTENSION_HEIGHT + "px"}, "fast");
										dashBoardOperator.changeHeight(boxHeight);
										$.getJSON('./json/program_info/' + program_id, function(data){
												if(data.error_message){
														$detail.append($("<div/>").attr("class", "error").html(data.error_message));
														return;
												}
												$detail.append($("<div/>").attr("class", "detail_detail").html(data.detail));
										});
										closeFunction = function(){
												boxHeight -= DETAIL_EXTENSION_HEIGHT;
												$detail.html("");
												$newLine.animate({"height": DEFAULT_LINE_HEIGHT + "px"}, "fast");
												return program_id
										};
								});
						});
						dashBoardOperator.changeFront($showBox);
				}, 'json');
		};
    var onFocus = function(){
				if($textInput.val() !== "")dashBoardOperator.changeFront($showBox);
				//dashBoardOperator.changeHeight(boxHeight);
				$resultList.html("");
				searchStr = "";
				$textInput.css("opacity", "1.00");
				observingInterval = setInterval(checkSearch, 100);
    };
    var onFocusOut = function(){
				$textInput.css("opacity", "0.50");
				if(observingInterval)clearInterval(observingInterval);
    };
		var init = function(){
				$.getJSON('./json/get_channel_list', function(data){
						$.each(data.channels, function(){
								var $newChannel = $("<option/>").attr("value", this.channel_id).html(this.name);
								$channelSelect.append($newChannel);
						});
				});
		};
    var bind = function(){
				$textInput.focus(onFocus);
				$textInput.focusout(onFocusOut);
				$channelSelect.change(search);
				$closeButton.click(function(){
						dashBoardOperator.close();
				});
    };
		init();
    return {bind: bind};
}

function makeChannelTitleBox(){
    var topClass     = "div.channel_title";
    var buttonClass  = "div.button";
    var lButtonClass = "div.left_button";
    var rButtonClass = "div.right_button";
    var $defaultAllChannelTitle = $("div.channel_title");
    var bind = function(){
				$defaultAllChannelTitle.mouseenter(function(){
						var index = $("div.channel_title").index(this);
						if(index !== 0)$(this).children(lButtonClass).show();
						if(index !== channelNum-1)$(this).children(rButtonClass).show();
				});
				$defaultAllChannelTitle.mouseleave(function(){
						$(this).animate({"height": "20px"}, "fast");
						$(this).children(buttonClass).hide();
				});
				$defaultAllChannelTitle.children("div.title").click(function(){
						$(this).parent(topClass).animate({"height": "60px"}, "fast");
				});
				$defaultAllChannelTitle.children(lButtonClass).click(function(){
						var $channelTitle     = $(this).parent();
						var myIndex           = $("div.channel_title").index($channelTitle);
						var $prevChannelTitle = $("div.channel_title").eq(myIndex - 1);
						$channelTitle.parent("div.channel_bar").after($prevChannelTitle.parent("div.channel_bar"));
						swapChannel($channelTitle.parent("div.channel_bar").attr("id"), $prevChannelTitle.parent("div.channel_bar").attr("id"));
				});
				$defaultAllChannelTitle.children(rButtonClass).click(function(){
						var $channelTitle     = $(this).parent();
						var myIndex           = $("div.channel_title").index($channelTitle);
						var $nextChannelTitle = $("div.channel_title").eq(myIndex + 1);
						$channelTitle.parent("div.channel_bar").before($nextChannelTitle.parent("div.channel_bar"));
						swapChannel($channelTitle.parent("div.channel_bar").attr("id"), $nextChannelTitle.parent("div.channel_bar").attr("id"));
				});
    };
    var swapChannel = function(channelId1, channelId2){
				$.post('./json/swap_channel_order', {
						channel_id1: channelId1,
						channel_id2: channelId2
				}, function(data){}, 'json');
    }
    return {bind: bind};
}

function makeTimer($timeDescription, $timeHorizon){
    var weeks    = new Array('日','月','火','水','木','金','土');
    var timeDiff = 0;
    var timeSynchronizer = function(){
				$.getJSON("./json/time.json", function(time){
						var correctTime = new Date();
						correctTime.setTime(Date.parse(time.str));
						var now = new Date()
						timeDiff = now.getTime() - correctTime.getTime();
				});
    };
    var timeCounter = function(){
				var now = new Date();
				now.setTime(now.getTime() - timeDiff);
				$timeDescription.html(timeInspect(now));
				var horizonTop = ~~((now.getTime() - originTime.getTime())/30000) + originTop;
				$timeHorizon.css("top", horizonTop + "px");
				setTimeout(timeCounter, 200);
    };
    var timeInspect = function(time){
				var zeroPadding = function(pad, num){ return ('00000' + num).slice(-pad);};
				var d = time.getFullYear() + "年" + (time.getMonth()+1) + "月" + time.getDate() + "日(" + weeks[time.getDay()] + ")";
				var t = zeroPadding(2, time.getHours()) + ":" + zeroPadding(2, time.getMinutes()) + ":" + zeroPadding(2, time.getSeconds());
				return  d + " " + t;
    };
    var start = function(){
				setInterval(timeSynchronizer, 60*1000);
				timeCounter();
    };
    return {start: start};
}

function makeProgramTileOperator($allProgramTile){
    var reserve = function(){
				var programId = $(this).attr("id")
				$.getJSON("./json/reserve/" + programId, function(reserveResponse){
						alert(reserveResponse.message);
				});
    };
    var bind = function(){
				$allProgramTile.click(reserve);
    };
    return {bind: bind};
}

$(document).ready(function(){
		var dashBoard          = makeDashBoard($("#dash_board"));
    var programTableFixer  = makeProgramTableSizeFixer();
    var scrollSynchronizer = makeProgramTableScrollSynchronizer($("div.channel_title"));
    var programTile        = makeProgramTileOperator($("div.program_tile"));
    var channelTitleBox    = makeChannelTitleBox();
    var timer              = makeTimer($("div#time"), $("div.now_time_horizon"));
    var programSearchBox   = makeProgramSearchBox(dashBoard.operator);
		var categoryView       = makeCategoryView(dashBoard.operator);
		var logView            = makeLogView(dashBoard.operator);
		var recordedView       = makeRecordedView(dashBoard.operator);
		
		//global
		util = makeUtility();

    //bind handler
		dashBoard.bind();
    programTableFixer.bind();
    scrollSynchronizer.bind();
    channelTitleBox.bind();
    programTile.bind();
    programSearchBox.bind();
		categoryView.bind();
		logView.bind();
		recordedView.bind();

    //call init process
    timer.start();
});
