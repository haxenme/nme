package nme;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.MovieClip;
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


class Cache
{
   public function new() { }
   public function removeBitmapData(inId:String) Assets.removeBitmapData(inId);
}

typedef AssetLibrary = nme.AssetLib;
typedef AssetLibFactory = String -> nme.AssetLib;





@:nativeProperty
class Assets 
{
   public static inline var UNCACHED = 0;
   public static inline var WEAK_CACHE = 1;
   public static inline var STRONG_CACHE = 2;

   public static var info = new haxe.ds.StringMap<AssetInfo>();
   public static var pathMapper = new haxe.ds.StringMap<String>();
   public static var byteFactory = new haxe.ds.StringMap<Void->ByteArray>();
   public static var libraryFactories = new haxe.ds.StringMap<AssetLibFactory>();
   public static var loadedLibraries = new haxe.ds.StringMap<AssetLib>();
   #if js
   public static var cacheMode:Int = STRONG_CACHE;
   #else
   public static var cacheMode:Int = WEAK_CACHE;
   #end

   public static var scriptBase = "";

   public static var cache = new Cache();



   public static function fromAssetList(assetList:String, inAddScriptBase:Bool,inAlphaToo:Bool)
   {
      var lines:Array<String> = null;
      if (assetList.indexOf('\r')>=0)
         lines = assetList.split('\r\n');
      else
         lines = assetList.split('\n');

      var i:Int = 1;
      while (i < lines.length-1)
      {
         var id:String = lines[i+0];
         var resourceName:String = lines[i+1];
         var type:AssetType = Type.createEnum(AssetType,lines[i+2]);
         var isResource:Bool = lines[i+3] != 'false';
         var className:String = lines[i+4];
         if (className=="null")
            className = null;
         if (inAddScriptBase && !isResource)
            resourceName = scriptBase + resourceName;
         var alphaMode:AlphaMode = inAlphaToo ? Type.createEnum(AlphaMode,lines[i+5]) : AlphaDefault;
         info.set(id, new AssetInfo(resourceName,type,isResource,className,id,alphaMode));
         i+= inAlphaToo ? 6 : 5;
      }
   }

   public static function loadAssetList()
   {
      #if jsprime
      var module:Dynamic = untyped window.Module;
      var items = module.nmeAppItems;
      var className = null;
      var isResource = false;
      if (items!=null)
         for(id in Reflect.fields(items))
         {
            var item:{flags:Int,type:String,value:haxe.io.Bytes,alphaMode:String} = Reflect.field(items,id);
            var alphaMode = AlphaMode.AlphaDefault;
            if (item.alphaMode!=null)
               alphaMode = Type.createEnum(AlphaMode,item.alphaMode);
            var type =  Type.createEnum(AssetType,item.type);
            byteFactory.set(id,function() return ByteArray.fromBytes(item.value) );
            info.set(id, new AssetInfo(id,type,isResource,className,id,alphaMode));
         }
 
      #else
      var assetList = haxe.Resource.getString("haxe/nme/assets.txt");
      if (assetList!=null)
         fromAssetList(assetList,false,true);
      #end
   }


   public static function loadScriptAssetList()
   {
      var assetList = haxe.Resource.getString("haxe/nme/scriptassets.txt");
      if (assetList!=null)
         fromAssetList(assetList,true,false);
   }

 
   // includes alpha mode
   public static function loadScriptAssetList2()
   {
      var assetList = haxe.Resource.getString("haxe/nme/scriptassets.txt");
      if (assetList!=null)
         fromAssetList(assetList,true,true);
   }


   //public static var id(get_id, null):Array<String>;

   public static function addLibraryFactory(inType:AssetType, inFactory:AssetLibFactory)
   {
      libraryFactories.set(Std.string(inType), inFactory);
   }

   public static function getAssetPath(inName:String) : String
   {
      var i = getInfo(inName);
      return i==null ? null : i.path;
   }
   inline public static function getPath(inName:String) return getAssetPath(inName);

   public static function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
   {
      //dispatcher.addEventListener (type, listener, useCapture, priority, useWeakReference);
   }

   public static function isEmbedded(inName:String)
   {
      if (byteFactory.get(inName)!=null)
         return true;
      return haxe.Resource.listNames().indexOf(inName)>=0;
   }

