package;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.Process;
import platforms.Platform;

class ProcessHelper 
{
   public static function getOutput(command:String, args:Array<String>, inEcho:Bool = false, inShowErrors=false, inThrowErrors=false) : Array<String>
   {
      var result = new Array<String>();

      Log.verbose(" " + command + " " + args.join(" ") );

      var process:Process = null;
      try
      {
         process = new Process(command, args);
         while(true)
         {
            var line = process.stdout.readLine();
            if (inEcho)
                Sys.println(line);
            result.push(line);
         }
      }
      catch(e:Dynamic) { }

      if (process!=null)
      {
         var code = process.exitCode();
         process.close();
         if (code!=0)
         {
            if (inShowErrors)
               Log.error("running: " + command + " " + args.join(" "));
            else if (inThrowErrors)
            {
               throw "Error running: " + command + " " + args.join(" ");
            }
         }
      }

      return result;
   }

   public static function logCommand(command:String, args:Array<String>, outFile:sys.io.FileOutput) : Int
   {
      Log.verbose(" " + command + " " + args.join(" ") );

      var process:Process = null;
      try
      {
         process = new Process(command, args);
         while(true)
         {
            var line = process.stdout.readLine();
            Sys.println(line);
            outFile.writeString(line + "\n");
         }
      }
      catch(e:Dynamic) { }

      outFile.close();

      if (process!=null)
      {
         var code = process.exitCode();
         process.close();
         return code;
      }

      return -1;
   }


   public static function openFile(workingDirectory:String, targetPath:String, executable:String = ""):Void 
   {
      if (executable == null) 
      {
         executable = "";
      }

      if (PlatformHelper.hostPlatform == Platform.WINDOWS) 
      {
         if (executable == "") 
         {
            if (targetPath.indexOf(":\\") == -1) 
            {
               runCommand(workingDirectory, targetPath, []);
            }
            else
            {
               runCommand(workingDirectory, ".\\" + targetPath, []);
            }
         }
         else
         {
            if (targetPath.indexOf(":\\") == -1) 
            {
               runCommand(workingDirectory, executable, [ targetPath ]);
            }
            else
            {
               runCommand(workingDirectory, executable, [ ".\\" + targetPath ]);
            }
         }

      } else if (PlatformHelper.hostPlatform == Platform.MAC) 
      {
         if (executable == "") 
         {
            executable = "/usr/bin/open";
         }

         if (targetPath.substr(0) == "/") 
         {
            runCommand(workingDirectory, executable, [ targetPath ]);
         }
         else
         {
            runCommand(workingDirectory, executable, [ "./" + targetPath ]);
         }
      }
      else
      {
         if (executable == "") 
         {
            executable = "/usr/bin/xdg-open";
         }

         if (targetPath.substr(0) == "/") 
         {
            runCommand(workingDirectory, executable, [ targetPath ]);
         }
         else
         {
            runCommand(workingDirectory, executable, [ "./" + targetPath ]);
         }
      }
   }

   public static function openURL(url:String):Void 
   {
      if (PlatformHelper.hostPlatform == Platform.WINDOWS) 
      {
         runCommand("", url, []);

      } else if (PlatformHelper.hostPlatform == Platform.MAC) 
      {
         runCommand("", "/usr/bin/open", [ url ]);
      }
      else
      {
         runCommand("", "/usr/bin/xdg-open", [ url ]);
      }
   }

   public static function runCommand(path:String, command:String, args:Array<String>, safeExecute:Bool = true, ignoreErrors:Bool = false, ?outFile:String):Void 
   {
      if (safeExecute) 
      {
         try 
         {
            if (path != "" && !FileSystem.exists(FileSystem.fullPath(path)) && !FileSystem.exists(FileSystem.fullPath(new Path(path).dir))) 
            {
               LogHelper.error("The specified target path \"" + path + "\" does not exist");
            }

            _runCommand(path, command, args, outFile);

         } catch(e:Dynamic) 
         {
            if (!ignoreErrors) 
            {
               LogHelper.error("", e);
            }
         }
      }
      else
      {
         _runCommand(path, command, args, outFile);
      }
   }

   private static function _runCommand(path:String, command:String, args:Array<String>, ?outFile:String) 
   {
      var oldPath:String = "";

      if (path != "") 
      {
         LogHelper.info("", " - Changing directory: " + path + "");

         oldPath = Sys.getCwd();
         Sys.setCwd(path);
      }

      var logFile = outFile!=null ? sys.io.File.write(outFile) : null;

      var argString = "";

      for(arg in args) 
      {
         if (arg.indexOf(" ") > -1) 
         {
            argString += " \"" + arg + "\"";
         }
         else
         {
            argString += " " + arg;
         }
      }

      Log.verbose(" " + command + argString);

      var result:Int = logFile!=null ? logCommand(command,args,logFile) : Sys.command(command, args);

      if (result == 0) 
      {
         //LogHelper.info("", "(Done)");
      }

      if (oldPath != "") 
      {
         Sys.setCwd(oldPath);
      }

      if (result != 0) 
      {
         throw("Error running: " + command + " " + args.join(" ") + " [" + path + "]");
      }
   }
}
