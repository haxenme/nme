package haxe;

#if macro
class Timer { }
#elseif (flash)

// Original haxe.Timer class
class Timer
{
   private var id : Null<Int>;

   /**
      Create a new timer that will run every [time_ms] (in milliseconds).
   **/
   public function new( time_ms : Int ){
      #if flash9
         var me = this;
         id = untyped __global__["flash.utils.setInterval"](function() { me.run(); },time_ms);
      #elseif flash
         var me = this;
         id = untyped _global["setInterval"](function() { me.run(); },time_ms);
      #elseif js
         var me = this;
         id = untyped window.setInterval(function() me.run(),time_ms);
      #end
   }

   /**
      Stop the timer definitely.
   **/
   public function stop() {
      if( id == null )
         return;
      #if flash9
         untyped __global__["flash.utils.clearInterval"](id);
      #elseif flash
         untyped _global["clearInterval"](id);
      #elseif js
         untyped window.clearInterval(id);
      #end
      id = null;
   }

   /**
      This is the [run()] method that is called when the Timer executes. It can be either overriden in subclasses or directly rebinded with another function-value.
   **/
   public dynamic function run() {
   }

   /**
      This will delay the call to [f] for the given time. [f] will only be called once.
   **/
   public static function delay( f : Void -> Void, time_ms : Int ) {
      var t = new haxe.Timer(time_ms);
      t.run = function() {
         t.stop();
         f();
      };
      return t;
   }


   /**
      Measure the time it takes to execute the function [f] and trace it. Returns the value returned by [f].
   **/
   public static function measure<T>( f : Void -> T, ?pos : PosInfos ) : T {
      var t0 = stamp();
      var r = f();
      Log.trace((stamp() - t0) + "s", pos);
      return r;
   }

   /**
      Returns the most precise timestamp, in seconds. The value itself might differ depending on platforms, only differences between two values make sense.
   **/
   public static function stamp() : Float {
      #if flash
         return flash.Lib.getTimer() / 1000;
      #elseif (neko || php)
         return Sys.time();
      #elseif js
         return Date.now().getTime() / 1000;
      #elseif cpp
         return untyped __global__.__time_stamp();
      #else
         return 0;
      #end
   }
}

#else

import nme.app.Application;
import nme.app.IPollClient;

// Custom haxe.Timer implementation for C++ and Neko

typedef TimerList = Array<Timer>;
class TimerPollClient implements IPollClient
{
   public function new() { }
   public function onPoll(timestamp:Float):Void Timer.nmeCheckTimers(timestamp);
   public function getNextWake(defaultWake:Float,timestamp:Float):Float
      return Timer.nmeGetNextWake(defaultWake,timestamp);

}

class Timer
{
   static var sRunningTimers:TimerList = null;
   static var sPollClient:IPollClient = null;

   var mTime:Float;
   var mFireAt:Float;
   var mRunning:Bool;


   public function new(inTimeMs:Float)
   {
      if (sRunningTimers==null)
      {
         sRunningTimers = [];
         sPollClient = new TimerPollClient();
         Application.addPollClient(sPollClient);
      }

      // Convert everything to seconds...
      mTime = inTimeMs*0.001;
      sRunningTimers.push(this);
      mFireAt = stamp() + mTime;
      mRunning = true;
   }

   public static function measure<T>( f : Void -> T, ?pos : PosInfos ) : T
   {
      var t0 = stamp();
      var r = f();
      Log.trace((stamp() - t0) + "s", pos);
      return r;
   }

   // Set this with "run=..."
   dynamic public function run() { }

   public function stop():Void
   {
      mRunning = false;
   }

   /**
    * @private
    */
   static public function nmeGetNextWake(inDefaultWake:Float,inStamp:Float):Float
   {
      var wake = inDefaultWake;
      for (timer in sRunningTimers)
      {
         if (!timer.mRunning)
            continue;
         var sleep = timer.mFireAt - inStamp;
         if (sleep < wake)
         {
            wake = sleep;
            if (wake < 0)
               return 0;
         }
      }
      return wake;
   }


   function nmeCheck(inTime:Float)
   {
      if (inTime >= mFireAt)
      {
         mFireAt += mTime;
         run();
      }
   }

   /**
    * @private
    */
   public static function nmeCheckTimers( inStamp:Float )
   {
      if (sRunningTimers!=null)
      {
         var i = 0;
         while(i<sRunningTimers.length)
         {
            var timer = sRunningTimers[i];
            if (timer.mRunning)
               timer.nmeCheck(inStamp);

            if (!timer.mRunning)
               sRunningTimers.splice(i,1);
            else
               i++;
         }
      }
   }

   // From std/haxe/Timer.hx
   public static function delay(f:Void -> Void, time:Int)
   {
      var t = new Timer(time);

      t.run = function()
      {
         t.stop();
         f();
      };

      return t;
   }

   static public function stamp():Float
   {
      return nme_time_stamp.call();
   }

   static var nme_time_stamp = nme.PrimeLoader.load("nme_time_stamp","d");
}




#end
