package nme.display;


#if flash
@:native ("flash.display.Loader")
extern class Loader extends DisplayObjectContainer {
	var content(default,null) : DisplayObject;
	var contentLoaderInfo(default,null) : LoaderInfo;
	@:require(flash10_1) var uncaughtErrorEvents(default,null) : nme.events.UncaughtErrorEvents;
	function new() : Void;
	function close() : Void;
	function load(request : nme.net.URLRequest, ?context : nme.system.LoaderContext) : Void;
	function loadBytes(bytes : nme.utils.ByteArray, ?context : nme.system.LoaderContext) : Void;
	function unload() : Void;
	@:require(flash10) function unloadAndStop(gc : Bool = true) : Void;
}
#else



import nme.net.URLRequest;
import nme.display.DisplayObject;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.LoaderInfo;
import nme.display.Shape;
import nme.events.Event;
import nme.events.IOErrorEvent;

/**
* @author   Hugh Sanderson
* @author   Niel Drummond
* @author   Russell Weir
* @author   Joshua Harlan Lifton
* @todo init, open, progress events
* @todo Complete LoaderInfo initialization
* @todo Cancel previous load request if new load request is made before completion.
**/
class Loader extends nme.display.Sprite
{
   public var content(default,null) : DisplayObject;
   public var contentLoaderInfo(default,null) : LoaderInfo;
   var nmeImage:BitmapData;
   var nmeSWF:MovieClip;

   public function new()
   {
      super();
      contentLoaderInfo = LoaderInfo.create(this);
      // Make sure we get in first...
      contentLoaderInfo.addEventListener(nme.events.Event.COMPLETE,onData);
   }

   // No "loader context" in nme
   public function load(request:URLRequest)
   {
      contentLoaderInfo.load(request);
   }

   public function unload()
   {
      if (numChildren > 0) 
      {
         while (numChildren > 0)
         {
            removeChildAt(0);
         }
         untyped
         {
            contentLoaderInfo.url = null;
            contentLoaderInfo.contentType = null;
            contentLoaderInfo.content = null;
            contentLoaderInfo.bytesLoaded = contentLoaderInfo.bytesTotal = 0;
            contentLoaderInfo.width = 0;
            contentLoaderInfo.height = 0;
         }
         dispatchEvent(new Event(Event.UNLOAD));
      }
   }

   function onData(_)
   {
      try
      {
         nmeImage = BitmapData.loadFromBytes(contentLoaderInfo.bytes);
         var bmp = new Bitmap(nmeImage);
         content = bmp;
         contentLoaderInfo.content = bmp;
         while (numChildren > 0)
         {
            removeChildAt(0);
         }
         addChild(bmp);
      }
      catch(e:Dynamic)
      {
         //trace("Error " + e);
         contentLoaderInfo.DispatchIOErrorEvent();
         return;
      }
   }

}
#end