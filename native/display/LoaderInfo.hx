package native.display;
#if (cpp || neko)

import native.events.Event;
import native.events.EventDispatcher;
import native.net.URLLoader;
import native.net.URLRequest;
import native.net.URLLoaderDataFormat;
import native.utils.ByteArray;

class LoaderInfo extends URLLoader 
{
   public var bytes(get_bytes, null):ByteArray;
   public var childAllowsParent(default, null):Bool;
   public var content:DisplayObject;
   public var contentType:String;
   public var frameRate(default, null):Float;
   public var height(default, null):Int;
   public var loader(default, null):Loader;
   public var loaderURL(default, null):String;
   public var parameters(default, null):Dynamic <String>;
   public var parentAllowsChild(default, null):Bool;
   public var sameDomain(default, null):Bool;
   public var sharedEvents(default, null):EventDispatcher;
   public var url(default, null):String;
   public var width(default, null):Int;
   //static function getLoaderInfoByDefinition(object : Dynamic) : nme.display.LoaderInfo;
   private var pendingURL:String;

   private function new() 
   {
      super();

      childAllowsParent = true;
      frameRate = 0;
      dataFormat = URLLoaderDataFormat.BINARY;
      loaderURL = null; // XXX : Don't know how to find the URL of the SWF file that initiated the loading.
      // Set the url attribute before any other callbacks are made.
      addEventListener(Event.COMPLETE, onURLLoaded);
   }

   public static function create(ldr:Loader) 
   {
      var li = new LoaderInfo();
      li.loader = ldr;
	  
	  if (ldr == null) {
		  
		  li.url = "";
		  
	  }

      return li;
   }

   public override function load(request:URLRequest) 
   {
      // get the file extension for the content type
      pendingURL = request.url;
      var dot = pendingURL.lastIndexOf(".");
      var extension = dot > 0 ? pendingURL.substr(dot + 1).toLowerCase() : "";

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

   // Event Handlers
   private function onURLLoaded(event:Event) 
   {
      url = pendingURL;
   }

   // Getters & Setters
   private function get_bytes():ByteArray 
   {
      return data;
   }
}

#end