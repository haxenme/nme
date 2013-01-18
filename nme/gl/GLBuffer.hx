package nme.gl;
#if display


extern class GLBuffer extends GLObject {
	
	function new(inVersion:Int, inId:Dynamic):Void;
	
}


#elseif (cpp || neko)
typedef GLBuffer = native.gl.GLBuffer;
#elseif js
typedef GLBuffer = browser.gl.GLBuffer;
#end