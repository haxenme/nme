package nme.display;


#if flash
@:native ("flash.display.NativeMenuItem")
@:require(flash10_1) extern class NativeMenuItem extends nme.events.EventDispatcher {
	var enabled : Bool;
	function new() : Void;
}
#end