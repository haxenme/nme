package nme.display;
#if code_completion


extern class SimpleButton extends InteractiveObject {
	var downState : DisplayObject;
	var enabled : Bool;
	var hitTestState : DisplayObject;
	var overState : DisplayObject;
	var soundTransform : nme.media.SoundTransform;
	var trackAsMenu : Bool;
	var upState : DisplayObject;
	var useHandCursor : Bool;
	function new(?upState : DisplayObject, ?overState : DisplayObject, ?downState : DisplayObject, ?hitTestState : DisplayObject) : Void;
}


#elseif (cpp || neko)
typedef SimpleButton = neash.display.SimpleButton;
#elseif js
typedef SimpleButton = jeash.display.SimpleButton;
#else
typedef SimpleButton = flash.display.SimpleButton;
#end