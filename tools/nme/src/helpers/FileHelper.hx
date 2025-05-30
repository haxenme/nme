package;

import sys.io.FileInput;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
#if neko
import neko.Lib;
#end

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
         if (Std.isOfType(asset.data, Bytes)) 
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
         if (Std.isOfType(asset.data, Bytes)) 
            File.saveBytes(destination, cast asset.data);
         else
            File.saveContent(destination, Std.string(asset.data));
      }
   }

   public static function copyFileReplace(source:String, destination:String,from:String,to:String, stripComments=false)
   {
      Log.verbose(" - Copying file by lines: " + source + " -> " + destination);
      var dir = haxe.io.Path.directory(destination);
      if (!sys.FileSystem.exists(dir))
        sys.FileSystem.createDirectory(dir);      

      var fileContents:String = File.getContent(source);

      var parts = fileContents.split(from);
      fileContents = parts.join(to);

      if (stripComments)
         fileContents = FileHelper.stripComments(destination,fileContents);
      //Log.verbose("   - replace " + from + " with " + to + " ok:" + (parts.length>1) );

      var fileOutput:FileOutput = File.write(destination, true);
      fileOutput.writeString(fileContents);
      fileOutput.close();
   }

   public static function stripComments(destination:String, html:String) : String
   {
      var len0 = html.length;
      html = html.split("\r").join("");
      var lines = html.split("\n");
      var newLines = [];
      var remove = false;
      for(l in lines)
      {
         if (remove)
         {
            if (l.indexOf("*/")>0)
               remove = false;
         }
         else
         {
            var pos =  l.indexOf("//");
            if (pos>=0)
            {
               var prefix = l.substr(0,pos);
               var allSpace = true;
               for(ch in prefix)
                  if (ch!=" ".code && ch!="\t".code)
                  {
                     allSpace = false;
                     break;
                  }
               if (!allSpace)
               {
                  if ( prefix.endsWith(" ") || prefix.endsWith("\t") )
                     newLines.push(prefix);
                  else
                     newLines.push(l);
               }
            }
            else if (l.length>0)
            {
               var commStart = l.indexOf("/**");
               if (commStart >= 0)
               {
                  var tail = l.substr(commStart);
                  l = l.substr(0,commStart);

                  var commEnd = tail.indexOf("*/");
                  if (commEnd>0)
                  {
                     l += tail.substr(commEnd+2);
                  }
                  else
                     remove = true;
               }

               for(ch in l)
                  if (ch!=" ".code && ch!="\t".code)
                  {
                     newLines.push(l);
                     break;
                  }
            }
         }
      }

      html = newLines.join("\n");

      if (html.length<len0)
         Log.verbose("Stripped " + destination );
      return html;
   }

   public static function copyFile(source:String, destination:String, ?context:{?MACROS:Dynamic}, process:Bool = true,
      ?onFile:String->Void, stripHtml=false) : Bool
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
            else if (extension=="html" && stripHtml)
               result = stripComments(destination,result);

            if (FileSystem.exists(destination) && File.getContent(destination)==result)
            {
               //Log.verbose(" - already current " +  destination);
            }
            else
            {
               Log.verbose(" - Copying template file: " + source + " -> " + destination);
               var dir = haxe.io.Path.directory(destination);
               if (!sys.FileSystem.exists(dir))
               {
                 sys.FileSystem.createDirectory(dir);      
               }
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

   public static function copyFileTemplate(templatePaths:Array<String>, source:String, destination:String, context:Dynamic = null, process:Bool = true, ?onFile:String->Void,stripHtml=false)
   {
      var path = PathHelper.findTemplate(templatePaths, source);

      if (path != null) 
      {
         copyFile(path, destination, context, process,onFile,stripHtml);
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
      ?onFile:String->Void, stripHtml=false) 
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
               copyFile(itemSource, itemDestination, context, process, null, stripHtml);
               if (onFile!=null)
                  onFile(itemDestination);
            }
         }
      }
   }

   public static function recursiveCopyTemplate(templatePaths:Array<String>, source:String, destination:String, context:Dynamic = null, process:Bool = true,warn=true, ?onFile:String->Void, ?inFilter:String->Bool, stripHtml=false)
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
            recursiveCopyTemplate(templatePaths, source + "/" + file, destination + "/" + file, context, process, false, onFile, inFilter, stripHtml );
         }
         else
         {
            if (copyFile(itemSource, itemDestination, context, process, null, stripHtml))
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
