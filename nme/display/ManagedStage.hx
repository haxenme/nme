package nme.display;

class ManagedStage extends Stage
{
   static var etUnknown = 0;
   static var etKeyDown = 1;
   static var etChar = 2;
   static var etKeyUp = 3;
   static var etMouseMove = 4;
   static var etMouseDown = 5;
   static var etMouseClick = 6;
   static var etMouseUp = 7;
   static var etResize = 8;
   static var etPoll = 9;
   static var etQuit = 10;
   static var etFocus = 11;
   static var etShouldRotate = 12;

   static var etDestroyHandler = 13;
   static var etRedraw = 14;

   static var etTouchBegin = 15;
   static var etTouchMove = 16;
   static var etTouchEnd = 17;
   static var etTouchTap = 18;

   static var etChange = 19;




   public function new(inWidth:Int,inHeight:Int)
   {
      super(nme_managed_stage_create(inWidth,inHeight),inWidth,inHeight);
   }

   public function resize(inWidth:Int,inHeight:Int)
   {
      pumpEvent({type:etResize, x:inWidth, y:inHeight});
   }

   override public function nmeRender(inSendEnterFrame:Bool)
   {
      beginRender();
      super.nmeRender(inSendEnterFrame);
      endRender();
   }

   override function nmeDoProcessStageEvent(inEvent:Dynamic) : Float
   {
      nmePollTimers();
      var wake = super.nmeDoProcessStageEvent(inEvent);
      setNextWake(wake);
      return wake;
   }

   public function pumpEvent(inEvent:Dynamic)
   {
      nme_managed_stage_pump_event(nmeHandle,inEvent);
   }

   public function sendQuit()
   {
      pumpEvent( { type:etQuit } );
   }

   dynamic public function setNextWake(inDelay:Float) { }
   dynamic public function beginRender() { }
   dynamic public function endRender() { }

   static var nme_managed_stage_create = nme.Loader.load("nme_managed_stage_create",2);
   static var nme_managed_stage_pump_event = nme.Loader.load("nme_managed_stage_pump_event",2);
}
