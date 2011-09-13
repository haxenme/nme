package nme.display;
#if cpp || neko


class MovieClip extends Sprite
{
   public function new()
	{
	   super();
      mCurrentFrame = 0;
      mTotalFrames = 0;
	}

   override function nmeGetType() { return "MovieClip"; }


   public var enabled:Bool;
   public var currentFrame(GetCurrentFrame,null):Int;
   public var framesLoaded(GetTotalFrames,null):Int;
   public var totalFrames(GetTotalFrames,null):Int;

   var mCurrentFrame:Int;
   var mTotalFrames:Int;

   function GetTotalFrames() { return mTotalFrames; }
   function GetCurrentFrame() { return mCurrentFrame; }

   public function gotoAndPlay(frame:Dynamic, ?scene:String):Void { }
   public function gotoAndStop(frame:Dynamic, ?scene:String):Void { }
   public function play():Void { }
   public function stop():Void { }

}


#else
typedef MovieClip = flash.display.MovieClip;
#end