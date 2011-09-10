#if flash


package nme.text;


@:native ("flash.text.TextLineMetrics")
extern class TextLineMetrics {
	var ascent : Float;
	var descent : Float;
	var height : Float;
	var leading : Float;
	var width : Float;
	var x : Float;
	function new(x : Float, width : Float, height : Float, ascent : Float, descent : Float, leading : Float) : Void;
}


#end