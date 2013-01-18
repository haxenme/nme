package nme.display;
#if display


extern class OpenGLView extends DirectRenderer {
	
	static inline var CONTEXT_LOST = "glcontextlost";
	static inline var CONTEXT_RESTORED = "glcontextrestored";
	
	static var isSupported(get_isSupported, null):Bool;
	
	function new():Void;
	
}


#elseif (cpp || neko)
typedef OpenGLView = native.display.OpenGLView;
#elseif js
typedef OpenGLView = browser.display.OpenGLView;
#end