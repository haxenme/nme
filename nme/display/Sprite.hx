package nme.display;
#if code_completion


extern class Sprite extends DisplayObjectContainer {
	var buttonMode : Bool;
	var dropTarget(default,null) : DisplayObject;
	var graphics(default,null) : Graphics;
	var hitArea : Sprite;
	var soundTransform : nme.media.SoundTransform;
	var useHandCursor : Bool;
	function new() : Void;
	function startDrag(lockCenter : Bool = false, ?bounds : nme.geom.Rectangle) : Void;
	@:require(flash10_1) function startTouchDrag(touchPointID : Int, lockCenter : Bool = false, ?bounds : nme.geom.Rectangle) : Void;
	function stopDrag() : Void;
	@:require(flash10_1) function stopTouchDrag(touchPointID : Int) : Void;
}


#elseif (cpp || neko)
typedef Sprite = neash.display.Sprite;
#elseif js
typedef Sprite = jeash.display.Sprite;
#else
typedef Sprite = flash.display.Sprite;
#end