package nme.display;


#if flash
@:native ("flash.display.Shader")
@:require(flash10) extern class Shader {
	var byteCode(null,default) : nme.utils.ByteArray;
	var data : ShaderData;
	var precisionHint : ShaderPrecision;
	function new(?code : nme.utils.ByteArray) : Void;
}
#end