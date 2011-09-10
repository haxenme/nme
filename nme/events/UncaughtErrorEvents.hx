#if flash


package nme.events;


@:native ("flash.events.UncaughtErrorEvents")
@:require(flash10_1) extern class UncaughtErrorEvents extends EventDispatcher {
	function new() : Void;
}


#end