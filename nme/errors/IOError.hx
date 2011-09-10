package nme.errors;


#if flash
@:native ("flash.errors.IOError")
extern class IOError extends Error {
	function new(?message : String, id : Int = 0) : Void;
}
#end