package nme.display;
#if code_completion


@:final extern class GraphicsPath implements IGraphicsData/*, implements IGraphicsPath*/ {
	var commands : nme.Vector<Int>;
	var data : nme.Vector<Float>;
	var winding : GraphicsPathWinding;
	function new(?commands : nme.Vector<Int>, ?data : nme.Vector<Float>, ?winding : GraphicsPathWinding) : Void;
	@:require(flash11) function cubicCurveTo(controlX1 : Float, controlY1 : Float, controlX2 : Float, controlY2 : Float, anchorX : Float, anchorY : Float) : Void;
	function curveTo(controlX : Float, controlY : Float, anchorX : Float, anchorY : Float) : Void;
	function lineTo(x : Float, y : Float) : Void;
	function moveTo(x : Float, y : Float) : Void;
	function wideLineTo(x : Float, y : Float) : Void;
	function wideMoveTo(x : Float, y : Float) : Void;
}


#elseif (cpp || neko)
typedef GraphicsPath = neash.display.GraphicsPath;
#elseif js
typedef GraphicsPath = jeash.display.GraphicsPath;
#else
typedef GraphicsPath = flash.display.GraphicsPath;
#end