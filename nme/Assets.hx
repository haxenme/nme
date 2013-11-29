package nme;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;
import nme.utils.WeakRef;

import nme.AssetData;


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

   public static var id(get_id, null):Array<String>;
   public static var path(get_path, null): Map<String,String>;
   public static var type(get_type, null): Map<String,AssetType>;
   public static var cacheMode:Int = WEAK_CACHE;

   private static var initialized = false;
   private static var cache:Map<String, WeakRef<Dynamic> >;

   private static function initialize():Void 
   {
      if (!initialized) 
      {
         AssetData.initialize();
         initialized = true;
         cache = new Map<String, WeakRef<Dynamic> >();
      }
   }

   public static function getAssetPath(inName:String) : String
   {
      var map = path;
      return map.get(inName);
   }

   static function getReso(inName:String) : ByteArray
   {
      var bytes = haxe.Resource.getBytes(inName);
      if (bytes==null)
         return null;
      #if flash
      return bytes.getData();
      #else
      return ByteArray.fromBytes(bytes);
      #end
   }

   public static function hasBitmapData(id:String):Bool 
   {
      initialize();

      return (AssetData.type.exists(id) && AssetData.type.get(id) == IMAGE);
   }

   public static function getCache(id:String,?inForce:Null<Bool>):Dynamic
   {
      if (inForce==false)
         return null;

      var ref:WeakRef<Dynamic> = cache.get(id);
      if (ref==null)
         return null;
      var value = ref.get();
      if (value==null)
         cache.remove(id);
      return value;
   }
 
   public static function setCache<T>(id:String,value:T,?inForce:Null<Bool>):T
   {
      if (inForce==false)
         return value;

      if (inForce==true || cacheMode!=UNCACHED)
      {
         cache.set(id, new WeakRef<Dynamic>(value, cacheMode==WEAK_CACHE) );
      }

      return value;
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
      if (hasBitmapData(id))
      {
         var cached = getCache(id,useCache);
         if (cached!=null)
            return cached;
         #if flash
         var data = cast(Type.createInstance(AssetData.className.get(id), []), BitmapData);
         #elseif js
         var data = cast(ApplicationMain.loaders.get(AssetData.path.get(id)).contentLoaderInfo.content, Bitmap).bitmapData;
         #else
         var name =  AssetData.path.get(id);
         var data =AssetData.useResources ? BitmapData.loadFromBytes( getReso(name) ) :  BitmapData.load(name);
         #end
         return setCache(id,data,useCache);
      }
      return null;
   }

   public static function hasBytes(id:String):Bool
   {
      initialize();

      return AssetData.type.exists(id);
   }
 


   /**
    * Gets an instance of an embedded binary asset
    * @usage      var bytes = Assets.getBytes("file.zip");
    * @param   id      The ID or asset path for the file
    * @return      A new ByteArray object
    */
   public static function getBytes(id:String,?useCache:Null<Bool>):ByteArray 
   {
      if (hasBytes(id))
      {
         var cached = getCache(id,useCache);
         if (cached!=null)
            return cached;

         #if flash
         return setCache(id,Type.createInstance(AssetData.className.get(id), []), useCache);

         #elseif js
         var bytes:ByteArray = null;
         var data = ApplicationMain.urlLoaders.get(AssetData.path.get(id)).data;
         if (Std.is(data, String)) 
         {
            var bytes = new ByteArray();
            bytes.writeUTFBytes(data);
         } else if (Std.is(data, ByteArray)) 
         {
            bytes = cast data;
         } else 
         {
            bytes = null;
         }

         if (bytes != null) 
         {
            bytes.position = 0;
            return setCache(id,bytes, useCache);
         } else 
         {
            return null;
         }
         #else

         return setCache(id,ByteArray.readFile(AssetData.path.get(id)), useCache);
         #end

      }
      else 
      {
         trace("[nme.Assets] There is no String or ByteArray asset with an ID of \"" + id + "\"");
      }

      return null;
   }

   public static function hasFont(id:String):Bool 
   {
      initialize();

      return (AssetData.type.exists(id) && AssetData.type.get(id) == FONT);
   }
   /**
    * Gets an instance of an embedded font
    * @usage      var fontName = Assets.getFont("font.ttf").fontName;
    * @param   id      The ID or asset path for the font
    * @return      A new Font object
    */
   public static function getFont(id:String,?useCache:Null<Bool>):Font 
   {
      if (hasFont(id))
      {
         var cached = getCache(id,useCache);
         if (cached!=null)
            return cached;

         #if (flash || js)

         return setCache(id,cast(Type.createInstance(AssetData.className.get(id), []), Font), useCache);

         #else

         return setCache(id,new Font(AssetData.path.get(id)), useCache);

         #end

      }
      else 
      {
         trace("[nme.Assets] There is no Font asset with an ID of \"" + id + "\"");
      }

      return null;
   }

   public static function hasSound(id:String):Bool 
   {
      initialize();

      if (AssetData.type.exists(id)) 
      {
         var type = AssetData.type.get(id);
         return (type == SOUND || type == MUSIC);
      }
      return false;
   }
 

   /**
    * Gets an instance of an embedded sound
    * @usage      var sound = Assets.getSound("sound.wav");
    * @param   id      The ID or asset path for the sound
    * @return      A new Sound object
    */
   public static function getSound(id:String,?useCache:Null<Bool>):Sound 
   {
      if (hasSound(id))
      {
         var cached = getCache(id,useCache);
         if (cached!=null)
            return cached;

         return setCache(id,
            #if flash
            cast(Type.createInstance(AssetData.className.get(id), []), Sound)
            #elseif js
            new Sound(new URLRequest(AssetData.path.get(id)))
            #else
            new Sound(new URLRequest(AssetData.path.get(id)), null, AssetData.type.get(id) == MUSIC)
            #end
         , useCache);
      }

      trace("[nme.Assets] There is no Sound asset with an ID of \"" + id + "\"");

      return null;
   }

   public static function hasText(id:String) { return hasBytes(id); }

   /**
    * Gets an instance of an embedded text asset
    * @usage      var text = Assets.getText("text.txt");
    * @param   id      The ID or asset path for the file
    * @return      A new String object
    */
   public static function getText(id:String,?useCache:Null<Bool>):String 
   {
      var bytes = getBytes(id,useCache);

      if (bytes == null) 
      {
         return null;

      } else 
      {
         return bytes.readUTFBytes(bytes.length);
      }
   }

   #if js

   private static function resolveClass(name:String):Class<Dynamic> 
   {
      name = StringTools.replace(name, "native.", "browser.");
      name = StringTools.replace(name, "nme.", "browser.");
      return Type.resolveClass(name);
   }

   private static function resolveEnum(name:String):Enum <Dynamic> 
   {
      name = StringTools.replace(name, "native.", "browser.");
      name = StringTools.replace(name, "nme.", "browser.");
      return Type.resolveEnum(name);
   }

   #end

   // Getters & Setters
   private static function get_id():Array<String> 
   {
      initialize();

      var ids = [];

      for(key in AssetData.type.keys()) 
      {
         ids.push(key);
      }

      return ids;
   }

   private static function get_path():Map<String,String> 
   {
      initialize();

      #if ((nme_install_tool && !display) && !flash)

      return AssetData.path;

      #else

      return new Map<String,String>();

      #end
   }

   private static function get_type(): Map<String,AssetType> 
   {
      initialize();

      return AssetData.type;
   }
}


