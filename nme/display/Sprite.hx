package nme.display;
#if (cpp || neko)


import nme.geom.Rectangle;


class Sprite extends DisplayObjectContainer
{
	
	
	// ignored right now
	public var buttonMode:Bool;
	public var useHandCursor:Bool;
	
	
	public function new()
	{
		super(DisplayObjectContainer.nme_create_display_object_container(), nmeGetType());
	}
	
	
	private function nmeGetType()
	{
		return "Sprite";
	}
	
	
	public function startDrag(lockCenter:Bool = false, ?bounds:Rectangle):Void
	{
		if (stage != null)
			stage.nmeStartDrag(this, lockCenter, bounds);
	}
	
	
	public function stopDrag():Void
	{
		if (stage != null)
			stage.nmeStopDrag(this);
	}
	
}


#elseif js


import nme.display.Graphics;
import nme.display.InteractiveObject;
import nme.geom.Matrix;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.Lib;
import nme.events.MouseEvent;

class Sprite extends DisplayObjectContainer {
	var jeashGraphics:Graphics;
	public var graphics(jeashGetGraphics,null):Graphics;
	public var useHandCursor(default,jeashSetUseHandCursor):Bool;
	public var buttonMode:Bool;
	public var dropTarget(jeashGetDropTarget,null):DisplayObject;

	var jeashCursorCallbackOver:Dynamic->Void;
	var jeashCursorCallbackOut:Dynamic->Void;
	var jeashDropTarget:DisplayObject;

	public function new() {
		Lib.canvas;
		jeashGraphics = new Graphics();
		if(jeashGraphics!=null)
			jeashGraphics.owner = this;
		super();
		buttonMode = false;
		name = "Sprite " + DisplayObject.mNameID++;
		Lib.jeashSetSurfaceId(jeashGraphics.jeashSurface, name);
	}

	public function startDrag(?lockCenter:Bool, ?bounds:Rectangle):Void {
		if (stage != null)
			stage.jeashStartDrag(this, lockCenter, bounds);
	}

	public function stopDrag():Void {
		if (stage != null) {
			stage.jeashStopDrag(this);
			var l = parent.jeashChildren.length-1;
			var obj:DisplayObject = stage;
			for(i in 0...parent.jeashChildren.length) {
				var result = parent.jeashChildren[l-i].jeashGetObjectUnderPoint(new Point(stage.mouseX, stage.mouseY));
				if (result != null) obj = result;
			}

			if (obj != this)
				jeashDropTarget = obj;
			else
				jeashDropTarget = stage;
		}
	}

	override function jeashGetGraphics() { 
		return jeashGraphics; 
	}

	function jeashSetUseHandCursor(cursor:Bool) {
		if (cursor == this.useHandCursor) return cursor;

		if (jeashCursorCallbackOver != null)
			removeEventListener(MouseEvent.ROLL_OVER, jeashCursorCallbackOver);
		if (jeashCursorCallbackOut != null)
			removeEventListener(MouseEvent.ROLL_OUT, jeashCursorCallbackOut);

		if (!cursor) {
			Lib.jeashSetCursor(false);
		} else {
			jeashCursorCallbackOver = function (_) { Lib.jeashSetCursor(true); }
			jeashCursorCallbackOut = function (_) { Lib.jeashSetCursor(false); }
			addEventListener(MouseEvent.ROLL_OVER, jeashCursorCallbackOver);
			addEventListener(MouseEvent.ROLL_OUT, jeashCursorCallbackOut);
		}
		this.useHandCursor = cursor;

		return cursor;
	}

	function jeashGetDropTarget() return jeashDropTarget
}


#else
typedef Sprite = flash.display.Sprite;
#end