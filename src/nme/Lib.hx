package nme;
#if (!flash)

import haxe.Timer;
import nme.bare.Surface;
import nme.app.Window;
import nme.display.ManagedStage;
import nme.display.MovieClip;
import nme.display.Stage;
import nme.net.URLRequest;
import nme.Lib;
import nme.Loader;
import nme.PrimeLoader;
import nme.app.Application;
import haxe.CallStack;
using StringTools;

#if (nme_static && cpp && !cppia)
import nme.StaticNme;
#end

import Sys;

@:nativeProperty
class Lib 
{
   // stage specific calls...
   public static var stage(get, never):Stage;
   public static var current(get, never):MovieClip;

   private static var nmeCurrent:MovieClip = null;
   public  static var nmeStage(default,null):Stage = null;

   // Wrapper to Application class
   public static var FULLSCREEN      = Application.FULLSCREEN;
   public static var BORDERLESS      = Application.BORDERLESS;
   public static var RESIZABLE       = Application.RESIZABLE;
   public static var HARDWARE        = Application.HARDWARE;
   public static var VSYNC           = Application.VSYNC;
   public static var HW_AA           = Application.HW_AA;
   public static var HW_AA_HIRES     = Application.HW_AA_HIRES;
   public static var ALLOW_SHADERS   = 0;
   public static var REQUIRE_SHADERS = 0;
   public static var DEPTH_BUFFER    = Application.DEPTH_BUFFER;
   public static var STENCIL_BUFFER  = Application.STENCIL_BUFFER;
   public static var SINGLE_INSTANCE = Application.SINGLE_INSTANCE;

   public static var initHeight(get, never):Int;
   public static var initWidth(get, never):Int;

   public static var company(get, never):String;
   public static var version(get, never):String;
   public static var packageName(get, never):String;
   public static var file(get, never):String;
   public static var title:String;

   public static var build(get, never):String;
   public static var ndllVersion(get, never):Int;
   public static var nmeStateVersion(get, never):String;
   public static var bits(get, never):Int;
   public static var silentRecreate(get,set):Bool;
   public static var stageFactory:(Window)->Stage;
   public static var nmeArgPrefix = "--nme-backend=";

   public static function create(inOnLoaded:Void->Void, inWidth:Int, inHeight:Int,
              inFrameRate:Float = 60.0, inColour:Int = 0xffffffff, inFlags:Int = 0x0f,
              inTitle:String = "NME", ?inIcon:Surface, ?inDummy:Dynamic) 
   {
      title = inTitle;

      #if sys
      if (nmeArgPrefix!=null && nme_set_renderer!=null)
      {
         var args = nme.system.System.getArgs();
         var nmeBackend:String = null;
         var kept = [];
         for(a in args)
            if (a.startsWith(nmeArgPrefix))
               nmeBackend = a.substr( nmeArgPrefix.length );
            else
               kept.push(a);
         if (nmeBackend!=null)
         {
            nme.system.System.setArgs(kept);
            nme_set_renderer(nmeBackend);
         }
      }
      #end

      var params = {
         width:inWidth,
         height:inHeight,
         flags:inFlags,
         title:inTitle,
         color:inColour,
         icon:inIcon
      };


      Application.createWindow(function(inWindow:Window) {
         try
         {
            if (stageFactory!=null)
               Lib.nmeStage = stageFactory(inWindow);
            else
               Lib.nmeStage = new Stage(inWindow);
            Lib.nmeStage.frameRate = inFrameRate;
            Lib.nmeStage.opaqueBackground = inColour;

            if (nmeCurrent != null) // Already created...
            {
               Lib.nmeStage.nmeCurrent = nmeCurrent;
               Lib.nmeStage.addChild(nmeCurrent);
               nmeCurrent = null;
            }

            inOnLoaded();
         }
         catch(e:Dynamic)
         {
            var stack = CallStack.toString(CallStack.exceptionStack());
            trace("Error creating window: (" + params + ")\n"+e+stack);
         }

      }, params );
   }

