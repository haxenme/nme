package nme;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.MovieClip;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;
import nme.utils.WeakRef;

class AssetLib
{
   public var eventCallback:Dynamic;

   public function new () { }
   
   public function exists(id:String, type:AssetType):Bool return false;
   public function getBitmapData(id:String):BitmapData return null;
   public function getBytes(id:String):ByteArray return null;
   public function getFont(id:String):Font return null;
   public function getMovieClip(id:String):MovieClip return null;
   public function getMusic(id:String):Sound return null;
   public function getPath(id:String):String return null;
   public function getSound(id:String):Sound return null;
   public function getText(id:String):String
   {
      var bytes = getBytes(id);
      if (bytes == null)
         return null;

      return bytes.readUTFBytes (bytes.length);
   }
   public function isLocal (id:String, type:AssetType):Bool return true;
   public function list(type:AssetType):Array<String> return null;
   public function load(handler:AssetLib -> Void):Void
      handler(this);

   public function loadBitmapData(id:String, handler:BitmapData -> Void):Void
      handler(getBitmapData(id));

   public function loadBytes(id:String, handler:ByteArray -> Void):Void
      handler(getBytes(id));

   public function loadFont (id:String, handler:Font -> Void):Void
      handler(getFont(id));

   public function loadMovieClip(id:String, handler:MovieClip -> Void):Void
      handler(getMovieClip(id));
   
   public function loadMusic(id:String, handler:Sound -> Void):Void
      handler(getMusic(id));
   
   public function loadSound (id:String, handler:Sound -> Void):Void
      handler(getSound (id));
   
   public function loadText(id:String, handler:String -> Void):Void
   {
      loadBytes(id, function (bytes:ByteArray):Void {
         if (bytes == null)
            handler(null);
         else
            handler(bytes.readUTFBytes(bytes.length));
      } );
   }
   public function unload():Void { }
}




