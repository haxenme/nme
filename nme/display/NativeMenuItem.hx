#if flash


package nme.display;


@:native ("flash.display.NativeMenuItem")
@:require(flash10_1) extern class NativeMenuItem extends nme.events.EventDispatcher {
	var enabled : Bool;
	function new() : Void;
}


#end