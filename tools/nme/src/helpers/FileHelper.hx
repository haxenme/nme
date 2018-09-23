package;

import sys.io.FileInput;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import platforms.Platform;
using StringTools;

class FileHelper 
{
   public static function copyAsset(asset:Asset, destination:String, context:Dynamic = null) 
   {
      if (asset.sourcePath != "") 
      {
         copyFile(asset.sourcePath, destination, context);
      }
      else
      {
         if (Std.is(asset.data, Bytes)) 
            File.saveBytes(destination, cast asset.data);
         else
            File.saveContent(destination, Std.string(asset.data));
      }
   }

   public static function copyAssetIfNewer(asset:Asset, destination:String) 
   {
      if (asset.sourcePath != "") 
      {
         if (isNewer(asset.sourcePath, destination)) 
            copyFile(asset.sourcePath, destination);
      }
      else
      {
         if (Std.is(asset.data, Bytes)) 
            File.saveBytes(destination, cast asset.data);
         else
            File.saveContent(destination, Std.string(asset.data));
      }
   }

   public static function copyFile(source:String, destination:String, ?context:{?MACROS:Dynamic}, process:Bool = true,
      ?onFile:String->Void) : Bool
   {
      var extension = Path.extension(source);
      var copied = false;

      if (process && context != null && 
            (extension == "xml" ||
             extension == "java" ||
             extension == "hx" ||
             extension == "hxml" ||
          extension == "html" || 
             extension == "ini" ||
             extension == "gpe" ||
             extension == "pch" ||
             extension == "pbxproj" ||
             extension == "plist" ||
             extension == "json" ||
             extension == "cpp" ||
             extension == "mm" ||
             extension == "m" ||
             extension == "nsis" ||
          extension == "properties" ||
          extension == "xcscheme" ||
          extension == "hxproj" ||
          extension == "nmml" ||
          extension == "gradle" ||
          extension == "storyboard" ||
          isText(source))) 
          {
         var fileContents:String = File.getContent(source);
         var template:Template = new Template(fileContents);

         try
         {
            var result = template.execute(context, context.MACROS);

            if (extension=="java")
               result = result.split("org.haxe.lime.GameActivity").join("org.haxe.nme.GameActivity");

            if (FileSystem.exists(destination) && File.getContent(destination)==result)
            {
               //Log.verbose(" - already current " +  destination);
            }
            else
            {
               Log.verbose(" - Copying template file: " + source + " -> " + destination);
               var fileOutput:FileOutput = File.write(destination, true);
               fileOutput.writeString(result);
               fileOutput.close();
               copied = true;
            }
            if (onFile!=null)
               onFile(destination);
         }
         catch(e:Dynamic)
         {
            Log.error("Error processing " + source + " : " + e);
         }
      }
      else
      {
         if (onFile!=null)
            onFile(destination);
         copied = copyIfNewer(source, destination);
      }

      return copied;
   }

   public static function copyFileTemplate(templatePaths:Array<String>, source:String, destination:String, context:Dynamic = null, process:Bool = true, ?onFile:String->Void) 
   {
      var path = PathHelper.findTemplate(templatePaths, source);

      if (path != null) 
      {
         copyFile(path, destination, context, process,onFile);
      }
   }

   #if neko
   static var neko_sys_command = neko.Lib.load("std","sys_command",1);
   #end

   public static function copyIfNewer(source:String, destination:String) : Bool
   {
      //allFiles.push(destination);
      if (!isNewer(source, destination)) 
      {
         return false;
      }

      PathHelper.mkdir(Path.directory(destination));

      // Use system copy to preserve file permissions
      if (PlatformHelper.hostPlatform == Platform.WINDOWS) 
      {
         var quote = #if (haxe_ver >= 3.300) "" #else "\"" #end;

         source = quote + source.split("/").join("\\").replace("\\\\","\\") + quote;
         destination = quote + destination.split("/").join("\\").replace("\\\\","\\") + quote;
         LogHelper.info("", " - Copying file: " + source + " -> " + destination);

         var redirect = #if (haxe_ver >= 3.300) [">nul"] #else [] #end;
         var code = Sys.command("cmd", ["/c", "copy",  source, destination].concat(redirect));
         if (code!=0)
         {
            #if (neko && haxe_ver >= 3.300) 
               // Try plain quotes - not sure what is going wrong...
               var cmd = 'cmd /c copy "$source" "$destination" >nul';
               code =  neko_sys_command(untyped cmd.__s);
               if (code!=0)
            #end
            Log.error('Could not copy $source to $destination');
         }
      }
      else
      {
         LogHelper.info("", " - Copying file: " + source + " -> " + destination);
         var code = Sys.command("cp", [source, destination]);
         if (code!=0)
            Log.error('Could not copy $source to $destination');
      }
      return true;
   }

