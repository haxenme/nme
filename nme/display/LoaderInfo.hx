package nme.display;

import nme.events.EventDispatcher;

/**
* @author	Niel Drummond
* @author	Russell Weir
* @todo init, open, progress, unload (?) events
**/
class LoaderInfo extends EventDispatcher {

	public var bytes(default,null) : nme.utils.ByteArray;
	public var bytesLoaded(default,null) : Int;
	public var bytesTotal(default,null) : Int;
	public var childAllowsParent(default,null) : Bool;
	public var content(default,null) : DisplayObject;
	public var contentType(default,null) : String;
	public var frameRate(default,null) : Float;
	public var height(default,null) : Int;
	public var loader(default,null) : Loader;
	public var loaderURL(default,null) : String;
	public var parameters(default,null) : Dynamic<String>;
	public var parentAllowsChild(default,null) : Bool;
	public var sameDomain(default,null) : Bool;
	public var sharedEvents(default,null) : nme.events.EventDispatcher;
	public var url(default,null) : String;
	public var width(default,null) : Int;
	//static function getLoaderInfoByDefinition(object : Dynamic) : flash.display.LoaderInfo;

	private function new() {
		super();
		bytesLoaded = 0;
		bytesTotal = 0;
		childAllowsParent = true;

	}

	public static function create(ldr : Loader) {
		var li = new LoaderInfo();
		li.loader = ldr;

		return li;
	}
}
