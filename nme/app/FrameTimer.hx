package nme.app;


class FrameTimer implements IPollClient
{
   public var fps(default,set):Float;
   public var lastRender:Float;
   public var framePeriod(default,null):Float;
   public var window:Window;
   public var invalid:Bool;

   /**
    * Time, in seconds, we wake up before the frame is due.  We then do a
    * "busy wait" to ensure the frame comes at the right time.  By increasing this number,
    * the frame rate will be more constant, but the busy wait will take more CPU.
    * @private
    */
   public var earlyWakeup:Float;


   public function new(inWindow:Window, inFps:Float)
   {
      fps = inFps;
      lastRender = 0.0;
      earlyWakeup = 0.005;
      window = inWindow;
      invalid = false;
      Application.addPollClient(this,true);
   }

   function set_fps(inFps:Float)
   {
      fps = inFps;
      framePeriod = fps > 0 ? 1.0/fps : 0.0;
      return inFps;
   }

   public function onPoll(timestamp:Float):Void
   {
      if (window.active)
      {
         if (invalid)
         {
            invalid = false;
            window.onInvalidFrame();
         }
         else if (fps>0 && timestamp >= lastRender + framePeriod) 
         {
            lastRender = timestamp;
            window.onNewFrame();
         }
      }
   }

   public function invalidate()
   {
      invalid = true;
   }

   public function getNextWake(defaultWake:Float,timestamp:Float):Float
   {
      if (!window.active)
         return 0;

      if (invalid)
         return 0.0;

      if (framePeriod==0.0)
         return defaultWake;

      var next = lastRender + framePeriod - timestamp - earlyWakeup;
      if (next < defaultWake)
         return next;

      return defaultWake;
   }

}

