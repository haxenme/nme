package nme.display;
#if code_completion


extern class GraphicsEndFill implements IGraphicsData, implements IGraphicsFill {
	function new() : Void;
}


#elseif (cpp || neko)
typedef GraphicsEndFill = neash.display.GraphicsEndFill;
#elseif js
typedef GraphicsEndFill = jeash.display.GraphicsEndFill;
#else
typedef GraphicsEndFill = flash.display.GraphicsEndFill;
#end