package nme.display;


#if flash
@:native ("flash.display.ShaderData")
extern class ShaderData implements Dynamic {
	function new(byteCode : nme.utils.ByteArray) : Void;
}
#end