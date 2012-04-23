package nme.display;
#if code_completion


@:final extern class GraphicsSolidFill implements IGraphicsData/*, implements IGraphicsFill*/ {
	var alpha : Float;
	var color : UInt;
	function new(color : UInt = 0, alpha : Float = 1) : Void;
}


#elseif (cpp || neko)
typedef GraphicsSolidFill = neash.display.GraphicsSolidFill;
#elseif js
typedef GraphicsSolidFill = jeash.display.GraphicsSolidFill;
#else
typedef GraphicsSolidFill = flash.display.GraphicsSolidFill;
#end