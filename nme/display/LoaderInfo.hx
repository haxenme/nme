package nme.display;
#if code_completion


extern class LoaderInfo extends nme.events.EventDispatcher {
	//var actionScriptVersion(default,null) : ActionScriptVersion;
	//var applicationDomain(default,null) : nme.system.ApplicationDomain;
	var bytes(default,null) : nme.utils.ByteArray;
	var bytesLoaded(default,null) : Int;
	var bytesTotal(default,null) : Int;
	var childAllowsParent(default,null) : Bool;
	var content(default,null) : DisplayObject;
	var contentType(default,null) : String;
	var frameRate(default,null) : Float;
	var height(default,null) : Int;
	@:require(flash10_1) var isURLInaccessible(default,null) : Bool;
	var loader(default,null) : Loader;
	var loaderURL(default,null) : String;
	var parameters(default,null) : Dynamic<String>;
	var parentAllowsChild(default,null) : Bool;
	var sameDomain(default,null) : Bool;
	var sharedEvents(default,null) : nme.events.EventDispatcher;
	var swfVersion(default,null) : Int;
	//@:require(flash10_1) var uncaughtErrorEvents(default,null) : nme.events.UncaughtErrorEvents;
	var url(default,null) : String;
	var width(default,null) : Int;
	static function getLoaderInfoByDefinition(object : Dynamic) : LoaderInfo;
}


#elseif (cpp || neko)
typedef LoaderInfo = neash.display.LoaderInfo;
#elseif js
typedef LoaderInfo = jeash.display.LoaderInfo;
#else
typedef LoaderInfo = flash.display.LoaderInfo;
#end