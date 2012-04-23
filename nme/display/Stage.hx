package nme.display;
#if code_completion


extern class Stage extends DisplayObjectContainer {
	var align : StageAlign;
	@:require(flash11) var allowsFullScreen(default,null) : Bool;
	@:require(flash10_2) var color : Int;
	//@:require(flash10) var colorCorrection : ColorCorrection;
	//@:require(flash10) var colorCorrectionSupport(default,null) : ColorCorrectionSupport;
	@:require(flash11) var displayContextInfo(default,null) : String;
	var displayState : StageDisplayState;
	var focus : InteractiveObject;
	var frameRate : Float;
	var fullScreenHeight(default,null) : Int;
	var fullScreenSourceRect : nme.geom.Rectangle;
	var fullScreenWidth(default,null) : Int;
	var quality : StageQuality;
	var scaleMode : StageScaleMode;
	var showDefaultContextMenu : Bool;
	@:require(flash11) var softKeyboardRect(default,null) : nme.geom.Rectangle;
	//@:require(flash11) var stage3Ds(default,null) : nme.Vector<Stage3D>;
	var stageFocusRect : Bool;
	var stageHeight : Int;
	//@:require(flash10_2) var stageVideos(default,null) : nme.Vector<nme.media.StageVideo>;
	var stageWidth : Int;
	@:require(flash10_1) var wmodeGPU(default,null) : Bool;
	function invalidate() : Void;
	function isFocusInaccessible() : Bool;
}


#elseif (cpp || neko)
typedef Stage = neash.display.Stage;
#elseif js
typedef Stage = jeash.display.Stage;
#else
typedef Stage = flash.display.Stage;
#end