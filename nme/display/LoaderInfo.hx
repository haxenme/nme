package nme.display;
#if (cpp || neko)


import nme.events.Event;
import nme.events.EventDispatcher;
import nme.net.URLLoader;
import nme.net.URLRequest;
import nme.net.URLLoaderDataFormat;


/**
* @author	Niel Drummond
* @author	Russell Weir
* @author       Joshua Harlan Lifton
* @todo init, open, progress, unload (?) events
**/
class LoaderInfo extends URLLoader {

	public var bytes(getBytes,null) : nme.utils.ByteArray;
	public var childAllowsParent(default,null) : Bool;
	public var content : DisplayObject;
	public var contentType : String;
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
	//static function getLoaderInfoByDefinition(object : Dynamic) : nme.display.LoaderInfo;

  private var pendingURL:String;

  private function new() {
    super();
    childAllowsParent = true;
    frameRate = 0;
    dataFormat = URLLoaderDataFormat.BINARY;
    loaderURL = null; // XXX : Don't know how to find the URL of the SWF file that initiated the loading.
    // Set the url attribute before any other callbacks are made.
    addEventListener(nme.events.Event.COMPLETE, onURLLoaded);
  }

   override public function load(request:URLRequest)
   {
      // get the file extension for the content type
      pendingURL = request.url;
      var dot = pendingURL.lastIndexOf(".");
      var extension = dot>0 ? pendingURL.substr(dot+1).toLowerCase() : "";
      contentType = switch(extension)
      {
         case "swf": "application/x-shockwave-flash";
         case "jpg","jpeg": "image/jpeg";
         case "png": "image/png";
         case "gif": "image/gif";
         default:
            throw "Unrecognized file " + pendingURL;
      }
      url = null;
      super.load(request);
   }

  private function onURLLoaded(event:Event){
    url = pendingURL;
  }

   function getBytes() : nme.utils.ByteArray { return data; }

	public static function create(ldr : Loader) {
  		var li = new LoaderInfo();
		li.loader = ldr;
		return li;
	}
}


#else
typedef LoaderInfo = flash.display.LoaderInfo;
#end