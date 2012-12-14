package native.display;


class MovieClip extends Sprite {
	
	
	public var currentFrame (get_currentFrame, null):Int;
	public var enabled:Bool;
	public var framesLoaded (get_framesLoaded, null):Int;
	public var totalFrames (get_totalFrames, null):Int;
	
	/** @private */ private var mCurrentFrame:Int;
	/** @private */ private var mTotalFrames:Int;
	
	
	public function new () {
		
		super ();
		
		mCurrentFrame = 0;
		mTotalFrames = 0;
		
	}
	
	
	public function gotoAndPlay (frame:Dynamic, ?scene:String):Void {
		
		
		
	}
	
	
	public function gotoAndStop (frame:Dynamic, ?scene:String):Void {
		
		
		
	}
	
	
	/** @private */ override function nmeGetType () {
		
		return "MovieClip";
		
	}
	
	
	public function play ():Void {
		
		
		
	}
	
	
	public function stop ():Void {
		
		
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	/** @private */ private function get_currentFrame () { return mCurrentFrame; }
	/** @private */ private function get_framesLoaded () { return mTotalFrames; }
	/** @private */ private function get_totalFrames () { return mTotalFrames; }
	
	
}