   public static function getResource(inName:String) : ByteArray
   {
      var bytes = haxe.Resource.getBytes(inName);
      if (bytes==null)
      {
         var factory = byteFactory.get(inName);
         if (factory!=null)
            return factory();
      }
      if (bytes==null)
      {
         trace("[nme.Assets] missing binary resource '" + inName + "'");
         for(key in info.keys())
            trace(" " + key + " -> " + info.get(key).path + " " + info.get(key).isResource );
         trace("---");
         trace("All resources: " +  haxe.Resource.listNames());
      }
      if (bytes==null)
         return null;
      #if flash
      return bytes.getData();
      #else
      return ByteArray.fromBytes(bytes);
      #end
   }

   public static function isLocal(inId:String, inType:AssetType)
   {
      var i = getInfo(inId);
      if (i==null)
         return false;
      #if flash
      return i.isResource || Type.resolveClass(i.className)!=null;
      #else
      return true;
      #end
   }

   public static function list(?inFilter:AssetType)
   {
      if (inFilter==null)
         return info.keys();

      var result = new Array<String>();
      for(id in info.keys())
      {
         var asset = info.get(id);
         if (asset.type==inFilter)
            result.push(id);
      }
      return result.iterator();
   }

   public static function removeBitmapData(inId:String)
   {
      var i = getInfo(inId);
      if (i!=null)
         i.uncache();
   }


   public static function trySetCache(info:AssetInfo, useCache:Null<Bool>, data:Dynamic)
   {
      if (useCache!=false && (useCache==true || cacheMode!=UNCACHED))
         info.setCache(data, cacheMode!=STRONG_CACHE);
   }

   public static function noId(id:String, type:String)
   {
      trace("[nme.Assets] missing asset '" + id + "' of type " + type);
      //trace(info);
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
         if (val!=null && Std.is(val,BitmapData) )
            return val;
      }
 
