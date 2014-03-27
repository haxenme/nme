package nme;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;
import nme.utils.WeakRef;

import nme.AssetInfo;


/**
 * <p>The Assets class provides a cross-platform interface to access 
 * embedded images, fonts, sounds and other resource files.</p>
 * 
 * <p>The contents are populated automatically when an application
 * is compiled using the NME command-line tools, based on the
 * contents of the *.nmml project file.</p>
 * 
 * <p>For most platforms, the assets are included in the same directory
 * or package as the application, and the paths are handled
 * automatically. For web content, the assets are preloaded before
 * the start of the rest of the application. You can customize the 
 * preloader by extending the <code>NMEPreloader</code> class,
 * and specifying a custom preloader using <window preloader="" />
 * in the project file.</p>
 */

class Assets 
{
   public static inline var UNCACHED = 0;
   public static inline var WEAK_CACHE = 1;
   public static inline var STRONG_CACHE = 2;

   public static var info = new Map<String,AssetInfo>();
   public static var cacheMode:Int = WEAK_CACHE;

   //public static var id(get_id, null):Array<String>;

   public static function getAssetPath(inName:String) : String
   {
      var i = getInfo(inName);
      return i==null ? null : i.path;
   }

   static function getResource(inName:String) : ByteArray
   {
      var bytes = haxe.Resource.getBytes(inName);
      if (bytes==null)
      {
         trace("[nme.Assets] missing binary resource '" + inName + "'");
         for(key in info.keys())
            trace(" " + key + " -> " + info.get(key).path + " " + info.get(key).isResource );
         trace("---");
      }
      if (bytes==null)
         return null;
      #if flash
      return bytes.getData();
      #else
      return ByteArray.fromBytes(bytes);
      #end
   }


   public static function trySetCache(info:AssetInfo, useCache:Null<Bool>, data:Dynamic)
   {
      if (useCache!=false && (useCache==true || cacheMode!=UNCACHED))
         info.setCache(data, cacheMode!=STRONG_CACHE);
   }

   public static function noId(id:String, type:String)
   {
      trace("[nme.Assets] missing asset '" + id + "' of type " + type);
      for(key in info.keys())
         trace(" " + key + " -> " + info.get(key).path );
      trace("---");
   }

   public static function badType(id:String, type:String)
   {
      var i = getInfo(id);
      trace("[nme.Assets] asset '" + id + "' is not of type " + type + " it is " + i.type);
   }

   public static function hasBitmapData(id:String):Bool 
   {
      var i = getInfo(id);

      return i!=null && i.type==IMAGE;
   }

   public static function getInfo(inName:String)
   {
      var result = info.get(inName);
      if (result!=null)
         return result;
      var parts = inName.split("/");
      var first = 0;
      while(first<parts.length)
      {
         if (parts[first]=="..")
            first++;
         else
         {
            var changed = false;
            var test = first+1;
            while(test<parts.length)
            {
               if (parts[test]==".." && parts[test-1]!="..")
               {
                  parts.splice(test-1,2);
                  changed = true;
                  break;
               }
               test++;
            }
            if (!changed)
               break;
         }
      }
      var path = parts.join("/");
      if (path!=inName)
      {
         result = info.get(path);
      }
      return result;
   }

   static function makeBitmapData(inClassName:String): BitmapData
   {
      var cls:Class<Dynamic> = Type.resolveClass(inClassName);
      if (cls==null)
        throw("Invalid class : " + inClassName);
      return Type.createInstance(cls, []);
   }

