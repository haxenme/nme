package nme.gl;
#if display


extern class GLShader extends GLObject {
	
	function new(inVersion:Int, inId:Dynamic):Void;
	
}


#elseif (cpp || neko)
typedef GLShader = native.gl.GLShader;
#elseif js
typedef GLShader = browser.gl.GLShader;
#end