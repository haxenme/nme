package nme.net;
#if (!flash)

#if sys
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import haxe.io.Path;
import Sys;
#elseif js
import js.html.Storage;
import js.Browser;
#end

import nme.Loader;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.io.Eof;
import nme.events.EventDispatcher;

@:nativeProperty
class SharedObject extends EventDispatcher 
{
   public var data(default, null):Dynamic;

   public var realPath(get,never):String;

   /** @private */ public var localPath(default,null):String;
   /** @private */ public var name(default,null):String;
   private function new(inName:String, inLocalPath:String, inData:Dynamic) 
   {
      super();

      name = inName;
      localPath = inLocalPath;
      data = inData;
   }

   public function clear():Void 
   {
      #if (js)
         var storage = Browser.getLocalStorage();
         if (storage != null)
            storage.removeItem(localPath + ":" + name);

      #elseif (iphone || android)

         untyped nme_clear_user_preference(name);

      #else

         var filePath = realPath;

         if (FileSystem.exists(filePath)) 
         {
            FileSystem.deleteFile(filePath);
         }

      #end
   }

   #if !(iphone || android || js)
   static public function mkdir(directory:String):Void 
   {
      directory = StringTools.replace(directory, "\\", "/");
      var total = "";

      if (directory.substr(0, 1) == "/") 
      {
         total = "/";
      }

      var parts = directory.split("/");
      var oldPath = "";

      if (parts.length > 0 && parts[0].indexOf(":") > -1) 
      {
         oldPath = Sys.getCwd();
         Sys.setCwd(parts[0] + "\\");
         parts.shift();
      }

      for(part in parts) 
      {
         if (part != "." && part != "") 
         {
            if (total != "/") 
            {
               total += "/";
            }

            total += part;

            if (!FileSystem.exists(total)) 
            {
               FileSystem.createDirectory(total);
            }
         }
      }

      if (oldPath != "") 
      {
         Sys.setCwd(oldPath);
      }
   }
   #end

   public function flush(minDiskSpace:Int = 0):SharedObjectFlushStatus 
   {
      var encodedData:String = Serializer.run(data);

      #if (js)

         var storage = Browser.getLocalStorage();
         if (storage != null)
         {
            storage.removeItem(localPath + ":" + name);
            storage.setItem(localPath + ":" + name, encodedData);
         }

      #elseif (iphone || android)

         untyped nme_set_user_preference(name, encodedData);

      #else

         var filePath = realPath;
         var folderPath = Path.directory(filePath);

         if (!FileSystem.exists(folderPath)) 
         {
            mkdir(folderPath);
         }

         var output:FileOutput = File.write(filePath, false);
         output.writeString(encodedData);
         output.close();

      #end

      return SharedObjectFlushStatus.FLUSHED;
   }

   #if sys
   private static function getFilePath(name:String, localPath:String):String 
   {
      var path:String = nme.filesystem.File.applicationStorageDirectory.nativePath;

      path +=  "/" + localPath + "/" + name + ".sol";

      return path;
   }
   #end

   function get_realPath():String 
   {
      #if (js)
      return "";
      #elseif (iphone || android)
      return "";
      #else
      return getFilePath(name,localPath);
      #end
   }

   public static function getLocal(name:String, ?localPath:String, secure:Bool = false):SharedObject 
   {
      if (localPath == null) 
      {
         localPath = "";
      }

      #if (js)
         var rawData:String = null;
         var storage = Browser.getLocalStorage();
         if (storage != null)
            rawData = storage.getItem(localPath + ":" + name);

      #elseif (iphone || android)

         var rawData:String = untyped nme_get_user_preference(name);

      #else

         var filePath = getFilePath(name, localPath);
         var rawData:String = "";

         if (FileSystem.exists(filePath)) 
         {
            rawData = File.getContent(filePath);
         }

      #end

      var loadedData:Dynamic = { };

      if (rawData == "" || rawData == null) 
      {
         // empty
      }
      else 
      {
         try 
         {
            var unserializer = new Unserializer(rawData);
            unserializer.setResolver(cast { resolveEnum: Type.resolveEnum, resolveClass: resolveClass } );
            loadedData = unserializer.unserialize();

         }
         catch(e:Dynamic) 
         {
            trace("Could not unserialize SharedObject");
         }
      }

      var so = new SharedObject(name, localPath, loadedData);

      return so;
   }

   private static function resolveClass(name:String):Class <Dynamic> 
   {
      if (name != null) 
      {
         return Type.resolveClass(StringTools.replace(name, "neash.", "nme."));
         return Type.resolveClass(StringTools.replace(name, "native.", "nme."));
      }

      return null;
   }
   
   public function setProperty(propertyName:String, ?value:Dynamic):Void
   {
      if (data != null)
      {
         Reflect.setField(data, propertyName, value);
      }
   }

   // Native Methods
   #if (iphone || android)
   private static var nme_get_user_preference = Loader.load("nme_get_user_preference", 1);
   private static var nme_set_user_preference = Loader.load("nme_set_user_preference", 2);
   private static var nme_clear_user_preference = Loader.load("nme_clear_user_preference", 1);
   #end
}

#else
typedef SharedObject = flash.net.SharedObject;
#end
