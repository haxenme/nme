package nme.gl;
#if display


extern class GLProgram extends GLObject {
	
	function new(inVersion:Int, inId:Dynamic):Void;
	function attach(s:GLShader):Void;
	function getShaders():Array<GLShader>;
	
}


#elseif (cpp || neko)
typedef GLProgram = native.gl.GLProgram;
#elseif js
typedef GLProgram = browser.gl.GLProgram;
#end