      #if flash
         var data = makeBitmapData(i.className);
      #elseif (js && !jsprime)
         var data:BitmapData = null;
         // TODO
         //var data = cast(ApplicationMain.loaders.get(i.path).contentLoaderInfo.content, Bitmap).bitmapData;
      #else
         var data:BitmapData = null;
         if (i.isResource)
            data = BitmapData.loadFromBytes( getResource(i.path) );
         else
         {
            var filename = i.path;
            if (pathMapper.exists(filename))
               filename = pathMapper.get(filename);
            if (byteFactory.exists(filename))
               data = BitmapData.loadFromBytes( byteFactory.get(filename)() );
            else
               data = BitmapData.load(filename);
         }
         if (data!=null && data.transparent)
         {
            switch(i.alphaMode)
            {
               case AlphaPostprocess:
                  data.premultipliedAlpha = true;
               case AlphaIsPremultiplied, AlphaPreprocess:
                  data.setFormat( nme.image.PixelFormat.pfBGRPremA, false );
               default:
            }
         }
      #end
      trySetCache(i,useCache,data);
      return data;
   }
   inline public static function getImage(id:String, ?useCache:Null<Bool>) return getBitmapData(id,useCache);


   public static function hasBytes(id:String):Bool
   {
      var i = getInfo(id);
      return i!=null;
   }

   public static function exists(id:String,?type:AssetType):Bool
   {
      var i = getInfo(id);
      if (i==null)
         return false;
      if (type==null)
         return true;
      return i.type==type;
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
      return getBytesInfo(i,useCache);
   }

   public static function getBytesInfo(i:AssetInfo,?useCache:Null<Bool>):ByteArray 
   {
      if (useCache!=false)
      {
         var cached = i.getCache();
         var val:ByteArray = Std.is(cached, ByteArray) ? cached : null;
         if (val!=null)
         {
            val.position = 0;
            return val;
         }
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
         #elseif (js&&!jsprime)
            return null;
            /*
            var asset:Dynamic = ApplicationMain.urlLoaders.get(i.path).data;
            data = null;
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
            */
         #else
            var filename = i.path;
            if (pathMapper.exists(filename))
               filename = pathMapper.get(filename);
            if (byteFactory.exists(filename))
               data = byteFactory.get(filename)();
            else
               data = ByteArray.readFile(filename);
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
         if (val!=null && Std.is(val,Font) )
            return val;
      }

      var font = 
         #if (flash || (js &&!jsprime) )
            cast(Type.createInstance(Type.resolveClass(i.className),[]), Font);
         #else
            i.isResource ?  new Font("",null,null,i.path,id) :  new Font(i.path,null,null,null,id);
         #end

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
    * @param   inEngine   Which sound engine (sdl, openal etc) to use
    * @return      A new Sound object
    */
   public static function getSound(id:String,?useCache:Null<Bool>, forceMusic=false, ?inEngine:String):Sound 
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
         if (val!=null && Std.is(val,Sound) )
            return val;
      }

      var sound:Sound = null;
      #if flash
      sound = cast(Type.createInstance(Type.resolveClass(i.className), []), Sound);
      #elseif (js&&!jsprime)
      sound = new Sound(new URLRequest(i.path));
      #else
      if (i.isResource)
      {
         sound = new Sound();
         var bytes = nme.Assets.getBytes(id);
         sound.loadCompressedDataFromByteArray(bytes, bytes.length,i.type == MUSIC || forceMusic, inEngine);
      }
      else if (byteFactory.exists(i.path))
      {
         var bytes = byteFactory.get(i.path)();
         sound = new Sound();
         sound.loadCompressedDataFromByteArray(bytes, bytes.length,i.type == MUSIC || forceMusic, inEngine);
      }
      else
      {
         sound = new Sound(new URLRequest(i.path), null, i.type == MUSIC || forceMusic, inEngine); 
      }
    
      #end

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
      if (i.type!=MUSIC && i.type!=SOUND)
      {
         badType(id,"Music");
         return null;
      }
      return getSound(id,useCache, true);
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

   public static function parseLibId(id:String)
   {
      var split = id.indexOf(":");
      if (split<0)
         return null;
      return [ id.substr(0,split), id.substr(split+1) ];
   }

   public static function loadLibrary(inLibName:String, onLoad:AssetLib->Void)
   {
      if (loadedLibraries.exists(inLibName))
      {
         onLoad( loadedLibraries.get(inLibName) );
         return;
      }

      var libInfo = info.get(inLibName);
      if (libInfo==null)
         throw "[nme.Assets] Unnkown library " + inLibName;

      var type = Std.string(libInfo.type);
      var factory = libraryFactories.get(type);
      if (factory==null)
         throw("[nme.Assets] missing library handler for '" + inLibName + "' of type " + type);

      factory(inLibName).load(function(lib) {
         loadedLibraries.set(inLibName,lib);
         onLoad(lib);
      } );
   }


   public static function getLoadedLibrary(inLibName:String) : AssetLib
   {
      if (!loadedLibraries.exists(inLibName))
      {
         var libInfo = info.get(inLibName);
         if (libInfo==null)
         {
            noId(inLibName,"Library");
            return null;
         }

         var type = Std.string(libInfo.type);
         var factory = libraryFactories.get(type);
         if (factory==null)
         {
            trace("[nme.Assets] missing library handler for '" + inLibName + "' of type " + type);
            return null;
         }

         factory(inLibName).load(function(lib) loadedLibraries.set(inLibName,lib) );
      }

      return loadedLibraries.get(inLibName);
   }

   public static function getMovieClip(id:String):MovieClip
   {
      var libId = parseLibId(id);
      if (libId!=null)
      {
         var lib = getLoadedLibrary(libId[0]);
         if (lib==null)
            return null;
         return lib.getMovieClip(libId[1]);
      }

      return null;
   }

  #if (cpp||neko)
   @:keep 
   private static var initResources:Dynamic = (function() {
       var nme_set_resource_factory = nme.PrimeLoader.load("nme_set_resource_factory", "ov");
       if (nme_set_resource_factory!=null)
       {
           var notFound = new Map<String,Bool>();
           nme_set_resource_factory(function(s) {
             if (notFound.exists(s))
                return null;
             var reso = haxe.Resource.getBytes(s);
             if (reso!=null)
                 ByteArray.fromBytes(reso);
             // Reverse lookup-by path...
             for(asset in info)
             {
                if (asset.path == s)
                   return getBytesInfo(asset);
             }
             if (hasBytes(s))
                return getBytes(s);
             notFound.set(s,true);
             return null;
         });
      }
      return null; } ) ();
  #end


  public static function initialize() {}


}


