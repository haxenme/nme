package nme.gl;
#if display


extern class GLObject {
	
	var id(default, null):Dynamic;
	var invalidated(get_invalidated, null):Bool;
	var valid(get_valid, null):Bool;
	
	function new(inVersion:Int, inId:Dynamic):Void;
	function getType():String;
	function invalidate():Void;
	function toString():String;
	function isValid():Bool;
	function isInvalid():Bool;
	
}


#elseif (cpp || neko)
typedef GLObject = native.gl.GLObject;
#elseif js
typedef GLObject = browser.gl.GLObject;
#end