   public static function createSecondaryWindow(inWidth:Int, inHeight:Int, inTitle:String,
              inFlags:Int = 0x0f,
              inColour:Int = 0xffffff,
              inFrameRate:Float = 0.0,
              ?inIcon:Surface) : Window
   {
      title = inTitle;

      var params = {
         width:inWidth,
         height:inHeight,
         flags:inFlags,
         title:inTitle,
         color:inColour,
         icon:inIcon
      };

      var window:Window = null;
      var err:String = null;

      Application.createWindow(function(inWindow:Window) {
         try
         {
            var stage = 
               if (stageFactory!=null)
                  stageFactory(inWindow);
               else
                  new Stage(inWindow);
            stage.frameRate = inFrameRate;
            stage.opaqueBackground = inColour;

            window = inWindow;
         }
         catch(e:Dynamic)
         {
            var stack = CallStack.toString(CallStack.exceptionStack());
            err = ("Error creating window: (" + params + ")\n"+e+stack);
         }

      }, params, true );

      if (err!=null)
         throw err;
      if (window==null)
         throw "multiple windows not supported on this target";

      return window;
   }



   public static function load(library:String, method:String, args:Int = 0):Dynamic
   {
      #if neko
      return neko.Lib.load(library,method,args);
      #elseif cpp
      return cpp.Lib.load(library,method,args);
      #end
      return null;
   }

   public static function crash()
   {
      nme_crash();
   }

   public static function log(str:String)
   {
      nme_log(str);
   }

   public static function redirectTrace()
   {
      haxe.Log.trace = function( v : Dynamic, ?infos : haxe.PosInfos )  {
         if (infos==null)
            log( Std.string(v) );
         else
            log( infos.fileName + ":" + infos.lineNumber + ": " + v);
      }
   }


   public static function createManagedStage(inWidth:Int, inHeight:Int, inFlags:Int = 0) 
   {
      Application.initWidth = inWidth;
      Application.initHeight = inHeight;

      var result = new ManagedStage(inWidth, inHeight, inFlags);
      nmeStage = result;

      return result;
   }


   // haxe flash compat
   public static function getURL(url:URLRequest, ?target:String):Void 
   {
      url.launchBrowser();
   }

   public static function getTimer():Int 
   {
      // Be careful not to blow precision, since storing ms since 1970 can overflow...
      return Std.int(Timer.stamp() * 1000.0);
   }


   // Getters & Setters
   static function get_current():MovieClip 
   {
      if (nmeStage!=null)
         return nmeStage.current;

      if (nmeCurrent == null)
         nmeCurrent = new MovieClip();

      return nmeCurrent;
   }

   private static function get_stage() 
   {
      if (nmeStage == null)
         throw("Error : stage can't be accessed until init is called");

      return nmeStage;
   }

   public static function nmeSetCurrentStage(inStage:Stage)
   {
      nmeStage = inStage;
   }

   // Delegate to app for old programs ..
   public static var close = Application.close;
   public static var exit = Application.exit;
   public static var forceClose = Application.forceClose;

   public static var pause = Application.pause;
   public static var postUICallback = Application.postUICallback;
   public static var resume = Application.resume;
   public static var setPackage = Application.setPackage;
   public static var setIcon = Application.setIcon;

   
   public static function get_initWidth() return Application.initWidth;
   public static function get_initHeight() return Application.initHeight;

   public static function get_company() return Application.company;
   public static function get_version() return Application.version;
   public static function get_packageName() return Application.packageName;
   public static function get_file() return Application.file;

   public static function get_build() return Application.get_build();
   public static function get_ndllVersion() return Application.get_ndllVersion();
   public static function get_nmeStateVersion() return Application.get_nmeStateVersion();
   public static function get_bits() return Application.get_bits();

   public static function get_silentRecreate() return Application.silentRecreate;
   public static function set_silentRecreate(inVal:Bool) { Application.silentRecreate=inVal; return inVal; }

   // Native Methods
   private static var nme_log = PrimeLoader.load("nme_log", "sv");
   private static var nme_crash = PrimeLoader.load("nme_crash","v");
   private static var nme_set_renderer = PrimeLoader.load("nme_set_renderer","sv");
}

#else
typedef Lib = flash.Lib;
#end
