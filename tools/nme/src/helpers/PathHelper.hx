package;

import sys.io.Process;
import sys.FileSystem;
import platforms.Platform;

class PathHelper 
{
   public static function combine(firstPath:String, secondPath:String):String 
   {
      if (firstPath == null || firstPath == "") 
      {
         return secondPath;
      }
      else if (secondPath != null && secondPath != "") 
      {
         if (isAbsolute(secondPath))
            return secondPath;

         var firstSlash = (firstPath.substr(-1) == "/" || firstPath.substr(-1) == "\\");
         var secondSlash = (secondPath.substr(0, 1) == "/" || secondPath.substr(0, 1) == "\\");

         if (firstSlash && secondSlash) 
            return firstPath + secondPath.substr(1);
         else if (!firstSlash && !secondSlash) 
            return firstPath + "/" + secondPath;
         else
            return firstPath + secondPath;
      }
      else
      {
         return firstPath;
      }
   }

   public static function escape(path:String):String 
   {
      if (PlatformHelper.hostPlatform != Platform.WINDOWS) 
      {
         path = StringTools.replace(path, " ", "\\ ");

         return expand(path);
      }

      return expand(path);
   }

   public static function expand(path:String):String 
   {
      if (path == null) 
      {
         path = "";
      }

      if (PlatformHelper.hostPlatform != Platform.WINDOWS) 
      {
         if (StringTools.startsWith(path, "~/")) 
         {
            path = Sys.getEnv("HOME") + "/" + path.substr(2);
         }
      }

      return path;
   }

   public static function findTemplate(templatePaths:Array<String>, path:String, warnIfNotFound:Bool = true):String 
   {
      var matches = findTemplates(templatePaths, path, warnIfNotFound);

      if (matches.length > 0) 
      {
         //return matches[0];
         return matches[matches.length - 1];
      }

      return null;
   }

   public static function findTemplates(templatePaths:Array<String>, path:String, warnIfNotFound:Bool = true):Array<String> 
   {
      var matches = [];

      for(templatePath in templatePaths) 
      {
         var targetPath = combine(templatePath, path);

         if (FileSystem.exists(targetPath)) 
         {
            matches.push(targetPath);
         }
      }

      if (matches.length == 0 && warnIfNotFound) 
      {
         LogHelper.warn("Could not find template file: " + path);
      }

      return matches;
   }


   static var libMap = new Map<String,String>();

   public static function getHaxelibPath(inNameVersion:String) : Array<String>
   {
      var result = new Array<String>();

      var proc = new Process(combine(Sys.getEnv("HAXEPATH"), "haxelib"), [ "path", inNameVersion ]);

      try 
      {
         while(true) 
         {
            var line = proc.stdout.readLine();
            result.push(line);
         }

      } catch(e:Dynamic) { };

      var code = proc.exitCode();
      proc.close();

      if (code!=0)
         return [];

      return result;
   }

   public static function getHaxelib(haxelib:Haxelib,inAllowFail:Bool = false):String 
   {
      var name = haxelib.name;

      if (haxelib.version != "") 
      {
         name += ":" + haxelib.version;
      }

      var cached = libMap.get(name);
      if (cached!=null)
         return cached;

      if (name == "nme") 
      {
         var nmePath = Sys.getEnv("NMEPATH");

         if (nmePath != null && nmePath != "") 
         {
            libMap.set(name,nmePath);
            return nmePath;
         }
      }

      var haxelibPath = getHaxelibPath(name);
      var result = "";
      var stupidHaxelib = false;
      var seenMinusD = false;

      for(line in haxelibPath)
      {
         if (line.substr(0,8)=="Library ") 
         {
            result = "";
            stupidHaxelib = true;
            break;
         }
         else if (line == "-D " + name || line.indexOf('-D $name=')==0)
         {
            // Found the -D -> last match was good
            break;
         }
         else if (line.substr(0, 1) != "-")
         {
            result = line;
            // Dont't break - might be a dependency
         }
      }


      if (stupidHaxelib)
      {
         var proc = new Process(combine(Sys.getEnv("HAXEPATH"), "haxelib"), [ "list" ]);
         try 
         {
            while(true) 
            {
               var line = proc.stdout.readLine();
   
               if (line.substr(0,haxelib.name.length+1)==haxelib.name+":")
               {
                  var current = ~/\[(dev:)?(.*)\]/;
                  if (current.match(line))
                  {
                     result = current.matched(2);
                  }
                  else
                  {
                     if (inAllowFail)
                        return null;
                     LogHelper.error("Could not find haxelib \"" + haxelib.name + "\", nothing is current?");
                  }

                  break;
               }
            }
         } catch(e:Dynamic) { };

         var code = proc.exitCode();
         proc.close();
         if (code!=0)
            result = "";
      }

      if (result == "") 
      {
         if (inAllowFail)
            return null;
         LogHelper.error("Could not find haxelib \"" + haxelib.name + "\", does it need to be installed?");
      }
      else
      {
         LogHelper.info("", " - Discovered haxelib \"" + name + "\" at \"" + result + "\"");
      }

      libMap.set(name,result);
      return result;
   }

/*
   public static function getLibraryPath(ndll:NDLL, directoryName:String, namePrefix:String = "", nameSuffix:String = ".ndll", allowDebug:Bool = false):String 
   {
      var usingDebug = false;
      var path = "";

      if (allowDebug) 
      {
         path = searchForLibrary(ndll, directoryName, namePrefix + ndll.name + "-debug" + nameSuffix);
         usingDebug = FileSystem.exists(path);
      }

      if (!usingDebug) 
      {
         path = searchForLibrary(ndll, directoryName, namePrefix + ndll.name + nameSuffix);
      }

      return path;
   }
*/
   public static function getTemporaryFile(extension:String = ""):String 
   {
      var path = "";

      if (PlatformHelper.hostPlatform == Platform.WINDOWS) 
      {
         path = Sys.getEnv("TEMP");
      }
      else
      {
         path = Sys.getEnv("TMPDIR");
      }

      path += "/temp_" + Math.round(0xFFFFFF * Math.random()) + extension;

      if (FileSystem.exists(path)) 
      {
         return getTemporaryFile(extension);
      }

      return path;
   }

