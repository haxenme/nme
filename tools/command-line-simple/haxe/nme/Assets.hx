package nme;

import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;
import haxe.ds.StringMap;

class Assets 
{
   public static var cachedBitmapData:StringMap<BitmapData> = new StringMap<BitmapData>();

   private static var initialized:Bool = false;
   private static var resourceNames:StringMap <String> = new StringMap <String> ();
   private static var resourceTypes:StringMap <String> = new StringMap <String> ();

   private static function initialize():Void 
   {
      if (!initialized) 
      {
         ::foreach assets::resourceNames.set("::id::", "::resourceName::");
         resourceTypes.set("::id::", "::type::");
         ::end::
         initialized = true;
      }
   }

   public static function getResourceName(id:String): String 
   {
      initialize();
      return resourceNames.get(id);
   }

   public static function getBitmapData(id:String, useCache:Bool = true):BitmapData 
   {
      initialize();

      if (resourceTypes.exists(id) && resourceTypes.get(id) == "image") 
      {
         if (useCache && cachedBitmapData.exists(id)) 
         {
            return cachedBitmapData.get(id);

         }
         else
         {
            var data = BitmapData.load(resourceNames.get(id));

            if (useCache) 
            {
               cachedBitmapData.set(id, data);
            }

            return data;
         }

      }
      else
      {
         trace("[nme.Assets] There is no BitmapData asset with an ID of \"" + id + "\"");

         return null;
      }
   }

   public static function getBytes(id:String):ByteArray 
   {
      initialize();

      if (resourceNames.exists(id)) 
      {
         return ByteArray.readFile(resourceNames.get(id));

      }
      else
      {
         trace("[nme.Assets] There is no String or ByteArray asset with an ID of \"" + id + "\"");

         return null;
      }
   }

   public static function getFont(id:String):Font 
   {
      initialize();

      if (resourceTypes.exists(id) && resourceTypes.get(id) == "font") 
      {
         return new Font(resourceNames.get(id));

      }
      else
      {
         trace("[nme.Assets] There is no Font asset with an ID of \"" + id + "\"");

         return null;
      }
   }

   public static function getSound(id:String):Sound 
   {
      initialize();

      if (resourceTypes.exists(id)) 
      {
         if (resourceTypes.get(id) == "sound") 
         {
            return new Sound(new URLRequest(resourceNames.get(id)), null, false);

         } else if (resourceTypes.get(id) == "music") 
         {
            return new Sound(new URLRequest(resourceNames.get(id)), null, true);
         }
      }

      trace("[nme.Assets] There is no Sound asset with an ID of \"" + id + "\"");

      return null;
   }

   public static function getText(id:String):String 
   {
      var bytes = getBytes(id);

      if (bytes == null) 
      {
         return null;

      }
      else
      {
         return bytes.readUTFBytes(bytes.length);
      }
   }
}