   /**
    * Gets an instance of an embedded bitmap
    * @usage      var bitmap = new Bitmap(Assets.getBitmapData("image.jpg"));
    * @param   id      The ID or asset path for the bitmap
    * @param   useCache      (Optional) Whether to use BitmapData from the cache(Default: according to setting)
    * @return      A new BItmapData object
    */
   public static function getBitmapData(id:String, ?useCache:Null<Bool>):BitmapData 
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"BitmapData");
         return null;
      }
      if (i.type!=IMAGE)
      {
         badType(id,"BitmapData");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }
 
      var data =
         #if flash
         makeBitmapData(i.className)
         #elseif js
         cast(ApplicationMain.loaders.get(i.path).contentLoaderInfo.content, Bitmap).bitmapData
         #else
         i.isResource ? BitmapData.loadFromBytes( getResource(i.path) ) :  BitmapData.load(i.path)
         #end
      ;
      trySetCache(i,useCache,data);
      return data;
   }

   public static function hasBytes(id:String):Bool
   {
      var i = getInfo(id);
      return i!=null;
   }


   /**
    * Gets an instance of an embedded binary asset
    * @usage      var bytes = Assets.getBytes("file.zip");
    * @param   id      The ID or asset path for the file
    * @return      A new ByteArray object
    */
   public static function getBytes(id:String,?useCache:Null<Bool>):ByteArray 
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"Bytes");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }

      var data:ByteArray = null;
      if (i.isResource)
      {
         data = getResource(i.path);
      }
      else
      {
         #if flash
         data = Type.createInstance(Type.resolveClass(i.className), []);
         #elseif js
         var asset:Dynamic = ApplicationMain.urlLoaders.get(i.path).data;
         data:ByteArray = null;
         if (Std.is(asset, String)) 
         {
            bytes = new ByteArray();
            bytes.writeUTFBytes(asset);
         }
         else if (!Std.is(data, ByteArray)) 
         {
            badType(is,"Bytes");
            return null;
         }
         #else
         data = ByteArray.readFile(i.path);
         #end
      }

      if (data != null) 
         data.position = 0;

      trySetCache(i,useCache,data);

      return data;
   }

   public static function hasFont(id:String):Bool 
   {
      var i = getInfo(id);

      return i!=null && i.type == FONT;
   }
   /**
    * Gets an instance of an embedded font
    * @usage      var fontName = Assets.getFont("font.ttf").fontName;
    * @param   id      The ID or asset path for the font
    * @return      A new Font object
    */
   public static function getFont(id:String,?useCache:Null<Bool>):Font 
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"Font");
         return null;
      }
      if (i.type!=FONT)
      {
         badType(id,"Font");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }

      var font = 
         #if (flash || js)
         cast(Type.createInstance(Type.resolveClass(i.className),[]), Font)
         #else
         new Font(i.path)
         #end
      ;

      trySetCache(i,useCache,font);

      return font;
   }

   public static function hasSound(id:String):Bool 
   {
      var i = getInfo(id);

      return i!=null && (i.type == SOUND || i.type==MUSIC);
   }
 

   /**
    * Gets an instance of an embedded sound
    * @usage      var sound = Assets.getSound("sound.wav");
    * @param   id      The ID or asset path for the sound
    * @return      A new Sound object
    */
   public static function getSound(id:String,?useCache:Null<Bool>):Sound 
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"Sound");
         return null;
      }
      if (i.type!=SOUND && i.type!=MUSIC)
      {
         badType(id,"Sound");
         return null;
      }
      if (useCache!=false)
      {
         var val = i.getCache();
         if (val!=null)
            return val;
      }

      var sound =
            #if flash
            cast(Type.createInstance(Type.resolveClass(i.className), []), Sound)
            #elseif js
            new Sound(new URLRequest(i.path))
            #else
            new Sound(new URLRequest(i.path), null, i.type == MUSIC)
            #end
      ;

      trySetCache(i,useCache,sound);

      return sound;
   }

   public static function getMusic(id:String,?useCache:Null<Bool>):Sound 
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"Music");
         return null;
      }
      if (i.type!=MUSIC)
      {
         badType(id,"Music");
         return null;
      }
      return getSound(id,useCache);
   }


   public static function hasText(id:String) { return hasBytes(id); }
   public static function hasString(id:String) {
     return hasBytes(id);
   }

   /**
    * Gets an instance of an embedded text asset
    * @usage      var text = Assets.getText("text.txt");
    * @param   id      The ID or asset path for the file
    * @return      A new String object
    */
   public static function getText(id:String,?useCache:Null<Bool>):String 
   {
      var i = getInfo(id);
      if (i==null)
      {
         noId(id,"String");
         return null;
      }

      if (i.isResource)
         return haxe.Resource.getString(i.path);

      var bytes = getBytes(id,useCache);

      if (bytes == null) 
         return null;

      var result = bytes.readUTFBytes(bytes.length);
      //trace(result);
      return result;
   }
   public static function getString(id:String,?useCache:Null<Bool>):String 
   {
       return getText(id,useCache);
   }

   private static var initResources:Dynamic = (function() {
       var nme_set_resource_factory = nme.Loader.load("nme_set_resource_factory", 1);
       nme_set_resource_factory(function(s) return
         ByteArray.fromBytes(haxe.Resource.getBytes(s)) ); return null; } ) ();

}


