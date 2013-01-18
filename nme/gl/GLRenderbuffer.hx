package nme.gl;
#if display


extern class GLRenderbuffer extends GLObject {
	
	function new(inVersion:Int, inId:Dynamic):Void;
	
}


#elseif (cpp || neko)
typedef GLRenderbuffer = native.gl.GLRenderbuffer;
#elseif js
typedef GLRenderbuffer = browser.gl.GLRenderbuffer;
#end