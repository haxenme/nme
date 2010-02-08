package nme;

class Lib
{
   static public var FULLSCREEN = 0x0001;
   static public var BORDERLESS = 0x0002;
   static public var RESIZABLE  = 0x0004;
   static public var HARDWARE   = 0x0008;
   static public var VSYNC      = 0x0010;

   static var nmeMainFrame: Dynamic = null;
   static var nmeCurrent: nme.display.MovieClip = null;
   static var nmeStage: nme.display.Stage = null;

   public static var stage(nmeGetStage,null): nme.display.Stage;
   public static var current(nmeGetCurrent,null): nme.display.MovieClip;


   public static function init(inWidth:Int, inHeight:Int,
                      inFrameRate:Float = 60.0,  inColour:Int = 0xffffff,
                      inFlags:Int = 0x0f, inTitle:String = "NME", inIcon : String="")
   {
      var create_main_frame = nme.Loader.load("nme_create_main_frame",5);
      nmeMainFrame = create_main_frame(inWidth,inHeight,inFlags,inTitle,inIcon);
      var stage_handle = nme_get_frame_stage(nmeMainFrame);
      nmeStage = new nme.display.Stage(stage_handle);
      nmeStage.frameRate = inFrameRate;
      nmeStage.opaqueBackground = inColour;
      nmeStage.onQuit = close;
   }

   static function nmeGetStage()
   {
      if (nmeStage==null)
         throw("Error : stage can't be accessed until init is called");
      return nmeStage;
   }

   // Be careful to to blow precision, since storing ms since 1970 can overflow...
   static var starttime : Float = haxe.Timer.stamp();
   static public function getTimer() : Int
   {
      return Std.int((haxe.Timer.stamp()-starttime) * 1000.0);
   }


   public static function mainLoop()
   {
      var main_loop = nme.Loader.load("nme_main_loop",0);
      main_loop();
   }

   public static function close()
   {
      var close = nme.Loader.load("nme_close",0);
      close();
   }

   public static function pollTimers()
   {
   }

   static function nmeGetCurrent() : nme.display.MovieClip
   {
      if (nmeCurrent==null)
      {
         nmeCurrent = new nme.display.MovieClip();
         stage.addChild(nmeCurrent);
      }
      return nmeCurrent;
   }


   static var nme_get_frame_stage = nme.Loader.load("nme_get_frame_stage",1);
}


