package nme.net;


#if flash
@:native ("flash.net.Responder")
extern class Responder {
	function new(result : Dynamic, ?status : Dynamic) : Void;
}
#end