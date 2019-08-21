package nme.display;
#if (!flash)

import nme.Loader;
import nme.app.Window;

@:nativeProperty
class ManagedStage extends Stage 
{
   static inline public var etUnknown = 0;
   static inline public var etKeyDown = 1;
   static inline public var etChar = 2;
   static inline public var etKeyUp = 3;
   static inline public var etMouseMove = 4;
   static inline public var etMouseDown = 5;
   static inline public var etMouseClick = 6;
   static inline public var etMouseUp = 7;
   static inline public var etResize = 8;
   static inline public var etPoll = 9;
   static inline public var etQuit = 10;
   static inline public var etFocus = 11;
   static inline public var etShouldRotate = 12;
   static inline public var etDestroyHandler = 13;
   static inline public var etRedraw = 14;
   static inline public var etTouchBegin = 15;
   static inline public var etTouchMove = 16;
   static inline public var etTouchEnd = 17;
   static inline public var etTouchTap = 18;
   static inline public var etChange = 19;
   static inline public var efLeftDown  =  0x0001;
   static inline public var efShiftDown =  0x0002;
   static inline public var efCtrlDown  =  0x0004;
   static inline public var efAltDown   =  0x0008;
   static inline public var efCommandDown = 0x0010;
   static inline public var efMiddleDown  = 0x0020;
   static inline public var efRightDown  = 0x0040;
   static inline public var efLocationRight  = 0x4000;
   static inline public var efPrimaryTouch   = 0x8000;

   public function new(inWidth:Int, inHeight:Int, inFlags:Int = 0) 
   {
      var managedStage = nme_managed_stage_create(inWidth, inHeight, inFlags);
      var managedWindow = new Window( managedStage, inWidth, inHeight );
      super(managedWindow);
   }


   /*
   override function nmeProcessStageEvent(inEvent:Dynamic):Float 
   {
      nmePollTimers();

      var wake = super.nmeProcessStageEvent(inEvent);
      setNextWake(wake);

      return wake;
   }

   */

   public function pumpEvent(inEvent:Dynamic) 
   {
      nme_managed_stage_pump_event(nmeHandle, inEvent);
   }

   public function onWindowSize(inWidth:Int, inHeight:Int) 
   {
      pumpEvent( { type: etResize, x: inWidth, y: inHeight } );
   }

   public function sendQuit() 
   {
      pumpEvent({ type: etQuit });
   }

   dynamic public function setNextWake(inDelay:Float) 
   {
   }

   public static function initSdlAudio()
   {
       nme_init_sdl_audio();
   }


   // Native Methods
   private static var nme_managed_stage_create = PrimeLoader.load("nme_managed_stage_create", "iiio");
   private static var nme_managed_stage_pump_event = PrimeLoader.load("nme_managed_stage_pump_event", "oov");
   private static var nme_init_sdl_audio = PrimeLoader.load("nme_init_sdl_audio", "v");
}

#end
