package nme.display;
#if code_completion


extern class Loader extends DisplayObjectContainer {
	var content(default,null) : DisplayObject;
	var contentLoaderInfo(default,null) : LoaderInfo;
	//@:require(flash10_1) var uncaughtErrorEvents(default,null) : nme.events.UncaughtErrorEvents;
	function new() : Void;
	function close() : Void;
	function load(request : nme.net.URLRequest) : Void;
	function loadBytes(bytes : nme.utils.ByteArray) : Void;
	/*function load(request : nme.net.URLRequest, ?context : nme.system.LoaderContext) : Void;
	function loadBytes(bytes : nme.utils.ByteArray, ?context : nme.system.LoaderContext) : Void;*/
	function unload() : Void;
	@:require(flash10) function unloadAndStop(gc : Bool = true) : Void;
}


#elseif (cpp || neko)
typedef Loader = neash.display.Loader;
#elseif js
typedef Loader = jeash.display.Loader;
#else
typedef Loader = flash.display.Loader;
#end