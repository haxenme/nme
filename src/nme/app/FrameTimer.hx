package nme.app;

@:nativeProperty
class FrameTimer implements IPollClient
{
   public var fps(default,set):Float;
   public var lastRender:Float;
   public var framePeriod(default,null):Float;
   public var window:Window;
   public var invalid:Bool;
   public var catchup:Bool;
   public var offTarget:Float;

   public function new(inWindow:Window, inFps:Float)
   {
      fps = inFps;
      lastRender = 0.0;
      window = inWindow;
      invalid = false;
      catchup = false;
      offTarget = 0.0;
      Application.addPollClient(this,true);
   }

   public function destory()
   {
      Application.removePollClient(this);
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
         var wasInvalid =invalid;
         invalid = false;
         #if jsprime
         if (fps>=60)
         {
            lastRender = timestamp;
            window.onNewFrame();
            offTarget = 0.0;
         } else
         #end
         //trace('onPoll $window $fps ' + (timestamp - (lastRender - offTarget + framePeriod - 0.0005) ) );
         if (fps>0 && timestamp >= lastRender - offTarget + framePeriod - 0.0005 ) 
         {
            if (catchup)
            {
               offTarget = timestamp-(lastRender+framePeriod);
               if (offTarget>framePeriod)
                  offTarget = framePeriod;
               if (offTarget<-framePeriod)
                  offTarget = -framePeriod;
            }
            else
                offTarget = 0.0;

            lastRender = timestamp;
            window.onNewFrame();
         }
         else if (wasInvalid)
         {
            offTarget = 0.0;
            window.onInvalidFrame();
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