   public static function normalise(path:String):String 
   {
      path = path.split("\\").join("/");
      var parts = path.split("/");
      var first = 0;
      while(first<parts.length)
      {
         if (parts[first]==".")
         {
            parts.splice(first,1);
         }
         else if (parts[first]=="..")
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
      return parts.join("/");
   }

   public static function isAbsolute(path:String):Bool 
   {
      if (StringTools.startsWith(path, "/") || StringTools.startsWith(path, "\\") ||
            path.substr(1,1)==':' ) 
      {
         return true;
      }

      return false;
   }

   public static function isRelative(path:String):Bool 
   {
      return !isAbsolute(path);
   }

   public static function mkdir(directory:String):Void 
   {
      directory = StringTools.replace(directory, "\\", "/");
      var total = "";

      if (directory.substr(0, 2) == "//") 
      {
         total = "//";
         directory = directory.substr(2);
      }
      else if (directory.substr(0, 1) == "/") 
      {
         total = "/";
         directory = directory.substr(1);
      }

      var parts = directory.split("/");
      var oldPath = "";

      if (parts.length > 0 && parts[0].indexOf(":") > -1) 
      {
         oldPath = Sys.getCwd();
         Sys.setCwd(parts[0] + "\\");
         parts.shift();
      }

      var first = true;
      for(part in parts) 
      {
         if (part != "." && part != "") 
         {
            if (!first)
               total += "/";
            total += part;
            first = false;

            if (!FileSystem.exists(total)) 
            {
               LogHelper.info("", " - Creating directory: " + total);

               FileSystem.createDirectory(total);
            }
         }
      }

      if (oldPath != "") 
      {
         Sys.setCwd(oldPath);
      }
   }

   public static function relocatePath(path:String, targetDirectory:String):String 
   {
      // this should be improved for target directories that are outside the current working path
      if (isAbsolute(path) || targetDirectory == "") 
      {
         return normalise(path);
      }
      else if (isAbsolute(targetDirectory)) 
      {
         return FileSystem.fullPath(path);
      }
      else
      {
         targetDirectory = StringTools.replace(targetDirectory, "\\", "/");
         var splitTarget = targetDirectory.split("/");
         var directories = 0;

         while(splitTarget.length > 0) 
         {
            switch(splitTarget.shift()) 
            {
               case ".":
                  // ignore

               case "..":
                  directories--;

               default:
                  directories++;
            }
         }

         var adjust = "";

         for(i in 0...directories) 
         {
            adjust += "../";
         }

         return normalise(adjust + path);
      }
   }

   public static function relocatePaths(paths:Array<String>, targetDirectory:String):Array<String> 
   {
      var relocatedPaths = paths.copy();

      for(i in 0...paths.length) 
      {
         relocatedPaths[i] = relocatePath(paths[i], targetDirectory);
      }

      return relocatedPaths;
   }

   public static function removeDirectory(directory:String):Void 
   {
      if (FileSystem.exists(directory)) 
      {
         for(file in FileSystem.readDirectory(directory)) 
         {
            var path = directory + "/" + file;

            if (FileSystem.isDirectory(path)) 
            {
               removeDirectory(path);
            }
            else
            {
               FileSystem.deleteFile(path);
            }
         }

         LogHelper.info("", " - Removing directory: " + directory);

         FileSystem.deleteDirectory(directory);
      }
   }

   public static function safeFileName(name:String):String 
   {
      var safeName = StringTools.replace(name, " ", "");
      return safeName;
   }

/*
   private static function searchForLibrary(ndll:NDLL, directoryName:String, filename:String):String 
   {
      if (ndll.path != null && ndll.path != "") 
         return ndll.path;
      else if (ndll.haxelib.name == "hxcpp") 
      {
         var dir = ndll.isStatic ? "lib/" : "bin/";
         return combine(getHaxelib(ndll.haxelib), dir + directoryName + "/" + filename);
      }
      else
      {
         var dir = ndll.isStatic ? "lib/" : "ndll/";
         var path = combine(getHaxelib(ndll.haxelib), dir + directoryName + "/" + filename);
         if (!FileSystem.exists(path) && ndll.isStatic)
         {
            var test = combine(getHaxelib(ndll.haxelib), "ndll/" + directoryName + "/" + filename);
            if (FileSystem.exists(test))
               path = test;
         }
        
         return path;
      }
   }
*/

   public static function addExePath(path:String)
   {
      var sep = PlatformHelper.hostPlatform == Platform.WINDOWS ? ";" : ":";
      var add = path + sep + Sys.getEnv("PATH");
      Sys.putEnv("PATH", add);
   }


   public static function tryFullPath(path:String):String 
   {
      try 
      {
         return FileSystem.fullPath(path);

      } catch(e:Dynamic) 
      {
         return expand(path);
      }
   }
}
