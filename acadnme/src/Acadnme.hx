import nme.display.Sprite;
import nme.display.Stage;
import nme.text.TextField;
import nme.events.Event;
import nme.system.System;
import nme.ui.Scale;
import nme.utils.Float32Array;
import nme.utils.UInt8Array;
import nme.events.KeyboardEvent;
import nme.utils.ByteArray;
import AllNme;
import Sys;

import nme.script.Server;
import nme.script.IScriptHandler;


class Acadnme extends Sprite implements IScriptHandler
{
   var script:String;
   var server:Server;
   var listener:Stage;

   static var instance:Acadnme;
   public static var directory:String = null;
   public static var connectionStatus:String;

   // Set by script
   public static var boot:IBoot;

   public function new()
   {
      super();


      instance = this;
      var startServer = #if web false #else true #end;

      // For attaching a debugger
      var delay = Sys.getEnv("ACADNME_DELAY")!=null;

      var args = Sys.args();
      var idx = 0;

      #if android
      installBackHandler();
      #end

      var unusedArgs = new Array<String>();
      for(arg in args)
      {
         var used = true;
         if (arg.substr(0,1)=='-')
         {
            if (arg=="-delay")
               delay = true;
            else if (arg=="-sleep")
               Sys.sleep(8);
            else if (arg=="-noserver")
               startServer = false;
            #if cpp
            else if (arg=="-nojit")
               enableJit(false);
            #end
            else if (arg=="-nogc")
            {
               trace("disable gc...");
               cpp.vm.Gc.enable(false);
            }
            else
               used = false;
         }
         else if (script==null)
         {
            script = arg;
            startServer = false;
         }
         else
            used = false;

         if (!used)
            unusedArgs.push(arg);
      }
      nme.system.System.setArgs(unusedArgs);



      if (startServer)
      {
         Server.functions["log"] = function(x) { scriptLog(x); return "ok"; }
         server = new Server("Acadnme", Sys.getEnv("ACADNME_DIR"), this );
         directory = server.directory;
         server.start();
         connectionStatus = server.connectedHost;
      }
      else
      {
         connectionStatus = "Not started";
      }

      if (script!=null)
      {
         if (delay)
         {
            var text = new TextField();
            text.text = "Click to continue";
            text.x = 100;
            text.y = 100;
            addChild(text);
            stage.addEventListener( nme.events.MouseEvent.CLICK, function(x) { removeChild(text); onClick(x); } );
         }
         else
            run(script);
      }
      else if (server!=null)
      {
         listener = stage;
         listener.addEventListener(Event.ENTER_FRAME, onEnter);
         runBoot();
      }
      else
      {
         runBoot();
      }

   }

   @:native("hx::EnableJit")
   extern static function enableJit(enable:Bool) : Void;


   public static function getNmeAppsDir() : String
   {
      #if (!android && !iphone && !emscripten)
      // Find list of nme apps in the "bin/apps" directory
      var exePath = nme.system.System.exeName;
      exePath = exePath.split("\\").join("/");
      var parts = exePath.split("/");

      for(p in 0...parts.length)
      {
         var idx = parts.length-1-p;
         // Deployed in bin directory....
         if (parts[idx]=="bin")
         {
            return parts.slice(0,idx+1).join("/") + "/apps";
         }
         // Run from dev direcotry
         if (parts[idx]=="acadnme")
         {
            return parts.slice(0,idx+1).join("/") + "/bin/apps";
         }
      }

      // exe directory
      parts[ parts.length-1 ] = "apps";
      return parts.join("/");
      #end

      return null;
   }

   function installBackHandler()
   {
      var downTime = 0.0;
      stage.addEventListener( KeyboardEvent.KEY_DOWN, function(x) {
         if (x.keyCode==27 && downTime==0.0)
            downTime = haxe.Timer.stamp();
      } );
      stage.addEventListener( KeyboardEvent.KEY_UP, function(x) {
          if (x.keyCode==27 && downTime!=0.0)
          {
             // Long back
             if ( haxe.Timer.stamp() > downTime + 2.0 )
                nme.system.System.restart();
          }
          downTime = 0.0;
      } );

   }

   function onClick(_)
   {
      stage.removeEventListener( nme.events.MouseEvent.CLICK, onClick );
      run(script);
   }


   // IScriptHandler
   public function scriptLog(inMessage:String)
   {
      trace("acadnme: " + inMessage);
   }


   public function scriptRunSync(f:Void->Void) : Void
   {
      haxe.Timer.delay(f,0);
   }

   public function onEnter(_)
   {
      while(server!=null)
      {
         var func = server.pollQueue();
         if (func==null)
            break;
         clearBoot();
         func();
      }
   }


   function clearBoot()
   {
      if (boot!=null)
      {
         boot.remove();
         boot = null;
      }
      if (listener!=null)
      {
         listener.removeEventListener(Event.ENTER_FRAME, onEnter);
         listener = null;
      }
   }

   public function run(inScript:String)
   {
      clearBoot();

      if (nme.Assets.hasBytes(inScript))
      {
         trace("Run resource " + inScript);
         nme.script.Nme.runBytes(nme.Assets.getBytes(inScript));
      }
      else
      {
         trace("Run file " + inScript);
         nme.script.Nme.runFile(inScript);
      }
   }

   public function runBytes(bytes:ByteArray)
   {
       clearBoot();
       trace("Run bytes " + bytes.length);
       nme.script.Nme.runBytes(bytes);
   }

   public function runBoot()
   {
      if (nme.Assets.hasBytes("AcadnmeBoot.nme"))
      {
         trace("Run AcadnmeBoot.nme");
         nme.script.Nme.runBytes(nme.Assets.getBytes("AcadnmeBoot.nme"));
      }
      else
      {
         var appsDir = getNmeAppsDir();
         if (appsDir==null)
            trace("Could not find boot directory");
         var file = appsDir+"/AcadnmeBoot.nme";
         nme.script.Nme.runFile(file);
      }
   }


   @:keep // Used by boot
   public static function runScript(inScript:String)
   {
      instance.run(inScript);
   }

   @:keep // Used by boot
   public static function runScriptBytes(inScript:ByteArray)
   {
      instance.runBytes(inScript);
   }


   @:keep // Used by boot
   public static function getEngines() : Array< {name:String, version:String} >
   {
      #if cppia
      return [];
      #else
      return cast ApplicationMain.engines;
      #end
   }

   @:keep // Used by boot
   public static function getNmeVersion() : String
   {
      #if cppia
      return "";
      #else
      return nme.Version.name;
      #end
   }


   #if cpp
   static public function __init__()
   {
      var exeDir = haxe.io.Path.directory(Sys.programPath());
      var slash = exeDir.indexOf("/") >=0 ? "/" : "\\";
      var parts = exeDir.split(slash);
      if (parts.length>3)
      {
         parts.pop();
         parts.pop();
         parts.pop();
         parts.push("ndll");
         parts.push(cpp.Lib.getBinDirectory());
         var dllPath = parts.join(slash);
         cpp.Lib.pushDllSearchPath( exeDir );
         cpp.Lib.pushDllSearchPath( dllPath );
      }
   }
   #end

}

