package nme;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;
import ApplicationMain;
import haxe.ds.StringMap;

/**
 * ...
 * @author Joshua Granick
 */

class Assets 
{
   public static var cachedBitmapData:StringMap<BitmapData> = new StringMap<BitmapData>();

   public static function getBitmapData(id:String, useCache:Bool = false):BitmapData 
   {
      // Should be bitmapData.clone(), but stopped working in recent Jeash builds
      // Without clone, BitmapData is already cached, so ignoring the StringMap table for now
      switch(id) 
      {
         ::foreach assets::::if (type == "image")::case "::id::": return cast(ApplicationMain.loaders.get("::resourceName::").contentLoaderInfo.content, Bitmap).bitmapData;
         ::end::::end::
      }

      return null;
   }

   public static function getBytes(id:String):ByteArray 
   {
      switch(id) 
      {
         //::foreach assets::case "::id::": return ByteArray.readFile("::resourceName::");
         //::end::
      }

      return null;
   }

   public static function getFont(id:String):Font 
   {
      switch(id) 
      {
         ::foreach assets::::if (type == "font")::case "::id::": var font = cast(new NME_::flatName:: (), Font); font.fontName = "::flatName::"; return font; 
         ::end::::end::
      }

      return null;
   }

   public static function getSound(id:String):Sound 
   {
      switch(id) 
      {
         ::foreach assets::::if (type == "sound")::case "::id::": return new Sound(new URLRequest("::resourceName::"));::elseif(type == "music")::case "::id::": return new Sound(new URLRequest("::resourceName::"));
         ::end::::end::
      }

      return null;
   }

   public static function getText(id:String):String 
   {
      switch(id) 
      {
         ::foreach assets::::if (type == "asset")::case "::id::": return ApplicationMain.urlLoaders.get("::resourceName::").data;
         ::end::::end::
      }

      return null;
   }
}
