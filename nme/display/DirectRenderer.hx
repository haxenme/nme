package nme.display;
#if display


import nme.geom.Rectangle;


extern class DirectRenderer extends DisplayObject {

	function new (inType:String = "DirectRenderer"):Void;
	dynamic function render (inRect:Rectangle):Void;
	
}


#elseif (cpp || neko)
typedef DirectRenderer = native.display.DirectRenderer;
#end