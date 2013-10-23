function makeTest(){
		var d = function(name, func){
				var $newDiv = $("<div/>").attr("class", name);
				if(func)func(function(name, func){
						$newDiv.append(d(name, func));
				}, $newDiv);
				return $newDiv
		};
		return {d: d};
}

$(document).ready(function(){
		var test = makeTest();

		$newDiv = test.d("first", function(d){
				d("second-1", function(d){

				});
				d("second-2", function(d){
						d("third");
				});
		});
		$(".test").append($newDiv);

});
