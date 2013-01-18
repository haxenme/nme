package nme.gl;
#if display


extern class GLFramebuffer extends GLObject {
	
	function new(inVersion:Int, inId:Dynamic):Void;
	
}


#elseif (cpp || neko)
typedef GLFramebuffer = native.gl.GLFramebuffer;
#elseif js
typedef GLFramebuffer = browser.gl.GLFramebuffer;
#end