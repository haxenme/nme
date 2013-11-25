package nme.display;
#if (cpp || neko)

import nme.net.URLRequest;
import nme.display.DisplayObject;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.LoaderInfo;
import nme.display.Shape;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.IOErrorEvent;
import nme.system.LoaderContext;
import nme.utils.ByteArray;

class Loader extends Sprite 
{
   public var content(default, null):DisplayObject;
   public var contentLoaderInfo(default, null):LoaderInfo;

   /** @private */ private var nmeImage:BitmapData;
   #if swf
   /** @private */ //private var nmeSWF:format.SWF;
   #end
   public function new() 
   {
      super();

      contentLoaderInfo = LoaderInfo.create(this);
      // Make sure we get in first...
      contentLoaderInfo.nmeOnComplete = doLoad;
   }

   private function doLoad(inBytes:ByteArray) 
   {
      if (inBytes == null)
         return false;
      
      try 
      {
         nmeImage = BitmapData.loadFromBytes(inBytes);
         var bmp = new Bitmap(nmeImage);
         content = bmp;
         contentLoaderInfo.content = bmp;

         while(numChildren > 0) 
         {
            removeChildAt(0);
         }

         addChild(bmp);
         return true;

      } catch(e:Dynamic) 
      {
         //trace("Error " + e);
         return false;
      }
   }

   public function load(request:URLRequest, context:LoaderContext = null) 
   {
      // No "loader context" in nme
      contentLoaderInfo.load(request);
   }

   public function loadBytes(bytes:ByteArray, context:LoaderContext = null) 
   {
      // No "loader context" in nme
      if (doLoad(bytes)) {
		 var event = new Event(Event.COMPLETE);
		 event.currentTarget = this;
         contentLoaderInfo.dispatchEvent(event);
      } else {
         contentLoaderInfo.DispatchIOErrorEvent();
	  }
   }

   public function unload() 
   {
      if (numChildren > 0) 
      {
         while(numChildren > 0) 
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
         var event = new Event(Event.UNLOAD);
		 event.currentTarget = this;
         dispatchEvent(event);
      }
   }

   // Event Handlers
   private function onData(event:Event) 
   {
      event.stopImmediatePropagation();
      doLoad(contentLoaderInfo.bytes);
   }
}

#else
typedef Loader = flash.display.Loader;
#end
