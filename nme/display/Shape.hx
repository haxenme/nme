package nme.display;
#if code_completion


extern class Shape extends DisplayObject {
	var graphics(default,null) : Graphics;
	function new() : Void;
}


#elseif (cpp || neko)
typedef Shape = neash.display.Shape;
#elseif js
typedef Shape = jeash.display.Shape;
#else
typedef Shape = flash.display.Shape;
#end