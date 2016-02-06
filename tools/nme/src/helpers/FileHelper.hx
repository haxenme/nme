package;

import haxe.io.Bytes;
import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import neko.Lib;
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
          extension == "properties" ||
          extension == "hxproj" ||
          extension == "nmml" ||
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

   // Paste here to avoid version issues
   #if neko


public static function quoteUnixArg(argument:String):String {
      // Based on cpython's shlex.quote().
      // https://hg.python.org/cpython/file/a3f076d4f54f/Lib/shlex.py#l278

      if (argument == "")
         return "''";

      if (!~/[^a-zA-Z0-9_@%+=:,.\/-]/.match(argument))
         return argument;

      // use single quotes, and put single quotes into double quotes
      // the string $'b is then quoted as '$'"'"'b'
      return "'" + StringTools.replace(argument, "'", "'\"'\"'") + "'";
   }

   /**
      Character codes of the characters that will be escaped by `quoteWinArg(_, true)`.
   */
   public static var winMetaCharacters = [" ".code, "(".code, ")".code, "%".code, "!".code, "^".code, "\"".code, "<".code, ">".code, "&".code, "|".code, "\n".code, "\r".code];

   /**
      Returns a String that can be used as a single command line argument
      on Windows.
      The input will be quoted, or escaped if necessary, such that the output
      will be parsed as a single argument using the rule specified in
      http://msdn.microsoft.com/en-us/library/ms880421

      Examples:
      ```
      quoteWinArg("abc") == "abc";
      quoteWinArg("ab c") == '"ab c"';
      ```
   */
   public static function quoteWinArg(argument:String, escapeMetaCharacters:Bool):String {
      // If there is no space, tab, back-slash, or double-quotes, and it is not an empty string.
      if (!~/^[^ \t\\"]+$/.match(argument)) {
         
         // Based on cpython's subprocess.list2cmdline().
         // https://hg.python.org/cpython/file/50741316dd3a/Lib/subprocess.py#l620

         var result = new StringBuf();
         var needquote = argument.indexOf(" ") != -1 || argument.indexOf("\t") != -1 || argument == "";

         if (needquote)
            result.add('"');

         var bs_buf = new StringBuf();
         for (i in 0...argument.length) {
            switch (argument.charCodeAt(i)) {
               case "\\".code:
                  // Don't know if we need to double yet.
                  bs_buf.add("\\");
               case '"'.code:
                  // Double backslashes.
                  var bs = bs_buf.toString();
                  result.add(bs);
                  result.add(bs);
                  bs_buf = new StringBuf();
                  result.add('\\"');
               case c:
                  // Normal char
                  if (bs_buf.length > 0) {
                     result.add(bs_buf.toString());
                     bs_buf = new StringBuf();
                  }
                  result.addChar(c);
            }
         }

         // Add remaining backslashes, if any.
         result.add(bs_buf.toString());

         if (needquote) {
            result.add(bs_buf.toString());
            result.add('"');
         }

         argument = result.toString();
      }

      if (escapeMetaCharacters) {
         var result = new StringBuf();
         for (i in 0...argument.length) {
            var c = argument.charCodeAt(i);
            if (winMetaCharacters.indexOf(c) >= 0) {
               result.addChar("^".code);
            }
            result.addChar(c);
         }
         return result.toString();
      } else {
         return argument;
      }
   }


   private static var sys_command = neko.Lib.load("std","sys_command",1);
   public static function neko_command( cmd : String, ?args : Array<String> ) : Int
   {
      if (args == null)
      {
         return sys_command(untyped cmd.__s);
      }
      else if (PlatformHelper.hostPlatform == Platform.WINDOWS)
      {
          cmd = [
             for (a in [StringTools.replace(cmd, "/", "\\")].concat(args))
                 quoteWinArg(a, true)
          ].join(" ");
          return sys_command(untyped cmd.__s);
      }
      else
      {
          cmd = [cmd].concat(args).map(quoteUnixArg).join(" ");
          return sys_command(untyped cmd.__s);
      }
   }
   #else
   public static function neko_command( cmd : String, ?args : Array<String> ) : Int
      return Sys.command(cmd, args);
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
         source = source.split("/").join("\\").replace("\\\\","\\");
         destination = destination.split("/").join("\\").replace("\\\\","\\");
         LogHelper.info("", " - Copying file: " + source + " -> " + destination);
         neko_command("copy", [source, destination]);
      }
      else
      {
         LogHelper.info("", " - Copying file: " + source + " -> " + destination);
         neko_command("cp", [source, destination]);
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

   public static function recursiveCopyTemplate(templatePaths:Array<String>, source:String, destination:String, context:Dynamic = null, process:Bool = true,warn=true, ?onFile:String->Void)
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
               if (file.substr(0, 1) != ".") 
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
            recursiveCopyTemplate(templatePaths, source + "/" + file, destination + "/" + file, context, process, false, onFile );
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

      var input = File.read(source, true);

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
