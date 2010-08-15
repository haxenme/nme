package nme;


typedef TimerList = Array<Timer>

class Timer
{
   static var sRunningTimers:TimerList = [];

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

   static public function nmeNextWake(limit:Float) : Float
	{
		var now = nme_time_stamp() * 1000.0;
		for(timer in sRunningTimers)
		{
			var sleep = timer.mFireAt - now;
			if (sleep<limit)
			{
				limit = sleep;
				if (limit<0) return 0;
			}
		}

      return limit;
	}

   function nmeCheck(inTime:Float)
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
         timer.nmeCheck(now);
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
		return t;
	}


   static public function stamp() : Float
   {
       return nme_time_stamp();
   }

	static var nme_time_stamp = nme.Loader.load("nme_time_stamp",0);
}


