package nme.app;


class FrameTimer implements IPollClient
{
   public var fps(default,set):Float;
   public var lastRender:Float;
   public var framePeriod(default,null):Float;
   public var window:Window;
   public var invalid:Bool;

   public function new(inWindow:Window, inFps:Float)
   {
      fps = inFps;
      lastRender = 0.0;
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
         else if (fps>0 && timestamp >= lastRender + framePeriod - 0.0005 ) 
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
         return defaultWake;

      if (invalid)
         return 0.0;

      if (framePeriod==0.0)
         return defaultWake;

      var next = lastRender + framePeriod - haxe.Timer.stamp();
      if (next < defaultWake)
         return next;

      return defaultWake;
   }

}

