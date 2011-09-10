#if flash


package nme.display;

@:native ("flash.display.ShaderData")
extern class ShaderData implements Dynamic {
	function new(byteCode : nme.utils.ByteArray) : Void;
}


#end