package nme.gl;
#if display


extern class GLTexture extends GLObject {
	
	function new(inVersion:Int, inId:Dynamic):Void;
	
}


#elseif (cpp || neko)
typedef GLTexture = native.gl.GLTexture;
#elseif js
typedef GLTexture = browser.gl.GLTexture;
#end