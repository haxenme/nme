#if flash


package nme.display;


@:native ("flash.display.NativeMenu")
@:require(flash10_1) extern class NativeMenu extends nme.events.EventDispatcher {
	function new() : Void;
}



#end