package nme.display;
#if display


@:final extern class GraphicsBitmapFill implements IGraphicsData, implements IGraphicsFill {
	var bitmapData : BitmapData;
	var matrix : nme.geom.Matrix;
	var repeat : Bool;
	var smooth : Bool;
	function new(?bitmapData : BitmapData, ?matrix : nme.geom.Matrix, repeat : Bool = true, smooth : Bool = false) : Void;
}


#elseif (cpp || neko)
typedef GraphicsBitmapFill = native.display.GraphicsBitmapFill;
#elseif js
typedef GraphicsBitmapFill = browser.display.GraphicsBitmapFill;
#else
typedef GraphicsBitmapFill = flash.display.GraphicsBitmapFill;
#end
