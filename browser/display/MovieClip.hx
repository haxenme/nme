package browser.display;


class MovieClip extends Sprite, implements Dynamic<Dynamic> {
	
	
	public var currentFrame (get_currentFrame, null):Int;
	public var enabled:Bool;
	public var framesLoaded (get_framesLoaded, null):Int;
	public var loaderInfo:LoaderInfo;
	public var totalFrames (get_totalFrames, null):Int;
	
	private var mCurrentFrame:Int;
	private var mTotalFrames:Int;
	
	
	public function new () {
		
		super ();
		
		enabled = true;
		mCurrentFrame = 0;
		mTotalFrames = 0;
		
		this.loaderInfo = LoaderInfo.create (null);
		
	}
	
	
	public function gotoAndPlay (frame:Dynamic, scene:String = ""):Void {
		
		
		
	}
	
	
	public function gotoAndStop (frame:Dynamic, scene:String = ""):Void {
		
		
		
	}
	
	
	public function play ():Void {
		
		
		
	}
	
	
	public function stop ():Void {
		
		
		
	}
	
	
	override public function toString ():String {
		
		return "[MovieClip name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_currentFrame ():Int { return mCurrentFrame; }
	private function get_framesLoaded ():Int { return mTotalFrames; }
	private function get_totalFrames ():Int { return mTotalFrames; }
	
	
}