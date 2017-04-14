package nme.app;

import haxe.Timer;
import nme.Loader;
import nme.bare.Surface;
import nme.app.Window;
import Sys;

#if cpp
import cpp.vm.Mutex;
#elseif neko
import neko.vm.Mutex;
#end

typedef WindowParams = {
    ? flags        : Null<Int>,
    ? fps          : Null<Float>,
    ? color        : Null<Int>,
    ? width        : Null<Int>,
    ? height       : Null<Int>,
    ? title        : String,
    ? icon         : Surface,
};

@:nativeProperty
class Application 
{
   public static inline var OrientationPortrait = 1;
   public static inline var OrientationPortraitUpsideDown = 2;
   public static inline var OrientationLandscapeRight = 3;
   public static inline var OrientationLandscapeLeft = 4;
   public static inline var OrientationFaceUp = 5;
   public static inline var OrientationFaceDown = 6;
   public static inline var OrientationPortraitAny = 7;
   public static inline var OrientationLandscapeAny = 8;
   public static inline var OrientationAny = 9;


   public inline static var FULLSCREEN      = 0x0001;
   public inline static var BORDERLESS      = 0x0002;
   public inline static var RESIZABLE       = 0x0004;
   public inline static var HARDWARE        = 0x0008;
   public inline static var VSYNC           = 0x0010;
   public inline static var HW_AA           = 0x0020;
   public inline static var HW_AA_HIRES     = 0x0060;
   public inline static var DEPTH_BUFFER    = 0x0200;
   public inline static var STENCIL_BUFFER  = 0x0400;
   public inline static var SINGLE_INSTANCE = 0x0800;

   public static var nmeFrameHandle:Dynamic = null;
   public static var nmeWindow:Window = null;
   public static var silentRecreate:Bool = false;
   public static var sIsInit = false;

   public static var initHeight:Int;
   public static var initWidth:Int;
   public static var initFrameRate:Float;

   public static var company(default, null):String;
   public static var version(default, null):String;
   public static var packageName(default, null):String;
   public static var file(default, null):String;

   public static var build(get, null):String;
   public static var ndllVersion(get, null):Int;
   public static var nmeStateVersion(get, null):String;
   public static var bits(get, null):Int;

   public static var onQuit:Void -> Void = close;
   public static var nmeQuitting = false;

   static var pollClientList:Array<IPollClient>;
   static var mainThreadJobs:Array<Void->Void> = [];
   #if (cpp||neko)
   static var mainThreadJobMutex = new Mutex();
   #end



   public static function createWindow(inOnLoaded:Window->Void, inParams:WindowParams)
   {
      if (sIsInit) 
      {
         if (silentRecreate) 
         {
            inOnLoaded(nmeWindow);
            return;
         }

         throw("nme.app.Application.createWindow called multiple times. This function is automatically called by the project code.");
      }

      sIsInit = true;
      initWidth = inParams.width==null ? 640 : inParams.width;
      initHeight = inParams.height==null ? 480 : inParams.height;
      initFrameRate = inParams.fps==null ? 60 : inParams.fps;
      var flags = inParams.flags==null ? 0x0f : inParams.flags;
      var title = inParams.title==null ? "NME" : inParams.title;
      var icon = inParams.icon==null ? null : inParams.icon.nmeHandle;

      var create_main_frame = nme.PrimeLoader.load("nme_create_main_frame","oiiisov");

      trace("create_main_frame...");
      create_main_frame(function(inFrameHandle:Dynamic) {
      trace("got calback " + inFrameHandle);
            onQuit = close;
            nmeFrameHandle = inFrameHandle;
            nmeWindow = new Window(nmeFrameHandle,initWidth,initHeight);
            nmeWindow.setBackground(inParams.color);
            inOnLoaded(nmeWindow);
         }, initWidth, initHeight, flags, title, icon );
      trace("wait...");
   }

   public static function close() 
   {
      nmeQuitting = true;
      var close = Loader.load("nme_close", 0);
      close();
   }

   public static function addPollClient(client:IPollClient,inAtEnd:Bool = false)
   {
      if (pollClientList==null)
         pollClientList = [];
      // Inset at beginning so frame update happens last
      if (inAtEnd)
         pollClientList.push(client);
      else
         pollClientList.insert(0,client);
   }

