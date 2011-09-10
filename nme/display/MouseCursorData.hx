package nme.display;


#if flash
@:native ("flash.display.MouseCursorData")
@:final @:require(flash10_2) extern class MouseCursorData {
	var data : nme.Vector<BitmapData>;
	var frameRate : Float;
	var hotSpot : nme.geom.Point;
	var name : String;
	function new(name : String) : Void;
}
#end