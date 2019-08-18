package nme.display;
#if (!flash)

@:nativeProperty
#if haxe4
class MovieClip extends Sprite
#else
class MovieClip extends Sprite implements Dynamic<DisplayObject>
#end
{
   public var currentFrame(get, null):Int;
   public var enabled:Bool;
   public var framesLoaded(get, null):Int;
   public var totalFrames(get, null):Int;

   var mCurrentFrame:Int;
   var mTotalFrames:Int;

   // Openfl alias
   private var __currentFrame(get,set):Int;
   function get___currentFrame() return mCurrentFrame;
   function set___currentFrame(f) return mCurrentFrame=f;
   private var __totalFrames(get,set):Int;
   function get___totalFrames() return mTotalFrames;
   function set___totalFrames(f) return mTotalFrames=f;

   private var __frameScripts:Map<Int, Void->Void>;
   private var __currentLabels:Array<FrameLabel>;
   private var __currentFrameLabel:String;
   private var __currentLabel:String;


   public function new() 
   {
      super();

      mCurrentFrame = 0;
      mTotalFrames = 0;
      __currentLabels = [];
      enabled = true;
   }

   public function gotoAndPlay(frame:Dynamic, ?scene:String):Void 
   {
   }

   public function gotoAndStop(frame:Dynamic, ?scene:String):Void 
   {
   }
   
   public function nextFrame():Void
   {
   }

   /** @private */ override function nmeGetType() {
      return "MovieClip";
   }

   public function play():Void 
   {
   }
   
   public function prevFrame():Void
   {
   }

   public function stop():Void 
   {
   }

   // Getters & Setters
   /** @private */ private function get_currentFrame() { return mCurrentFrame; }
   /** @private */ private function get_framesLoaded() { return mTotalFrames; }
   /** @private */ private function get_totalFrames() { return mTotalFrames; }
}

#else
typedef MovieClip = flash.display.MovieClip;
#end
