package nme.display;
#if (cpp || neko)


class MovieClip extends Sprite
{
	
	public var currentFrame(nmeGetCurrentFrame, null):Int;
	public var enabled:Bool;
	public var framesLoaded(nmeGetTotalFrames, null):Int;
	public var totalFrames(nmeGetTotalFrames, null):Int;
	
	private var mCurrentFrame:Int;
	private var mTotalFrames:Int;
	

	public function new()
	{
		super();
		mCurrentFrame = 0;
		mTotalFrames = 0;
	}
	
	
	public function gotoAndPlay(frame:Dynamic, ?scene:String):Void
	{
		
	}
	
	
	public function gotoAndStop(frame:Dynamic, ?scene:String):Void
	{
		
	}
	
	
	override function nmeGetType()
	{
		return "MovieClip";
	}
	
	
	public function play():Void
	{
		
	}
	
	
	public function stop():Void
	{
		
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetCurrentFrame() { return mCurrentFrame; }
	private function nmeGetTotalFrames() { return mTotalFrames; }

}


#elseif js

class MovieClip extends Sprite
{
   public var enabled:Bool;
   public var currentFrame(GetCurrentFrame,null):Int;
   public var framesLoaded(GetTotalFrames,null):Int;
   public var totalFrames(GetTotalFrames,null):Int;

   var mCurrentFrame:Int;
   var mTotalFrames:Int;

   function GetTotalFrames() { return mTotalFrames; }
   function GetCurrentFrame() { return mCurrentFrame; }

   public function new()
   {
      super();
      enabled = true;
      mCurrentFrame = 0;
      mTotalFrames = 0;
      name = "MovieClip " + flash.display.DisplayObject.mNameID++;
   }

   public function gotoAndPlay(frame:Dynamic, ?scene:String):Void { }
   public function gotoAndStop(frame:Dynamic, ?scene:String):Void { }
   public function play():Void { }
   public function stop():Void { }


}

#else
typedef MovieClip = flash.display.MovieClip;
#end

