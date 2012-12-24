package nme.display;
#if display


extern class OpenGLView extends DirectRenderer {
	
	static inline var CONTEXT_LOST = "glcontextlost";
	static inline var CONTEXT_RESTORED = "glcontextrestored";
	
	function new ():Void;
	
}


#elseif (cpp || neko)
typedef OpenGLView = native.display.OpenGLView;
#end