   public static function copyLibrary(ndll:NDLL, directoryName:String, namePrefix:String, nameSuffix:String, targetDirectory:String, allowDebug:Bool = false, targetSuffix:String = null) 
   {

   }

   public static function recursiveCopy(source:String, destination:String, context:Dynamic = null, process:Bool = true,
      ?onFile:String->Void) 
   {
      PathHelper.mkdir(destination);

      var files:Array<String> = null;

      try 
      {
         files = FileSystem.readDirectory(source);

      } catch(e:Dynamic) 
      {
         LogHelper.error("Could not find source directory \"" + source + "\"");
      }

      for(file in files) 
      {
         if (file.substr(0, 1) != ".") 
         {
            var itemDestination:String = destination + "/" + file;
            var itemSource:String = source + "/" + file;

            if (FileSystem.isDirectory(itemSource)) 
            {
               recursiveCopy(itemSource, itemDestination, context, process);
            }
            else
            {
               copyFile(itemSource, itemDestination, context, process);
               if (onFile!=null)
                  onFile(itemDestination);
            }
         }
      }
   }

   public static function recursiveCopyTemplate(templatePaths:Array<String>, source:String, destination:String, context:Dynamic = null, process:Bool = true,warn=true, ?onFile:String->Void, ?inFilter:String->Bool)
   {
      PathHelper.mkdir(destination);

      var files:Map<String,String> = null;
      var ignored = new Map<String,String>();

      for(path in templatePaths)
      {
         try 
         {
            var dir = FileSystem.readDirectory(path+"/"+source);

            if (files==null)
                files=new Map<String,String>();

            for(file in dir)
               if (file.substr(0, 1) != "." && (inFilter==null || inFilter(file) ) )
               {
                  if (!files.exists(file))
                     files.set(file, path);
                  else
                     ignored.set(file, path);
               }

         } catch(e:Dynamic) { }
      }

      if (files==null)
      {
         if (warn)
            LogHelper.error("Could not find any source directory \"" + source + "\" in " + templatePaths);
         return false;
      }

      var copiedFile = false;
      for(file in files.keys()) 
      {
         copiedFile = true;
         var itemDestination:String = destination + "/" + file;
         var itemSource:String = files.get(file) + "/" + source + "/" + file;

         if (FileSystem.isDirectory(itemSource)) 
         {
            recursiveCopyTemplate(templatePaths, source + "/" + file, destination + "/" + file, context, process, false, onFile, inFilter );
         }
         else
         {
            if (copyFile(itemSource, itemDestination, context, process))
            {
               var notCopied = ignored.get(file);
               if (notCopied!=null)
                  Log.verbose("  ignored " + file + " from " + notCopied);
            }

            if (onFile!=null)
               onFile(itemDestination);
         }
      }

      return copiedFile;
   }

   public static function isNewer(source:String, destination:String):Bool 
   {
      if (source == null || !FileSystem.exists(source)) 
      {
         LogHelper.error("IsNewer - source path \"" + source + "\" does not exist");
         return false;
      }

      if (FileSystem.exists(destination)) 
      {
         if (FileSystem.stat(source).mtime.getTime() <= FileSystem.stat(destination).mtime.getTime()) 
         {
            return false;
         }
      }

      return true;
   }

   public static function isText(source:String):Bool 
   {
      if (!FileSystem.exists(source)) 
      {
         return false;
      }

      var input:FileInput = File.read(source, true);
      var ret:Bool = calcIsText(input);
      input.close();
      return ret;
   }

   static function calcIsText(input:FileInput):Bool
   {
      var numChars = 0;
      var numBytes = 0;

      try 
      {
         while(numBytes < 512) 
         {
            var byte = input.readByte();

            numBytes++;

            if (byte == 0) 
            {
               return false;
            }

            if ((byte > 8 && byte < 16) ||(byte > 32 && byte < 256) || byte > 287) 
            {
               numChars++;
            }
         }

      } catch(e:Dynamic) { }

      if (numBytes == 0 ||(numChars / numBytes) > 0.7) 
      {
         return true;
      }

      return false;
   }
}
