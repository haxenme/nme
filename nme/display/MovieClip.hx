package nme.display;


#if flash
@:native ("flash.display.MovieClip")
extern class MovieClip extends Sprite #if !flash_strict, implements Dynamic #end {
	var currentFrame(default,null) : Int;
	@:require(flash10) var currentFrameLabel(default,null) : String;
	var currentLabel(default,null) : String;
	var currentLabels(default,null) : Array<FrameLabel>;
	var currentScene(default,null) : Scene;
	var enabled : Bool;
	var framesLoaded(default,null) : Int;
	var scenes(default,null) : Array<Scene>;
	var totalFrames(default,null) : Int;
	var trackAsMenu : Bool;
	function new() : Void;
	function addFrameScript(?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic) : Void;
	function gotoAndPlay(frame : Dynamic, ?scene : String) : Void;
	function gotoAndStop(frame : Dynamic, ?scene : String) : Void;
	function nextFrame() : Void;
	function nextScene() : Void;
	function play() : Void;
	function prevFrame() : Void;
	function prevScene() : Void;
	function stop() : Void;
}
#else



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
#end