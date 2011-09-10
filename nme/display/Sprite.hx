package nme.display;


#if flash
@:native ("flash.display.Sprite")
extern class Sprite extends DisplayObjectContainer {
	var buttonMode : Bool;
	var dropTarget(default,null) : DisplayObject;
	var graphics(default,null) : Graphics;
	var hitArea : Sprite;
	var soundTransform : nme.media.SoundTransform;
	var useHandCursor : Bool;
	function new() : Void;
	function startDrag(lockCenter : Bool = false, ?bounds : nme.geom.Rectangle) : Void;
	@:require(flash10_1) function startTouchDrag(touchPointID : Int, lockCenter : Bool = false, ?bounds : nme.geom.Rectangle) : Void;
	function stopDrag() : Void;
	@:require(flash10_1) function stopTouchDrag(touchPointID : Int) : Void;
}
#else



class Sprite extends DisplayObjectContainer
{
   public function new()
	{
	   super(DisplayObjectContainer.nme_create_display_object_container(),nmeGetType());
	}

   public function startDrag(lockCenter:Bool = false, ?bounds:nme.geom.Rectangle):Void
	{
		if (stage!=null)
			stage.nmeStartDrag(this,lockCenter,bounds);
	}

	public function stopDrag() : Void
	{
		if (stage!=null)
			stage.nmeStopDrag(this);
	}
   function nmeGetType() { return "Sprite"; }
}
#end