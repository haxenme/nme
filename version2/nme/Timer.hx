package nme;

#if flash
typedef Timer = haxe.Timer;
#else

typedef TimerList = Array<Timer>

class Timer
{
   static var sRunningTimers:TimerList = [];
	static var sInitTime:Float = haxe.Timer.stamp();        //traacks time since VM instantion (approximately)

   var mTime:Float;
   var mFireAt:Float;
   var mRunning:Bool;

   public function new(time:Float)
   {
      mTime = time;
      sRunningTimers.push(this);
      mFireAt = GetMS()+mTime;
      mRunning = true;
   }

   // Set this with "run=..."
   dynamic public function run(){ }

   public function stop() : Void
   {
      if (mRunning)
      {
         mRunning = false;
         sRunningTimers.remove(this);
      }
   }

   function Check(inTime:Float)
   {
      if (inTime>=mFireAt)
      {
         mFireAt += mTime;
         run();
      }
   }

   public static function nmeCheckTimers()
   {
      var now = GetMS();
      for(timer in sRunningTimers)
         timer.Check(now);
   }

   static function GetMS() : Float
   { 
   	return stamp()*1000.0; 
   }


   // From std/haxe/Timer.hx
	public static function delay( f : Void -> Void, time : Int ) {
		var t = new nme.Timer(time);
		t.run = function() {
			t.stop();
			f();
		};
	}


   static public function stamp() : Float
   {
       //subtraction is needed to get a VM time offset within the 31-bit Int range
       //since on Linux/neko the normal timestamp is since 1970 (which *1000
       //in GetMS overflows)
       return haxe.Timer.stamp() - sInitTime;
   }

}


#end
