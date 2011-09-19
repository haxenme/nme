package haxe;
#if (!neko && !cpp)


// Original haxe.Timer class

class Timer {
	#if (neko || php)
	#else

	private var id : Null<Int>;

	#if js
	private static var arr = new Array<Timer>();
	private var timerId : Int;
	#end

	public function new( time_ms : Int ){
		#if flash9
			var me = this;
			id = untyped __global__["flash.utils.setInterval"](function() { me.run(); },time_ms);
		#elseif flash
			var me = this;
			id = untyped _global["setInterval"](function() { me.run(); },time_ms);
		#elseif js
			id = arr.length;
			arr[id] = this;
			timerId = untyped window.setInterval("haxe.Timer.arr["+id+"].run();",time_ms);
		#end
	}

	public function stop() {
		if( id == null )
			return;
		#if flash9
			untyped __global__["flash.utils.clearInterval"](id);
		#elseif flash
			untyped _global["clearInterval"](id);
		#elseif js
			untyped window.clearInterval(timerId);
			arr[id] = null;
			if( id > 100 && id == arr.length - 1 ) {
				// compact array
				var p = id - 1;
				while( p >= 0 && arr[p] == null )
					p--;
				arr = arr.slice(0,p+1);
			}
		#end
		id = null;
	}

	public dynamic function run() {
	}

	public static function delay( f : Void -> Void, time_ms : Int ) {
		var t = new haxe.Timer(time_ms);
		t.run = function() {
			t.stop();
			f();
		};
		return t;
	}

	#end
	
	public static function measure<T>( f : Void -> T, ?pos : PosInfos ) : T {
		var t0 = stamp();
		var r = f();
		Log.trace((stamp() - t0) + "s", pos);
		return r;
	}

	/**
		Returns a timestamp, in seconds
	**/
	public static function stamp() : Float {
		#if flash
			return flash.Lib.getTimer() / 1000;
		#elseif neko
			return neko.Sys.time();
		#elseif php
			return php.Sys.time();
		#elseif js
			return Date.now().getTime() / 1000;
		#elseif cpp
			return untyped __time_stamp();
		#else
			return 0;
		#end
	}

}
#else




// Custom haxe.Timer implementation for C++ and Neko

typedef TimerList = Array <Timer>;


class Timer {
	
	
	static var sRunningTimers:TimerList = [];
	
	var mTime:Float;
	var mFireAt:Float;
	var mRunning:Bool;
	
	
	public function new (time:Float) {
		
		mTime = time;
		sRunningTimers.push (this);
		mFireAt = GetMS () + mTime;
		mRunning = true;
		
	}
	
	
	// Set this with "run=..."
	dynamic public function run () {
		
		
		
	}
   
	
	public function stop ():Void {
		
		if (mRunning) {
			
			mRunning = false;
			sRunningTimers.remove (this);
			
		}
		
	}
	
	
	static public function nmeNextWake (limit:Float):Float {
		
		var now = nme_time_stamp () * 1000.0;
		
		for (timer in sRunningTimers) {
			
			var sleep = timer.mFireAt - now;
			
			if (sleep < limit) {
				
				limit = sleep;
				
				if (limit < 0) {
					
					return 0;
					
				}
				
			}
			
		}
		
		return limit;
		
	}
	

	function nmeCheck (inTime:Float) {
		
		if (inTime >= mFireAt) {
			
			mFireAt += mTime;
			run ();
			
		}
		
	}
	

	public static function nmeCheckTimers () {
		
		var now = GetMS ();
		
		for (timer in sRunningTimers) {
			
			timer.nmeCheck (now);
			
		}
		
	}
	
	
	static function GetMS ():Float {
		
		return stamp () * 1000.0;
		
	}
	

   // From std/haxe/Timer.hx
	public static function delay (f:Void -> Void, time:Int) {
		
		var t = new Timer (time);
		
		t.run = function () {
			t.stop ();
			f ();
		};
		
		return t;
		
	}
	
	
	static public function stamp ():Float {
		
		return nme_time_stamp ();
		
	}
	

	static var nme_time_stamp = nme.Loader.load ("nme_time_stamp", 0);
	
	
}
#end