   public static function pollThreadJobs()
   {
      while(!nmeQuitting && mainThreadJobs.length>0)
      {
         var job:Void->Void = null;
         #if ((cpp||neko) && !emscripten)
         mainThreadJobMutex.acquire();
         job = mainThreadJobs.shift();
         mainThreadJobMutex.release();
         #else
         job = mainThreadJobs.shift();
         #end
         if (job!=null)
            job();
      }
   }

   public static function pollClients(timestamp:Float) : Void
   {
      if (mainThreadJobs.length>0)
         pollThreadJobs();
      if (pollClientList!=null && !nmeQuitting)
      {
         for(client in pollClientList)
             client.onPoll(timestamp);
      }
      if (mainThreadJobs.length>0)
         pollThreadJobs();
   }


   public static function getNextWake(timestamp:Float) : Float
   {
      var nextWake = 1e30;

      if (pollClientList!=null && !nmeQuitting)
      {
         for(client in pollClientList)
         {
             var wake = client.getNextWake(nextWake,timestamp);
             if (wake<=0)
                return 0;
             if (wake < nextWake)
                nextWake = wake;
         }
      }
      return nextWake;
   }

   public static function setFixedOrientation(inOrientation:Int):Void
   {
      nme_stage_set_fixed_orientation(inOrientation);
   }

   public static function exit() 
   {
      if (onQuit != null) 
      {
         #if android
         if (onQuit == close) 
         {
            Sys.exit(0);
         }
         #end

         onQuit();
      }
   }

   public static function forceClose() 
   {
      // Terminates the process straight away, bypassing graceful shutdown
      var terminate = Loader.load("nme_terminate", 0);
      terminate();
   }

   public static function pause() 
   {
      nme_pause_animation();
   }

   public static function runOnMainThread(inCallback:Void->Void) 
   {
      #if ((cpp||neko) && !emscripten)
      mainThreadJobMutex.acquire();
      mainThreadJobs.push(inCallback);
      mainThreadJobMutex.release();
      #else
      mainThreadJobs.push(inCallback);
      #end
   }

   public static function postUICallback(inCallback:Void->Void) 
   {
      #if android
      nme_post_ui_callback(inCallback);
      #else
      runOnMainThread(inCallback);
      #end
   }

   public static function resume() 
   {
      nme_resume_animation();
   }

   // Is this still used?
   //public static function setAssetBase(inBase:String)
   //{
     //nme_set_asset_base(inBase);
   //}
   //private static var nme_set_asset_base = Loader.load("nme_set_asset_base", 1);
   public static function setIcon(path:String) 
   {
      //Useful only on SDL platforms. Sets the title bar's icon, based on the path given.
      var set_icon = Loader.load("nme_set_icon", 1);
      set_icon(path);
   }

   public static function setPackage(inCompany:String, inFile:String, inPack:String, inVersion:String) 
   {
      company = inCompany;
      file = inFile;
      packageName = inPack;
      version = inVersion;

      nme_set_package(inCompany, inFile, inPack, inVersion);
   }
   
   public static function get_build():String { return Version.name; }
   public static function get_ndllVersion():Int { return nme_get_ndll_version(); }
   public static function get_nmeStateVersion():String { return nme_get_nme_state_version(); }
   public static function get_bits():Int { return nme_get_bits(); }

   // Native Methods
   #if android
   private static var nme_post_ui_callback = Loader.load("nme_post_ui_callback", 1);
   #end
   private static var nme_set_package = Loader.load("nme_set_package", 4);
   private static var nme_get_frame_stage = Loader.load("nme_get_frame_stage", 1);
   private static var nme_pause_animation = Loader.load("nme_pause_animation", 0);
   private static var nme_resume_animation = Loader.load("nme_resume_animation", 0);
   private static var nme_get_ndll_version = Loader.load("nme_get_ndll_version", 0);
   private static var nme_get_nme_state_version = Loader.load("nme_get_ndll_version", 0);
   private static var nme_stage_set_fixed_orientation = Loader.load("nme_stage_set_fixed_orientation", 1);
   private static var nme_get_bits = Loader.load("nme_get_bits", 0);
}



