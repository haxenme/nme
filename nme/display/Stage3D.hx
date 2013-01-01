package nme.display;
#if display


extern class Stage3D extends nme.events.EventDispatcher {
	var context3D(default,null) : nme.display3D.Context3D;
	var visible : Bool;
	var x : Float;
	var y : Float;
	function requestContext3D(?context3DRenderMode : String) : Void;
}


#elseif (cpp || neko)
typedef Stage3D = native.display.Stage3D;
#elseif !js
typedef Stage3D = flash.display.Stage3D;
#end