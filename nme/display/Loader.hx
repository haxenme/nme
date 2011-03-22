package nme.display;

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
* @todo init, open, progress, unload (?) events
* @todo Complete LoaderInfo initialization
**/
class Loader extends nme.display.Sprite
{
   public var content(default,null) : DisplayObject;
   public var contentLoaderInfo(default,null) : LoaderInfo;
   var nmeImage:BitmapData;
   var nmeSWF:MovieClip;
   public var url(default,null):String;

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

   function onData(_)
   {
      try
      {
         nmeImage = BitmapData.loadFromBytes(contentLoaderInfo.bytes);
         var bmp = new Bitmap(nmeImage);
         content = bmp;
         contentLoaderInfo.content = bmp;
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

