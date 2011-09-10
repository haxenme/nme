package nme.display;


#if flash
@:native ("flash.display.Scene")
@:final extern class Scene {
	var labels(default,null) : Array<FrameLabel>;
	var name(default,null) : String;
	var numFrames(default,null) : Int;
	function new(name : String, labels : Array<FrameLabel>, numFrames : Int) : Void;
}
#end